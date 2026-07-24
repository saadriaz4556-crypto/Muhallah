import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'package:muhallah/screens/features_screen/edit_rishta_profile_sheet.dart';

class RishtaDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const RishtaDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<RishtaDetailScreen> createState() => _RishtaDetailScreenState();
}

class _RishtaDetailScreenState extends State<RishtaDetailScreen> {
  final Color _primaryColor = const Color(0xFF08d9d6);
  final Color _darkBackground = const Color(0xFF252a34);
  final Color _darkCardColor = const Color(0xFF2a303c);
  final Color _darkTextColor = const Color(0xFFe0e0e0);
  final Color _darkSecondaryText = const Color(0xFF9e9e9e);

  bool _isDeleting = false;

  Future<void> _deleteProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkCardColor,
        title: Text(
          'Delete Profile?',
          style: TextStyle(color: _darkTextColor),
        ),
        content: Text(
          'Are you sure you want to delete this profile? This action cannot be undone.',
          style: TextStyle(color: _darkSecondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: _darkSecondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      await FirebaseFirestore.instance
          .collection('rishta_profiles')
          .doc(widget.docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile deleted successfully'),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _sendRishtaRequest() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to send a rishta request'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      // Save request to Firestore
      await FirebaseFirestore.instance.collection('rishta_requests').add({
        'fromUserId': currentUser.uid,
        'fromUserName': currentUser.displayName ?? 'Anonymous',
        'toUserId': widget.data['postedBy'],
        'profileId': widget.docId,
        'profileName': widget.data['name'],
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _darkCardColor,
            title: Text(
              'Send Rishta Request',
              style: TextStyle(color: _darkTextColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your interest will be noted. Contact the family directly:',
                  style: TextStyle(color: _darkSecondaryText),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _darkBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.phone, color: _primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.data['contactNumber'] ?? 'N/A',
                        style: TextStyle(
                          color: _darkTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: _darkSecondaryText),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final phoneNumber = widget.data['contactNumber'] ?? '';
                  if (phoneNumber.isNotEmpty) {
                    final uri = Uri(scheme: 'tel', path: phoneNumber);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Call Now'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.data['name'] ?? 'Unknown';
    final age = widget.data['age'] ?? 0;
    final profession = widget.data['profession'] ?? '';
    final city = widget.data['city'] ?? '';
    final gender = widget.data['gender'] ?? 'Male';
    final photoUrl = widget.data['photoUrl'] ?? '';
    final isVerified = widget.data['isVerified'] ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == widget.data['postedBy'];

    return Scaffold(
      backgroundColor: _darkBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: _darkCardColor,
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Photo — must fill the full FlexibleSpaceBar area
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: photoUrl.isNotEmpty
                            ? () => _openPhotoViewer(
                                  context: context,
                                  photoUrl: photoUrl,
                                  isOwner: isOwner,
                                )
                            : null,
                        child: photoUrl.isNotEmpty
                            ? (isOwner
                                ? Image.network(
                                    photoUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: _darkCardColor,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: _primaryColor,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return _buildPhotoPlaceholder();
                                    },
                                  )
                                : ImageFiltered(
                                    imageFilter: ui.ImageFilter.blur(
                                        sigmaX: 5, sigmaY: 5),
                                    child: Image.network(
                                      photoUrl,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, progress) {
                                        if (progress == null) return child;
                                        return Container(
                                          color: _darkCardColor,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: _primaryColor,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return _buildPhotoPlaceholder();
                                      },
                                    ),
                                  ))
                            : _buildPhotoPlaceholder(),
                      ),
                    ),
                    // Verified Badge
                    if (isVerified)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    // Gender Chip
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: gender == 'Female' ? Colors.pink : Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          gender,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
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
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Content
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Basic Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: _darkTextColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$age years • $profession',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                color: _darkSecondaryText, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              city,
                              style: TextStyle(
                                color: _darkSecondaryText,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.data['shortIntro'] ?? '',
                          style: TextStyle(
                            color: _darkSecondaryText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFF3a4050)),
                  // Details Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Details',
                          style: TextStyle(
                            color: _darkTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                            'Education', widget.data['education'] ?? 'N/A'),
                        _buildDetailRow('Marital Status',
                            widget.data['maritalStatus'] ?? 'N/A'),
                        if ((widget.data['familyBackground'] ?? '').isNotEmpty)
                          _buildDetailRow('Family Background',
                              widget.data['familyBackground'] ?? ''),
                        if ((widget.data['caste'] ?? '').isNotEmpty)
                          _buildDetailRow(
                              'Caste/Biradari', widget.data['caste'] ?? ''),
                        if ((widget.data['height'] ?? '').isNotEmpty)
                          _buildDetailRow(
                              'Height', widget.data['height'] ?? ''),
                        if ((widget.data['complexion'] ?? '').isNotEmpty &&
                            widget.data['complexion'] != 'None')
                          _buildDetailRow(
                              'Complexion', widget.data['complexion'] ?? ''),
                        if ((widget.data['sect'] ?? '').isNotEmpty)
                          _buildDetailRow('Sect', widget.data['sect'] ?? ''),
                      ],
                    ),
                  ),
                  // Partner Expectations Section
                  if ((widget.data['partnerExpectations'] ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Looking For / Expectations',
                            style: TextStyle(
                              color: _darkTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.data['partnerExpectations'] ?? '',
                            style: TextStyle(
                              color: _darkSecondaryText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Send Rishta Request Button
                        ElevatedButton(
                          onPressed: _sendRishtaRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Send Rishta Request',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Edit and Delete Buttons (only for owner)
                        if (isOwner) ...[
                          OutlinedButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => EditRishtaProfileSheet(
                                  docId: widget.docId,
                                  data: widget.data,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryColor,
                              side: BorderSide(color: _primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _isDeleting ? null : _deleteProfile,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isDeleting
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: _primaryColor,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Delete Profile',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
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
          size: 80,
        ),
      ),
    );
  }

  void _openPhotoViewer({
    required BuildContext context,
    required String photoUrl,
    required bool isOwner,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: isOwner
                      ? Image.network(photoUrl, fit: BoxFit.contain)
                      : ImageFiltered(
                          imageFilter:
                              ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child:
                              Image.network(photoUrl, fit: BoxFit.contain),
                        ),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: _primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: _darkTextColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
