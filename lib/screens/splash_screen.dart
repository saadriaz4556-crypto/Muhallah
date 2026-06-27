import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Brand palette (kept from your RN file)
  static const Color primaryTeal = Color(0xFF08D9D6);
  static const Color accentCoral = Color(0xFFFF2E63);
  static const Color deepNavy = Color(0xFF252A34);
  static const Color premiumWhite = Color(0xFFEAEAEA);

  late final AnimationController _bgController;
  late final Animation<double> _bgAnimation; // for horizontal pan
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    // background pan animation (slow)
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _bgAnimation = Tween<double>(
      begin: -30.0,
      end: 30.0,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
    _bgController.repeat(reverse: true);

    // logo pop animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoController.forward();

    // navigate to login or home after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizes
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    // scale fonts/buttons on small devices
    final baseText = (w < 360) ? 14.0 : 16.0;

    // You can replace this Unsplash URL with any other image URL you prefer.
    const bgImageUrl = 'assets/images/splash.jpg'; // Ya koi aur image

    return Scaffold(
      backgroundColor: deepNavy,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated background image (pans left-right)
            AnimatedBuilder(
              animation: _bgAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_bgAnimation.value, 0),
                  child: child,
                );
              },
              child: SizedBox(
                width: w * 1.4, // slightly larger to allow panning
                height: h,
                child: Image.asset(
                  // ← Yahan Image.network se Image.asset kardia
                  bgImageUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),

            // Dark gradient overlay to improve contrast + match theme
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    deepNavy.withValues(alpha: 0.85),
                    deepNavy.withValues(alpha: 0.72),
                    deepNavy.withValues(alpha: 0.95),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Content
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated logo circle
                    ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: (w < 360) ? 84 : 100,
                        height: (w < 360) ? 84 : 100,
                        decoration: BoxDecoration(
                          color: deepNavy,
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryTeal, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🏘️', style: TextStyle(fontSize: 40)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // App name
                    Text(
                      'Digital Muhallah',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: premiumWhite,
                        fontSize: (w < 360) ? 22 : 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      'Connecting Communities',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryTeal.withValues(alpha: 0.95),
                        fontSize: baseText + 0.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: h * 0.06),

                    // Loading indicator + text
                    Column(
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              accentCoral,
                            ),
                            backgroundColor: primaryTeal.withValues(alpha: 0.18),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            color: premiumWhite.withValues(alpha: 0.9),
                            fontSize: baseText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer note (bottom)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 18,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'Your Local Community Platform',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: premiumWhite.withValues(alpha: 0.72),
                      fontSize: (w < 360) ? 12 : 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // small version text / version
                  Text(
                    'v1.0',
                    style: TextStyle(
                      color: premiumWhite.withValues(alpha: 0.48),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
