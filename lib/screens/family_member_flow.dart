import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'registration_screen.dart';

// ═══════════════════════════════════════════════════════════════
//  SCREEN 1 — FamilyMemberTypeScreen
//  Select relationship type, then navigate to OwnerVerificationScreen
// ═══════════════════════════════════════════════════════════════
class FamilyMemberTypeScreen extends StatefulWidget {
  const FamilyMemberTypeScreen({super.key});

  @override
  State<FamilyMemberTypeScreen> createState() => _FamilyMemberTypeScreenState();
}

class _FamilyMemberTypeScreenState extends State<FamilyMemberTypeScreen> {
  String? _selectedRelation;

  // Each entry: { label, icon, emoji }
  static const List<Map<String, dynamic>> _relations = [
    {'label': 'Father', 'icon': Icons.man_rounded, 'emoji': '👨'},
    {'label': 'Mother', 'icon': Icons.woman_rounded, 'emoji': '👩'},
    {'label': 'Brother', 'icon': Icons.person_rounded, 'emoji': '👦'},
    {'label': 'Sister', 'icon': Icons.person_outline_rounded, 'emoji': '👧'},
    {'label': 'Spouse', 'icon': Icons.favorite_rounded, 'emoji': '💑'},
    {'label': 'Guard', 'icon': Icons.security_rounded, 'emoji': '💂'},
    {'label': 'Maid', 'icon': Icons.cleaning_services_rounded, 'emoji': '🧹'},
    {'label': 'Other', 'icon': Icons.people_rounded, 'emoji': '👤'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: teal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Relationship',
          style: TextStyle(
            color: whiteish,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Header banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: teal.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.family_restroom_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Family Member',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Choose your relationship with the owner',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Who are you to the Owner?',
                style: TextStyle(
                  color: whiteish,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 16),

              // ── Relationship grid ──
              Expanded(
                child: GridView.builder(
                  itemCount: _relations.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.45,
                  ),
                  itemBuilder: (context, i) {
                    final rel = _relations[i];
                    final isSelected = _selectedRelation == rel['label'];
                    return GestureDetector(
                      onTap: () => setState(
                          () => _selectedRelation = rel['label'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? primaryGradient
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF1E2533),
                                    Color(0xFF252D3D)
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.white12,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: teal.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              rel['emoji'] as String,
                              style: const TextStyle(fontSize: 26),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              rel['label'] as String,
                              style: TextStyle(
                                color: isSelected ? Colors.white : whiteish,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  '✓ Selected',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ── Continue button ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: AnimatedOpacity(
                  opacity: _selectedRelation != null ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: _selectedRelation == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OwnerVerificationScreen(
                                  role: _selectedRelation!,
                                ),
                              ),
                            );
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: teal.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SCREEN 2 — OwnerVerificationScreen
//  Enter owner CNIC + issue date → verify against Firestore
// ═══════════════════════════════════════════════════════════════
class OwnerVerificationScreen extends StatefulWidget {
  final String role; // e.g. "Father", "Mother", etc.

  const OwnerVerificationScreen({super.key, required this.role});

  @override
  State<OwnerVerificationScreen> createState() =>
      _OwnerVerificationScreenState();
}

class _OwnerVerificationScreenState extends State<OwnerVerificationScreen> {
  final _cnicController = TextEditingController();
  DateTime? _issueDate;
  bool _verifying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _cnicController.dispose();
    super.dispose();
  }

  // ── CNIC formatter: 00000-0000000-0 ──────────────────────────

  String _formatDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ── Core: Query Firestore for matching owner ──────────────────
  Future<void> _verifyOwner() async {
    // Local validation first
    final cnicDigits = _cnicController.text.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{13}$').hasMatch(cnicDigits)) {
      setState(() => _errorMessage = 'Please enter a valid 13-digit CNIC.');
      return;
    }
    if (_issueDate == null) {
      setState(() => _errorMessage = 'Please select the CNIC Date of Issue.');
      return;
    }

    setState(() {
      _verifying = true;
      _errorMessage = null;
    });

    try {
      final formattedDate = _formatDate(_issueDate!);

      // Query owners collection
      final snapshot = await FirebaseFirestore.instance
          .collection('users') // adjust collection name if needed
          .where('role', isEqualTo: 'owner')
          .where('cnic', isEqualTo: cnicDigits)
          .where('cnicIssueDate', isEqualTo: formattedDate)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        // ── Case 2: Owner NOT found ────────────────────────────
        setState(() {
          _verifying = false;
          _errorMessage =
              'No owner found with this CNIC and issue date.\nPlease ask your owner to register first.';
        });
      } else {
        // ── Case 1: Owner found ────────────────────────────────
        final ownerDoc = snapshot.docs.first;
        final ownerId = ownerDoc.id;
        final ownerName = ownerDoc.data()['fullName'] as String? ?? 'Owner';
        final ownerEmail = ownerDoc.data()['email'] as String? ?? '';

        if (ownerEmail.isEmpty) {
          setState(() {
            _verifying = false;
            _errorMessage =
                'Owner email not found. Please contact the administrator.';
          });
          return;
        }

        setState(() => _verifying = false);

        // Show brief success banner then navigate
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Owner verified: $ownerName',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: successGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerEmailDisplayScreen(
              role: widget.role,
              ownerId: ownerId,
              ownerName: ownerName,
              ownerEmail: ownerEmail,
              ownerCnic: cnicDigits,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verifying = false;
          _errorMessage = 'Verification failed. Please check your connection.';
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate ?? DateTime(now.year - 5),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: teal,
            onPrimary: Colors.white,
            surface: sectionBg,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: deepNavy),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _issueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: teal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify Owner',
          style: TextStyle(
            color: whiteish,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Role chip ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: teal.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.family_restroom_rounded,
                        color: teal, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Registering as: ${widget.role}',
                      style: const TextStyle(
                        color: teal,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Info card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: warningAmber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: warningAmber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: warningAmber.withValues(alpha: 0.8), size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Enter the Owner\'s CNIC and the date it was issued. '
                        'The owner must already be registered in the system.',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── CNIC Field ──
              _fieldLabel('Owner CNIC *'),
              _cnicInput(),

              const SizedBox(height: 20),

              // ── Date of Issue ──
              _fieldLabel('CNIC Date of Issue *'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: teal, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        _issueDate != null
                            ? _formatDate(_issueDate!)
                            : 'Select Date of Issue',
                        style: TextStyle(
                          color: _issueDate != null ? whiteish : Colors.white38,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Error box ──
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: coral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: coral.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: coral, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Owner Not Found',
                            style: TextStyle(
                              color: coral,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // ── "Register as Owner" redirect button ──
                      GestureDetector(
                        onTap: () {
                          // Pop all and go back to role selection.
                          // Adjust to your actual route name if using named routes.
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [coral, Color(0xFFE01E5A)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.home_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Register as Owner Instead',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Verify button ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: GestureDetector(
                  onTap: _verifying ? null : _verifyOwner,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _verifying
                          ? const LinearGradient(
                              colors: [Color(0xFF4B3A7E), Color(0xFF4B3A7E)])
                          : primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: teal.withValues(alpha: _verifying ? 0.1 : 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _verifying
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
                              Icon(Icons.verified_rounded,
                                  color: Colors.white, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Verify Owner',
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

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: whiteish,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _cnicInput() {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: _cnicController,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: whiteish, fontSize: 16, letterSpacing: 1),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(13),
          _CnicInputFormatter(),
        ],
        decoration: const InputDecoration(
          hintText: '00000-0000000-0',
          hintStyle: TextStyle(color: Colors.white30, letterSpacing: 1),
          prefixIcon: Icon(Icons.credit_card_rounded, color: teal, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SCREEN 3 — OwnerEmailDisplayScreen
//  Shows masked owner email, sends OTP via EmailJS
// ═══════════════════════════════════════════════════════════════
class OwnerEmailDisplayScreen extends StatefulWidget {
  final String role;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final String ownerCnic;

  const OwnerEmailDisplayScreen({
    super.key,
    required this.role,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerCnic,
  });

  @override
  State<OwnerEmailDisplayScreen> createState() =>
      _OwnerEmailDisplayScreenState();
}

class _OwnerEmailDisplayScreenState extends State<OwnerEmailDisplayScreen> {
  bool _sendingOtp = false;

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 2) return '${'*' * local.length}@$domain';
    return '${local[0]}${'*' * (local.length - 2)}${local[local.length - 1]}@$domain';
  }

  String _generateOtp() {
    final rng = Random();
    return (100000 + rng.nextInt(900000)).toString();
  }

  Future<bool> _sendOtpEmail(String toEmail, String otpCode) async {
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
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _sendOtp() async {
    setState(() => _sendingOtp = true);
    final otp = _generateOtp();
    final success = await _sendOtpEmail(widget.ownerEmail, otp);
    setState(() => _sendingOtp = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to owner\'s email ✓'),
          backgroundColor: successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            role: widget.role,
            ownerId: widget.ownerId,
            ownerName: widget.ownerName,
            ownerEmail: widget.ownerEmail,
            generatedOtp: otp,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send OTP. Please try again.'),
          backgroundColor: coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: teal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify Owner Email',
          style: TextStyle(
            color: whiteish,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: teal.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Text(
                      'Owner Verification',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'We will send a verification code to the owner\'s email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: successGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: successGreen.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: successGreen, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Owner account found',
                      style: TextStyle(
                        color: successGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Owner: ${widget.ownerName}',
                style: const TextStyle(
                  color: whiteish,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'CNIC: ${widget.ownerCnic}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Owner\'s Email',
                style: TextStyle(
                  color: whiteish,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _sendOtp,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sectionBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_rounded, color: teal, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _maskEmail(widget.ownerEmail),
                          style: const TextStyle(
                            color: whiteish,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: teal, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tap the email above to send OTP',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: GestureDetector(
                  onTap: _sendingOtp ? null : _sendOtp,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: teal.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _sendingOtp
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
                              Icon(Icons.send_rounded,
                                  color: Colors.white, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Send OTP',
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
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SCREEN 4 — OtpVerificationScreen
//  Enter 6-digit OTP, verify against sent OTP
// ═══════════════════════════════════════════════════════════════
class OtpVerificationScreen extends StatefulWidget {
  final String role;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final String generatedOtp;

  const OtpVerificationScreen({
    super.key,
    required this.role,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.generatedOtp,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  String? _errorMessage;
  int _remainingAttempts = 3;
  bool _otpExpired = false;
  late Timer _timer;
  int _remainingTime = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        setState(() => _otpExpired = true);
        _timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _verifyOtp() {
    if (_otpExpired) {
      setState(
          () => _errorMessage = 'OTP has expired. Please go back and resend.');
      return;
    }

    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP.');
      return;
    }

    if (enteredOtp == widget.generatedOtp) {
      // Success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('OTP verified successfully!'),
            ],
          ),
          backgroundColor: successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FamilyMemberRegistrationScreen(
                role: widget.role,
                ownerId: widget.ownerId,
                ownerName: widget.ownerName,
                ownerEmail: widget.ownerEmail,
              ),
            ),
          );
        }
      });
    } else {
      setState(() {
        _remainingAttempts--;
        _errorMessage =
            'Incorrect OTP. $_remainingAttempts attempts remaining.';
      });
      if (_remainingAttempts <= 0) {
        _showMaxAttemptsDialog();
      }
    }
  }

  void _showMaxAttemptsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: sectionBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Too Many Attempts',
            style: TextStyle(color: coral, fontWeight: FontWeight.w700)),
        content: const Text(
            'You have exceeded the maximum number of attempts. Please start over.',
            style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK', style: TextStyle(color: teal)),
          ),
        ],
      ),
    );
  }

  Future<void> _resendOtp() async {
    // Reset state
    setState(() {
      _remainingTime = 300;
      _otpExpired = false;
      _errorMessage = null;
      _remainingAttempts = 3;
    });
    _startTimer();

    // Generate new OTP and send
    final newOtp = (100000 + Random().nextInt(900000)).toString();
    final success = await _sendOtpEmail(widget.ownerEmail, newOtp);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New OTP sent!'),
          backgroundColor: successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Update the generatedOtp in navigation? Wait, since it's passed, we need to push a new screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            role: widget.role,
            ownerId: widget.ownerId,
            ownerName: widget.ownerName,
            ownerEmail: widget.ownerEmail,
            generatedOtp: newOtp,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to resend OTP.'),
          backgroundColor: coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _sendOtpEmail(String toEmail, String otpCode) async {
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
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: teal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Enter OTP',
          style: TextStyle(
            color: whiteish,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: teal.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'OTP sent to owner\'s email',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _maskEmail(widget.ownerEmail),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Enter the 6-digit code',
                style: TextStyle(
                  color: whiteish,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    color: whiteish,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 12,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '• • • • • •',
                    hintStyle: TextStyle(
                        color: Colors.white24, letterSpacing: 10, fontSize: 22),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _otpExpired
                    ? 'OTP expired'
                    : 'Expires in: ${_formatTime(_remainingTime)}',
                style: TextStyle(
                  color: _otpExpired ? coral : Colors.white60,
                  fontSize: 14,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: coral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: coral.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: coral, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: GestureDetector(
                  onTap: (_otpExpired || _remainingAttempts <= 0)
                      ? null
                      : _verifyOtp,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: (_otpExpired || _remainingAttempts <= 0)
                          ? const LinearGradient(
                              colors: [Color(0xFF4B3A7E), Color(0xFF4B3A7E)])
                          : primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: teal.withValues(
                              alpha: (_otpExpired || _remainingAttempts <= 0)
                                  ? 0.1
                                  : 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded,
                            color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Verify OTP',
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
              const SizedBox(height: 16),
              TextButton(
                onPressed: _otpExpired ? _resendOtp : null,
                child: Text(
                  _otpExpired
                      ? 'Resend OTP'
                      : 'Resend in ${_formatTime(_remainingTime)}',
                  style: TextStyle(
                    color: _otpExpired ? teal : Colors.white38,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 2) return '${'*' * local.length}@$domain';
    return '${local[0]}${'*' * (local.length - 2)}${local[local.length - 1]}@$domain';
  }
}

// ═══════════════════════════════════════════════════════════════
//  SCREEN 5 — FamilyMemberRegistrationScreen
//  Full registration form for the family member
// ═══════════════════════════════════════════════════════════════
class FamilyMemberRegistrationScreen extends StatefulWidget {
  final String role; // relationship (Father / Mother / …)
  final String ownerId; // Firestore doc ID of verified owner
  final String ownerName;
  final String? ownerEmail; // optional

  const FamilyMemberRegistrationScreen({
    super.key,
    required this.role,
    required this.ownerId,
    required this.ownerName,
    this.ownerEmail,
  });

  @override
  State<FamilyMemberRegistrationScreen> createState() =>
      _FamilyMemberRegistrationScreenState();
}

class _FamilyMemberRegistrationScreenState
    extends State<FamilyMemberRegistrationScreen> {
  // ── Controllers ───────────────────────────────────────────────
  final _fullNameCtrl = TextEditingController();
  final _parentNameCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _customRelationCtrl = TextEditingController();

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _parentNameCtrl.dispose();
    _cnicCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _customRelationCtrl.dispose();
    super.dispose();
  }

  // ── Document uploads ──────────────────────────────────────────
  XFile? _cnicFrontFile;
  XFile? _cnicBackFile;
  XFile? _passportPhotoFile;
  String? _cnicFrontName;
  String? _cnicBackName;
  String? _passportPhotoName;

  // ── UI state ──────────────────────────────────────────────────
  bool _obscurePwd = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String _password = '';

  // ── Cloudinary config (same as existing registration_screen) ──
  static const _cloudName = 'drposqmf0';
  static const _uploadPreset = 'flutter_uploads';

  // ── Helpers ───────────────────────────────────────────────────
  Map<String, bool> _passwordRules(String p) => {
        'length': p.length >= 8,
        'uppercase': RegExp(r'[A-Z]').hasMatch(p),
        'lowercase': RegExp(r'[a-z]').hasMatch(p),
        'number': RegExp(r'[0-9]').hasMatch(p),
        'special': RegExp(r'[!@#$%^&*]').hasMatch(p),
      };

  Future<String?> _uploadToCloudinary(XFile file) async {
    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final req = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _uploadPreset
      ..headers['X-Requested-With'] = 'XMLHttpRequest';
    final bytes = await file.readAsBytes();
    req.files
        .add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));
    try {
      final res = await req.send();
      final body = await res.stream.toBytes();
      final json = jsonDecode(String.fromCharCodes(body));
      if (res.statusCode == 200) return json['secure_url'] as String?;
    } catch (_) {}
    return null;
  }

  Future<void> _pickImage(String key) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      switch (key) {
        case 'cnic_front':
          _cnicFrontFile = image;
          _cnicFrontName = image.name;
          break;
        case 'cnic_back':
          _cnicBackFile = image;
          _cnicBackName = image.name;
          break;
        case 'passport':
          _passportPhotoFile = image;
          _passportPhotoName = image.name;
          break;
      }
    });
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: sectionBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style:
                const TextStyle(color: whiteish, fontWeight: FontWeight.w700)),
        content: Text(msg,
            style: const TextStyle(color: Colors.white60, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: teal)),
          ),
        ],
      ),
    );
  }

  // ── Submit ────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    // Validation
    if (_fullNameCtrl.text.trim().isEmpty) {
      _showAlert('Required', 'Please enter Full Name.');
      return;
    }
    if (_parentNameCtrl.text.trim().isEmpty) {
      _showAlert('Required', 'Please enter Father/Mother Name.');
      return;
    }
    final cnicDigits = _cnicCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{13}$').hasMatch(cnicDigits)) {
      _showAlert('Required', 'Please enter a valid 13-digit CNIC.');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty ||
        !RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(_emailCtrl.text.trim())) {
      _showAlert('Required', 'Please enter a valid email address.');
      return;
    }
    if (_phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length < 11) {
      _showAlert('Required', 'Please enter a valid 11-digit phone number.');
      return;
    }
    final rules = _passwordRules(_password);
    if (rules.values.any((v) => !v)) {
      _showAlert('Weak Password',
          'Password must be 8+ chars with uppercase, lowercase, number and special character.');
      return;
    }
    if (_password != _confirmPasswordCtrl.text) {
      _showAlert('Password Mismatch', 'Passwords do not match.');
      return;
    }

    if (widget.role == 'Other' && _customRelationCtrl.text.trim().isEmpty) {
      _showAlert('Required', 'Please specify your relation with the owner.');
      return;
    }
    if (_cnicFrontFile == null || _cnicBackFile == null) {
      _showAlert('Required', 'Please upload CNIC Front and Back images.');
      return;
    }
    if (_passportPhotoFile == null) {
      _showAlert('Required', 'Please upload a Passport Size Photo.');
      return;
    }

    setState(() => _saving = true);

    try {
      // 1. Create Firebase Auth account using the member's real email
      final authEmail =
          _emailCtrl.text.trim(); // real email entered in the form
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: authEmail,
        password: _password,
      );
      final uid = credential.user!.uid;

      // 2. Upload documents to Cloudinary
      final cnicFrontUrl = await _uploadToCloudinary(_cnicFrontFile!);
      final cnicBackUrl = await _uploadToCloudinary(_cnicBackFile!);
      final passportUrl = await _uploadToCloudinary(_passportPhotoFile!);

      // 3. Format CNIC
      final formattedCnic = '${cnicDigits.substring(0, 5)}-'
          '${cnicDigits.substring(5, 12)}-'
          '${cnicDigits.substring(12)}';

      // 4. Write to Firestore: users/{uid}
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'role': 'family_member',
        'relationship': widget.role == 'Other'
            ? _customRelationCtrl.text.trim()
            : widget.role,
        'relationshipType': widget.role, // 'Other' raw value bhi save rakhein reference ke liye
        'ownerId': widget.ownerId, // ← foreign key link to owner
        'ownerName': widget.ownerName,
        'fullName': _fullNameCtrl.text.trim(),
        'parentName': _parentNameCtrl.text.trim(),
        'cnic': formattedCnic,
        'email': _emailCtrl.text.trim(),
        'authEmail':
            _emailCtrl.text.trim(), // ← ADD this field for Firebase Auth lookup
        'phone': _phoneCtrl.text.trim(),
        'documents': {
          'cnicFront': cnicFrontUrl,
          'cnicBack': cnicBackUrl,
          'passportPhoto': passportUrl,
        },
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 5. Also add subcollection reference under owner
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.ownerId)
          .collection('family_members')
          .doc(uid)
          .set({
        'uid': uid,
        'name': _fullNameCtrl.text.trim(),
        'relationship': widget.role == 'Other'
            ? _customRelationCtrl.text.trim()
            : widget.role,
        'cnic': formattedCnic,
        'addedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() => _saving = false);

      // 6. Success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: sectionBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                'Registration Successful!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: whiteish,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your Family Member profile is under review.\n'
                'You will be notified once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Pop all screens back to root (role selection)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Done',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _saving = false);
      if (e.code == 'email-already-in-use') {
        _showAlert('Already Registered',
            'This email address is already registered. If you forgot your password, use the Forgot Password option.');
      } else {
        _showAlert(
            'Auth Error',
            e.code == 'email-already-in-use'
                ? 'This email is already registered.'
                : e.message ?? 'Registration failed.');
      }
    } catch (e) {
      // Rollback auth on Firestore failure
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (_) {}
      setState(() => _saving = false);
      _showAlert('Error', 'Registration failed. Please try again.\n$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rules = _passwordRules(_password);
    final metCount = rules.values.where((v) => v).length;
    final strengthColor = metCount == 5
        ? successGreen
        : metCount >= 3
            ? warningAmber
            : coral;

    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: teal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Family Member Registration',
          style: TextStyle(
            color: whiteish,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Owner + Role summary ──────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: teal.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.family_restroom_rounded,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Relationship: ${widget.role}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Owner: ${widget.ownerName}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✓ Verified',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ─────────────────────────────────────────────────
              //  SECTION: Personal Information
              // ─────────────────────────────────────────────────
              _sectionHeader('Personal Information', Icons.person_rounded),
              const SizedBox(height: 16),

              // ── Other: Custom Relation field ─────────────────────────
              if (widget.role == 'Other') ...[
                _fieldLabel('Your Relation with Owner *'),
                Container(
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: _customRelationCtrl,
                    style: const TextStyle(color: whiteish, fontSize: 15),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Uncle, Cousin, Neighbour...',
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                      prefixIcon:
                          Icon(Icons.people_alt_rounded, color: teal, size: 20),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _fieldLabel('Full Name *'),
              _textInput(_fullNameCtrl, hint: 'Enter your full name'),
              const SizedBox(height: 16),

              _fieldLabel('Father / Mother Name *'),
              _textInput(_parentNameCtrl, hint: 'Enter parent\'s name'),
              const SizedBox(height: 16),

              _fieldLabel('CNIC Number *'),
              _cnicField(),
              const SizedBox(height: 16),

              _fieldLabel('Email Address *'),
              _textInput(
                _emailCtrl,
                hint: 'example@email.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _fieldLabel('Phone Number *'),
              _phoneField(),

              const SizedBox(height: 28),

              // ─────────────────────────────────────────────────
              //  SECTION: Document Uploads
              // ─────────────────────────────────────────────────
              _sectionHeader('Document Uploads', Icons.upload_file_rounded),
              const SizedBox(height: 16),

              _uploadTile(
                title: 'CNIC Front Side *',
                fileName: _cnicFrontName,
                icon: Icons.credit_card_rounded,
                onTap: () => _pickImage('cnic_front'),
              ),
              const SizedBox(height: 12),

              _uploadTile(
                title: 'CNIC Back Side *',
                fileName: _cnicBackName,
                icon: Icons.credit_card_outlined,
                onTap: () => _pickImage('cnic_back'),
              ),
              const SizedBox(height: 12),

              _uploadTile(
                title: 'Passport Size Photo *',
                fileName: _passportPhotoName,
                icon: Icons.photo_camera_rounded,
                onTap: () => _pickImage('passport'),
              ),

              const SizedBox(height: 28),

              // ─────────────────────────────────────────────────
              //  SECTION: Set Password
              // ─────────────────────────────────────────────────
              _sectionHeader('Set Password', Icons.lock_rounded),
              const SizedBox(height: 16),

              _fieldLabel('Password *'),
              _passwordField(
                controller: _passwordCtrl,
                hint: 'Create a strong password',
                obscure: _obscurePwd,
                onToggle: () => setState(() => _obscurePwd = !_obscurePwd),
                onChanged: (v) => setState(() => _password = v),
              ),

              // Password strength bar
              if (_password.isNotEmpty) ...[
                const SizedBox(height: 12),
                _passwordStrengthWidget(rules, metCount, strengthColor),
              ],

              const SizedBox(height: 16),

              _fieldLabel('Confirm Password *'),
              _passwordField(
                controller: _confirmPasswordCtrl,
                hint: 'Re-enter your password',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),

              const SizedBox(height: 36),

              // ── Submit button ──────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 58,
                child: GestureDetector(
                  onTap: _saving ? null : _handleSubmit,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _saving
                          ? const LinearGradient(
                              colors: [Color(0xFF3B2F6E), Color(0xFF3B2F6E)])
                          : primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: teal.withValues(alpha: _saving ? 0.1 : 0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _saving
                        ? const Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.how_to_reg_rounded,
                                  color: Colors.white, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Complete Registration',
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

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: teal.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: teal, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: whiteish,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(height: 1, color: Colors.white12),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: whiteish,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _textInput(
    TextEditingController ctrl, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: whiteish, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _cnicField() {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: _cnicCtrl,
        keyboardType: TextInputType.number,
        style:
            const TextStyle(color: whiteish, fontSize: 16, letterSpacing: 1.2),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(13),
          _CnicInputFormatter(),
        ],
        decoration: const InputDecoration(
          hintText: '00000-0000000-0',
          hintStyle: TextStyle(color: Colors.white30, letterSpacing: 1),
          prefixIcon: Icon(Icons.credit_card_rounded, color: teal, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }

  Widget _phoneField() {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        style: const TextStyle(color: whiteish, fontSize: 15),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11),
          _PakistaniPhoneFormatter(),
        ],
        decoration: const InputDecoration(
          hintText: '03XX-XXXXXXX',
          hintStyle: TextStyle(color: Colors.white30),
          prefixIcon: Icon(Icons.phone_rounded, color: teal, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onChanged: onChanged,
        style: const TextStyle(color: whiteish, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
          prefixIcon: const Icon(Icons.lock_rounded, color: teal, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: Colors.white38,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }

  Widget _uploadTile({
    required String title,
    required String? fileName,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final uploaded = fileName != null;
    return Container(
      decoration: BoxDecoration(
        color: uploaded
            ? teal.withValues(alpha: 0.08)
            : inputBg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: uploaded ? teal.withValues(alpha: 0.4) : Colors.white12,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: uploaded
                ? teal.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: uploaded ? teal : Colors.white38, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
              color: whiteish, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          uploaded ? fileName : 'Tap to upload image',
          style: TextStyle(
            color: uploaded ? teal : Colors.white38,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              uploaded ? 'Change' : 'Upload',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordStrengthWidget(
      Map<String, bool> rules, int metCount, Color strengthColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sectionBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rule rows
          for (final entry in {
            'length': 'Minimum 8 characters',
            'uppercase': 'Uppercase letter',
            'lowercase': 'Lowercase letter',
            'number': 'At least one number',
            'special': 'Special character (!@#\$%^&*)',
          }.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color:
                          rules[entry.key]! ? successGreen : Colors.transparent,
                      border: Border.all(
                          color: rules[entry.key]!
                              ? successGreen
                              : Colors.redAccent),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      rules[entry.key]! ? Icons.check : Icons.close,
                      color:
                          rules[entry.key]! ? Colors.white : Colors.redAccent,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    entry.value,
                    style: TextStyle(
                      color:
                          rules[entry.key]! ? Colors.white60 : Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          // Strength bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Password Strength',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text(
                metCount == 5
                    ? 'Strong'
                    : metCount >= 3
                        ? 'Medium'
                        : 'Weak',
                style: TextStyle(
                    color: strengthColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: metCount / 5,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(strengthColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Input formatters
// ─────────────────────────────────────────────

/// Formats CNIC as 00000-0000000-0
class _CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    final digits = newVal.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 13; i++) {
      if (i == 5 || i == 12) buf.write('-');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Formats phone as 03XX-XXXXXXX
class _PakistaniPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    final digits = newVal.text.replaceAll(RegExp(r'\D'), '').substring(
        0,
        newVal.text.replaceAll(RegExp(r'\D'), '').length > 11
            ? 11
            : newVal.text.replaceAll(RegExp(r'\D'), '').length);
    final text = digits.length <= 4
        ? digits
        : '${digits.substring(0, 4)}-${digits.substring(4)}';
    return TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
