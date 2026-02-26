import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added Firestore import
import 'package:muhallah/screens/features_screen/Poll_voting.dart';
import 'package:muhallah/screens/features_screen/announcements.dart';
import 'package:muhallah/screens/features_screen/bill_remminder.dart';
import 'package:muhallah/screens/features_screen/event_donation.dart';
import 'package:muhallah/screens/features_screen/invitation_card.dart';
import 'package:muhallah/screens/features_screen/jobs.dart';
import 'package:muhallah/screens/features_screen/localservices.dart';
import 'package:muhallah/screens/features_screen/lostfound.dart';
import 'package:muhallah/screens/features_screen/marriage_event.dart';
import 'package:muhallah/screens/features_screen/panic_buttom.dart';
import 'package:muhallah/screens/features_screen/quick_report.dart';
import 'feed_screen.dart';
import 'complaints_screen.dart';
import 'market_screen.dart';
import 'profile_screen.dart';

const Map<String, Color> COLORS = {
  'background': Color(0xFF252A34),
  'accent': Color(0xFF08D9D6),
  'danger': Color(0xFFFF2E63),
  'light': Color(0xFFEAEAEA),
  'darkText': Color(0xFF252A34),
  'mutedText': Color(0xFF777777),
  'success': Color(0xFF4CAF50),
  'warning': Color(0xFFFF9800),
};

const double SPACING = 16.0;
const double RADIUS = 12.0;

final List<Map<String, String>> FEATURES = [
  {'title': 'Announcements', 'emoji': '📢', 'color': '#2196F3'},
  {'title': 'Complaints', 'emoji': '🚨', 'color': '#FF5722'},
  {'title': 'Marketplace', 'emoji': '🛒', 'color': '#4CAF50'},
  {'title': 'Lost & Found', 'emoji': '🔍', 'color': '#FF9800'},
  {'title': 'Local Services', 'emoji': '🔧', 'color': '#795548'},
  {'title': 'Marriage Events', 'emoji': '💍', 'color': '#E91E63'},
  {'title': 'Invitation Cards', 'emoji': '🎴', 'color': '#9C27B0'},
  {'title': 'Bill Reminders', 'emoji': '💰', 'color': '#FFC107'},
  {'title': 'Jobs', 'emoji': '💼', 'color': '#607D8B'},
  {'title': 'Polls/Voting', 'emoji': '🗳️', 'color': '#3F51B5'},
  {'title': 'Events & Donations', 'emoji': '🎉', 'color': '#00BCD4'},
  {'title': 'Smart Search', 'emoji': '🔎', 'color': '#009688'},
];

Color _hexToColor(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

class HomeScreeen extends StatefulWidget {
  const HomeScreeen({super.key});

  @override
  State<HomeScreeen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreeen>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  int _currentIndex = 0;
  String userName = ''; // Removed hardcoded 'Saad'
  String muhalla = ''; // Removed hardcoded 'Gulshan Block A'
  bool _isLoading = true; // Added loading state
  bool _isDataFetched = false; // Prevent duplicate fetches

  // Screens list (initialized in didChangeDependencies)
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
    // _fetchUserData(); // Moved to didChangeDependencies to access arguments
  }

  Future<void> _fetchUserData() async {
    try {
      String? targetUid;
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        targetUid = user.uid;
      } else {
        // Fallback: Check arguments for UID if Auth is null
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is String && args.isNotEmpty) {
          targetUid = args;
        }
      }

      if (targetUid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          if (mounted) {
            setState(() {
              userName = data['fullName'] ?? 'User';
              // Construct address from available fields
              if (data['area'] != null) {
                muhalla = data['area'];
              } else if (data['propertyAddress'] != null) {
                // Try to keep it short if it's a full address
                muhalla = data['propertyAddress'].toString().split(',')[0];
              } else {
                muhalla = 'No Address';
              }
              _isLoading = false;
            });
          }
        } else {
          // Document does not exist
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        // No user and no fallback ID
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataFetched) {
      _fetchUserData();
      _isDataFetched = true;
    }
    // YAHAN ACTUAL SCREEN FILES USE KAREIN
    _screens = [
      _buildHomeTab(), // Home tab with existing content
      const FeedScreen(), // Actual FeedScreen from feed_screen.dart
      const ComplaintsScreen(), // Actual ComplaintsScreen from complaints_screen.dart
      const MarketplaceModule(), // Actual MarketScreen from market_screen.dart
      const ProfileApp(), // Actual ProfileScreen from profile_screen.dart
    ];
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ✅ UPDATED: Feature press handler with navigation for ALL features
  void _handleFeaturePress(String title) {
    switch (title) {
      case 'Announcements':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AnnouncementApp()),
        );
        break;

      case 'Complaints':
        setState(() {
          _currentIndex = 2;
        });
        break;

      case 'Marketplace':
        setState(() {
          _currentIndex = 3;
        });
        break;

      case 'Lost & Found':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LostFoundApp()),
        );
        break;

      case 'Local Services':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LocalServicesScreen()),
        );
        break;

      case 'Marriage Events':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MarriageEventsScreen()),
        );
        break;

      case 'Invitation Cards':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InvitationCardScreen()),
        );
        break;

      case 'Bill Reminders':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BillRemindersApp()),
        );
        break;

      case 'Jobs':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JobsApp()),
        );
        break;

      case 'Polls/Voting':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PollsVotingApp()),
        );
        break;

      case 'Events & Donations':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EventsDonationsApp()),
        );
        break;

        break;

      default:
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: const Text('This feature will be available soon!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
    }
  }

  void _handleEmergency() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PanicApp()),
    );
  }

  Future<void> _goToLogin() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // MAIN: Home tab made non-scrollable
  Widget _buildHomeTab() {
    final bg = COLORS['background']!;
    final accent = COLORS['accent']!;
    final danger = COLORS['danger']!;
    final light = COLORS['light']!;
    final darkText = COLORS['darkText']!;
    final muted = COLORS['mutedText']!;

    final screenWidth = MediaQuery.of(context).size.width;
    const int perRow = 3;
    const gap = 12.0;

    // total horizontal padding used by the scroll view (left + right)
    const totalHorizontalPadding = SPACING * 2;
    // available width for the cards (screen width minus horizontal paddings and the gaps between cards)
    final availableWidth =
        screenWidth - totalHorizontalPadding - (gap * (perRow - 1));
    final cardWidth = availableWidth / perRow;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SPACING),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _handleEmergency,
                  borderRadius: BorderRadius.circular(RADIUS),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: COLORS['danger'],
                      borderRadius: BorderRadius.circular(RADIUS),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('🚨', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'Emergency',
                                    style: TextStyle(
                                      color: light,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'SOS Alert',
                                    style: TextStyle(
                                      color: light,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuickReportApp(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(RADIUS),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(RADIUS),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Report',
                                style: TextStyle(
                                  color: light,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
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
            ],
          ),

          const SizedBox(height: 15),

          // Stats Section
          Text(
            'Community Overview',
            style: TextStyle(
              color: light,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _hexToColor('#2196F3'),
                    borderRadius: BorderRadius.circular(RADIUS),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '1,234',
                        style: TextStyle(
                          color: light,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Active Residents',
                        style: TextStyle(color: light, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _hexToColor('#4CAF50'),
                    borderRadius: BorderRadius.circular(RADIUS),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '42',
                        style: TextStyle(
                          color: light,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Issues Resolved',
                        style: TextStyle(color: light, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: _hexToColor('#FF9800'),
                    borderRadius: BorderRadius.circular(RADIUS),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '98%',
                        style: TextStyle(
                          color: light,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Satisfaction Rate',
                        style: TextStyle(color: light, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Features grid
          Text(
            'Community Services',
            style: TextStyle(
              color: light,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: FEATURES.map((f) {
              final colorHex = f['color']!;
              final color = _hexToColor(colorHex);
              return SizedBox(
                width: cardWidth,
                child: InkWell(
                  onTap: () => _handleFeaturePress(f['title']!),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: light,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                      border: Border(left: BorderSide(color: color, width: 3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text(
                              f['emoji']!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          f['title']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: darkText,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = COLORS['background']!;
    final light = COLORS['light']!;
    final accent = COLORS['accent']!;
    final danger = COLORS['danger']!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: CircularProgressIndicator(color: accent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        toolbarHeight: 78,
        centerTitle: false,
        title: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName 👋',
                  style: TextStyle(
                    color: light,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '📍 $muhalla',
                  style: TextStyle(
                    color: accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: COLORS['success'],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '✓ Verified Resident',
                    style: TextStyle(
                      color: light,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: danger,
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 2),
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '',
                style: TextStyle(
                  color: light,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _goToLogin,
            icon: const Icon(Icons.logout_rounded),
            color: light,
            tooltip: 'Logout / Go to login',
          ),
        ],
      ),
      // YAHAN ACTUAL SCREENS SHOW HONGI
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: bg,
        selectedItemColor: accent,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.feed), label: "Feed"),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: "Complaints",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Market",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
