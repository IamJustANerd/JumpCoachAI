import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile.dart';
import 'error_page.dart';
import 'calibration_page.dart'; // <--- 1. Import the Calibration Page

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _username = "User";
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          setState(() {
            _username = doc['username'] ?? "User";
          });
        }
      } catch (e) {
        if (user!.email != null) {
          setState(() {
            _username = user!.email!.split('@')[0];
          });
        }
      }
    }
  }

  // --- Logic to Check User Data on Start ---
  Future<void> _handleStart() async {
    if (user == null) return;

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Check if weight or height is missing
        bool hasWeight = data.containsKey('weight') && data['weight'] != null;
        bool hasHeight = data.containsKey('height') && data['height'] != null;

        if (!hasWeight || !hasHeight) {
          // MISSING DATA -> Show Error Page
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ErrorPage()),
            );
          }
        } else {
          // DATA EXISTS -> Navigate to Calibration Page
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CalibrationPage()), // <--- 2. Navigate here
            );
          }
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 40),

                  // --- Top Text Section ---
                  Column(
                    children: [
                      Text(
                        "Hi, $_username!",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Are you Ready to break your record before?",
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),

                  // --- Middle START Button ---
                  GestureDetector(
                    onTap: _handleStart,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'assets/button_start.png',
                          width: 220,
                          height: 220,
                          fit: BoxFit.contain,
                        ),
                        const Text(
                          'START',
                          style: TextStyle(
                            fontFamily: 'LexendMega',
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Bottom "Last Attempt" Section ---
                  Column(
                    children: const [
                      Text(
                        "Last Attempt",
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "100cm",
                        style: TextStyle(
                          fontFamily: 'LexendMega',
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Height",
                        style: TextStyle(
                          color: Color(0xFF00FFFF),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // --- Custom Bottom Navigation Bar ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.history,
                      color: Colors.black,
                      size: 28,
                    ),
                    onPressed: () {
                      /* Navigate History */
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.sync,
                      color: Color(0xFF00FFFF),
                      size: 36,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardPage(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.person_outline,
                      color: Colors.black,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}