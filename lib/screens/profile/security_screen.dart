import 'package:flutter/material.dart';
import 'utils/profile_constants.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        title: const Text('Security', style: TextStyle(color: whiteish)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: primaryGradient),
        ),
      ),
      body: const Center(
        child: Text(
          'Security Settings\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      ),
    );
  }
}
