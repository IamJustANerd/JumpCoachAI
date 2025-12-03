import 'package:flutter/material.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // --- Top Left Cloud ---
          Positioned(
            top: 60,
            left: -20, // Negative to cut it off slightly like design
            child: Image.asset(
              'assets/cloud.png',
              width: 120,
              color: const Color(
                0xFF00E5FF,
              ).withOpacity(0.2), // Tinted cyan slightly
              colorBlendMode: BlendMode.srcATop,
            ),
          ),

          // --- Bottom Right Cloud ---
          Positioned(
            bottom: 100,
            right: -20,
            child: Image.asset(
              'assets/cloud.png',
              width: 140,
              color: const Color(0xFF00E5FF).withOpacity(0.2),
            ),
          ),

          // --- Main Content ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "ERROR",
                  style: TextStyle(
                    fontFamily: 'LexendMega', // Assuming you use this font
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "ALERT",
                  style: TextStyle(
                    fontFamily: 'LexendMega',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Your profile is incomplete. We need your Height and Weight to calculate your jump metrics accurately.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // --- Back Button ---
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "Back",
                      style: TextStyle(
                        color: Color(0xFF00FFFF), // Cyan text
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Bottom Cyan Line ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              width: 120,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF00FFFF).withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
