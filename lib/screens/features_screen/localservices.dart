import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LocalServicesScreen extends StatefulWidget {
  final String townName;

  const LocalServicesScreen({super.key, this.townName = "Green Valley"});

  @override
  State<LocalServicesScreen> createState() => _LocalServicesScreenState();
}

class _LocalServicesScreenState extends State<LocalServicesScreen> {
  // UI colors matching app design system
  final Color _darkBackground = const Color(0xFF252A34);
  final Color _primaryColor = const Color(0xFF08D9D6);
  final Color _accentColor = const Color(0xFF08D9D6);
  final Color _darkCardColor = const Color(0xFF2A303C);
  final Color _darkTextColor = const Color(0xFFEAEAEA);
  final Color _darkSecondaryText = Colors.white70;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Plumber',
    'Electrician',
    'Carpenter',
    'AC Technician',
    'Mechanic',
    'Doctor',
    'Painter',
    'Mason',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Function to launch phone dialer
  Future<void> _launchPhoneDialer(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number provided')),
      );
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber.trim());
    try {
      final bool launched = await launchUrl(phoneUri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not launch dialer'),
            backgroundColor: _accentColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch dialer: $e'),
          backgroundColor: _accentColor,
        ),
      );
    }
  }

  // Function to launch SMS app
  Future<void> _launchSMS(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number provided')),
      );
      return;
    }
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber.trim());
    try {
      final bool launched = await launchUrl(smsUri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not launch messaging app'),
            backgroundColor: _accentColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch messaging app: $e'),
          backgroundColor: _accentColor,
        ),
      );
    }
  }

  Future<void> _deleteService(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkCardColor,
        title: Text('Delete Service', style: TextStyle(color: _darkTextColor)),
        content: Text(
          'Are you sure you want to delete this service post?',
          style: TextStyle(color: _darkSecondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('local_services')
            .doc(docId)
            .delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service post deleted successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_darkBackground, _primaryColor.withValues(alpha: 0.2)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 2),
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
          const SizedBox(height: 16),
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim().toLowerCase();
              });
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by name, profession or location...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF08D9D6)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: _darkCardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white10),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF08D9D6)),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(cat),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : _darkTextColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              backgroundColor: _darkCardColor,
              selectedColor: _primaryColor,
              checkmarkColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? _primaryColor : Colors.white10,
                ),
              ),
              onSelected: (_) {
                setState(() {
                  _selectedCategory = cat;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _serviceCard(Map<String, dynamic> service, String docId) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    final ownerId = service['userId'] ?? service['uid'];
    final ownerEmail = service['userEmail'] ?? service['email'];
    final isOwner = (currentUserId != null && ownerId == currentUserId) ||
        (currentUserEmail != null && ownerEmail == currentUserEmail);

    final name = service['name'] ?? service['userName'] ?? service['title'] ?? 'Service Provider';
    final profession = service['profession'] ?? service['serviceName'] ?? service['category'] ?? 'Service';
    final category = service['category'] ?? 'General';
    final location = service['location'] ?? service['address'] ?? 'Local Area';
    final phone = (service['phone'] ?? service['contactNumber'] ?? '').toString();
    final profileImg = service['imageUrl'] ?? service['photoUrl'] ?? service['profileImage'] ?? '';

    return Card(
      color: _darkCardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Avatar / DP
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _primaryColor.withValues(alpha: 0.2),
                  backgroundImage: profileImg.toString().isNotEmpty
                      ? NetworkImage(profileImg.toString())
                      : null,
                  child: profileImg.toString().isEmpty
                      ? Icon(Icons.person, color: _primaryColor, size: 28)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toString(),
                        style: TextStyle(
                          color: _darkTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profession.toString(),
                        style: const TextStyle(
                          color: Color(0xFF08D9D6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category.toString(),
                          style: TextStyle(
                              color: _darkSecondaryText, fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.white54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location.toString(),
                              style: TextStyle(
                                color: _darkSecondaryText,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _launchPhoneDialer(phone),
                      icon: Icon(Icons.call, color: _accentColor),
                      tooltip: 'Call',
                    ),
                    IconButton(
                      onPressed: () => _launchSMS(phone),
                      icon: Icon(Icons.message, color: _accentColor),
                      tooltip: 'SMS',
                    ),
                  ],
                ),
              ],
            ),
            if (isOwner) ...[
              const Divider(color: Colors.white10, height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                  ),
                  onPressed: () => _deleteService(docId),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
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
            _buildHeader(),
            const SizedBox(height: 12),
            _buildCategoryFilter(),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('local_services')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading services: ${snapshot.error}',
                        style: TextStyle(color: _darkSecondaryText),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data();
                    final name = (data['name'] ?? data['userName'] ?? data['title'] ?? '').toString().toLowerCase();
                    final profession = (data['profession'] ?? data['serviceName'] ?? data['category'] ?? '').toString().toLowerCase();
                    final category = (data['category'] ?? '').toString();
                    final location = (data['location'] ?? data['address'] ?? '').toString().toLowerCase();

                    final matchesCategory = _selectedCategory == 'All' ||
                        category.toLowerCase() == _selectedCategory.toLowerCase();

                    final matchesSearch = _searchQuery.isEmpty ||
                        name.contains(_searchQuery) ||
                        profession.contains(_searchQuery) ||
                        category.toLowerCase().contains(_searchQuery) ||
                        location.contains(_searchQuery);

                    return matchesCategory && matchesSearch;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.design_services_outlined,
                              size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          Text(
                            'No services found',
                            style: TextStyle(
                              color: _darkSecondaryText,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      return _serviceCard(doc.data(), doc.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pushNamed(context, '/add_service').catchError((_) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Add Service screen will be built in the next task'),
              ),
            );
            return null;
          });
        },
        backgroundColor: _primaryColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
