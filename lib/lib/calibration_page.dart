import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
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

  // Accelerometer (For Elevation/Tilt)
  double _currentElevationAngle = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Timer
  Timer? _jumpTimer;
  double _timerValue = 0.0;

  // State Flags
  bool _isCalibrated = false;
  bool _isJumping = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  void _initSensors() {
    // 1. Initialize Barometer & Calculate Altitude Live
    _barometerSubscription = barometerEventStream().listen((
      BarometerEvent event,
    ) {
      if (mounted) {
        // Calculate current altitude immediately
        double currentAltitude =
            44330 * (1.0 - pow(event.pressure / 1013.25, 0.1903));

        setState(() {
          _currentPressure = event.pressure;
        });

        // --- NEW LOGIC: Calculate Max Jump Height ---
        // Only run this if we are in the "Jumping" phase and have a baseline
        if (_isJumping && globals.calibration_value != null) {
          // Calculate height difference from baseline
          double currentJumpDiff = currentAltitude - globals.calibration_value!;

          // Update max if this is the highest point reached so far
          // We use 0.0 as a floor (ignore negative dips below start point)
          if (currentJumpDiff > (globals.max_jump_height ?? 0.0)) {
            globals.max_jump_height = currentJumpDiff;
          }
        }
      }
    }, onError: (e) => print("Barometer error: $e"));

    // 2. Initialize Accelerometer
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
      _showMessage("Waiting for sensor data...");
      return;
    }

    // Set Baseline Altitude
    double altitude = 44330 * (1.0 - pow(_currentPressure / 1013.25, 0.1903));
    globals.calibration_value = altitude;

    globals.starting_elevation = _currentElevationAngle;
    globals.jumping_elevation = 0.0;
    globals.jump_duration = 0.0;
    globals.max_jump_height = 0.0; // Reset max height

    setState(() {
      _isCalibrated = true;
      _isFinished = false;
    });

    _showMessage(
      "Calibration Set! Elevation: ${globals.starting_elevation!.toStringAsFixed(1)}°",
    );
  }

  // --- LOGIC: JUMP ---
  void _handleJump() {
    // Reset jump specific stats before starting
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
    });

    print("JUMP STARTED. Base Alt: ${globals.calibration_value}");
  }

  // --- LOGIC: STOP ---
  void _handleStop() {
    _jumpTimer?.cancel();
    setState(() {
      _isJumping = false;
      _isFinished = true;
    });

    print("=== JUMP SESSION FINISHED ===");
    print("Duration: ${globals.jump_duration!.toStringAsFixed(1)}s");
    print(
      "Max Elevation Gain: ${globals.jumping_elevation.toStringAsFixed(1)}°",
    );
    print("Max Jump Height: ${globals.max_jump_height?.toStringAsFixed(3)}m");
  }

  // --- LOGIC: EVALUATE ---
  void _handleEvaluate() {
    print("Evaluate button pressed.");
    _showMessage("Evaluation logic not implemented yet.");
  }

  // --- LOGIC: RESET ---
  void _resetCalibration() {
    _jumpTimer?.cancel();
    setState(() {
      _isCalibrated = false;
      _isJumping = false;
      _isFinished = false;
      globals.calibration_value = null;
      globals.starting_elevation = null;
      globals.jumping_elevation = 0.0;
      globals.jump_duration = 0.0;
      globals.max_jump_height = 0.0; // Reset
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00E5FF),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // Clouds
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

          // Main Content
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

                  // Instruction Text
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

                  // Live Timer
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

                  // --- MAIN ACTION BUTTON (SET / JUMP / STOP) ---
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

                  // --- RESET BUTTON ---
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

                  // --- DEBUG INFO ---
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
                          const SizedBox(height: 5),
                          Text(
                            "Start Angle: ${globals.starting_elevation?.toStringAsFixed(1)}°",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            "Max Gain: ${globals.jumping_elevation.toStringAsFixed(1)}°",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          // --- NEW: Display Max Jump Height ---
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

                    // --- EVALUATE BUTTON ---
                    GestureDetector(
                      onTap: _handleEvaluate,
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
                        child: const Text(
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

          // Back Button
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
