import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation_screen.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _progressController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeIn),
      ),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOutCubic),
    );

    _animController.forward();
    _startProgressAndNavigate();
  }

  Future<void> _startProgressAndNavigate() async {
    // Start continuous 0% -> 100% progress animation
    final progressFuture = _progressController.forward();

    // Ensure AuthProvider initialization has completed without blocking UI
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoading) {
      final completer = Completer<void>();
      void listener() {
        if (!authProvider.isLoading) {
          authProvider.removeListener(listener);
          if (!completer.isCompleted) completer.complete();
        }
      }
      authProvider.addListener(listener);
      // Wait for auth readiness or fallback timeout
      await Future.any([
        completer.future,
        Future.delayed(const Duration(milliseconds: 1000)),
      ]);
      authProvider.removeListener(listener);
    }

    // Await completion of the full 0% -> 100% animation
    await progressFuture;

    if (!mounted) return;
    await _navigateNext();
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, anim, secAnim) => const MainNavigationScreen(),
          transitionsBuilder: (ctx, animation, secAnim, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, anim, secAnim) => const LoginScreen(),
          transitionsBuilder: (ctx, animation, secAnim, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Center Logo & Content
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Brand Title: Bold Yellow TWIST
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppStrings.appName,
                          style: AppTypography.splashTitle.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            color: AppColors.primaryYellow,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tagline
                      Text(
                        AppStrings.appTagline,
                        textAlign: TextAlign.center,
                        style: AppTypography.splashTagline.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom minimalist progress bar (Matching Reference Panel 1)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Container(
                      width: 130,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryYellow,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
