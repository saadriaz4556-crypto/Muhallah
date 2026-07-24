import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'package:muhallah/screens/features_screen/add_rishta_profile_sheet.dart';
import 'package:muhallah/screens/features_screen/rishta_detail_screen.dart';

class MarriageEventsScreen extends StatefulWidget {
  final String townName;

  const MarriageEventsScreen({super.key, this.townName = "Green Valley"});

  @override
  State<MarriageEventsScreen> createState() => _MarriageEventsScreenState();
}

class _MarriageEventsScreenState extends State<MarriageEventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Color palette
  final Color _primaryColor = const Color(0xFF08d9d6);
  final Color _darkBackground = const Color(0xFF252a34);
  final Color _darkCardColor = const Color(0xFF2a303c);
  final Color _darkTextColor = const Color(0xFFe0e0e0);
  final Color _darkSecondaryText = const Color(0xFF9e9e9e);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      floatingActionButton: _buildAddRishtaButton(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildRishtaProfilesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_darkCardColor, _primaryColor.withValues(alpha: 0.3)],
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
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back, color: _darkTextColor),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Rishta Profiles',
                  style: TextStyle(
                    color: _darkTextColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Location info
            Row(
              children: [
                Icon(Icons.location_on, color: _primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.townName,
                  style: TextStyle(
                    color: _darkTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search bar
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _darkCardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search profiles, city...',
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

  Widget _buildRishtaProfilesList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('rishta_profiles').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: _primaryColor),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading profiles',
              style: TextStyle(color: _darkTextColor),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No rishta profiles yet',
              style: TextStyle(color: _darkSecondaryText),
            ),
          );
        }

        // Sort and filter in Dart
        var docs = snapshot.data!.docs.toList();

        // Sort by createdAt descending
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        // Search filter in Dart
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final name = (d['name'] ?? '').toString().toLowerCase();
            final city = (d['city'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery.toLowerCase()) ||
                city.contains(_searchQuery.toLowerCase());
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No matching profiles found',
              style: TextStyle(color: _darkSecondaryText),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemCount: docs.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildRishtaProfileCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildRishtaProfileCard(String docId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final age = data['age'] ?? 0;
    final profession = data['profession'] ?? '';
    final city = data['city'] ?? '';
    final shortIntro = data['shortIntro'] ?? '';
    final gender = data['gender'] ?? 'Brother';
    final photoUrl = data['photoUrl'] ?? '';
    final isVerified = data['isVerified'] ?? false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RishtaDetailScreen(
              docId: docId,
              data: data,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        decoration: BoxDecoration(
          color: _darkCardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo section
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: photoUrl.isNotEmpty
                      ? _buildBlurredPhoto(photoUrl)
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _primaryColor.withValues(alpha: 0.6),
                                _primaryColor.withValues(alpha: 0.3),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.person,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 60,
                            ),
                          ),
                        ),
                ),
                // Verified badge
                if (isVerified)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                // Gender chip
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: gender == 'Sister' ? Colors.pink : Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      gender,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Profile info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    style: TextStyle(
                      color: _darkTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Age + Profession
                  Text(
                    '$age years • $profession',
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // City
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: _darkSecondaryText,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        city,
                        style: TextStyle(
                          color: _darkSecondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Short intro
                  Text(
                    shortIntro,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _darkSecondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurredPhoto(String photoUrl) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryColor.withValues(alpha: 0.6),
                    _primaryColor.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 60,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddRishtaButton() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddRishtaProfileSheet(
            currentUserId: currentUser.uid,
            currentUserName: currentUser.displayName ?? 'User',
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
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
                color: Colors.black.withValues(alpha: _isHovered ? 0.4 : 0.2),
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
                        widget.primaryColor.withValues(alpha: 0.6),
                        widget.accentColor.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white.withValues(alpha: 0.8),
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
                                      widget.primaryColor
                                          .withValues(alpha: 0.8),
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
                color: Colors.black.withValues(alpha: _isHovered ? 0.4 : 0.2),
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
                        color: Colors.black.withValues(alpha: 0.3),
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
                        color: widget.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.primaryColor.withValues(alpha: 0.3),
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
                                widget.primaryColor.withValues(alpha: 0.8),
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
                  color: primaryColor.withValues(alpha: 0.1),
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
                color: Colors.black.withValues(alpha: 0.2),
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
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
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
                  color: primaryColor.withValues(alpha: 0.1),
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
                color: Colors.black.withValues(alpha: 0.2),
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
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
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
                  color: primaryColor.withValues(alpha: 0.1),
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
                color: Colors.black.withValues(alpha: 0.2),
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
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
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
