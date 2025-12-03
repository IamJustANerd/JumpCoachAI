import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'globals.dart' as globals;

class CalibrationPage extends StatefulWidget {
  const CalibrationPage({super.key});

  @override
  State<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  // Barometer
  double _currentPressure = 0.0;
  StreamSubscription<BarometerEvent>? _barometerSubscription;

  // Accelerometer
  double _currentElevationAngle = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Timer
  Timer? _jumpTimer;
  double _timerValue = 0.0;

  // State Flags
  bool _isCalibrated = false;
  bool _isJumping = false;
  bool _isFinished = false;

  bool _usingMockData = false;
  bool _isLoading = false;

  // ⚠️ SERVER CONFIGURATION
  final String _baseUrl = 'http://192.168.43.113:5000';
  String get _predictUrl => '$_baseUrl/predict_score';
  String get _feedbackUrl => '$_baseUrl/generate_feedback';

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  void _initSensors() {
    _barometerSubscription = barometerEventStream().listen(
      (BarometerEvent event) {
        if (mounted) {
          double currentAltitude =
              44330 * (1.0 - pow(event.pressure / 1013.25, 0.1903));
          setState(() {
            _currentPressure = event.pressure;
            _usingMockData = false;
          });

          if (_isJumping && globals.calibration_value != null) {
            double heightDiff = currentAltitude - globals.calibration_value!;
            if (heightDiff > 0) {
              if (heightDiff > (globals.max_jump_height ?? 0.0)) {
                globals.max_jump_height = heightDiff;
              }
            }
          }
        }
      },
      onError: (e) {
        print("Barometer error: $e");
      },
    );

    _accelerometerSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      if (mounted) {
        double angle = atan2(event.y, event.z) * 180 / pi;
        setState(() {
          _currentElevationAngle = angle;
        });

        if (_isJumping && globals.starting_elevation != null) {
          double diff = (_currentElevationAngle - globals.starting_elevation!)
              .abs();
          if (diff > globals.jumping_elevation) {
            globals.jumping_elevation = diff;
          }
        }
      }
    }, onError: (e) => print("Accelerometer error: $e"));
  }

  @override
  void dispose() {
    _barometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _jumpTimer?.cancel();
    super.dispose();
  }

  // --- LOGIC: SET ---
  void _setCalibration() {
    if (_currentPressure <= 0.0) {
      setState(() {
        _currentPressure = 1013.25;
        _usingMockData = true;
      });
      _showMessage("No Sensor. Using MOCK Data.");
    }

    double altitude = 44330 * (1.0 - pow(_currentPressure / 1013.25, 0.1903));
    globals.calibration_value = altitude;
    globals.starting_elevation = _currentElevationAngle;
    globals.jumping_elevation = 0.0;
    globals.jump_duration = 0.0;
    globals.max_jump_height = 0.0;

    setState(() {
      _isCalibrated = true;
      _isFinished = false;
    });

    if (!_usingMockData) {
      _showMessage(
        "Calibration Set! Base Alt: ${altitude.toStringAsFixed(1)}m",
      );
    }
  }

  // --- LOGIC: JUMP ---
  void _handleJump() {
    globals.max_jump_height = 0.0;
    globals.jumping_elevation = 0.0;

    setState(() {
      _isJumping = true;
      _timerValue = 0.0;
    });

    _jumpTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _timerValue += 0.1;
        globals.jump_duration = _timerValue;
      });

      if (_usingMockData && _timerValue > 1.0 && _timerValue < 2.0) {
        globals.max_jump_height = 0.50;
      }
    });
  }

  // --- LOGIC: STOP ---
  void _handleStop() {
    _jumpTimer?.cancel();
    setState(() {
      _isJumping = false;
      _isFinished = true;
    });
  }

  double _parseSafeDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // --- LOGIC: EVALUATE ---
  Future<void> _handleEvaluate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage("Error: User not logged in.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Fetch User Data
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) throw Exception("User profile not found.");

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      double weightKg = _parseSafeDouble(userData['weight'], 70.0);
      double heightRaw = _parseSafeDouble(userData['height'], 170.0);
      double heightM = heightRaw > 3.0 ? heightRaw / 100.0 : heightRaw;

      // Prepare Metrics
      double maxJumpM = globals.max_jump_height ?? 0.0;
      double jumpVsHeight = heightM > 0 ? (maxJumpM / heightM) : 0.0;

      // 2. GET SCORE API Call
      Map<String, dynamic> scoreBody = {
        "height_m": heightM,
        "weight_kg": weightKg,
        "airtime_s": globals.jump_duration,
        "max_jump_m": maxJumpM,
        "jump_vs_height": jumpVsHeight,
        "tilt_deg_mean": globals.jumping_elevation,
      };

      final scoreResponse = await http.post(
        Uri.parse(_predictUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(scoreBody),
      );

      if (scoreResponse.statusCode != 200) {
        throw Exception("Score API Error: ${scoreResponse.statusCode}");
      }

      var jsonResponse = jsonDecode(scoreResponse.body);
      double rawScore = 0.0;
      if (jsonResponse is Map && jsonResponse.containsKey('score')) {
        rawScore = _parseSafeDouble(jsonResponse['score'], 0.0);
      } else if (jsonResponse is num) {
        rawScore = jsonResponse.toDouble();
      }

      String formattedScore = rawScore.toStringAsFixed(1);

      // --- 3. SAVE TO FIRESTORE (New Logic) ---
      // A. Update History
      List<dynamic> currentHistory = userData['history'] ?? [];
      currentHistory.add(double.parse(formattedScore)); // Add new score

      // B. Update Best Jump Height
      double existingBest = _parseSafeDouble(userData['bestJumpHeight'], 0.0);
      double currentJump = globals.max_jump_height ?? 0.0;
      double newBest = (currentJump > existingBest)
          ? currentJump
          : existingBest;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'history': currentHistory, 'bestJumpHeight': newBest},
      );
      print("✅ Firestore Updated: Score $formattedScore added, Best: $newBest");

      // 4. GET FEEDBACK API Call
      Map<String, dynamic> feedbackBody = {
        "score": formattedScore,
        "tilt_deg_mean": globals.jumping_elevation,
        "airtime_s": globals.jump_duration,
        "jump_vs_height": jumpVsHeight,
      };

      final feedbackResponse = await http.post(
        Uri.parse(_feedbackUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(feedbackBody),
      );

      String feedbackText = "No feedback received.";
      if (feedbackResponse.statusCode == 200) {
        try {
          var fbJson = jsonDecode(feedbackResponse.body);
          if (fbJson is Map && fbJson.containsKey('feedback')) {
            feedbackText = fbJson['feedback'].toString();
          } else {
            feedbackText = feedbackResponse.body;
          }
        } catch (e) {
          feedbackText = feedbackResponse.body;
        }
      } else {
        feedbackText = "Feedback Error: ${feedbackResponse.statusCode}";
      }

      if (mounted) _showResultDialog(formattedScore, feedbackText);
    } catch (e) {
      print("Evaluation Error: $e");
      _showMessage("Failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showResultDialog(String score, String feedback) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            "JUMP ANALYSIS",
            style: TextStyle(
              color: Color(0xFF00FFFF),
              fontFamily: 'LexendMega',
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "SCORE",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                score,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LexendMega',
                ),
              ),
              const SizedBox(height: 20),
              Container(height: 2, width: 100, color: Colors.white24),
              const SizedBox(height: 20),
              const Text(
                "COACH FEEDBACK",
                style: TextStyle(
                  color: Color(0xFF00FFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                feedback,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "CLOSE",
                style: TextStyle(color: Color(0xFF00FFFF), fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIC: RESET ---
  void _resetCalibration() {
    _jumpTimer?.cancel();
    setState(() {
      _isCalibrated = false;
      _isJumping = false;
      _isFinished = false;
      _usingMockData = false;
      _currentPressure = 0.0;

      globals.calibration_value = null;
      globals.starting_elevation = null;
      globals.jumping_elevation = 0.0;
      globals.jump_duration = 0.0;
      globals.max_jump_height = 0.0;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00E5FF),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          Positioned(
            top: 60,
            left: -20,
            child: Image.asset(
              'assets/cloud.png',
              width: 120,
              color: const Color(0xFF00E5FF).withOpacity(0.2),
              colorBlendMode: BlendMode.srcATop,
            ),
          ),
          Positioned(
            bottom: 100,
            right: -20,
            child: Image.asset(
              'assets/cloud.png',
              width: 140,
              color: const Color(0xFF00E5FF).withOpacity(0.2),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "CALIBRATION",
                    style: TextStyle(
                      fontFamily: 'LexendMega',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00FFFF),
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _isJumping
                          ? "Recording Jump... Press STOP when done."
                          : _isCalibrated
                          ? "Ready? Press JUMP to start recording."
                          : "Place phone on ground to set baseline.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),

                  if (_isJumping)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "${_timerValue.toStringAsFixed(1)}s",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  GestureDetector(
                    onTap: _isJumping
                        ? _handleStop
                        : (_isCalibrated ? _handleJump : _setCalibration),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          _isJumping
                              ? 'assets/button_stop.png'
                              : 'assets/button_start.png',
                          width: 220,
                          height: 220,
                          fit: BoxFit.contain,
                        ),
                        Text(
                          _isJumping
                              ? 'STOP'
                              : (_isCalibrated ? 'JUMP' : 'SET'),
                          style: const TextStyle(
                            fontFamily: 'LexendMega',
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_isCalibrated && !_isJumping) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: 140,
                      height: 45,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white30, width: 1.5),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TextButton(
                        onPressed: _resetCalibration,
                        child: const Text(
                          "RESET",
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (_isFinished) ...[
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "DEBUG DATA",
                            style: TextStyle(
                              color: Color(0xFF00FFFF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_usingMockData)
                            const Text(
                              "(MOCK DATA)",
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                              ),
                            ),
                          const SizedBox(height: 5),
                          Text(
                            "Max Elevation Gain: ${globals.jumping_elevation.toStringAsFixed(1)}°",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            "Max Height: ${(globals.max_jump_height ?? 0.0).toStringAsFixed(3)} m",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Duration: ${globals.jump_duration!.toStringAsFixed(1)}s",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // EVALUATE BUTTON
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : _handleEvaluate, // Disable if loading
                      child: Container(
                        width: 200,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FFFF),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FFFF).withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "EVALUATE",
                                style: TextStyle(
                                  fontFamily: 'LexendMega',
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
