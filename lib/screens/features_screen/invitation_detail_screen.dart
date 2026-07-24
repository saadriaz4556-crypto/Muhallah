import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'edit_invitation_sheet.dart';

class InvitationDetailScreen extends StatefulWidget {
  final String invitationId;
  final Map<String, dynamic> data;

  const InvitationDetailScreen({
    super.key,
    required this.invitationId,
    required this.data,
  });

  @override
  State<InvitationDetailScreen> createState() => _InvitationDetailScreenState();
}

class _InvitationDetailScreenState extends State<InvitationDetailScreen> {
  // Colors based on Rishta dark theme
  final Color _primaryColor = const Color(0xFF08d9d6);
  final Color _darkBackground = const Color(0xFF121212);
  final Color _darkCardColor = const Color(0xFF1E1E1E);
  final Color _darkTextColor = const Color(0xFFe0e0e0);
  final Color _darkSecondaryText = const Color(0xFF9e9e9e);
  final Color _accentColor = const Color(0xFFff2e63);

  late Map<String, dynamic> _invitationData;
  late String _invitationId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _invitationData = widget.data;
    _invitationId = widget.invitationId;
  }

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditInvitationSheet(
        docId: _invitationId,
        data: _invitationData,
      ),
    ).then((_) {
      // Refresh data after edit is closed
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final doc = await FirebaseFirestore.instance.collection('invitations').doc(_invitationId).get();
    if (doc.exists && mounted) {
      setState(() {
        _invitationData = doc.data()!;
      });
    }
  }

  Future<void> _deleteInvitation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkCardColor,
        title: Text('Delete Invitation', style: TextStyle(color: _darkTextColor)),
        content: Text('Are you sure you want to delete this invitation?', style: TextStyle(color: _darkSecondaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _darkSecondaryText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      await FirebaseFirestore.instance.collection('invitations').doc(_invitationId).delete();
      if (mounted) {
        Navigator.pop(context); // Go back
      }
    }
  }

  Future<void> _handleRSVP() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to RSVP')),
      );
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkCardColor,
        title: Text('RSVP', style: TextStyle(color: _darkTextColor)),
        content: Text('Will you be attending?', style: TextStyle(color: _darkSecondaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'No'),
            child: const Text('No', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'Yes'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await FirebaseFirestore.instance
            .collection('invitations')
            .doc(_invitationId)
            .collection('rsvps')
            .doc(user.uid)
            .set({
          'status': result,
          'userName': user.displayName ?? 'User',
          'timestamp': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('RSVP marked as $result!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving RSVP: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _openMap() async {
    final mapUrl = _invitationData['mapLocation'] ?? '';
    if (mapUrl.isNotEmpty) {
      final uri = Uri.parse(mapUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open map link')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _darkBackground,
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    final title = _invitationData['title'] ?? 'Invitation';
    final category = _invitationData['category'] ?? '';
    final coverImageUrl = _invitationData['coverImageUrl'] ?? '';
    final description = _invitationData['description'] ?? '';
    final venue = _invitationData['venue'] ?? '';
    final mapLocation = _invitationData['mapLocation'] ?? '';
    final dt = _invitationData['dateTime'] as Timestamp?;
    final dateStr = dt != null ? DateFormat('MMMM d, yyyy').format(dt.toDate()) : 'TBD';
    final timeStr = dt != null ? DateFormat('h:mm a').format(dt.toDate()) : '';

    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == _invitationData['postedBy'];

    final categoryData = _invitationData['categoryData'] ?? {};
    final bool rsvpEnabled = categoryData['rsvpEnabled'] == true;
    final bool showRSVPButton = category == 'wedding' && rsvpEnabled && !isOwner;

    return Scaffold(
      backgroundColor: _darkBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar with Cover Photo
            SliverAppBar(
              backgroundColor: _darkCardColor,
              expandedHeight: 250,
              pinned: true,
              actions: [
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: _openEditSheet,
                  ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: _deleteInvitation,
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverImageUrl.isNotEmpty)
                      Image.network(
                        coverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: _darkCardColor),
                      )
                    else
                      Container(
                        color: _darkCardColor,
                        child: Icon(Icons.event, size: 80, color: _primaryColor.withOpacity(0.5)),
                      ),
                    // Gradient overlay to make text readable
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            _darkBackground.withOpacity(0.8),
                            _darkBackground,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Main Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Category
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: _darkTextColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: TextStyle(
                              color: _primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Date & Time
                    _buildInfoTile(Icons.calendar_today, '$dateStr at $timeStr'),
                    const SizedBox(height: 8),
                    // Venue
                    _buildInfoTile(Icons.location_on, venue),
                    
                    if (mapLocation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _openMap,
                        child: Row(
                          children: [
                            const SizedBox(width: 28),
                            Text(
                              'View on Map',
                              style: TextStyle(
                                color: _accentColor,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),

                    // Description
                    if (description.isNotEmpty) ...[
                      Text(
                        'Details',
                        style: TextStyle(
                          color: _darkTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          color: _darkSecondaryText,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Dynamic Fields based on category
                    if (categoryData.isNotEmpty) ...[
                      Text(
                        'Event Information',
                        style: TextStyle(
                          color: _darkTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._buildCategoryFields(categoryData),
                    ],

                    const SizedBox(height: 80), // Padding for RSVP button if visible
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: showRSVPButton
          ? FloatingActionButton.extended(
              onPressed: _handleRSVP,
              backgroundColor: _primaryColor,
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text('RSVP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInfoTile(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _primaryColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: _darkSecondaryText,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCategoryFields(Map<String, dynamic> data) {
    List<Widget> widgets = [];
    data.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty && value is! bool) {
        String formattedKey = _formatKeyName(key);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    formattedKey,
                    style: TextStyle(
                      color: _darkTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      color: _darkSecondaryText,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
    return widgets;
  }

  String _formatKeyName(String key) {
    // Basic camelCase to Title Case
    String titleCase = key.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ');
    if (titleCase.isEmpty) return key;
    return titleCase[0].toUpperCase() + titleCase.substring(1);
  }
}
