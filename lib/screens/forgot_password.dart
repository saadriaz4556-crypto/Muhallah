import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

void main() {
  runApp(const MyApp());
}

const Map<String, Color> COLORS = {
  'primaryTeal': Color(0xFF08D9D6),
  'accentCoral': Color(0xFFFF2E63),
  'deepNavy': Color(0xFF252A34),
  'premiumWhite': Color(0xFFEAEAEA),
  'successGreen': Color(0xFF10B981),
  'warningAmber': Color(0xFFF59E0B),
  'background': Color(0xFF2A303C),
};

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forgot Password Flow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: COLORS['deepNavy'],
      ),
      home: const ForgotPasswordFlow(),
    );
  }
}

class ForgotPasswordFlow extends StatefulWidget {
  const ForgotPasswordFlow({super.key});

  @override
  State<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends State<ForgotPasswordFlow> {
  // step: 1 identity, 2 success, 3 otp, 4 reset password
  int step = 1;

  // Track generated OTP document ID
  String? _otpDocId;

  // Identity form
  String _cnicDigits = '';
  String _cnicError = '';
  DateTime? _issueDate;
  bool _verifyingCnic = false;
  final TextEditingController _cnicController = TextEditingController();

  // NEW: Role selector (owner or family_member)
  String _userRole = 'owner'; // 'owner' or 'family_member'

  // Date picker inputs
  String _dpDay = '';
  String _dpMonth = '';
  String _dpYear = '';
  final TextEditingController _dpDayController = TextEditingController();
  final TextEditingController _dpMonthController = TextEditingController();
  final TextEditingController _dpYearController = TextEditingController();

  // OTP Options
  int _resendSeconds = 59;
  bool _otpSending = false;
  Timer? _resendTimer;

  // OTP input controllers (6 boxes)
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  // Registered email (from backend after CNIC verification)
  String _registeredEmail = '';

  // Reset password
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _savingPassword = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _cnicController.dispose();
    _dpDayController.dispose();
    _dpMonthController.dispose();
    _dpYearController.dispose();
    super.dispose();
  }

  // ─── CNIC helpers ─────────────────────────────────────────────────────────

  String _formatCnicForDisplay(String digits) {
    final d = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length <= 5) return d;
    if (d.length <= 12) return '${d.substring(0, 5)}-${d.substring(5)}';
    return '${d.substring(0, 5)}-${d.substring(5, 12)}-${d.substring(12, d.length)}';
  }

  void _handleCnicChange(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= 13) {
      setState(() => _cnicDigits = digits);
      final formatted = _formatCnicForDisplay(digits);
      _cnicController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    if (digits.length == 13) {
      final formatted = _formatCnicForDisplay(digits);
      final valid = RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(formatted);
      setState(
        () => _cnicError = valid ? '' : 'CNIC format should be XXXXX-XXXXXXX-X',
      );
    } else {
      setState(() => _cnicError = '');
    }
  }

  Future<void> _verifyCnic() async {
    FocusScope.of(context).unfocus();
    final formatted = _formatCnicForDisplay(_cnicDigits);
    if (!RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(formatted)) {
      setState(
        () => _cnicError =
            'Please enter a valid CNIC in the format XXXXX-XXXXXXX-X',
      );
      return;
    }

    if (_userRole == 'family_member') {
      await _verifyFamilyMemberCnic();
      return;
    }

    // Owner/Renter verification (existing code)
    if (_issueDate == null) {
      _showAlert(
        'Missing CNIC issue date',
        'Please select the CNIC issue date.',
      );
      return;
    }
    setState(() => _verifyingCnic = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('cnic', isEqualTo: _cnicDigits)
          .limit(1)
          .get();

      if (!mounted) return;

      if (querySnapshot.docs.isEmpty) {
        setState(() => _verifyingCnic = false);
        _showAlert('Record Not Found', 'No account found with this CNIC.');
        return;
      }

      final userData = querySnapshot.docs.first.data();
      final storedDateStr = userData['cnicIssueDate'] as String?;

      final formattedInput =
          '${_issueDate!.year.toString().padLeft(4, '0')}-${_issueDate!.month.toString().padLeft(2, '0')}-${_issueDate!.day.toString().padLeft(2, '0')}';

      if (storedDateStr != formattedInput) {
        setState(() => _verifyingCnic = false);
        _showAlert('Verification Failed',
            'CNIC Issue Date does not match our records.');
        return;
      }

      final email = userData['email'] as String?;
      if (email == null || email.isEmpty) {
        setState(() => _verifyingCnic = false);
        _showAlert(
            'Error', 'No registered email address found for this account.');
        return;
      }

      // Trim and lowercase email to ensure consistency
      final trimmedEmail = email.trim().toLowerCase();
      debugPrint('Verified email for CNIC $_cnicDigits: $trimmedEmail');

      setState(() {
        _verifyingCnic = false;
        _registeredEmail = trimmedEmail;
        step = 2;
      });
    } catch (e) {
      setState(() => _verifyingCnic = false);
      _showAlert('Error', 'An error occurred during verification: $e');
    }
  }

  // NEW: Family Member CNIC Verification
  Future<void> _verifyFamilyMemberCnic() async {
    setState(() => _verifyingCnic = true);

    try {
      // Format CNIC for Firestore lookup
      final formattedCnic = '${_cnicDigits.substring(0, 5)}-'
          '${_cnicDigits.substring(5, 12)}-'
          '${_cnicDigits.substring(12)}';

      // Look up family member by CNIC
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'family_member')
          .where('cnic', isEqualTo: formattedCnic)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        setState(() => _verifyingCnic = false);
        _showAlert('Record Not Found',
            'No family member account found with this CNIC. Please check your CNIC or register first.');
        return;
      }

      final userData = snapshot.docs.first.data();
      final email =
          userData['authEmail'] as String? ?? userData['email'] as String?;

      if (email == null || email.isEmpty) {
        setState(() => _verifyingCnic = false);
        _showAlert('Error',
            'Could not find your registered email. Please contact support.');
        return;
      }

      final trimmedEmail = email.trim().toLowerCase();
      debugPrint(
          'Verified family member email for CNIC $_cnicDigits: $trimmedEmail');

      setState(() {
        _verifyingCnic = false;
        _registeredEmail = trimmedEmail;
        step = 2;
      });
    } catch (e) {
      setState(() => _verifyingCnic = false);
      _showAlert('Error', 'An error occurred during verification: $e');
    }
  }

  // ─── OTP flow ─────────────────────────────────────────────────────────────

  Future<void> _startOtpFlow() async {
    setState(() {
      step = 3;
      _resendSeconds = 59;
      _otpSending = true;
    });
    await _sendOtp();
  }

  Future<void> _sendOtp() async {
    if (!mounted) return;
    setState(() => _otpSending = true);

    // 1. Generate a 6-digit OTP
    final String otp = (100000 + Random().nextInt(900000)).toString();
    final DateTime now = DateTime.now();
    final DateTime expiresAt = now.add(const Duration(minutes: 5));

    try {
      // 2. Save OTP to Firestore for verification
      debugPrint('Saving OTP to Firestore for email: $_registeredEmail');
      final otpRef = await FirebaseFirestore.instance.collection('otps').add({
        'email': _registeredEmail,
        'otp': otp,
        'createdAt': now.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'used': false,
      });

      _otpDocId = otpRef.id;
      debugPrint('OTP document created with ID: $_otpDocId');

      // 3. Send email via EmailJS API
      debugPrint('Sending email via EmailJS to: $_registeredEmail');
      final emailSent = await _sendOTPEmail(_registeredEmail, otp);

      if (!emailSent) {
        debugPrint('ERROR: Failed to send email via EmailJS');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send OTP. Please try again.'),
              backgroundColor: Color(0xFFF59E0B),
              duration: Duration(seconds: 5),
            ),
          );
          setState(() => _otpSending = false);
          return;
        }
      }
      debugPrint('Email sent successfully via EmailJS');

      // Verify OTP document exists before showing success
      final verifyDoc = await FirebaseFirestore.instance
          .collection('otps')
          .doc(_otpDocId)
          .get();

      if (!verifyDoc.exists) {
        throw Exception('OTP document was not saved properly');
      }
      debugPrint('OTP document verified in Firestore');

      if (!mounted) return;
      setState(() => _otpSending = false);
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to your email'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('ERROR in _sendOtp: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() => _otpSending = false);
      _showAlert('Error', 'Failed to send OTP: $e');
    }
  }

  /// Sends OTP email via EmailJS API
  Future<bool> _sendOTPEmail(String toEmail, String otpCode) async {
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': 'service_0o1zvt5',
          'template_id': 'template_hqrlbl3',
          'user_id': 'XjahsXTRo5lPcFfEs',
          'template_params': {
            'to_email': toEmail,
            'otp_code': otpCode,
          }
        }),
      );
      print('EmailJS Status: ${response.statusCode}');
      print('EmailJS Body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Email send exception: $e');
      return false;
    }
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = _otpControllers.map((c) => c.text).join();
    if (enteredOtp.length != 6) {
      _showAlert('Invalid', 'Please enter the 6-digit OTP.');
      return;
    }

    if (_otpDocId == null) {
      _showAlert('Error', 'No OTP session found. Please resend the code.');
      return;
    }

    setState(
        () => _otpSending = true); // Using this for verification loading state

    try {
      final doc = await FirebaseFirestore.instance
          .collection('otps')
          .doc(_otpDocId!)
          .get();

      if (!doc.exists) {
        setState(() => _otpSending = false);
        _showAlert('Error', 'OTP session not found.');
        return;
      }

      final data = doc.data()!;
      final storedOtp = data['otp'] as String;
      final expiresAt = DateTime.parse(data['expiresAt'] as String);
      final used = data['used'] as bool;
      final now = DateTime.now();

      if (used) {
        setState(() => _otpSending = false);
        _showAlert('Error', 'This OTP has already been used.');
        return;
      }

      if (now.isAfter(expiresAt)) {
        setState(() => _otpSending = false);
        _showAlert('Error', 'This OTP has expired.');
        return;
      }

      if (storedOtp == enteredOtp) {
        // Mark as used
        await doc.reference.update({'used': true});
        if (!mounted) return;
        setState(() {
          _otpSending = false;
          step = 4;
        });
      } else {
        setState(() => _otpSending = false);
        _showAlert('Wrong OTP', 'The OTP you entered is incorrect.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _otpSending = false);
      _showAlert('Error', 'Failed to verify OTP: $e');
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds <= 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  // ─── Reset password ────────────────────────────────────────────────────────

  Future<void> _saveNewPassword() async {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass.isEmpty) {
      _showAlert('Error', 'Please enter a new password.');
      return;
    }
    if (newPass.length < 6) {
      _showAlert('Error', 'Password must be at least 6 characters.');
      return;
    }
    if (newPass != confirmPass) {
      _showAlert('Error', 'Passwords do not match.');
      return;
    }

    setState(() => _savingPassword = true);

    try {
      // Step 1: Get user document from Firestore using verified email
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _registeredEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _showAlert('Error', 'User not found. Please try again.');
        setState(() => _savingPassword = false);
        return;
      }

      final userDoc = querySnapshot.docs.first;
      final oldPassword = userDoc.data()['password'] ?? '';

      // Step 2: Update password in Firestore
      await userDoc.reference.update({
        'password': newPass,
      });

      // Step 3: Temporarily sign in to update Firebase Auth password
      try {
        final userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _registeredEmail,
          password: oldPassword,
        );

        await userCredential.user!.updatePassword(newPass);

        await FirebaseAuth.instance.signOut();
      } catch (authError) {
        print('Firebase Auth update error: $authError');
        // Firestore already updated — acceptable fallback
      }

      if (!mounted) return;
      setState(() => _savingPassword = false);

      // Step 4: Show success and go to Login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Password updated successfully! Please login with your new password.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Save password error: $e');
      if (!mounted) return;
      setState(() => _savingPassword = false);
      _showAlert('Error', 'Failed to update password. Please try again.');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _maskedEmail() {
    if (_registeredEmail.isEmpty) return '****@****.com';
    final parts = _registeredEmail.split('@');
    if (parts.length != 2) return '****@****.com';
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '$name****@$domain';
    return '${name.substring(0, 2)}****@$domain';
  }

  Future<void> _openDatePickerModal() async {
    if (_issueDate != null) {
      _dpDay = _issueDate!.day.toString().padLeft(2, '0');
      _dpMonth = (_issueDate!.month).toString().padLeft(2, '0');
      _dpYear = _issueDate!.year.toString();
    } else {
      final now = DateTime.now();
      _dpDay = '';
      _dpMonth = '';
      _dpYear = now.year.toString();
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInner) {
            return AlertDialog(
              backgroundColor: COLORS['background'],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Select CNIC Issue Date',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'DD',
                        hintStyle: TextStyle(
                          color: COLORS['premiumWhite']!.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: COLORS['deepNavy'],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (t) {
                        final v = t.replaceAll(RegExp(r'[^0-9]'), '');
                        setStateInner(() => _dpDay = v);
                      },
                      controller: _dpDayController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'MM',
                        hintStyle: TextStyle(
                          color: COLORS['premiumWhite']!.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: COLORS['deepNavy'],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (t) {
                        final v = t.replaceAll(RegExp(r'[^0-9]'), '');
                        setStateInner(() => _dpMonth = v);
                      },
                      controller: _dpMonthController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'YYYY',
                        hintStyle: TextStyle(
                          color: COLORS['premiumWhite']!.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: COLORS['deepNavy'],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (t) {
                        final v = t.replaceAll(RegExp(r'[^0-9]'), '');
                        setStateInner(() => _dpYear = v);
                      },
                      controller: _dpYearController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: COLORS['premiumWhite']),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [COLORS['primaryTeal']!, COLORS['accentCoral']!],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: () {
                      final day = int.tryParse(_dpDay);
                      final month = int.tryParse(_dpMonth);
                      final year = int.tryParse(_dpYear);
                      final currentYear = DateTime.now().year;
                      if (day == null || day < 1 || day > 31) {
                        _showAlert(
                          'Invalid day',
                          'Please enter a valid day (1-31).',
                        );
                        return;
                      }
                      if (month == null || month < 1 || month > 12) {
                        _showAlert(
                          'Invalid month',
                          'Please enter a valid month (1-12).',
                        );
                        return;
                      }
                      if (year == null || year < 1900 || year > currentYear) {
                        _showAlert(
                          'Invalid year',
                          'Please enter a valid year between 1900 and $currentYear.',
                        );
                        return;
                      }
                      final candidate = DateTime(year, month, day);
                      if (candidate.day != day ||
                          candidate.month != month ||
                          candidate.year != year) {
                        _showAlert(
                          'Invalid date',
                          'The date you entered is not valid.',
                        );
                        return;
                      }
                      setState(() => _issueDate = candidate);
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year';
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: COLORS['background'],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [COLORS['primaryTeal']!, COLORS['accentCoral']!],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Screens ───────────────────────────────────────────────────────────────

  Widget _identityScreen() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            COLORS['background']!,
            COLORS['background']!.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Recovery',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: [
                          COLORS['primaryTeal']!,
                          COLORS['accentCoral']!,
                        ],
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verify your identity using CNIC details to secure your account',
                  style: TextStyle(
                    color: COLORS['premiumWhite']!.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // NEW: Role selector (Owner vs Family Member)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: COLORS['primaryTeal']!.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _userRole = 'owner'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _userRole == 'owner'
                            ? COLORS['primaryTeal']!.withValues(alpha: 0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Owner/Renter',
                          style: TextStyle(
                            color: _userRole == 'owner'
                                ? COLORS['primaryTeal']
                                : Colors.white60,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _userRole = 'family_member'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _userRole == 'family_member'
                            ? COLORS['primaryTeal']!.withValues(alpha: 0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Family Member',
                          style: TextStyle(
                            color: _userRole == 'family_member'
                                ? COLORS['primaryTeal']
                                : Colors.white60,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'CNIC Number',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              keyboardType: TextInputType.number,
              maxLength: 15,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'XXXXX-XXXXXXX-X',
                hintStyle: TextStyle(
                  color: COLORS['premiumWhite']!.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: COLORS['deepNavy'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                prefixIcon: Icon(
                  Icons.credit_card,
                  color: COLORS['primaryTeal'],
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: COLORS['primaryTeal']!.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: COLORS['primaryTeal']!,
                    width: 2,
                  ),
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              onChanged: _handleCnicChange,
              controller: _cnicController,
            ),
          ),
          if (_cnicError.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _cnicError,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Hide CNIC issue date for family members
          if (_userRole == 'owner') ...[
            const Text(
              'CNIC Issue Date',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _openDatePickerModal,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: COLORS['deepNavy'],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: COLORS['primaryTeal']!.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: COLORS['primaryTeal']),
                    const SizedBox(width: 12),
                    Text(
                      _issueDate != null
                          ? _formatDate(_issueDate!)
                          : 'DD/MM/YYYY',
                      style: TextStyle(
                        color: _issueDate != null
                            ? Colors.white
                            : COLORS['premiumWhite']!.withValues(alpha: 0.5),
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: COLORS['primaryTeal']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            const SizedBox(height: 12),
          ],
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: COLORS['accentCoral']!.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _verifyingCnic ? null : _verifyCnic,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _verifyingCnic
                        ? [Colors.grey, Colors.grey.shade700]
                        : [COLORS['primaryTeal']!, COLORS['accentCoral']!],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    _verifyingCnic ? 'Verifying...' : 'Verify CNIC',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget _successScreen() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            COLORS['background']!,
            COLORS['background']!.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [COLORS['successGreen']!, COLORS['primaryTeal']!],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: COLORS['successGreen']!.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.check, color: Colors.white, size: 50),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Identity Verified Successfully',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [COLORS['primaryTeal']!, COLORS['successGreen']!],
                ).createShader(const Rect.fromLTWH(0, 0, 300, 70)),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your CNIC has been authenticated. OTP will be sent to your registered email address.',
            style: TextStyle(
              color: COLORS['premiumWhite']!.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildOptionCard(
            icon: Icons.email_outlined,
            title: 'Send OTP to Registered Email',
            description:
                'One-time password will be sent to your linked email address ${_maskedEmail()}',
            emoji: '🔒',
            onTap: _startOtpFlow,
            gradient: [COLORS['primaryTeal']!, const Color(0xFF009688)],
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => setState(() => step = 1),
            style: OutlinedButton.styleFrom(
              foregroundColor: COLORS['premiumWhite'],
              side: BorderSide(color: COLORS['primaryTeal']!),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Back to Verification'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required String emoji,
    required VoidCallback onTap,
    required List<Color> gradient,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _otpScreen() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            COLORS['background']!,
            COLORS['background']!.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [COLORS['primaryTeal']!, const Color(0xFF009688)],
              ),
              boxShadow: [
                BoxShadow(
                  color: COLORS['primaryTeal']!.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.mark_email_read_outlined,
                color: Colors.white, size: 44),
          ),
          const SizedBox(height: 24),
          Text(
            'Enter Verification Code',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [COLORS['primaryTeal']!, COLORS['accentCoral']!],
                ).createShader(const Rect.fromLTWH(0, 0, 300, 70)),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "We've sent a 6-digit code to\n${_maskedEmail()}",
            style: TextStyle(
              color: COLORS['premiumWhite']!.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Please also check your spam/junk folder",
            style: TextStyle(
              color: COLORS['primaryTeal']!.withValues(alpha: 0.9),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // 6 OTP input boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              return Container(
                width: 44,
                height: 54,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: COLORS['deepNavy'],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: COLORS['primaryTeal']!.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else if (val.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 32),

          // Verify button
          _otpSending
              ? const CircularProgressIndicator(color: Color(0xFF08D9D6))
              : Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [COLORS['primaryTeal']!, COLORS['accentCoral']!],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: COLORS['primaryTeal']!.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 24),

          // Resend timer
          _resendSeconds > 0
              ? Text(
                  'Resend OTP in $_resendSeconds seconds',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                )
              : TextButton(
                  onPressed: () {
                    setState(() {
                      _resendSeconds = 59;
                      _otpSending = true;
                    });
                    _sendOtp();
                  },
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: COLORS['primaryTeal'],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => setState(() => step = 2),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: COLORS['primaryTeal']!),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _resetScreen() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            COLORS['background']!,
            COLORS['background']!.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    COLORS['accentCoral']!,
                    COLORS['primaryTeal']!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: COLORS['accentCoral']!.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.lock_reset, color: Colors.white, size: 44),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Set New Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [
                      COLORS['accentCoral']!,
                      COLORS['primaryTeal']!,
                    ],
                  ).createShader(const Rect.fromLTWH(0, 0, 260, 70)),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Choose a strong password for your account',
              style: TextStyle(
                color: COLORS['premiumWhite']!.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // New password field
          const Text(
            'New Password',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newPasswordController,
            obscureText: !_newPasswordVisible,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Enter new password',
              hintStyle: TextStyle(
                color: COLORS['premiumWhite']!.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: COLORS['deepNavy'],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: COLORS['primaryTeal']!.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: COLORS['primaryTeal']!,
                  width: 2,
                ),
              ),
              prefixIcon:
                  Icon(Icons.lock_outline, color: COLORS['primaryTeal']),
              suffixIcon: IconButton(
                icon: Icon(
                  _newPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: COLORS['primaryTeal'],
                ),
                onPressed: () =>
                    setState(() => _newPasswordVisible = !_newPasswordVisible),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Confirm password field
          const Text(
            'Confirm Password',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPasswordController,
            obscureText: !_confirmPasswordVisible,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Confirm new password',
              hintStyle: TextStyle(
                color: COLORS['premiumWhite']!.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: COLORS['deepNavy'],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: COLORS['primaryTeal']!.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: COLORS['primaryTeal']!,
                  width: 2,
                ),
              ),
              prefixIcon:
                  Icon(Icons.lock_outline, color: COLORS['primaryTeal']),
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: COLORS['primaryTeal'],
                ),
                onPressed: () => setState(
                    () => _confirmPasswordVisible = !_confirmPasswordVisible),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Save button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: _savingPassword
                    ? [Colors.grey, Colors.grey.shade700]
                    : [COLORS['accentCoral']!, COLORS['primaryTeal']!],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: COLORS['accentCoral']!.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _savingPassword ? null : _saveNewPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _savingPassword ? 'Saving...' : 'Save New Password',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: Family Member Forgot Password (CNIC → email lookup → sendPasswordResetEmail) ---
  Future<void> _familyMemberForgotPassword() async {
    final cnicDigits = _cnicController.text.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{13}$').hasMatch(cnicDigits)) {
      _showAlert('Invalid CNIC', 'Please enter a valid 13-digit CNIC.');
      return;
    }
    setState(() => _verifyingCnic = true);
    try {
      // Format CNIC for Firestore lookup
      final formattedCnic =
          '${cnicDigits.substring(0, 5)}-${cnicDigits.substring(5, 12)}-${cnicDigits.substring(12)}';
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'family_member')
          .where('cnic', isEqualTo: formattedCnic)
          .limit(1)
          .get();
      if (!mounted) return;
      if (snapshot.docs.isEmpty) {
        setState(() => _verifyingCnic = false);
        _showAlert('Not Found',
            'No family member account found with this CNIC. Please check your CNIC or register first.');
        return;
      }
      final userDoc = snapshot.docs.first.data();
      final authEmail =
          userDoc['authEmail'] as String? ?? userDoc['email'] as String?;
      if (authEmail == null || authEmail.isEmpty) {
        setState(() => _verifyingCnic = false);
        _showAlert('Error',
            'Could not find your registered email. Please contact support.');
        return;
      }
      // If old account (fake email), show special message
      if (authEmail.endsWith('@community.app')) {
        setState(() => _verifyingCnic = false);
        _showAlert(
          'Old Account',
          'Your account was registered with the old system and cannot be reset online. Please contact the administrator to reset your password, or register a new account with your real email.',
        );
        return;
      }
      // Otherwise, send password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: authEmail);
      setState(() => _verifyingCnic = false);
      _showAlert('Reset Email Sent',
          'Password reset email sent to your registered email address. Please check your inbox and follow the link to reset your password.');
    } on FirebaseAuthException catch (e) {
      setState(() => _verifyingCnic = false);
      if (e.code == 'user-not-found') {
        _showAlert('Not Found',
            'No account found. Please check your CNIC or register first.');
      } else {
        _showAlert(
            'Error', e.message ?? 'Failed to send reset email. Try again.');
      }
    } catch (e) {
      setState(() => _verifyingCnic = false);
      _showAlert(
          'Error', 'Something went wrong. Please check your connection.');
    }
  }

  // --- UI: Add a button for family member forgot password ---
  Widget _familyMemberForgotPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Forgot Password (Family Member)',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: COLORS['inputBg'],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: TextField(
            controller: _cnicController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, letterSpacing: 1),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
            ],
            decoration: const InputDecoration(
              hintText: 'Enter your CNIC (00000-0000000-0)',
              hintStyle: TextStyle(color: Colors.white30, letterSpacing: 1),
              prefixIcon: Icon(Icons.credit_card_rounded,
                  color: Color(0xFF08D9D6), size: 20),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
            onChanged: _handleCnicChange,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: GestureDetector(
            onTap: _verifyingCnic ? null : _familyMemberForgotPassword,
            child: Container(
              decoration: BoxDecoration(
                gradient: _verifyingCnic
                    ? const LinearGradient(
                        colors: [Color(0xFF4B3A7E), Color(0xFF4B3A7E)])
                    : const LinearGradient(
                        colors: [Color(0xFF08D9D6), Color(0xFF00B4B2)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF08D9D6)
                        .withValues(alpha: _verifyingCnic ? 0.1 : 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _verifyingCnic
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email_rounded,
                            color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Send Reset Link',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (step == 1) {
      content = _identityScreen();
    } else if (step == 2) {
      content = _successScreen();
    } else if (step == 3) {
      content = _otpScreen();
    } else {
      content = _resetScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [COLORS['deepNavy']!, COLORS['background']!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                // Step indicator (labeled steps)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _fpStepHeader(0, 'Identity'),
                    _fpStepLine(0),
                    _fpStepHeader(1, 'Email'),
                    _fpStepLine(1),
                    _fpStepHeader(2, 'OTP'),
                    _fpStepLine(2),
                    _fpStepHeader(3, 'Reset'),
                  ],
                ),
                const SizedBox(height: 24),
                content,
                _familyMemberForgotPasswordSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fpStepHeader(int index, String title) {
    final bool isActive = step >= index + 1;
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor:
              isActive ? COLORS['primaryTeal'] : Colors.grey.shade700,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: isActive ? COLORS['deepNavy'] : Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: isActive ? COLORS['premiumWhite'] : Colors.grey,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _fpStepLine(int index) {
    return Container(
      width: 36,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
      decoration: BoxDecoration(
        gradient: step > index + 1
            ? LinearGradient(
                colors: [COLORS['primaryTeal']!, COLORS['accentCoral']!],
              )
            : const LinearGradient(
                colors: [Colors.white24, Colors.white12],
              ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
