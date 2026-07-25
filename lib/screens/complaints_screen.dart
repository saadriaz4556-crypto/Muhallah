import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:muhallah/screens/new_complaint_screen.dart';
import 'package:muhallah/services/complaint_service.dart';
import 'package:muhallah/widgets/fullscreen_image_viewer.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  String activeFilter = 'all';
  String selectedSort = 'newest';
  final Set<String> upvotedComplaints = <String>{};
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String searchQuery = '';
  bool showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  // Colors matching the React Native version
  final colors = {
    'background': const Color(0xFF252A34),
    'cardBackground': const Color(0xFF2A303C),
    'surface': const Color(0xFF3A4250),
    'primary': const Color(0xFF08D9D6),
    'accent': const Color(0xFFFF2E63),
    'textPrimary': const Color(0xFFEAEAEA),
    'textSecondary': Colors.white70,
    'textTertiary': Colors.white38,
    'border': Colors.white10,
    'success': const Color(0xFF10B981),
    'warning': const Color(0xFFF59E0B),
    'error': const Color(0xFFFF2E63),
  };

  // Filter options
  final List<Map<String, dynamic>> filters = [
    {'id': 'all', 'label': 'All'},
    {'id': 'pending', 'label': 'Pending'},
    {'id': 'inProgress', 'label': 'In Progress'},
    {'id': 'resolved', 'label': 'Resolved'},
    {'id': 'myComplaints', 'label': 'My Complaints'},
  ];

  // Sort options
  final List<Map<String, String>> sortOptions = [
    {'id': 'newest', 'label': 'Newest'},
    {'id': 'upvoted', 'label': 'Most Upvoted'},
    {'id': 'reported', 'label': 'Most Reported'},
  ];

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return colors['warning']!;
      case 'inProgress':
        return colors['primary']!;
      case 'resolved':
        return colors['success']!;
      default:
        return colors['textTertiary']!;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'inProgress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  }

  String getCategoryIcon(String category) {
    const icons = {
      'sanitation': '🗑️',
      'electricity': '💡',
      'water': '💧',
      'roads': '🛣️',
      'security': '👮',
      'sewerage': '🚽',
    };
    return icons[category] ?? '📋';
  }

  Future<void> handleUpvote(String complaintId) async {
    final complaintRef =
        FirebaseFirestore.instance.collection('complaints').doc(complaintId);
    if (upvotedComplaints.contains(complaintId)) {
      upvotedComplaints.remove(complaintId);
      await complaintRef.update({'upvotes': FieldValue.increment(-1)});
    } else {
      upvotedComplaints.add(complaintId);
      await complaintRef.update({'upvotes': FieldValue.increment(1)});
    }
    setState(() {});
  }

  void _showCommentSheet(BuildContext context, Map<String, dynamic> complaint) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors['cardBackground'],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comments',
                style: TextStyle(
                    color: colors['textPrimary'],
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .doc(complaint['id'])
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No comments yet',
                        style: TextStyle(color: Colors.white54)),
                  );
                }
                return SizedBox(
                  height: 200,
                  child: ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                                radius: 16, backgroundColor: colors['surface']),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d['authorName'] ?? 'Resident',
                                    style: TextStyle(
                                        color: colors['primary'],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                Text(d['text'] ?? '',
                                    style: TextStyle(
                                        color: colors['textPrimary'],
                                        fontSize: 14)),
                              ],
                            )),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: commentController,
                  style: TextStyle(color: colors['textPrimary']),
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: TextStyle(color: colors['textTertiary']),
                    filled: true,
                    fillColor: colors['surface'],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final text = commentController.text.trim();
                  if (text.isEmpty) return;
                  final compRef = FirebaseFirestore.instance
                      .collection('complaints')
                      .doc(complaint['id']);
                  await compRef.collection('comments').add({
                    'text': text,
                    'authorId': FirebaseAuth.instance.currentUser?.uid ?? '',
                    'authorName': FirebaseAuth.instance.currentUser?.displayName
                                ?.isNotEmpty ==
                            true
                        ? FirebaseAuth.instance.currentUser!.displayName!
                        : (FirebaseAuth.instance.currentUser?.email
                                ?.split('@')
                                .first ??
                            'Resident'),
                    'createdAt': Timestamp.now(),
                  });
                  await compRef.update({'comments': FieldValue.increment(1)});
                  commentController.clear();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors['primary'],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showCardMenu(BuildContext context, Map<String, dynamic> item) {
    final isOwner = item['userId'] == currentUserId;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors['cardBackground'],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Complaint'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditSheet(context, item);
                },
              ),
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Complaint'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dctx) => AlertDialog(
                      title: const Text('Delete complaint?'),
                      content: const Text(
                          'Are you sure you want to delete this complaint?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dctx, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(dctx, true),
                            child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FirebaseFirestore.instance
                        .collection('complaints')
                        .doc(item['id'])
                        .delete();
                  }
                },
              ),
            if (!isOwner)
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Report'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dctx) => AlertDialog(
                      title: const Text('Report complaint?'),
                      content:
                          const Text('Do you want to report this complaint?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dctx, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(dctx, true),
                            child: const Text('Report')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FirebaseFirestore.instance
                        .collection('complaints')
                        .doc(item['id'])
                        .update({'reports': FieldValue.increment(1)});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Complaint reported')));
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, Map<String, dynamic> item) {
    final titleController = TextEditingController(text: item['title']);
    final descController = TextEditingController(text: item['description']);
    final categoryController =
        TextEditingController(text: item['category'] ?? '');
    final locationController =
        TextEditingController(text: item['location'] ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors['cardBackground'],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Complaint',
                style: TextStyle(
                    color: colors['textPrimary'],
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
                controller: titleController,
                style: TextStyle(color: colors['textPrimary']),
                decoration: InputDecoration(
                    hintText: 'Title',
                    hintStyle: TextStyle(color: colors['textTertiary']),
                    filled: true,
                    fillColor: colors['surface'],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)))),
            const SizedBox(height: 8),
            TextField(
                controller: categoryController,
                style: TextStyle(color: colors['textPrimary']),
                decoration: InputDecoration(
                    hintText: 'Category',
                    hintStyle: TextStyle(color: colors['textTertiary']),
                    filled: true,
                    fillColor: colors['surface'],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)))),
            const SizedBox(height: 8),
            TextField(
                controller: descController,
                maxLines: 4,
                style: TextStyle(color: colors['textPrimary']),
                decoration: InputDecoration(
                    hintText: 'Description',
                    hintStyle: TextStyle(color: colors['textTertiary']),
                    filled: true,
                    fillColor: colors['surface'],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)))),
            const SizedBox(height: 8),
            TextField(
                controller: locationController,
                style: TextStyle(color: colors['textPrimary']),
                decoration: InputDecoration(
                    hintText: 'Location',
                    hintStyle: TextStyle(color: colors['textTertiary']),
                    filled: true,
                    fillColor: colors['surface'],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)))),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: colors['primary']),
                onPressed: () async {
                  final title = titleController.text.trim();
                  final desc = descController.text.trim();
                  final category = categoryController.text.trim();
                  final location = locationController.text.trim();
                  if (title.isEmpty || desc.isEmpty) return;
                  await FirebaseFirestore.instance
                      .collection('complaints')
                      .doc(item['id'])
                      .update({
                    'title': title,
                    'description': desc,
                    'category': category,
                    'location': location,
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ])
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(Map<String, dynamic> filter) {
    final isActive = activeFilter == filter['id'];
    return GestureDetector(
      onTap: () => setState(() => activeFilter = filter['id']),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isActive ? colors['primary'] : Colors.transparent,
          border: Border.all(
            color: isActive ? colors['primary']! : colors['border']!,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${filter['label']} (${filter['count']})',
          style: TextStyle(
            color: isActive ? colors['textPrimary'] : colors['textSecondary'],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> item) {
    final String imageUrl = item['imageUrl']?.toString() ?? '';
    final String formattedTime = item['timestamp'] is Timestamp
        ? (item['timestamp'] as Timestamp).toDate().toString()
        : item['timestamp']?.toString() ?? '';
    final userName = item['userName']?.toString() ?? 'Resident';
    final userRole = item['userId'] == currentUserId ? 'You' : 'Resident';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: colors['cardBackground'],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors['border']!),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category and Title Section
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getCategoryIcon(item['category']),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: TextStyle(
                                color: colors['textPrimary'],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(
                                    color: colors['textSecondary'],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  ' • $userRole',
                                  style: TextStyle(
                                    color: colors['textTertiary'],
                                    fontSize: 13,
                                  ),
                                ),
                                if (item['verified'] == true)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors['primary'],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '✓ Verified',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
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
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(item['status']),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    getStatusText(item['status']),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              item['description'],
              style: TextStyle(
                color: colors['textSecondary'],
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Image and Metadata Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                SizedBox(
                  width: 80,
                  height: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FullscreenImageViewer(imageUrl: imageUrl),
                                ),
                              );
                            },
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: colors['surface'],
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: colors['textTertiary'],
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            color: colors['surface'],
                            child: Icon(
                              Icons.image_not_supported,
                              color: colors['textTertiary'],
                              size: 24,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📍 ${item['location']}',
                        style: TextStyle(
                          color: colors['textTertiary'],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          color: colors['textTertiary'],
                          fontSize: 12,
                        ),
                      ),
                      if (item['priority'] == 'high')
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors['error']!.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: colors['error']!),
                          ),
                          child: Text(
                            '🔥 High Priority',
                            style: TextStyle(
                              color: colors['error'],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Engagement Bar
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors['border']!)),
              ),
              child: Row(
                children: [
                  // Upvote Button
                  _buildEngagementButton(
                    icon: '▲',
                    count: item['upvotes'] ?? 0,
                    isActive: upvotedComplaints.contains(item['id']),
                    onTap: () => handleUpvote(item['id']),
                  ),
                  const SizedBox(width: 16),
                  // Comments Button
                  _buildEngagementButton(
                    icon: '💬',
                    count: item['comments'] ?? 0,
                    isActive: false,
                    onTap: () => _showCommentSheet(context, item),
                  ),
                  const SizedBox(width: 16),
                  // share button removed per requirements
                  const Spacer(),
                  // More Button (use IconButton for reliable tap area)
                  IconButton(
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: () => _showCardMenu(context, item),
                    icon: Text(
                      '⋯',
                      style: TextStyle(
                        color: colors['textTertiary'],
                        fontSize: 16,
                      ),
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

  Widget _buildEngagementButton({
    required String icon,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(
            icon,
            style: TextStyle(
              color: isActive ? colors['primary'] : colors['textTertiary'],
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            count.toString(),
            style: TextStyle(
              color: colors['textSecondary'],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _complaintStream() {
    final complaintService = ComplaintService();
    String? status;

    if (activeFilter == 'pending') {
      status = 'pending';
    } else if (activeFilter == 'inProgress') {
      status = 'inProgress';
    } else if (activeFilter == 'resolved') {
      status = 'resolved';
    }

    final userId = activeFilter == 'myComplaints' ? currentUserId : null;

    return complaintService.complaintStream(status: status, userId: userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors['background'],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors['background']!,
                    colors['primary']!.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  // Left side
                  Row(
                    children: [
                      showSearch
                          ? Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) =>
                                    setState(() => searchQuery = v),
                                style: TextStyle(color: colors['textPrimary']),
                                decoration: InputDecoration(
                                  hintText: 'Search complaints...',
                                  hintStyle:
                                      TextStyle(color: colors['textTertiary']),
                                  border: InputBorder.none,
                                ),
                              ),
                            )
                          : Text(
                              'Complaints',
                              style: TextStyle(
                                color: colors['textPrimary'],
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ],
                  ),
                  const Spacer(),
                  // Right side
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() {
                          showSearch = !showSearch;
                          if (!showSearch) {
                            _searchController.clear();
                            searchQuery = '';
                          }
                        }),
                        icon: Icon(Icons.search, color: colors['textPrimary']),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Chip
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colors['surface'],
                          border: Border.all(color: colors['border']!),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '📍 Gulshan Block A',
                              style: TextStyle(
                                color: colors['textPrimary'],
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Change',
                              style: TextStyle(
                                color: colors['primary'],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Filter Chips
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filters.length,
                        itemBuilder: (context, index) {
                          return _buildFilterChip(filters[index]);
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Sort options removed per requirements

                    // Complaints List
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _complaintStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Text(
                              'No complaints yet',
                              style: TextStyle(
                                color: colors['textSecondary'],
                                fontSize: 14,
                              ),
                            );
                          }

                          final complaints = snapshot.data!.docs
                              .map((doc) => {
                                    'id': doc.id,
                                    ...doc.data(),
                                  })
                              .toList();

                          final query = searchQuery.trim().toLowerCase();
                          final filtered = query.isEmpty
                              ? complaints
                              : complaints.where((c) {
                                  final title = (c['title'] ?? '')
                                      .toString()
                                      .toLowerCase();
                                  final desc = (c['description'] ?? '')
                                      .toString()
                                      .toLowerCase();
                                  return title.contains(query) ||
                                      desc.contains(query);
                                }).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent Complaints (${complaints.length})',
                                style: TextStyle(
                                  color: colors['textPrimary'],
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Column(
                                children: filtered
                                    .map((complaint) =>
                                        _buildComplaintCard(complaint))
                                    .toList(),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewComplaintScreen()),
          );
          if (result == true && mounted) {
            setState(() {});
          }
        },
        backgroundColor: colors['primary'],
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
