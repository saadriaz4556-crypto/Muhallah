import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'utils/profile_constants.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isLoading = false;

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Show password confirmation dialog
    final passwordController = TextEditingController();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: sectionBg,
        title:
            const Text('Confirm Deletion', style: TextStyle(color: whiteish)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your password to confirm account deletion.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: whiteish),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: teal),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              if (passwordController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: errorRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // Delete from Auth
      await user.delete();

      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: coral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        title: const Text('Delete Account', style: TextStyle(color: whiteish)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
              gradient: secondaryGradient), // Red gradient header
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            color: sectionBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: 1.2),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: const Icon(Icons.warning_amber_rounded,
                            color: errorRed, size: 80),
                      );
                    },
                    onEnd: () {
                      // Optionally we can reverse or loop but basic TweenAnimationBuilder just runs once by default.
                      // For a true pulse we'd use an AnimationController, but this simple bounce is okay.
                    },
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Are you sure you want to delete your account?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: whiteish,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This action is irreversible. All your personal data, properties, posts, and complaints will remain but your access will be permanently lost.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 40),
                  _isLoading
                      ? const CircularProgressIndicator(color: errorRed)
                      : ElevatedButton(
                          onPressed: _deleteAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: errorRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            elevation: 5,
                          ),
                          child: const Text("Delete Permanently",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
