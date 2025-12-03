import 'package:flutter/material.dart';
import 'home_page.dart'; // Import the page you are navigating TO

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

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

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

    // 2) fade logo out while welcome text animates in
    _logoController.reverse();
    await _welcomeController.forward();

    await Future.delayed(const Duration(milliseconds: 500));

    // 3) slide the whole splash screen up
    await _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, animation, secondaryAnimation) =>
          const MyHomePage(title: 'Jumpcoach Home'),
          transitionsBuilder: (_, animation, __, child) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
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
        child: Center(
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
                    width: 150,
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