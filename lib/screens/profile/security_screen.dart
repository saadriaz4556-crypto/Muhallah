import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'utils/profile_constants.dart';
import 'edit_profile_screen.dart' show ChangePasswordDialog;

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _isProfilePrivate = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final lastSignIn = user?.metadata.lastSignInTime;
    final lastSignInStr = lastSignIn != null
        ? lastSignIn.toLocal().toString().split('.')[0]
        : 'Unknown';

    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        title: const Text('Security', style: TextStyle(color: whiteish)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: primaryGradient),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Change Password
          _buildSecurityMenuItem(
            icon: Icons.lock_reset,
            color: teal,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const ChangePasswordDialog(),
              );
            },
          ),
          const SizedBox(height: 12),

          // Two-Factor Auth (Coming Soon)
          _buildSecurityMenuItem(
            icon: Icons.security,
            color: warningAmber,
            title: 'Two-Factor Auth',
            subtitle: 'Add an extra layer of security',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: warningAmber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: warningAmber),
              ),
              child: const Text(
                'Coming Soon',
                style: TextStyle(
                  color: warningAmber,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Active Sessions
          _buildSecurityMenuItem(
            icon: Icons.devices,
            color: const Color(0xFF6C63FF),
            title: 'Active Sessions',
            subtitle: 'Last login: $lastSignInStr\nCurrent Device',
          ),
          const SizedBox(height: 12),

          // Privacy Settings
          Card(
            color: sectionBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.visibility_off, color: successGreen),
              ),
              title: const Text(
                'Private Profile',
                style: TextStyle(color: whiteish, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Hide profile details from public searches',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: Switch(
                value: _isProfilePrivate,
                activeThumbColor: teal,
                onChanged: (val) {
                  setState(() => _isProfilePrivate = val);
                  // Feature for future implementation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy settings updated')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityMenuItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      color: sectionBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(color: whiteish, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing:
            trailing ??
            (onTap != null
                ? const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white24,
                    size: 16,
                  )
                : null),
      ),
    );
  }
}
