import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added Firestore import
import 'package:muhallah/screens/polls/polls_screen.dart';
import 'package:muhallah/screens/business_registration_screen.dart';
import 'package:muhallah/screens/business_directory_screen.dart';
import 'package:muhallah/screens/features_screen/announcement_entry_screen.dart';
import 'package:muhallah/features/bill_reminder/screens/bill_list_screen.dart';
import 'package:muhallah/screens/rental/rental_listings_screen.dart';
import 'package:muhallah/screens/features_screen/invitation_card.dart';
import 'package:muhallah/screens/features_screen/jobs.dart';
import 'package:muhallah/screens/features_screen/localservices.dart';
import 'package:muhallah/screens/features_screen/lostfound.dart'
    show LostFoundHome;
import 'package:muhallah/screens/features_screen/marriage_event.dart';
import 'package:muhallah/screens/features_screen/panic_buttom.dart';
import 'package:muhallah/screens/features_screen/quick_report.dart';
import 'package:muhallah/screens/islamic_corner/islamic_corner_screen.dart';
import 'package:muhallah/screens/local_vibes/local_vibes_screen.dart';
import 'package:muhallah/screens/smart_search_screen.dart';
import 'feed_screen.dart';
import 'complaints_screen.dart';
import 'market_screen.dart';
import 'profile_screen.dart';
import 'new_complaint_screen.dart';
import 'new_listing_screen.dart';
import 'package:muhallah/services/complaint_service.dart';
// import 'inbox_screen.dart';

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

final List<Map<String, dynamic>> FEATURES = [
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
  {
    'title': 'House for Rent',
    'icon': Icons.home_work_outlined,
    'color': '#00BCD4'
  },
  {'title': 'Islamic Corner', 'icon': Icons.mosque, 'color': '#009688'},
  {'title': 'Local Business', 'emoji': '🏪', 'color': '#00BCD4'},
  {'title': 'Local Vibes', 'emoji': '🔥', 'color': '#FF6B35'},
  {
    'title': 'Smart Search',
    'icon': Icons.travel_explore_rounded,
    'color': '#6C63FF'
  },
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

  int _currentIndex = 0;
  String userName = ''; // Removed hardcoded 'Saad'
  String muhalla = ''; // Removed hardcoded 'Gulshan Block A'
  bool _isLoading = true; // Added loading state
  bool _isDataFetched = false; // Prevent duplicate fetches

  // Screens list (initialized in didChangeDependencies)
  late List<Widget> _screens;

  // Unread messages count
  int _unreadCount = 0;
  int _complaintsCount = 0;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

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
      Builder(builder: (context) => _buildHomeTab()),
      const FeedScreen(),
      const ComplaintsScreen(),
      const MarketplaceModule(),
      const ProfileApp(),
    ];

    // Listen for unread messages
    _listenForUnreadMessages();
    _listenForComplaintsCount();
  }

  void _listenForComplaintsCount() {
    ComplaintService().complaintsCount().listen((count) {
      if (mounted) {
        setState(() {
          _complaintsCount = count;
        });
      }
    });
  }

  void _listenForUnreadMessages() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) {
      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCount = data['unreadCount'] as int? ?? 0;
        final lastMessageSenderId =
            data['lastMessageSenderId'] as String? ?? '';
        if (unreadCount > 0 && lastMessageSenderId != user.uid) {
          totalUnread += unreadCount;
        }
      }
      if (mounted) {
        setState(() {
          _unreadCount = totalUnread;
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Feature press handler with navigation for common features
  void _handleFeaturePress(String title) {
    switch (title) {
      case 'Announcements':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const AnnouncementEntryScreen()),
        );
        break;

      case 'Complaints':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NewComplaintScreen()),
        );
        break;

      case 'Marketplace':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NewListingScreen()),
        );
        break;

      case 'Lost & Found':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LostFoundHome()),
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
          MaterialPageRoute(builder: (context) => BillListScreen()),
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
          MaterialPageRoute(builder: (context) => const PollsScreen()),
        );
        break;

      case 'House for Rent':
      case 'Ghar Khali Hai':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RentalListingsScreen()),
        );
        break;

      case 'Islamic Corner':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const IslamicCornerScreen()),
        );
        break;

      case 'Local Business':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BusinessDirectoryScreen(),
          ),
        );
        break;

      case 'Local Vibes':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LocalVibesScreen(),
          ),
        );
        break;

      case 'Smart Search':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SmartSearchScreen(),
          ),
        );
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

  // MAIN: Home tab made scrollable
  Widget _buildHomeTab() {
    final light = COLORS['light']!;
    final screenWidth = MediaQuery.of(context).size.width;
    const int perRow = 3;
    const gap = 6.0;

    // total horizontal padding used by the scroll view (left + right)
    const totalHorizontalPadding = SPACING * 2;
    // available width for the cards (screen width minus horizontal paddings and the gaps between cards)
    final availableWidth =
        screenWidth - totalHorizontalPadding - (gap * (perRow - 1));
    final cardWidth = availableWidth / perRow;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: SPACING),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),

          // Welcome Header
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assalamu Alaikum 👋',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName.isNotEmpty ? userName : 'Resident',
                      style: TextStyle(
                        color: COLORS['light']!,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (muhalla.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 13, color: COLORS['accent']),
                          const SizedBox(width: 2),
                          Text(
                            muhalla,
                            style: TextStyle(
                              color: COLORS['accent'],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: COLORS['accent']!.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: COLORS['accent']!.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: COLORS['accent'],
                    size: 22,
                  ),
                ),
              ],
            ),
          ),

          // SOS Button Full Width, Quick Report Below
          Column(
            children: [
              // SOS — Full Width
              InkWell(
                onTap: _handleEmergency,
                borderRadius: BorderRadius.circular(RADIUS),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF2E63),
                        Color(0xFFB71C1C),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(RADIUS),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF2E63).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🚨', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EMERGENCY SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Tap to send instant alert',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios,
                          color: Colors.white54, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Quick Report — Below SOS
              InkWell(
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
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  decoration: BoxDecoration(
                    color: COLORS['accent']!.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(RADIUS),
                    border: Border.all(
                      color: COLORS['accent']!.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('📝', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Text(
                        'Quick Report',
                        style: TextStyle(
                          color: COLORS['accent'],
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios,
                          color: COLORS['accent']!.withValues(alpha: 0.5),
                          size: 14),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Register Business — Below Quick Report
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BusinessRegistrationScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(RADIUS),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  decoration: BoxDecoration(
                    color: COLORS['accent']!.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(RADIUS),
                    border: Border.all(
                      color: COLORS['accent']!.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🏪', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Text(
                        'Register Your Business',
                        style: TextStyle(
                          color: COLORS['accent'],
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios,
                          color: COLORS['accent']!.withValues(alpha: 0.5),
                          size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Stats Section - One Dark Card, Three Stats Inside
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: COLORS['accent'],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Where Neighbors Become Family',
                style: TextStyle(
                  color: light,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2E),
              borderRadius: BorderRadius.circular(RADIUS),
              border: Border.all(
                color: COLORS['accent']!.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'Building stronger connections, one mohallah at a time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Features grid
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: COLORS['accent'],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Community Services',
                style: TextStyle(
                  color: light,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: FEATURES.map((f) {
              return SizedBox(
                width: cardWidth,
                child: GestureDetector(
                  onTap: () => _handleFeaturePress(f['title']!),
                  child: Container(
                    height: 110,
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(
                          color: _hexToColor(f['color']!),
                          width: 4,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _hexToColor(f['color']!),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: f['icon'] != null
                                ? Icon(f['icon'] as IconData,
                                    size: 26, color: Colors.white)
                                : Text(
                                    f['emoji']!,
                                    style: TextStyle(
                                      fontSize:
                                          f['title'] == 'Complaints' ? 18 : 22,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: f['title'] == 'Complaints' ? 4 : 6),
                        Text(
                          f['title']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF252A34),
                            fontSize: f['title'] == 'Complaints' ? 9 : 10,
                            fontWeight: FontWeight.w700,
                            height: f['title'] == 'Complaints' ? 1.1 : 1.2,
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
    final accent = COLORS['accent']!;

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
        toolbarHeight: 0,
      ),
      // YAHAN ACTUAL SCREENS SHOW HONGI
      body: _currentIndex == 0 ? _buildHomeTab() : _screens[_currentIndex],
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
