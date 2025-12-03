import 'package:flutter/material.dart';
import 'login.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // --- Top-left decorative cloud ---
          Positioned(
            top: 60,
            left: 20,
            child: Image.asset(
              'assets/cloud.png',
              width: 120,
              opacity: const AlwaysStoppedAnimation(0.8),
            ),
          ),

          // --- Bottom-right decorative cloud ---
          Positioned(
            bottom: 60,
            right: 20,
            child: Image.asset(
              'assets/cloud.png',
              width: 120,
              opacity: const AlwaysStoppedAnimation(0.8),
            ),
          ),

          // --- Main centered content ---
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/logo.png',
                    width: 120,
                  ),
                  const SizedBox(height: 0),

                  // Description
                  const Text(
                    "Welcome to Jumpcoach!\nYour personal AI Vertical Jump Coach that come in handy.\nNo money need to be spend to get better on your journey.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // "NEXT" button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00FFFF), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 28),
                    ),
                    child: const Text(
                      'NEXT',
                      style: TextStyle(
                        fontFamily: 'LexendMega',
                        color: Color(0xFF00FFFF),
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
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