import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LocalServicesScreen extends StatefulWidget {
  final String townName;

  const LocalServicesScreen({super.key, this.townName = "Green Valley"});

  @override
  State<LocalServicesScreen> createState() => _LocalServicesScreenState();
}

class _LocalServicesScreenState extends State<LocalServicesScreen> {
  // Updated local services list
  final List<Map<String, dynamic>> _services = [
    {
      'name': 'Plumber',
      'category': 'Home Repair',
      'phone': '+923001234001',
      'address': 'Muhallah - Near Community Gate',
    },
    {
      'name': 'Electrician',
      'category': 'Home Repair',
      'phone': '+923001234002',
      'address': 'Muhallah - Market Area',
    },
    {
      'name': 'Carpenter',
      'category': 'Home Repair',
      'phone': '+923001234003',
      'address': 'Muhallah - Workshop Lane',
    },
    {
      'name': 'AC Technician',
      'category': 'Appliance Repair',
      'phone': '+923001234004',
      'address': 'Muhallah - Service Street',
    },
    {
      'name': 'Mechanic (Cars, Bikes, Generators)',
      'category': 'Vehicle Repair',
      'phone': '+923001234005',
      'address': 'Muhallah - Garage Row',
    },
    {
      'name': 'Painter',
      'category': 'Home Repair',
      'phone': '+923001234006',
      'address': 'Muhallah - Color Lane',
    },
    {
      'name': 'Mason / Construction Labor',
      'category': 'Construction',
      'phone': '+923001234007',
      'address': 'Muhallah - Build Site',
    },
    {
      'name': 'Tube-well Operator',
      'category': 'Utilities',
      'phone': '+923001234008',
      'address': 'Muhallah - Water Point',
    },
    {
      'name': 'Cable / Internet Service Office',
      'category': 'Connectivity',
      'phone': '+923001234009',
      'address': 'Muhallah - Telecom Block',
    },
    {
      'name': 'School / Tuition Center',
      'category': 'Education',
      'phone': '+923001234010',
      'address': 'Muhallah - Education Road',
    },
    {
      'name': 'Mosque Committee / Religious Center',
      'category': 'Religious',
      'phone': '+923001234011',
      'address': 'Muhallah - Main Mosque',
    },
    {
      'name': 'Community Hall / Meeting Point',
      'category': 'Community',
      'phone': '+923001234012',
      'address': 'Muhallah - Hall Street',
    },
    {
      'name': 'Parking / Transport Stand',
      'category': 'Transport',
      'phone': '+923001234013',
      'address': 'Muhallah - Transport Hub',
    },
  ];

  // UI colors
  final Color _darkBackground = const Color(0xFF252A34);
  final Color _primaryColor = const Color(0xFF08D9D6);
  final Color _accentColor = const Color(0xFF08D9D6);
  final Color _darkCardColor = const Color(0xFF2A303C);
  final Color _darkTextColor = const Color(0xFFEAEAEA);
  final Color _darkSecondaryText = Colors.white70;

  // Function to launch phone dialer
  Future<void> _launchPhoneDialer(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      final bool launched = await launchUrl(phoneUri);
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not launch dialer'),
            backgroundColor: _accentColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not launch dialer: \$e'),
          backgroundColor: _accentColor,
        ),
      );
    }
  }

  // Function to launch SMS app
  Future<void> _launchSMS(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    try {
      final bool launched = await launchUrl(smsUri);
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not launch messaging app'),
            backgroundColor: _accentColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not launch messaging app: \$e'),
          backgroundColor: _accentColor,
        ),
      );
    }
  }

  Widget _buildHeader() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_darkBackground, _primaryColor.withValues(alpha: 0.3)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button and title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _darkCardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.arrow_back, color: _darkTextColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.townName,
                          style: TextStyle(
                            color: _darkTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Local Services',
                          style: TextStyle(
                            color: _darkSecondaryText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _darkCardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.more_vert, color: _darkTextColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard(Map<String, dynamic> service) {
    return Card(
      color: _darkCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['name'],
                        style: TextStyle(
                          color: _darkTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        service['category'],
                        style: TextStyle(color: _darkSecondaryText),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        service['address'],
                        style: TextStyle(color: _darkSecondaryText),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _launchPhoneDialer(service['phone']),
                      icon: Icon(Icons.call, color: _accentColor),
                    ),
                    IconButton(
                      onPressed: () => _launchSMS(service['phone']),
                      icon: Icon(Icons.message, color: _accentColor),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(),
            // Search and list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _serviceCard(_services[index]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
