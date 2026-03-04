import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- enhanced color palette with gradients
  static const Color deepNavy = Color(0xFF252A34);
  static const Color primaryTeal = Color(0xFF08D9D6);
  static const Color coral = Color(0xFFFF2E63);
  static const Color cardBg = Color(0xFF1E1E2F);
  static const Color premiumWhite = Color(0xFFEAEAEA);

  static const Color gradientStart = Color(0xFF0066CC);
  static const Color gradientEnd = Color(0xFF00CCFF);

  // --- slider images
  static const List<String> _sliderImages = [
    'assets/images/slider1.jpg',
    'assets/images/slider2.jpg',
    'assets/images/slider3.jpg',
    'assets/images/slider4.jpg',
    'assets/images/slider5.jpg',
    'assets/images/slider6.jpg',
  ];

  // --- preserved state variables and controllers
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- slider state variables
  int _currentSlide = 0;
  Timer? _slideTimer;
  final PageController _slideController = PageController();

  // Format CNIC like: 12345-1234567-1 (preserved behavior)
  String _formatCnicDigits(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    final limited =
        digitsOnly.length > 13 ? digitsOnly.substring(0, 13) : digitsOnly;

    if (limited.length <= 5) {
      return limited;
    } else if (limited.length <= 12) {
      return '${limited.substring(0, 5)}-${limited.substring(5)}';
    } else {
      return '${limited.substring(0, 5)}-${limited.substring(5, 12)}-${limited.substring(12)}';
    }
  }

  void _onCnicChanged(String value) {
    final formatted = _formatCnicDigits(value);
    if (_cnicController.text != formatted) {
      _cnicController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        title: Text(title, style: const TextStyle(color: premiumWhite)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: primaryTeal)),
          ),
        ],
      ),
    );
  }

  // <--- MAJOR CHANGE: Firebase Login Logic
  Future<void> _handleLogin() async {
    final cnicText = _cnicController.text.replaceAll(RegExp(r'\D'), '');
    final password = _passwordController.text.trim();

    if (cnicText.isEmpty || password.isEmpty) {
      _showAlert('Error', 'Please enter both CNIC and password.');
      return;
    }
    if (!RegExp(r'^\d{13}$').hasMatch(cnicText)) {
      _showAlert('Error', 'Please enter a valid 13-digit CNIC number.');
      return;
    }

    // CNIC ko pseudo-email mein convert karein
    // Ensure this domain matches the one used in registration_screen.dart
    final email = '$cnicText@muhallah.com';

    try {
      setState(() => _isLoading = true);

      // Firebase Authentication se sign in karein
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // --- NEW VALIDATION: Ensure Auth password matches Firestore password
      // This prevents login with 'old' password if it was changed via Forgot Password flow
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        final storedPassword = userDoc.data()?['password'];
        // If Firestore has a password field, users MUST use that password.
        // If storedPassword differs from input password (which Auth accepted),
        // it means Auth is stale (old password). We must reject this login.
        if (storedPassword != null && storedPassword != password) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            // Treat as wrong password to the user
            _showAlert('Login Failed',
                'Invalid password. Please use your new password.');
            setState(() => _isLoading = false);
            return;
          }
        }
      }
      // --- END NEW VALIDATION

      // Success: Home screen par navigate karein
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on FirebaseAuthException catch (e) {
      bool fallbackSuccess = false;

      // Fallback Strategy: If Firebase Auth fails, check Firestore directly
      // This is necessary because 'Forgot Password' only updates Firestore, not Auth.
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        try {
          // Check Firestore for this CNIC
          final querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('cnic', isEqualTo: cnicText) // stored as plain digits
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            final userDoc = querySnapshot.docs.first.data();
            final storedPassword = userDoc['password'];

            if (storedPassword != null && storedPassword == password) {
              // Credentials match in Firestore!
              fallbackSuccess = true;
              debugPrint(
                  'Fallback Login Successful: Authenticated via Firestore');

              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/home',
                    arguments: querySnapshot.docs.first.id);
                return; // Exit function successfully
              }
            }
          }
        } catch (firestoreError) {
          debugPrint('Fallback check failed: $firestoreError');
        }
      }

      if (!fallbackSuccess) {
        String message;
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          message =
              'Invalid CNIC or password. User not found or incorrect credentials.';
        } else if (e.code == 'invalid-email') {
          message = 'The CNIC format is incorrect.';
        } else {
          message =
              'Login failed. Please check your credentials and try again. (Error: ${e.code})';
        }
        _showAlert('Login Error', message);
      }
    } catch (e) {
      _showAlert(
        'Error',
        'An unknown error occurred during login: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // END MAJOR CHANGE

  void _navigateToRoleSelection() {
    // This function seems unused in your routes, keeping for completeness
    Navigator.pushNamed(context, '/role_selection');
  }

  @override
  void initState() {
    super.initState();
    _slideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      final next = (_currentSlide + 1) % _sliderImages.length;
      _slideController.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
      setState(() => _currentSlide = next);
    });
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _slideController.dispose();
    _cnicController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // compute button enabled state (preserved logic)
    // final isButtonDisabled = _isLoading ||
    //     _cnicController.text.replaceAll(RegExp(r'\D'), '').length !=
    //         13 || // Check for 13 digits
    //     _passwordController.text.trim().isEmpty;
    final isButtonDisabled = _isLoading; // Only disable if loading

    // Responsive sizing
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;
    final headerHeight = (height * 0.28).clamp(280.0, 360.0);

    return Scaffold(
      backgroundColor: deepNavy,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - mq.viewInsets.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(
                        height: headerHeight,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              // ── Sliding Images (Local Assets) ──
                              PageView.builder(
                                controller: _slideController,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _sliderImages.length,
                                onPageChanged: (i) => setState(() => _currentSlide = i),
                                itemBuilder: (context, index) {
                                  return Image.asset(
                                    _sliderImages[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  );
                                },
                              ),

                              // ── Dark Overlay ──
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.38),
                                ),
                              ),

                              // ── Decorative Circles (preserved) ──
                              Positioned(
                                top: -20,
                                right: -20,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -30,
                                left: -30,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              // ── Welcome Back Text (preserved) ──
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [primaryTeal, gradientEnd],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 4),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.security_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Welcome Back',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Sign in to access your account and continue your journey with us',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // ── Dot Indicators ──
                              Positioned(
                                bottom: 14,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(_sliderImages.length, (index) {
                                    final isActive = index == _currentSlide;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      width: isActive ? 20 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? const Color(0xFF08D9D6)
                                            : Colors.white.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: cardBg.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              offset: Offset(0, 10),
                              blurRadius: 25,
                              spreadRadius: 0,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Account Login',
                                style: TextStyle(
                                  color: premiumWhite,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Enter your credentials to continue',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // CNIC Field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _cnicController,
                                  keyboardType: TextInputType.number,
                                  // inputFormatters: [
                                  //   FilteringTextInputFormatter.digitsOnly,
                                  // ],
                                  onChanged: _onCnicChanged,
                                  enabled: !_isLoading,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.black.withOpacity(0.3),
                                    hintText: '12345-1234567-1',
                                    hintStyle: const TextStyle(
                                      color: Colors.white38,
                                    ),
                                    labelText: 'CNIC Number',
                                    labelStyle: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryTeal.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.badge_outlined,
                                        color: primaryTeal,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: primaryTeal.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: primaryTeal,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Password Field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  enabled: !_isLoading,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.black.withOpacity(0.3),
                                    hintText: 'Enter your password',
                                    hintStyle: const TextStyle(
                                      color: Colors.white38,
                                    ),
                                    labelText: 'Password',
                                    labelStyle: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: coral.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.lock_outline_rounded,
                                        color: coral,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: coral.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: coral,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Login button
                              Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: isButtonDisabled
                                      ? LinearGradient(
                                          colors: [
                                            Colors.grey.shade600,
                                            Colors.grey.shade500,
                                          ],
                                        )
                                      : const LinearGradient(
                                          colors: [gradientStart, gradientEnd],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  boxShadow: isButtonDisabled
                                      ? null
                                      : const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 6),
                                            blurRadius: 12,
                                          ),
                                        ],
                                ),
                                child: ElevatedButton(
                                  onPressed:
                                      isButtonDisabled ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: _isLoading
                                        ? const Row(
                                            key: ValueKey('loading'),
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Verifying Credentials...',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Row(
                                            key: ValueKey('text'),
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Footer links
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            Navigator.pushNamed(
                                              context,
                                              '/forgot_password',
                                            );
                                          },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                    ),
                                    child: const Text(
                                      'Forget Password?',
                                      style: TextStyle(
                                        color: primaryTeal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            Navigator.pushNamed(
                                                context, '/help');
                                          },
                                    child: const Text(
                                      'Need Help?',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Registration prompt
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account?",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.pushNamed(
                                        context,
                                        '/registration_screen',
                                      );
                                    },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                              ),
                              child: const Text(
                                'Register NoW',
                                style: TextStyle(
                                  color: primaryTeal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
