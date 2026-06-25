import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  // --- Constants & Colors ---
  static const Color deepNavy = Color(0xFF252A34);
  static const Color primaryTeal = Color(0xFF08D9D6);
  static const Color coral = Color(0xFFFF2E63);
  static const Color cardBg = Color(0xFF1E1E2F);
  static const Color premiumWhite = Color(0xFFEAEAEA);

  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _allFaqs = [
    {
      'question': 'I can’t sign in / Invalid CNIC or password',
      'answer':
          'Check CNIC digits (13 digits). Format app accepts: 12345-1234567-1. If still failing, tap Reset Password.'
    },
    {
      'question': 'Forgot password',
      'answer':
          'Tap Reset Password and follow the steps. You’ll receive instructions.'
    },
    {
      'question': 'Account locked / Too many attempts',
      'answer':
          'Wait 15 minutes and try again. If still locked, contact support via the form.'
    },
    {
      'question': 'I don’t know my CNIC format',
      'answer':
          'CNIC must be 13 numeric digits. We convert it to an internal email CNIC@muhallah.com.'
    },
    {
      'question': 'I never received reset email / code',
      'answer':
          'Check spam/junk. If not found, use Contact Support and include CNIC and timestamp.'
    },
    {
      'question': 'App errors / crashes',
      'answer':
          'Use Report Bug — include short description and what you were doing.'
    },
  ];

  List<Map<String, String>> _filteredFaqs = [];

  @override
  void initState() {
    super.initState();
    _filteredFaqs = List.from(_allFaqs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFaqs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFaqs = List.from(_allFaqs);
      } else {
        _filteredFaqs = _allFaqs
            .where((faq) =>
                faq['question']!.toLowerCase().contains(query.toLowerCase()) ||
                faq['answer']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _navigateToResetPassword() {
    Navigator.pushNamed(context, '/forgot_password');
  }

  void _showTroubleshootDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        title: const Text('Troubleshoot Sign-in',
            style: TextStyle(color: premiumWhite)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Check internet connection.',
                style: TextStyle(color: Colors.white70)),
            SizedBox(height: 8),
            Text('2. Ensure CNIC format is 12345-1234567-1.',
                style: TextStyle(color: Colors.white70)),
            SizedBox(height: 8),
            Text('3. Clear app cache if persistent.',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: primaryTeal)),
          ),
        ],
      ),
    );
  }

  void _showContactSupportDialog() {
    // Placeholder for Contact Support Form
    _showFormDialog('Contact Support', 'Describe your issue...');
  }

  void _showReportBugDialog() {
    // Placeholder for Report Bug Form
    _showFormDialog('Report Bug', 'Describe the bug...');
  }

  void _showFormDialog(String title, String hint) {
    final TextEditingController msgController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        title: Text(title, style: const TextStyle(color: premiumWhite)),
        content: TextField(
          controller: msgController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement actual submission logic (Firestore)
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Request sent successfully (Simulated)')),
              );
            },
            child: const Text('Send', style: TextStyle(color: primaryTeal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        backgroundColor: deepNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Help Centre', style: TextStyle(color: premiumWhite)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterFaqs,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                hintText: 'Search help',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickActionButton(
                  icon: Icons.lock_reset,
                  label: 'Reset\nPassword',
                  onTap: _navigateToResetPassword,
                  color: coral,
                ),
                _QuickActionButton(
                  icon: Icons.build_circle_outlined,
                  label: 'Troubleshoot',
                  onTap: _showTroubleshootDialog,
                  color: primaryTeal,
                ),
                _QuickActionButton(
                  icon: Icons.support_agent,
                  label: 'Contact\nSupport',
                  onTap: _showContactSupportDialog,
                  color: Colors.amber, // Distinct color for support
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // FAQ List
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredFaqs.length,
                  itemBuilder: (context, index) {
                    final faq = _filteredFaqs[index];
                    return Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        iconTheme: const IconThemeData(color: primaryTeal),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          faq['question']!,
                          style: const TextStyle(
                            color: premiumWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  faq['answer']!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Was this helpful?',
                                      style: TextStyle(
                                        color: Colors.white30,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Thanks for your feedback!'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: const Icon(
                                        Icons.thumb_up_alt_outlined,
                                        color: Colors.white30,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    InkWell(
                                      onTap: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Thanks for your feedback!'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: const Icon(
                                        Icons.thumb_down_alt_outlined,
                                        color: Colors.white30,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Report Bug Button at User Safe Area
          Container(
            color: cardBg,
            padding: const EdgeInsets.all(16.0),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showReportBugDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.bug_report, color: Colors.white54),
                  label: const Text(
                    'Report a Bug',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFEAEAEA), // premiumWhite
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
