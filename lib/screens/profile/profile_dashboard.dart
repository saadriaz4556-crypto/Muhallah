import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'edit_profile_screen.dart';
import 'utils/profile_constants.dart';
import 'package:muhallah/models/business_model.dart';
import 'package:muhallah/widgets/business_card_widget.dart' hide deepNavy, sectionBg, teal, coral, whiteish, successGreen, primaryGradient, headingStyle;
import 'package:muhallah/screens/business_registration_screen.dart' hide deepNavy, sectionBg, teal, coral, whiteish, successGreen, primaryGradient, headingStyle;

class ProfileDashboard extends StatefulWidget {
  const ProfileDashboard({super.key});

  @override
  State<ProfileDashboard> createState() => _ProfileDashboardState();
}

class _ProfileDashboardState extends State<ProfileDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? _currentUser;
  String? _resolvedUid;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUploadingImage = false;

  // Stats
  int _postsCount = 0;
  int _propertiesCount = 0;
  int _complaintsCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = FirebaseAuth.instance.currentUser;
      _currentUser ??= await FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(const Duration(seconds: 2), onTimeout: () => null);

      _resolvedUid = _currentUser?.uid;
      if (_resolvedUid == null || _resolvedUid!.isEmpty) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is String && args.isNotEmpty) {
          _resolvedUid = args;
        }
      }

      if (_resolvedUid != null && _resolvedUid!.isNotEmpty) {
        final uid = _resolvedUid!;

        // Fetch user doc in background
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get()
            .then((doc) {
          if (mounted) {
            setState(() {
              _userData = doc.data();
            });
          }
        }).catchError((e) {
          debugPrint('Profile userDoc fetch error: $e');
        });

        // Fetch stats in background
        Future.wait([
          FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: uid)
              .get(),
          FirebaseFirestore.instance
              .collection('properties')
              .where('userId', isEqualTo: uid)
              .get(),
          FirebaseFirestore.instance
              .collection('complaints')
              .where('userId', isEqualTo: uid)
              .get(),
        ]).then((statsResults) {
          if (mounted) {
            setState(() {
              _postsCount = statsResults[0].size;
              _propertiesCount = statsResults[1].size;
              _complaintsCount = statsResults[2].size;
            });
          }
        }).catchError((e) {
          debugPrint('Profile stats fetch error: $e');
        });
      }
    } catch (e) {
      debugPrint('Profile fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
    _fetchData(); // Refresh on return
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Close bottom sheet
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image =
          await picker.pickImage(source: source, imageQuality: 70);

      if (image != null) {
        await _uploadProfilePicture(File(image.path));
      }
    } catch (e) {
      _showSnackbar("Failed to pick image: $e", true);
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    final String uid = _resolvedUid ?? '';
    if (uid.isEmpty) return;

    setState(() => _isUploadingImage = true);

    try {
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(uid)
          .child('profile.jpg');

      final metadata = SettableMetadata(contentType: 'image/jpeg');

      final UploadTask uploadTask = storageRef.putFile(imageFile, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'profilePicture': downloadUrl});

      setState(() {
        _userData?['profilePicture'] = downloadUrl;
      });

      _showSnackbar("Profile picture updated", false);
    } catch (e) {
      _showSnackbar("Failed to upload image: $e", true);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: sectionBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Update Profile Picture",
                  style: headingStyle.copyWith(fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: teal),
              title:
                  const Text('Take a photo', style: TextStyle(color: whiteish)),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: teal),
              title: const Text('Choose from gallery',
                  style: TextStyle(color: whiteish)),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? coral : teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: deepNavy,
        body: Center(child: CircularProgressIndicator(color: teal)),
      );
    }

    final uid = _resolvedUid ?? '';
    if (uid.isEmpty) {
      return Scaffold(
        backgroundColor: deepNavy,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle_outlined, size: 80, color: teal),
                const SizedBox(height: 16),
                const Text(
                  "Not Logged In",
                  style: TextStyle(
                    color: whiteish,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Please log in to view your profile dashboard.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: deepNavy,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Go to Login",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
        backgroundColor: deepNavy,
        appBar: null,
        body: SafeArea(
          top: false,
          child: DefaultTabController(
            length: 4,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // 1. HEADER (STREAMBUILDER)
                  SliverToBoxAdapter(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Container(
                            height: 280,
                            color: deepNavy,
                            child: const Center(
                              child: Text(
                                "Error loading profile details.",
                                style: TextStyle(color: coral),
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return Container(
                              height: 280,
                              color: deepNavy,
                              child: const Center(
                                  child:
                                      CircularProgressIndicator(color: teal)));
                        }
                        if (!snapshot.data!.exists) {
                          return Container(
                            height: 280,
                            color: deepNavy,
                            child: const Center(
                              child: Text(
                                "Profile document not found.",
                                style: TextStyle(color: coral),
                              ),
                            ),
                          );
                        }

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>? ??
                                {};
                        final userName = data['fullName'] ?? 'User';
                        final userInitials = userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : 'U';
                        final area = data['area'] ?? '';
                        final isVerified = data['status'] == 'verified';
                        final profilePicture = data['profilePicture'];

                        return Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: primaryGradient,
                          ),
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top + 20,
                              bottom: 30),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Edited Icon Positioned
                              Positioned(
                                top: 0,
                                right: 16,
                                child: IconButton(
                                  icon: const Icon(Icons.edit, color: whiteish),
                                  onPressed: _navigateToEditProfile,
                                  tooltip: 'Edit Profile',
                                ),
                              ),

                              // Avatar and Name
                              Center(
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: _showImagePickerOptions,
                                      child: Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: teal, width: 3),
                                              boxShadow: [
                                                BoxShadow(
                                                    color:
                                                        teal.withValues(alpha: 0.3),
                                                    blurRadius: 15,
                                                    spreadRadius: 2),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: 55,
                                              backgroundColor: sectionBg,
                                              backgroundImage: profilePicture !=
                                                      null
                                                  ? NetworkImage(profilePicture)
                                                  : null,
                                              child: profilePicture == null
                                                  ? Text(
                                                      userInitials,
                                                      style: const TextStyle(
                                                          fontSize: 36,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.white24),
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          if (_isUploadingImage)
                                            const Positioned.fill(
                                              child: CircularProgressIndicator(
                                                  color: teal, strokeWidth: 3),
                                            ),
                                          Positioned(
                                            bottom: 0,
                                            right: 5,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: const BoxDecoration(
                                                  color: teal,
                                                  shape: BoxShape.circle),
                                              child: const Icon(
                                                  Icons.camera_alt,
                                                  size: 18,
                                                  color: deepNavy),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Name
                                    Text(userName,
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: whiteish)),
                                    const SizedBox(height: 4),
                                    // Area
                                    if (area.isNotEmpty)
                                      Text(area,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: teal,
                                              fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 8),
                                    // Verified Badge
                                    if (isVerified)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: successGreen.withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: successGreen, width: 1),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.verified,
                                                color: successGreen, size: 14),
                                            SizedBox(width: 4),
                                            Text("Verified Resident",
                                                style: TextStyle(
                                                    color: successGreen,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // 2. STATS ROW (SliverPersistentHeader or SliverToBoxAdapter)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 20.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: sectionBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(_postsCount.toString(), "Posts"),
                            _buildDivider(),
                            _buildStatItem(
                                _propertiesCount.toString(), "Properties"),
                            _buildDivider(),
                            _buildStatItem(
                                _complaintsCount.toString(), "Complaints"),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. TAB BAR (Pinned)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: teal,
                        unselectedLabelColor: Colors.white54,
                        indicatorColor: teal,
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        tabs: const [
                          Tab(text: "Posts"),
                          Tab(text: "Properties"),
                          Tab(text: "Complaints"),
                          Tab(text: "About"),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildContentTab("posts"),
                  _buildContentTab("properties"),
                  _buildContentTab("complaints"),
                  _buildAboutTab(),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: teal.withValues(alpha: 0.3),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: whiteish),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildContentTab(String collectionName) {
    final uid = _resolvedUid ?? '';
    if (uid.isEmpty) return _buildEmptyState();

    Query query = FirebaseFirestore.instance
        .collection(collectionName)
        .where('userId', isEqualTo: uid);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final title = data['title'] ?? data['description'] ?? 'Untitled';
            return Card(
              color: sectionBg,
              elevation: 4,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: whiteish,
                        fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat.yMMMd().format(
                        (data['timestamp'] as Timestamp?)?.toDate() ??
                            DateTime.now()),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.white24),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.white24),
          SizedBox(height: 16),
          Text("No Content Available",
              style: TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    if (_userData == null) return const SizedBox.shrink();
    final uid = _resolvedUid ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: sectionBg,
            elevation: 4,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.email, "Email", _userData!['email']),
                  const Divider(color: Colors.white10, height: 24),
                  _buildInfoRow(Icons.phone, "Phone", _userData!['phone']),
                  const Divider(color: Colors.white10, height: 24),
                  _buildInfoRow(Icons.location_on, "Address",
                      _userData!['fullAddress'] ?? _userData!['address']),
                  const Divider(color: Colors.white10, height: 24),
                  _buildInfoRow(Icons.perm_identity, "CNIC", _userData!['cnic']),
                ],
              ),
            ),
          ),
          if (uid.isNotEmpty) ...[
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('businesses')
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                final doc = snapshot.data!.docs.first;
                final data = doc.data() as Map<String, dynamic>;
                final business = BusinessModel.fromMap(data);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0, bottom: 10.0),
                      child: Text(
                        'MY BUSINESS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    BusinessCardWidget(
                      business: business,
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusinessRegistrationScreen(
                              existingBusiness: business,
                              documentId: doc.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: teal, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(fontSize: 16, color: whiteish)),
            ],
          ),
        )
      ],
    );
  }
}

// Delegate for persistent TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent =>
      _tabBar.preferredSize.height +
      1; // +1 for a bottom border line if any, or just height
  @override
  double get maxExtent => _tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: deepNavy,
      child: Column(
        children: [
          _tabBar,
          Container(
              height: 1, color: Colors.white10), // Bottom border for tab bar
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
