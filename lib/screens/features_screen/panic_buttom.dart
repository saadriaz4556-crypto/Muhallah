import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for haptic feedback

void main() {
  runApp(const PanicApp());
}

class PanicApp extends StatelessWidget {
  const PanicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Panic Button',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF252A34),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const PanicScreen(),
    );
  }
}

class PanicScreen extends StatefulWidget {
  const PanicScreen({super.key});

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> {
  // Colors provided by user
  static const Color teal = Color(0xFF08D9D6);
  static const Color darkGray = Color(0xFF252A34);
  static const Color panicRed = Color(0xFFFF2E63);
  static const Color textGray = Color(0xFFEAEAEA);
  bool _isLoading = false;
  bool _alertSent = false;

  Future<void> _showAlertOptions() async {
    HapticFeedback.lightImpact();

    final choice = await showModalBottomSheet<_AlertChoice>(
      context: context,
      backgroundColor: darkGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose alert type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _OptionCard(
                icon: Icons.campaign_rounded,
                title: 'Alert Community',
                subtitle:
                    'Notify all community members & security within radius',
                onTap: () => Navigator.of(context).pop(_AlertChoice.community),
              ),
              const SizedBox(height: 8),
              _OptionCard(
                icon: Icons.shield_rounded,
                title: 'Alert Group Admin',
                subtitle: 'Notify only your group admins & on-duty security',
                onTap: () => Navigator.of(context).pop(_AlertChoice.admin),
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );

    if (choice != null) {
      await _showConfirmationDialog(choice);
    }
  }

  Future<void> _showConfirmationDialog(_AlertChoice choice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: darkGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Are you sure?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          choice == _AlertChoice.community
              ? 'This will send an emergency alert to all community members and security personnel. This should only be used in real emergencies.'
              : 'This will send an emergency alert to group admins and on-duty security. This should only be used in real emergencies.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: panicRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Yes, Send Alert',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _sendAlert(choice);
    }
  }

  Future<void> _sendAlert(_AlertChoice choice) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _alertSent = true;
    });

    HapticFeedback.heavyImpact();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: teal,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Alert Sent Successfully!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              choice == _AlertChoice.community
                  ? 'Community & security have been notified'
                  : 'Group admins have been alerted',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );

    // Reset after some time
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _alertSent = false;
        });
      }
    });
  }

  void _resetAlert() {
    setState(() {
      _alertSent = false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final buttonDiameter = size.width * 0.65;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkGray,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            // Fixed: Simply pop the current screen to go back to home
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Emergency'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Status Message
            if (_alertSent)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: teal.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: teal, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Help is on the way!',
                              style: TextStyle(
                                color: teal,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Emergency services have been notified',
                              style: TextStyle(
                                color: teal.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: teal, size: 20),
                        onPressed: _resetAlert,
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox.shrink(),

            const SizedBox(height: 24),

            // Main Panic Button
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _alertSent ? _resetAlert : _showAlertOptions,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing Animation when alert is sent
                      if (_alertSent)
                        TweenAnimationBuilder(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(seconds: 2),
                          builder: (context, value, child) {
                            return Container(
                              width: buttonDiameter + (value * 60),
                              height: buttonDiameter + (value * 60),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: teal.withOpacity(0.2 * (1 - value)),
                              ),
                            );
                          },
                        ),

                      // Outer glow effect
                      Container(
                        width: buttonDiameter + 30,
                        height: buttonDiameter + 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _alertSent
                                  ? teal.withOpacity(0.4)
                                  : panicRed.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),

                      // Main button container
                      Container(
                        width: buttonDiameter,
                        height: buttonDiameter,
                        decoration: BoxDecoration(
                          color: _alertSent ? teal : panicRed,
                          shape: BoxShape.circle,
                          gradient: _alertSent
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [teal, teal.withOpacity(0.8)],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [panicRed, panicRed.withOpacity(0.8)],
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: _alertSent
                                  ? teal.withOpacity(0.5)
                                  : panicRed.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoading)
                              const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                _alertSent
                                    ? Icons.check
                                    : Icons.warning_amber_rounded,
                                size: 52,
                                color: Colors.white,
                              ),
                            const SizedBox(height: 12),
                            Text(
                              _alertSent ? 'Alert Sent!' : 'Panic Button',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (!_alertSent && !_isLoading)
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Tap to activate',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Information Cards
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                children: [
                  _InfoCard(
                    icon: Icons.access_time_filled,
                    title: 'Immediate Response',
                    description:
                        'Alert will be sent to nearby emergency contacts instantly',
                    color: teal,
                  ),
                  SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.location_pin,
                    title: 'Location Sharing',
                    description:
                        'Your current location will be shared with responders',
                    color: panicRed,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

enum _AlertChoice { community, admin }

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
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
