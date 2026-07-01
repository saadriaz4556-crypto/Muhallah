import 'package:flutter/material.dart';

class InvitationCardScreen extends StatefulWidget {
  final String townName;

  const InvitationCardScreen({super.key, this.townName = "Green Valley"});

  @override
  State<InvitationCardScreen> createState() => _InvitationCardScreenState();
}

class _InvitationCardScreenState extends State<InvitationCardScreen> {
  // Categories data
  final List<Map<String, dynamic>> _categories = [
    {
      'id': '1',
      'title': 'Shaadi / Valima',
      'subtitle': 'Wedding Invitations',
      'icon': Icons.favorite,
      'color': const Color(0xFF08d9d6),
      'description':
          'Elegant wedding and valima invitations with couple details',
      'features': ['Bride-Groom Names', 'Venue & Time', 'RSVP', 'Map Location'],
      'theme': 'Royal, Floral, Gold Themes',
    },
    {
      'id': '2',
      'title': 'Dua / Qur\'an Khawani',
      'subtitle': 'Religious Gatherings',
      'icon': Icons.mosque,
      'color': const Color(0xFF4CAF50),
      'description':
          'Respectful invitations for religious ceremonies and prayers',
      'features': [
        'Purpose of Dua',
        'Venue Details',
        'Gender Specific',
        'Religious Quotes',
      ],
      'theme': 'Simple, Respectful Design',
    },
    {
      'id': '3',
      'title': 'Mehndi / Dholki',
      'subtitle': 'Pre-Wedding Events',
      'icon': Icons.celebration,
      'color': const Color(0xFFFF2E63),
      'description': 'Colorful and festive mehndi and dholki invitations',
      'features': [
        'Colorful Layout',
        'Dress Code',
        'Entertainment Info',
        'Host Details',
      ],
      'theme': 'Colorful, Festive Themes',
    },
    {
      'id': '4',
      'title': 'Aqeeqa / Bismillah',
      'subtitle': 'Baby Celebrations',
      'icon': Icons.child_care,
      'color': const Color(0xFF9C27B0),
      'description': 'Sweet invitations for baby celebrations and milestones',
      'features': [
        'Baby\'s Name',
        'Parents\' Names',
        'Occasion Type',
        'Venue & Time',
      ],
      'theme': 'Cute, Playful Designs',
    },
    {
      'id': '5',
      'title': 'Condolence / Majlis',
      'subtitle': 'Sympathy Invitations',
      'icon': Icons.flag,
      'color': const Color(0xFF607D8B),
      'description': 'Respectful invitations for condolence gatherings',
      'features': [
        'Deceased Name',
        'Majlis Details',
        'Religious Verses',
        'Organizer Info',
      ],
      'theme': 'Respectful, Somber Colors',
    },
    {
      'id': '6',
      'title': 'Community Events',
      'subtitle': 'Neighborhood Gatherings',
      'icon': Icons.people,
      'color': const Color(0xFFFF9800),
      'description': 'Invitations for community events and gatherings',
      'features': [
        'Event Type',
        'Venue & Time',
        'Purpose',
        'Organizer Details',
      ],
      'theme': 'Clean, Community-focused',
    },
  ];

  // Recent invitations mock data
  final List<Map<String, dynamic>> _recentInvitations = [
    {
      'id': '1',
      'type': 'Shaadi',
      'title': 'Ali & Fatima Wedding',
      'date': 'Dec 15, 2024',
      'time': '6:00 PM',
      'venue': 'Grand Palace Hotel',
      'status': 'Active',
      'created': '2 days ago',
      'views': 45,
      'color': const Color(0xFF08d9d6),
    },
    {
      'id': '2',
      'type': 'Dua',
      'title': 'Qur\'an Khawani',
      'date': 'Nov 20, 2024',
      'time': '4:00 PM',
      'venue': 'Central Mosque',
      'status': 'Active',
      'created': '1 week ago',
      'views': 23,
      'color': const Color(0xFF4CAF50),
    },
    {
      'id': '3',
      'type': 'Aqeeqa',
      'title': 'Baby Ahmed Aqeeqa',
      'date': 'Nov 25, 2024',
      'time': '1:00 PM',
      'venue': 'Community Hall',
      'status': 'Expired',
      'created': '2 weeks ago',
      'views': 67,
      'color': const Color(0xFF9C27B0),
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
      floatingActionButton: _buildCreateButton(),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(),
            // Content Area - Using Expanded to take remaining space
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Recent Invitations Section
                  _buildRecentInvitationsSliver(),
                  // Categories Section
                  _buildCategoriesSliver(),
                  // Add some bottom padding to prevent overflow
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header with background
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_darkColor, _primaryColor.withValues(alpha: 0.3)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button and title
            Row(
              children: [
                ScaleTapAnimation(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back, color: _lightColor, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Invitation Cards',
                  style: TextStyle(
                    color: _lightColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Create Beautiful Invitations',
              style: TextStyle(
                color: _lightColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Design and share invitations for any occasion',
              style: TextStyle(
                color: _lightColor.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recent invitations section
  SliverToBoxAdapter _buildRecentInvitationsSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Invitations',
                  style: TextStyle(
                    color: _darkTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ScaleTapAnimation(
                  onTap: () => _viewAllInvitations(),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130, // Reduced from 160 to 130
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _recentInvitations.length,
                itemBuilder: (context, index) {
                  final invitation = _recentInvitations[index];
                  return RecentInvitationCard(
                    invitation: invitation,
                    primaryColor: _primaryColor,
                    darkCardColor: _darkCardColor,
                    darkTextColor: _darkTextColor,
                    darkSecondaryText: _darkSecondaryText,
                    onTap: () => _viewInvitation(invitation),
                    onShare: () => _shareInvitation(invitation),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Categories grid section
  SliverPadding _buildCategoriesSliver() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85, // Reduced from 0.9 to 0.85
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final category = _categories[index];
          return CategoryCard(
            category: category,
            primaryColor: _primaryColor,
            darkCardColor: _darkCardColor,
            darkTextColor: _darkTextColor,
            darkSecondaryText: _darkSecondaryText,
            onTap: () => _createInvitation(category),
          );
        }, childCount: _categories.length),
      ),
    );
  }

  // Create new invitation FAB
  Widget _buildCreateButton() {
    return ScaleTapAnimation(
      onTap: () => _createCustomInvitation(),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_accentColor, _accentColor.withValues(alpha: 0.8)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _accentColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 22),
      ),
    );
  }

  // Navigation and action methods
  void _createInvitation(Map<String, dynamic> category) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Creating ${category['title']} invitation'),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _createCustomInvitation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateOptionsSheet(
        primaryColor: _primaryColor,
        accentColor: _accentColor,
        darkCardColor: _darkCardColor,
        darkTextColor: _darkTextColor,
        darkSecondaryText: _darkSecondaryText,
        onTemplate: () {
          Navigator.pop(context);
          _showTemplateSelection();
        },
        onCustom: () {
          Navigator.pop(context);
          _createBlankInvitation();
        },
      ),
    );
  }

  void _viewInvitation(Map<String, dynamic> invitation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${invitation['title']}'),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewAllInvitations() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Viewing all invitations'),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareInvitation(Map<String, dynamic> invitation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${invitation['title']}'),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showTemplateSelection() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening template gallery'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _createBlankInvitation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creating custom invitation from scratch'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Recent Invitation Card Widget
class RecentInvitationCard extends StatefulWidget {
  final Map<String, dynamic> invitation;
  final Color primaryColor;
  final Color darkCardColor;
  final Color darkTextColor;
  final Color darkSecondaryText;
  final VoidCallback onTap;
  final VoidCallback onShare;

  const RecentInvitationCard({
    super.key,
    required this.invitation,
    required this.primaryColor,
    required this.darkCardColor,
    required this.darkTextColor,
    required this.darkSecondaryText,
    required this.onTap,
    required this.onShare,
  });

  @override
  State<RecentInvitationCard> createState() => _RecentInvitationCardState();
}

class _RecentInvitationCardState extends State<RecentInvitationCard> {
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
          width: 240, // Reduced from 280 to 240
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: widget.darkCardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.4 : 0.2),
                blurRadius: _isHovered ? 12 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background accent
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: widget.invitation['color'],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.invitation['color'].withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.invitation['type'],
                            style: TextStyle(
                              color: widget.invitation['color'],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.invitation['status'] == 'Active'
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.invitation['status'],
                            style: TextStyle(
                              color: widget.invitation['status'] == 'Active'
                                  ? Colors.green
                                  : Colors.grey,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      widget.invitation['title'],
                      style: TextStyle(
                        color: widget.darkTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Date and Time
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: widget.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.invitation['date'],
                          style: TextStyle(
                            color: widget.darkSecondaryText,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: widget.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.invitation['time'],
                          style: TextStyle(
                            color: widget.darkSecondaryText,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Venue
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: widget.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.invitation['venue'],
                            style: TextStyle(
                              color: widget.darkSecondaryText,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Footer with stats and actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.invitation['views']} views • ${widget.invitation['created']}',
                          style: TextStyle(
                            color: widget.darkSecondaryText,
                            fontSize: 9,
                          ),
                        ),
                        ScaleTapAnimation(
                          onTap: widget.onShare,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.share,
                              color: widget.primaryColor,
                              size: 14,
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

// Category Card Widget
class CategoryCard extends StatefulWidget {
  final Map<String, dynamic> category;
  final Color primaryColor;
  final Color darkCardColor;
  final Color darkTextColor;
  final Color darkSecondaryText;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.primaryColor,
    required this.darkCardColor,
    required this.darkTextColor,
    required this.darkSecondaryText,
    required this.onTap,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
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
          decoration: BoxDecoration(
            color: widget.darkCardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.4 : 0.2),
                blurRadius: _isHovered ? 12 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.category['color'].withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.category['color'].withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.category['icon'] as IconData,
                        color: widget.category['color'],
                        size: 20, // Reduced icon size
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Title and Subtitle
                    Text(
                      widget.category['title'],
                      style: TextStyle(
                        color: widget.darkTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.category['subtitle'],
                      style: TextStyle(
                        color: widget.darkSecondaryText,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Description
                    Expanded(
                      child: Text(
                        widget.category['description'],
                        style: TextStyle(
                          color: widget.darkSecondaryText,
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Features
                    Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      children: (widget.category['features'] as List<String>)
                          .take(2)
                          .map((feature) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: widget.category['color'].withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                feature,
                                style: TextStyle(
                                  color: widget.category['color'],
                                  fontSize: 7,
                                ),
                              ),
                            );
                          })
                          .toList(),
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

// Create Options Bottom Sheet
class CreateOptionsSheet extends StatelessWidget {
  final Color primaryColor;
  final Color accentColor;
  final Color darkCardColor;
  final Color darkTextColor;
  final Color darkSecondaryText;
  final VoidCallback onTemplate;
  final VoidCallback onCustom;

  const CreateOptionsSheet({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    required this.darkCardColor,
    required this.darkTextColor,
    required this.darkSecondaryText,
    required this.onTemplate,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create New Invitation',
              style: TextStyle(
                color: darkTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Template Option
            ScaleTapAnimation(
              onTap: onTemplate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.abc, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use Template',
                            style: TextStyle(
                              color: darkTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose from beautiful pre-designed templates',
                            style: TextStyle(
                              color: darkSecondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: primaryColor,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Custom Option
            ScaleTapAnimation(
              onTap: onCustom,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom Design',
                            style: TextStyle(
                              color: darkTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Create your own design from scratch',
                            style: TextStyle(
                              color: darkSecondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: accentColor, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Close button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: TextStyle(color: darkSecondaryText, fontSize: 12),
              ),
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
