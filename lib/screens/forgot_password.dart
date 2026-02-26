import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';

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
  'background': Color(0xFF1F2430),
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

  // Identity form
  String _cnicDigits = '';
  String _cnicError = '';
  DateTime? _issueDate;
  bool _verifyingCnic = false;

  // Date picker inputs
  String _dpDay = '';
  String _dpMonth = '';
  String _dpYear = '';

  // OTP
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());
  int _resendSeconds = 59;
  bool _otpSending = false;
  Timer? _resendTimer;

  // Registered email (from backend after CNIC verification)
  String _registeredEmail = '';
  String _generatedOtp = '';

  @override
  void initState() {
    super.initState();
  }

  // CNIC helpers
  String _formatCnicForDisplay(String digits) {
    final d = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length <= 5) return d;
    if (d.length <= 12) return '${d.substring(0, 5)}-${d.substring(5)}';
    return '${d.substring(0, 5)}-${d.substring(5, 12)}-${d.substring(12, d.length)}';
  }

  void _handleCnicChange(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= 13) {
      setState(() {
        _cnicDigits = digits;
      });
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
    if (_issueDate == null) {
      _showAlert(
        'Missing CNIC issue date',
        'Please select the CNIC issue date.',
      );
      return;
    }
    setState(() => _verifyingCnic = true);

    try {
      // Query Firestore for user with this CNIC
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('cnic', isEqualTo: _cnicDigits) // Assuming stored as digits
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

      // Verify Date of Issue
      final formattedInput =
          '${_issueDate!.year.toString().padLeft(4, '0')}-${_issueDate!.month.toString().padLeft(2, '0')}-${_issueDate!.day.toString().padLeft(2, '0')}';

      if (storedDateStr != formattedInput) {
        setState(() => _verifyingCnic = false);
        _showAlert('Verification Failed',
            'CNIC Issue Date does not match our records.');
        return;
      }

      // If valid, get email
      final email = userData['email'] as String?;
      if (email == null || email.isEmpty) {
        setState(() => _verifyingCnic = false);
        _showAlert(
            'Error', 'No registered email address found for this account.');
        return;
      }

      setState(() {
        _verifyingCnic = false;
        _registeredEmail = email;
        step = 2;
      });
    } catch (e) {
      setState(() => _verifyingCnic = false);
      _showAlert('Error', 'An error occurred during verification: $e');
    }
  }

  // OTP flow
  Future<void> _startOtpFlow() async {
    setState(() {
      step = 3;
      _resendSeconds = 59;
      _otpSending = true;
      for (var c in _otpControllers) {
        c.text = '';
      }
    });

    // Focus first OTP field
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_otpFocus.isNotEmpty) _otpFocus[0].requestFocus();
    });

    await _sendOtp();
  }

  Future<void> _sendOtp() async {
    if (!mounted) return;
    try {
      debugPrint('Attempting to send OTP to: $_registeredEmail');

      // Define the password variable
      // App Password provided by user
      var smtpPassword = "evzz scbv wgjw kmdu";

      // Strip spaces which might be copied by accident
      smtpPassword = smtpPassword.replaceAll(' ', '');

      if (smtpPassword == "INSERT_YOUR_APP_PASSWORD_HERE" ||
          smtpPassword.isEmpty) {
        if (!mounted) return;
        setState(() => _otpSending = false);
        _showAlert(
          'Configuration Error',
          'App Password not set. Please replace "INSERT_YOUR_APP_PASSWORD_HERE" in the code with your 16-character Google App Password.',
        );
        return;
      }

      // Generate localized OTP
      final rng = Random();
      _generatedOtp = (rng.nextInt(900000) + 100000).toString();

      // Configure SMTP Server (Gmail)
      // Using the gmail() helper handles the port (465/587) and SSL/TLS settings automatically.
      final smtpServer = gmail('saadriaz4556@gmail.com', smtpPassword);

      // Create Message
      final message = Message()
        ..from = const Address('saadriaz4556@gmail.com', 'Muhallah App')
        ..recipients.add(_registeredEmail.trim()) // Ensure no whitespace
        ..subject = 'Password Reset OTP'
        ..html = '''
          <div style="font-family: Arial, sans-serif; padding: 20px;">
            <h2>Muhallah App Password Reset</h2>
            <p>You have requested to reset your password.</p>
            <p>Your Verification Code is:</p>
            <h1 style="color: #08D9D6; letter-spacing: 5px;">$_generatedOtp</h1>
            <p>This code is valid for 10 minutes.</p>
            <p>If you did not request this, please ignore this email.</p>
          </div>
        ''';

      // Send the email
      final sendReport = await send(message, smtpServer);
      debugPrint('Message sent: ${sendReport.toString()}');

      if (!mounted) return;
      setState(() {
        _otpSending = false;
      });
      _startResendTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to $_registeredEmail'),
          backgroundColor: COLORS['successGreen'],
        ),
      );
    } on MailerException catch (e) {
      if (!mounted) return;
      setState(() => _otpSending = false);

      String errorMsg = 'Failed to send OTP.';
      String title = 'Error';

      // Check for Authentication Error (535)
      // This is the most common error with Gmail
      if (e.message.toString().contains('535') ||
          e.message.toString().contains('Username and Password not accepted') ||
          e.message.toString().contains('Invalid login')) {
        title = 'Authentication Failed';
        errorMsg = 'Google rejected the password.\n\n'
            '1. Ensure you are using a 16-character "App Password".\n'
            '2. Go to Google Account > Security > 2-Step Verification > App Passwords.\n'
            '3. Create a new App Password for "Mail" and update the code.';
      } else {
        errorMsg =
            'Error details: ${e.message}\n\nCheck your internet connection and try again.';
      }

      _showAlert(title, errorMsg);
    } catch (e, stackTrace) {
      if (!mounted) return;
      debugPrint('Exception sending OTP: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _otpSending = false);
      _showAlert('Error', 'Failed to send OTP: $e');
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

  void _resendCode() {
    if (_resendSeconds > 0) return;
    setState(() {
      _resendSeconds = 59;
      _otpSending = true;
    });

    _sendOtp();
  }

  void _handleOtpInput(int idx, String value) {
    if (value.isEmpty) {
      _otpControllers[idx].text = '';
      if (idx > 0) _otpFocus[idx - 1].requestFocus();
      return;
    }
    final ch = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (ch.isEmpty) return;
    _otpControllers[idx].text = ch.substring(ch.length - 1);
    if (idx < 5) {
      _otpFocus[idx + 1].requestFocus();
    } else {
      _otpFocus[idx].unfocus();
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) {
      _showAlert('Enter code', 'Please enter the 6-digit verification code.');
      return;
    }

    setState(() => _otpSending = true);

    try {
      // Verify OTP locally
      bool valid = (code == _generatedOtp);

      if (!mounted) return;

      if (valid) {
        setState(() => _otpSending = false);
        _showAlert(
          'Verified',
          'OTP verified successfully. You can now reset your password.',
        );
        setState(() => step = 4);
      } else {
        setState(() => _otpSending = false);
        _showAlert('Invalid OTP', 'The verification code is invalid.');
      }
    } catch (e) {
      setState(() => _otpSending = false);
      _showAlert('Error', 'An error occurred: $e');
    }
  }

  // Reset password
  String _password = '';
  String _confirmPassword = '';
  bool _savingPassword = false;

  Map<String, bool> _passwordRules(String pass) {
    return {
      'length': pass.length >= 8,
      'uppercase': RegExp(r'[A-Z]').hasMatch(pass),
      'lowercase': RegExp(r'[a-z]').hasMatch(pass),
      'number': RegExp(r'[0-9]').hasMatch(pass),
      'special': RegExp(r'[!@#$%^&*]').hasMatch(pass),
    };
  }

  Future<void> _saveNewPassword() async {
    if (_password != _confirmPassword) {
      _showAlert('Password mismatch', 'Confirm password does not match.');
      return;
    }
    final rules = _passwordRules(_password);
    final strengthCount = rules.values.where((v) => v).length;
    if (strengthCount < 4) {
      _showAlert('Weak password', 'Please follow the password requirements.');
      return;
    }
    setState(() => _savingPassword = true);

    try {
      // Ensure no conflicting auth state exists
      await FirebaseAuth.instance.signOut();

      // Update password in Firestore (Hybrid Login Strategy)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('cnic', isEqualTo: _cnicDigits)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .update({'password': _password});
      }

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      setState(() {
        _savingPassword = false;
        _showAlert('Success',
            'Password reset successful. Please login with your new password.');

        // Reset flow
        step = 1;
        _cnicDigits = '';
        _issueDate = null;
        _password = '';
        _confirmPassword = '';
        _registeredEmail = '';
      });
    } catch (e) {
      setState(() => _savingPassword = false);
      _showAlert('Error', 'Failed to update password: $e');
    }
  }

  String _maskedEmail() {
    if (_registeredEmail.isEmpty) return '****@****.com';
    final parts = _registeredEmail.split('@');
    if (parts.length != 2) return '****@****.com';
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '$name****@$domain';
    return '${name.substring(0, 2)}****@$domain';
  }

  // Date picker modal
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
                          color: COLORS['premiumWhite']!.withOpacity(0.6),
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
                      onChanged: (t) => setStateInner(
                        () => _dpDay = t.replaceAll(RegExp(r'[^0-9]'), ''),
                      ),
                      controller: TextEditingController(text: _dpDay),
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
                          color: COLORS['premiumWhite']!.withOpacity(0.6),
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
                      onChanged: (t) => setStateInner(
                        () => _dpMonth = t.replaceAll(RegExp(r'[^0-9]'), ''),
                      ),
                      controller: TextEditingController(text: _dpMonth),
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
                          color: COLORS['premiumWhite']!.withOpacity(0.6),
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
                      onChanged: (t) => setStateInner(
                        () => _dpYear = t.replaceAll(RegExp(r'[^0-9]'), ''),
                      ),
                      controller: TextEditingController(text: _dpYear),
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

  @override
  void dispose() {
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocus) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  // Screens
  Widget _identityScreen() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            COLORS['background']!,
            COLORS['background']!.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
                    color: COLORS['premiumWhite']!.withOpacity(0.8),
                    fontSize: 14,
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
                  color: Colors.black.withOpacity(0.2),
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
                  color: COLORS['premiumWhite']!.withOpacity(0.5),
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
                    color: COLORS['primaryTeal']!.withOpacity(0.3),
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
              controller: TextEditingController(
                text: _formatCnicForDisplay(_cnicDigits),
              ),
            ),
          ),
          if (_cnicError.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: COLORS['deepNavy'],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: COLORS['primaryTeal']!.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
                          : COLORS['premiumWhite']!.withOpacity(0.5),
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
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: COLORS['accentCoral']!.withOpacity(0.4),
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
            COLORS['background']!.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
                  color: COLORS['successGreen']!.withOpacity(0.4),
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
            'Your CNIC has been authenticated. OTP will be sent to your registered mobile number.',
            style: TextStyle(
              color: COLORS['premiumWhite']!.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Only one option now - Send OTP
          _buildOptionCard(
            icon: Icons.smartphone,
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
              color: gradient.first.withOpacity(0.3),
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
                    color: Colors.white.withOpacity(0.2),
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
                          color: Colors.white.withOpacity(0.9),
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
                    color: Colors.white.withOpacity(0.2),
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
            COLORS['background']!.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          ),
          const SizedBox(height: 8),
          Text(
            "We've sent a 6-digit code to your registered email ${_maskedEmail()}",
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FittedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                return Container(
                  width: 50,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _otpControllers[i],
                    focusNode: _otpFocus[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: COLORS['deepNavy'],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: COLORS['primaryTeal']!.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: COLORS['primaryTeal']!,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (v) => _handleOtpInput(i, v),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: "Didn't receive code? ",
                  style: TextStyle(color: Colors.white70),
                ),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: _resendSeconds > 0 ? null : _resendCode,
                    child: Text(
                      _resendSeconds > 0
                          ? 'Resend in 0:${_resendSeconds.toString().padLeft(2, '0')}'
                          : 'Resend Now',
                      style: TextStyle(
                        color: _resendSeconds > 0
                            ? Colors.white70
                            : COLORS['primaryTeal'],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: COLORS['accentCoral']!.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _otpSending ? null : _verifyOtp,
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
                    colors: _otpSending
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
                    _otpSending ? 'Verifying...' : 'Verify OTP',
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
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => setState(() => step = 2),
            style: OutlinedButton.styleFrom(
              foregroundColor: COLORS['premiumWhite'],
              side: BorderSide(color: COLORS['primaryTeal']!),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Back to Options'),
          ),
        ],
      ),
    );
  }

  Widget _resetScreen() {
    final rules = _passwordRules(_password);
    final strengthCount = rules.values.where((v) => v).length;
    final widthFactor = (strengthCount / rules.length).clamp(0.0, 1.0);
    Color strengthColor = Colors.red;
    if (strengthCount >= 4) {
      strengthColor = COLORS['successGreen']!;
    } else if (strengthCount >= 2) strengthColor = COLORS['warningAmber']!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            COLORS['background']!,
            COLORS['background']!.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Create New Password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [COLORS['primaryTeal']!, COLORS['accentCoral']!],
                ).createShader(const Rect.fromLTWH(0, 0, 300, 70)),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ensure your new password meets security requirements',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          const Text(
            'New Password',
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
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              obscureText: true,
              decoration: InputDecoration(
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: COLORS['primaryTeal']!.withOpacity(0.3),
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
              onChanged: (v) => setState(() => _password = v),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Confirm New Password',
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
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              obscureText: true,
              decoration: InputDecoration(
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: COLORS['primaryTeal']!.withOpacity(0.3),
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
              onChanged: (v) => setState(() => _confirmPassword = v),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: COLORS['deepNavy'],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔒 Password Requirements:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                _ruleRow(rules['length']!, 'Minimum 8 characters'),
                _ruleRow(rules['uppercase']!, 'Uppercase letter'),
                _ruleRow(rules['lowercase']!, 'Lowercase letter'),
                _ruleRow(rules['number']!, 'At least one number'),
                _ruleRow(rules['special']!, 'Special character (!@#\$%^&*)'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Password Strength',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      strengthCount == 5
                          ? 'Strong'
                          : strengthCount >= 3
                              ? 'Medium'
                              : 'Weak',
                      style: TextStyle(
                        color: strengthColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: widthFactor,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            strengthColor,
                            strengthColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: strengthColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: COLORS['primaryTeal']!.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _savingPassword ? null : _saveNewPassword,
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
                    colors: _savingPassword
                        ? [Colors.grey, Colors.grey.shade700]
                        : [COLORS['primaryTeal']!, const Color(0xFF009688)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    _savingPassword ? 'Saving...' : 'Save New Password',
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
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => setState(() => step = 2),
            style: OutlinedButton.styleFrom(
              foregroundColor: COLORS['premiumWhite'],
              side: BorderSide(color: COLORS['primaryTeal']!),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Back to Options'),
          ),
        ],
      ),
    );
  }

  Widget _ruleRow(bool ok, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: ok ? COLORS['successGreen'] : Colors.transparent,
              border: Border.all(
                color: ok ? COLORS['successGreen']! : Colors.redAccent,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ok ? Icons.check : Icons.close,
              color: ok ? Colors.white : Colors.redAccent,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: ok ? Colors.white70 : Colors.redAccent,
              fontSize: 14,
            ),
          ),
        ],
      ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: step == index + 1 ? 24 : 12,
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: step >= index + 1
                            ? LinearGradient(
                                colors: [
                                  COLORS['primaryTeal']!,
                                  COLORS['accentCoral']!,
                                ],
                              )
                            : const LinearGradient(
                                colors: [Colors.white24, Colors.white12],
                              ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: step >= index + 1
                            ? [
                                BoxShadow(
                                  color: COLORS['primaryTeal']!.withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
