import 'dart:async';

import 'package:flutter/material.dart';
import 'package:studybuddy/screens/homepage.dart';
import 'package:studybuddy/shared/app_palette.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
    _startSplashFlow();
  }

  Future<void> _startSplashFlow() async {
    const Duration visibleDuration = Duration(milliseconds: 2400);

    _navigationTimer = Timer(visibleDuration, () async {
      if (!mounted) {
        return;
      }

      await _controller.reverse();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 550),
          pageBuilder: (context, primaryAnimation, secondaryAnimation) =>
              const Homepage(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            final Animation<double> fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            final Animation<Offset> slide = Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppPalette.primarySoft,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.black, width: 1.8),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 50,
                        color: AppPalette.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'StudyBuddy',
                      style: TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Plan smarter. Focus better.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppPalette.textMuted,
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppPalette.primary,
                        ),
                        backgroundColor: AppPalette.primarySoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
