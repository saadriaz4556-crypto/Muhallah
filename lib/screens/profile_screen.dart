import 'package:flutter/material.dart';
import 'profile/profile_dashboard.dart';

// This class is kept for backward compatibility with HomeScreen
class ProfileApp extends StatelessWidget {
  const ProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileDashboard();
  }
}
