import 'package:flutter/material.dart';

/*
Buat jalanin di chrome:
flutter build web
flutter run -d web-server
masukin localhost
*/

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animated Entrance Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _welcomeController;
  late AnimationController _slideController;

  late Animation<double> _logoFade;
  late Animation<Offset> _logoMove;
  late Animation<double> _welcomeFade;
  late Animation<Offset> _welcomeMove;
  late Animation<Offset> _screenSlide;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation( parent: _logoController, curve: Curves.easeOut, ));

    _logoMove = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.0))
        .animate(CurvedAnimation(
      parent: _welcomeController,
      curve: Curves.easeInOut,
    ));

    _welcomeFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _welcomeController,
      curve: Curves.easeOut,
    ));

    _welcomeMove =
        Tween<Offset>(begin: const Offset(0, 0.5), end: const Offset(0, -0.2))
            .animate(CurvedAnimation(
          parent: _welcomeController,
          curve: Curves.easeInOut,
        ));

    _screenSlide =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1)).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );

    _playAnimationSequence();
  }

  Future<void> _playAnimationSequence() async {
    // 1) fade logo in
    await _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 500));

    // 2) fade logo out while welcome text animates in (run both together)
    _logoController.reverse(); // start fading out
    await _welcomeController.forward(); // start moving logo up & welcome in
    // alternatively wait for both explicitly:
    // await Future.wait([ _logoController.reverse(), _welcomeController.forward() ]);

    await Future.delayed(const Duration(milliseconds: 500));

    // 3) slide the whole splash screen up
    await _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, animation, secondaryAnimation) =>
          const MyHomePage(title: 'Flutter Demo Home Page'),
          transitionsBuilder: (_, animation, __, child) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0, 1), // start from bottom
              end: Offset.zero, // move to normal position
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        ),
      );
    }
  }


  @override
  void dispose() {
    _logoController.dispose();
    _welcomeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SlideTransition(
        position: _screenSlide,
        child: Center( // <-- Center vertically & horizontally
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Logo Animation
              FadeTransition(
                opacity: _logoFade,
                child: SlideTransition(
                  position: _logoMove,
                  child: Image.asset(
                    'assets/logo.png',
                    width: 150, // adjust as needed
                    height: 150,
                  ),
                ),
              ),

              // Welcome Text Animation
              FadeTransition(
                opacity: _welcomeFade,
                child: SlideTransition(
                  position: _welcomeMove,
                  child: const Text(
                    'Welcome',
                    style: TextStyle(
                      fontFamily: 'LexendMega',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                      // TODO: navigate to next page
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