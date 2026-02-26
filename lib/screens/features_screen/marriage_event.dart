import 'package:flutter/material.dart';

class MarriageEventsScreen extends StatefulWidget {
  final String townName;

  const MarriageEventsScreen({super.key, this.townName = "Green Valley"});

  @override
  State<MarriageEventsScreen> createState() => _MarriageEventsScreenState();
}

class _MarriageEventsScreenState extends State<MarriageEventsScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Events', 'Rishta', 'Marriage Office'];

  // Mock data for marriage events
  final List<Map<String, dynamic>> _events = [
    {
      'id': '1',
      'title': 'Royal Garden Wedding',
      'venue': 'Grand Palace Hotel',
      'date': 'Dec 15, 2024',
      'time': '6:00 PM - 11:00 PM',
      'price': '\$2,500',
      'guestCapacity': '300 Guests',
      'rating': 4.8,
      'reviews': 89,
      'image': 'assets/images/event1.jpg',
      'description':
          'Luxurious outdoor garden wedding with premium amenities and five-star catering service.',
      'features': [
        'Outdoor Garden',
        'Premium Catering',
        'DJ Service',
        'Photography',
      ],
      'isAvailable': true,
    },
    {
      'id': '2',
      'title': 'Beachside Ceremony',
      'venue': 'Sunset Beach Resort',
      'date': 'Jan 20, 2025',
      'time': '4:00 PM - 10:00 PM',
      'price': '\$3,200',
      'guestCapacity': '200 Guests',
      'rating': 4.9,
      'reviews': 67,
      'image': 'assets/images/event2.jpg',
      'description':
          'Romantic beachfront wedding with ocean view, perfect for intimate ceremonies.',
      'features': ['Beach Front', 'Sea View', 'Bonfire', 'Marquee Setup'],
      'isAvailable': true,
    },
  ];

  // Mock data for rishta/profiles
  final List<Map<String, dynamic>> _rishtaProfiles = [
    {
      'id': '1',
      'name': 'Ahmed Khan',
      'age': 28,
      'profession': 'Software Engineer',
      'education': 'Masters in Computer Science',
      'familyBackground': 'Respected family, 2 siblings',
      'location': 'Same Town',
      'image': 'assets/images/rishta1.jpg',
      'description':
          'Looking for an educated, family-oriented girl. Prefers simple lifestyle.',
      'expectations': 'Educated, Family-oriented, Age 22-26',
      'contact': 'Family Contact: +1-555-0101',
      'isVerified': true,
    },
    {
      'id': '2',
      'name': 'Fatima Noor',
      'age': 25,
      'profession': 'Doctor',
      'education': 'MBBS, Specialization in Pediatrics',
      'familyBackground': 'Medical family, well-educated',
      'location': 'Neighboring Town',
      'image': 'assets/images/rishta2.jpg',
      'description':
          'Professional doctor seeking like-minded partner. Values family and career balance.',
      'expectations': 'Professional, Understanding, Age 27-32',
      'contact': 'Father Contact: +1-555-0102',
      'isVerified': true,
    },
    {
      'id': '3',
      'name': 'Bilal Ahmed',
      'age': 30,
      'profession': 'Business Owner',
      'education': 'MBA from LUMS',
      'familyBackground': 'Business family, well-settled',
      'location': 'Same Town',
      'image': 'assets/images/rishta1.jpg',
      'description':
          'Successful entrepreneur looking for a life partner to share dreams with.',
      'expectations': 'Graduate, Supportive, Family Values',
      'contact': 'Mother Contact: +1-555-0103',
      'isVerified': false,
    },
  ];

  // Mock data for marriage offices
  final List<Map<String, dynamic>> _marriageOffices = [
    {
      'id': '1',
      'name': 'Rishta Express',
      'service': 'Professional Matchmaking',
      'experience': '15+ Years',
      'successRate': '95%',
      'rating': 4.8,
      'reviews': 234,
      'contact': '+1-555-0201',
      'services': [
        'Rishta Service',
        'Family Meetings',
        'Background Verification',
      ],
      'description':
          'Trusted matchmaking service with high success rate and verified profiles.',
      'isAvailable': true,
    },
    {
      'id': '2',
      'name': 'Family Rishta Center',
      'service': 'Traditional Matchmaking',
      'experience': '20+ Years',
      'successRate': '92%',
      'rating': 4.6,
      'reviews': 189,
      'contact': '+1-555-0202',
      'services': [
        'Family Matching',
        'Bio Data Service',
        'Meeting Arrangements',
      ],
      'description':
          'Traditional approach to matchmaking with focus on family values and compatibility.',
      'isAvailable': true,
    },
  ];

  // Color palette for dark theme
  final Color _primaryColor = const Color(0xFF08d9d6);
  final Color _darkColor = const Color(0xFF252a34);
  final Color _accentColor = const Color(0xFFff2e63);
  final Color _lightColor = const Color(0xFFeaeaea);
  final Color _darkBackground = const Color(0xFF121212);
  final Color _darkCardColor = const Color(0xFF1E1E1E);
  final Color _darkTextColor = const Color(0xFFE0E0E0);
  final Color _darkSecondaryText = const Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      floatingActionButton: _selectedTab == 1 ? _buildAddRishtaButton() : null,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(),
            // Tab Bar
            _buildTabBar(),
            // Content based on selected tab
            _buildContent(),
          ],
        ),
      ),
    );
  }

  // Header with background and search
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_darkColor, _primaryColor.withOpacity(0.3)],
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
              children: [
                ScaleTapAnimation(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back, color: _lightColor),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Marriage & Rishta',
                  style: TextStyle(
                    color: _lightColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Location and stats
            Text(
              'Services in',
              style: TextStyle(
                color: _lightColor.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, color: _accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.townName,
                  style: TextStyle(
                    color: _lightColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getStatsText(),
              style: TextStyle(
                color: _lightColor.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            // Search Bar
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  // Get stats text based on current tab
  String _getStatsText() {
    switch (_selectedTab) {
      case 0:
        return '${_events.length} events available';
      case 1:
        return '${_rishtaProfiles.length} rishta profiles';
      case 2:
        return '${_marriageOffices.length} marriage offices';
      default:
        return '';
    }
  }

  // Search bar
  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _darkCardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search, color: _darkSecondaryText),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: _getSearchHint(),
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: _darkSecondaryText),
                ),
                style: TextStyle(color: _darkTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get search hint based on current tab
  String _getSearchHint() {
    switch (_selectedTab) {
      case 0:
        return 'Search events, venues...';
      case 1:
        return 'Search profiles, professions...';
      case 2:
        return 'Search marriage offices...';
      default:
        return 'Search...';
    }
  }

  // Tab bar for switching between features
  Widget _buildTabBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTab == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12, top: 16),
            child: ScaleTapAnimation(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? _primaryColor
                        : _darkSecondaryText.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : _darkTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Content based on selected tab
  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildEventsTab();
      case 1:
        return _buildRishtaTab();
      case 2:
        return _buildMarriageOfficeTab();
      default:
        return _buildEventsTab();
    }
  }

  // Events Tab Content
  Widget _buildEventsTab() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          itemCount: _events.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final event = _events[index];
            return EventCard(
              event: event,
              primaryColor: _primaryColor,
              accentColor: _accentColor,
              darkCardColor: _darkCardColor,
              darkTextColor: _darkTextColor,
              darkSecondaryText: _darkSecondaryText,
              onTap: () => _navigateToEventDetail(event),
              onBook: () => _bookEvent(event),
            );
          },
        ),
      ),
    );
  }

  // Rishta Tab Content
  Widget _buildRishtaTab() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          itemCount: _rishtaProfiles.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final profile = _rishtaProfiles[index];
            return RishtaProfileCard(
              profile: profile,
              primaryColor: _primaryColor,
              accentColor: _accentColor,
              darkCardColor: _darkCardColor,
              darkTextColor: _darkTextColor,
              darkSecondaryText: _darkSecondaryText,
              onTap: () => _navigateToRishtaDetail(profile),
              onContact: () => _contactFamily(profile),
            );
          },
        ),
      ),
    );
  }

  // Marriage Office Tab Content
  Widget _buildMarriageOfficeTab() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          itemCount: _marriageOffices.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final office = _marriageOffices[index];
            return MarriageOfficeCard(
              office: office,
              primaryColor: _primaryColor,
              accentColor: _accentColor,
              darkCardColor: _darkCardColor,
              darkTextColor: _darkTextColor,
              darkSecondaryText: _darkSecondaryText,
              onTap: () => _navigateToOfficeDetail(office),
              onContact: () => _contactOffice(office),
            );
          },
        ),
      ),
    );
  }

  // Add Rishta Floating Action Button
  Widget _buildAddRishtaButton() {
    return ScaleTapAnimation(
      onTap: () => _addNewRishta(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_accentColor, _accentColor.withOpacity(0.8)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.person_add, color: Colors.white, size: 24),
      ),
    );
  }

  // Navigation methods
  void _navigateToEventDetail(Map<String, dynamic> event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${event['title']} details'),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToRishtaDetail(Map<String, dynamic> profile) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${profile['name']} profile'),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToOfficeDetail(Map<String, dynamic> office) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${office['name']} details'),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _bookEvent(Map<String, dynamic> event) {
    if (!event['isAvailable']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${event['title']} is currently booked'),
          backgroundColor: _accentColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingBottomSheet(
        event: event,
        primaryColor: _primaryColor,
        accentColor: _accentColor,
        darkCardColor: _darkCardColor,
        darkTextColor: _darkTextColor,
        darkSecondaryText: _darkSecondaryText,
        onConfirm: () => _confirmBooking(event),
      ),
    );
  }

  void _contactFamily(Map<String, dynamic> profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ContactFamilySheet(
        profile: profile,
        primaryColor: _primaryColor,
        accentColor: _accentColor,
        darkCardColor: _darkCardColor,
        darkTextColor: _darkTextColor,
        darkSecondaryText: _darkSecondaryText,
      ),
    );
  }

  void _contactOffice(Map<String, dynamic> office) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ContactOfficeSheet(
        office: office,
        primaryColor: _primaryColor,
        accentColor: _accentColor,
        darkCardColor: _darkCardColor,
        darkTextColor: _darkTextColor,
        darkSecondaryText: _darkSecondaryText,
      ),
    );
  }

  void _addNewRishta() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Add new rishta profile'),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmBooking(Map<String, dynamic> event) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking request sent for ${event['title']}'),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Event Card Widget (Same as before)
class EventCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final Color primaryColor;
  final Color accentColor;
  final Color darkCardColor;
  final Color darkTextColor;
  final Color darkSecondaryText;
  final VoidCallback onTap;
  final VoidCallback onBook;

  const EventCard({
    super.key,
    required this.event,
    required this.primaryColor,
    required this.accentColor,
    required this.darkCardColor,
    required this.darkTextColor,
    required this.darkSecondaryText,
    required this.onTap,
    required this.onBook,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return ScaleTapAnimation(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: widget.darkCardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.4 : 0.2),
                blurRadius: _isHovered ? 12 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Image and Overlay
              Stack(
                children: [
                  // Placeholder for event image
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.primaryColor.withOpacity(0.6),
                          widget.accentColor.withOpacity(0.4),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.celebration,
                        color: Colors.white.withOpacity(0.8),
                        size: 50,
                      ),
                    ),
                  ),
                  // Rating badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.event['rating']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Availability badge
                  if (!widget.event['isAvailable'])
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'BOOKED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Event Details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.event['title'],
                                style: TextStyle(
                                  color: widget.darkTextColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.event['venue'],
                                style: TextStyle(
                                  color: widget.darkSecondaryText,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.event['price'],
                          style: TextStyle(
                            color: widget.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Date and Time
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: widget.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.event['date'],
                          style: TextStyle(
                            color: widget.darkTextColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          color: widget.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.event['time'],
                          style: TextStyle(
                            color: widget.darkTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Guest Capacity
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: widget.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.event['guestCapacity'],
                          style: TextStyle(
                            color: widget.darkTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Features
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (widget.event['features'] as List<String>)
                          .take(3)
                          .map((feature) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: widget.primaryColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                feature,
                                style: TextStyle(
                                  color: widget.primaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ScaleTapAnimation(
                            onTap: widget.onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: widget.primaryColor),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  'VIEW DETAILS',
                                  style: TextStyle(
                                    color: widget.primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ScaleTapAnimation(
                            onTap: widget.onBook,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: widget.event['isAvailable']
                                    ? LinearGradient(
                                        colors: [
                                          widget.primaryColor,
                                          widget.primaryColor.withOpacity(0.8),
                                        ],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                                color: widget.event['isAvailable']
                                    ? null
                                    : Colors.grey.withOpacity(0.5),
                              ),
                              child: Center(
                                child: Text(
                                  'BOOK NOW',
                                  style: TextStyle(
                                    color: widget.event['isAvailable']
                                        ? Colors.white
                                        : widget.darkSecondaryText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
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
    );
  }
}

// Rishta Profile Card Widget
class RishtaProfileCard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Color primaryColor;
  final Color accentColor;
  final Color darkCardColor;
  final Color darkTextColor;
  final Color darkSecondaryText;
  final VoidCallback onTap;
  final VoidCallback onContact;

  const RishtaProfileCard({
    super.key,
    required this.profile,
    required this.primaryColor,
    required this.accentColor,
    required this.darkCardColor,
    required this.darkTextColor,
    required this.darkSecondaryText,
    required this.onTap,
    required this.onContact,
  });

  @override
  State<RishtaProfileCard> createState() => _RishtaProfileCardState();
}

class _RishtaProfileCardState extends State<RishtaProfileCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return ScaleTapAnimation(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: widget.darkCardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.4 : 0.2),
                blurRadius: _isHovered ? 12 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.primaryColor.withOpacity(0.6),
                        widget.accentColor.withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white.withOpacity(0.8),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Profile Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Verification
                      Row(
                        children: [
                          Text(
                            widget.profile['name'],
                            style: TextStyle(
                              color: widget.darkTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (widget.profile['isVerified'])
                            Icon(
                              Icons.verified,
                              color: widget.primaryColor,
                              size: 16,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Basic Info
                      Text(
                        '${widget.profile['age']} years • ${widget.profile['profession']}',
                        style: TextStyle(
                          color: widget.darkSecondaryText,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.profile['education'],
                        style: TextStyle(
                          color: widget.darkSecondaryText,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: widget.primaryColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.profile['location'],
                            style: TextStyle(
                              color: widget.darkTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Expectations
                      Text(
                        'Looking for: ${widget.profile['expectations']}',
                        style: TextStyle(
                          color: widget.darkSecondaryText,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ScaleTapAnimation(
                              onTap: widget.onTap,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: widget.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.transparent,
                                ),
                                child: Center(
                                  child: Text(
                                    'VIEW PROFILE',
                                    style: TextStyle(
                                      color: widget.primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ScaleTapAnimation(
                              onTap: widget.onContact,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      widget.primaryColor,
                                      widget.primaryColor.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'CONTACT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
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
    );
  }
}

// Marriage Office Card Widget
class MarriageOfficeCard extends StatefulWidget {
  final Map<String, dynamic> office;
  final Color primaryColor;
  final Color accentColor;
  final Color darkCardColor;
  final Color darkTextColor;
  final Color darkSecondaryText;
  final VoidCallback onTap;
  final VoidCallback onContact;

  const MarriageOfficeCard({
    super.key,
    required this.office,
    required this.primaryColor,
    required this.accentColor,
    required this.darkCardColor,
    required this.darkTextColor,
    required this.darkSecondaryText,
    required this.onTap,
    required this.onContact,
  });

  @override
  State<MarriageOfficeCard> createState() => _MarriageOfficeCardState();
}

class _MarriageOfficeCardState extends State<MarriageOfficeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return ScaleTapAnimation(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: widget.darkCardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.4 : 0.2),
                blurRadius: _isHovered ? 12 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Office Name and Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.office['name'],
                      style: TextStyle(
                        color: widget.darkTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.office['rating']}',
                            style: TextStyle(
                              color: widget.darkTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Service and Experience
                Text(
                  '${widget.office['service']} • ${widget.office['experience']} Experience',
                  style: TextStyle(
                    color: widget.darkSecondaryText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                // Success Rate and Reviews
                Row(
                  children: [
                    Icon(Icons.thumb_up, color: widget.primaryColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.office['successRate']} Success Rate',
                      style: TextStyle(
                        color: widget.darkTextColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.reviews, color: widget.primaryColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.office['reviews']} Reviews',
                      style: TextStyle(
                        color: widget.darkTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Services
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (widget.office['services'] as List<String>).map((
                    service,
                  ) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        service,
                        style: TextStyle(
                          color: widget.primaryColor,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ScaleTapAnimation(
                        onTap: widget.onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: widget.primaryColor),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              'VIEW DETAILS',
                              style: TextStyle(
                                color: widget.primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ScaleTapAnimation(
                        onTap: widget.onContact,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.primaryColor,
                                widget.primaryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'CONTACT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Bottom Sheets (Booking, Contact Family, Contact Office)
class BookingBottomSheet extends StatelessWidget {
  final Map<String, dynamic> event;
  final Color primaryColor;
  final Color accentColor;
  final Color darkCardColor;
  final Color darkTextColor;
  final Color darkSecondaryText;
  final VoidCallback onConfirm;

  const BookingBottomSheet({
    super.key,
    required this.event,
    required this.primaryColor,
    required this.accentColor,
    required this.darkCardColor,
    required this.darkTextColor,
    required this.darkSecondaryText,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Book ${event['title']}',
              style: TextStyle(
                color: darkTextColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.celebration, color: primaryColor),
              ),
              title: Text(
                event['title'],
                style: TextStyle(color: darkTextColor),
              ),
              subtitle: Text(
                '${event['venue']} • ${event['date']}',
                style: TextStyle(color: darkSecondaryText),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Package Price:',
                        style: TextStyle(color: darkTextColor, fontSize: 16),
                      ),
                      Text(
                        event['price'],
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Capacity:',
                        style: TextStyle(color: darkSecondaryText),
                      ),
                      Text(
                        event['guestCapacity'],
                        style: TextStyle(color: darkTextColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ScaleTapAnimation(
              onTap: onConfirm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_available, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Confirm Booking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CLOSE', style: TextStyle(color: darkSecondaryText)),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactFamilySheet extends StatelessWidget {
  final Map<String, dynamic> profile;
  final Color primaryColor;
  final Color accentColor;
  final Color darkCardColor;
  final Color darkTextColor;
  final Color darkSecondaryText;

  const ContactFamilySheet({
    super.key,
    required this.profile,
    required this.primaryColor,
    required this.accentColor,
    required this.darkCardColor,
    required this.darkTextColor,
    required this.darkSecondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact ${profile['name']}\'s Family',
              style: TextStyle(
                color: darkTextColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: primaryColor),
              ),
              title: Text(
                profile['name'],
                style: TextStyle(color: darkTextColor),
              ),
              subtitle: Text(
                '${profile['age']} years • ${profile['profession']}',
                style: TextStyle(color: darkSecondaryText),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family Contact:',
                    style: TextStyle(color: darkTextColor, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile['contact'],
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please be respectful and formal when contacting the family.',
                    style: TextStyle(
                      color: darkSecondaryText,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ScaleTapAnimation(
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Contacting ${profile['name']}\'s family'),
                    backgroundColor: primaryColor,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Call Family',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CLOSE', style: TextStyle(color: darkSecondaryText)),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactOfficeSheet extends StatelessWidget {
  final Map<String, dynamic> office;
  final Color primaryColor;
  final Color accentColor;
  final Color darkCardColor;
  final Color darkTextColor;
  final Color darkSecondaryText;

  const ContactOfficeSheet({
    super.key,
    required this.office,
    required this.primaryColor,
    required this.accentColor,
    required this.darkCardColor,
    required this.darkTextColor,
    required this.darkSecondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact ${office['name']}',
              style: TextStyle(
                color: darkTextColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.business, color: primaryColor),
              ),
              title: Text(
                office['name'],
                style: TextStyle(color: darkTextColor),
              ),
              subtitle: Text(
                office['service'],
                style: TextStyle(color: darkSecondaryText),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Office Contact:',
                    style: TextStyle(color: darkTextColor, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    office['contact'],
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Experience: ${office['experience']}',
                    style: TextStyle(color: darkTextColor),
                  ),
                  Text(
                    'Success Rate: ${office['successRate']}',
                    style: TextStyle(color: darkTextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ScaleTapAnimation(
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Contacting ${office['name']}'),
                    backgroundColor: primaryColor,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Call Office',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CLOSE', style: TextStyle(color: darkSecondaryText)),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable scale animation widget
class ScaleTapAnimation extends StatefulWidget {
  final Widget? child;
  final VoidCallback onTap;
  final double scaleValue;

  const ScaleTapAnimation({
    super.key,
    this.child,
    required this.onTap,
    this.scaleValue = 0.98,
  });

  @override
  State<ScaleTapAnimation> createState() => _ScaleTapAnimationState();
}

class _ScaleTapAnimationState extends State<ScaleTapAnimation> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleValue : 1.0,
        duration: const Duration(milliseconds: 150),
        child: widget.child,
      ),
    );
  }
}
