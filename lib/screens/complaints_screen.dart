import 'package:flutter/material.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  String activeFilter = 'all';
  String selectedSort = 'newest';
  final Set<String> upvotedComplaints = <String>{};

  // Colors matching the React Native version
  final colors = {
    'background': const Color(0xFF121212),
    'cardBackground': const Color(0xFF1E1E1E),
    'surface': const Color(0xFF252525),
    'primary': const Color(0xFF11988D),
    'accent': const Color(0xFFFFC107),
    'textPrimary': const Color(0xFFFFFFFF),
    'textSecondary': const Color(0xFFB0B0B0),
    'textTertiary': const Color(0xFF888888),
    'border': const Color(0xFF333333),
    'success': const Color(0xFF059669),
    'warning': const Color(0xFFF59E0B),
    'error': const Color(0xFFDC2626),
  };

  // Filter options
  final List<Map<String, dynamic>> filters = [
    {'id': 'all', 'label': 'All', 'count': 42},
    {'id': 'pending', 'label': 'Pending', 'count': 18},
    {'id': 'inProgress', 'label': 'In Progress', 'count': 12},
    {'id': 'resolved', 'label': 'Resolved', 'count': 9},
    {'id': 'highPriority', 'label': 'High Priority', 'count': 3},
    {'id': 'myComplaints', 'label': 'My Complaints', 'count': 5},
  ];

  // Sort options
  final List<Map<String, String>> sortOptions = [
    {'id': 'newest', 'label': 'Newest'},
    {'id': 'upvoted', 'label': 'Most Upvoted'},
    {'id': 'reported', 'label': 'Most Reported'},
  ];

  // Sample complaints data
  final List<Map<String, dynamic>> complaints = [
    {
      'id': '1',
      'title': 'Garbage accumulation near park entrance',
      'category': 'sanitation',
      'description':
          'Large pile of garbage has been sitting for 3 days, causing smell and attracting stray animals',
      'status': 'pending',
      'priority': 'high',
      'upvotes': 23,
      'comments': 8,
      'shares': 3,
      'timestamp': '2 hours ago',
      'location': 'Near Central Park',
      'image': 'assets/images/Garbage.jpg',
      'verified': true,
      'user': {'name': 'Saad Riaz', 'role': 'Resident'},
    },
    {
      'id': '2',
      'title': 'Street light outage on Main Street',
      'category': 'electricity',
      'description':
          'Section of Main Street completely dark at night, safety concern for pedestrians',
      'status': 'inProgress',
      'priority': 'medium',
      'upvotes': 15,
      'comments': 12,
      'shares': 2,
      'timestamp': '5 hours ago',
      'location': 'Main Street Block B',
      'image': 'assets/images/Electricity.jpg',
      'verified': false,
      'user': {'name': 'Bilal Ahmed', 'role': 'Resident'},
    },
    {
      'id': '3',
      'title': 'Water leakage from broken pipe',
      'category': 'water',
      'description':
          'Constant water flow from broken pipeline, wasting water and causing road damage',
      'status': 'resolved',
      'priority': 'low',
      'upvotes': 8,
      'comments': 4,
      'shares': 1,
      'timestamp': '1 day ago',
      'location': 'Gulshan Road',
      'image': 'assets/images/Water.jpg',
      'verified': true,
      'user': {'name': 'Admin', 'role': 'Municipal Team'},
    },
    {
      'id': '4',
      'title': 'Potholes causing traffic hazards',
      'category': 'roads',
      'description':
          'Large potholes developing on the main road, dangerous for vehicles and motorcycles',
      'status': 'pending',
      'priority': 'medium',
      'upvotes': 31,
      'comments': 15,
      'shares': 6,
      'timestamp': '3 hours ago',
      'location': 'Market Road',
      'image': 'assets/images/Traffic.jpg',
      'verified': false,
      'user': {'name': 'Sameer Khan', 'role': 'Resident'},
    },
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

  void handleUpvote(String complaintId) {
    setState(() {
      if (upvotedComplaints.contains(complaintId)) {
        upvotedComplaints.remove(complaintId);
      } else {
        upvotedComplaints.add(complaintId);
      }
    });
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
                                  item['user']['name'],
                                  style: TextStyle(
                                    color: colors['textSecondary'],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  ' • ${item['user']['role']}',
                                  style: TextStyle(
                                    color: colors['textTertiary'],
                                    fontSize: 13,
                                  ),
                                ),
                                if (item['verified'])
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
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: AssetImage(item['image']),
                      fit: BoxFit.cover,
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
                        item['timestamp'],
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
                            color: colors['error']!.withOpacity(0.12),
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
                    count: item['upvotes'],
                    isActive: upvotedComplaints.contains(item['id']),
                    onTap: () => handleUpvote(item['id']),
                  ),
                  const SizedBox(width: 16),
                  // Comments Button
                  _buildEngagementButton(
                    icon: '💬',
                    count: item['comments'],
                    isActive: false,
                    onTap: () {},
                  ),
                  const SizedBox(width: 16),
                  // Share Button
                  _buildEngagementButton(
                    icon: '↗️',
                    count: item['shares'],
                    isActive: false,
                    onTap: () {},
                  ),
                  const Spacer(),
                  // More Button
                  GestureDetector(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        '⋯',
                        style: TextStyle(
                          color: colors['textTertiary'],
                          fontSize: 16,
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors['background'],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors['cardBackground'],
                border: Border(bottom: BorderSide(color: colors['border']!)),
              ),
              child: Row(
                children: [
                  // Left side
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back,
                          color: colors['textPrimary'],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
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
                        onPressed: () {},
                        icon: Icon(Icons.search, color: colors['textPrimary']),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.more_vert,
                          color: colors['textPrimary'],
                        ),
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

                    // Sort Options
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: colors['border']!),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sort by:',
                            style: TextStyle(
                              color: colors['textSecondary'],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: sortOptions.map((option) {
                              final isSelected = selectedSort == option['id'];
                              return GestureDetector(
                                onTap: () => setState(
                                  () => selectedSort = option['id']!,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colors['primary']
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? colors['primary']!
                                          : colors['border']!,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    option['label']!,
                                    style: TextStyle(
                                      color: isSelected
                                          ? colors['textPrimary']
                                          : colors['textSecondary'],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    // Complaints List
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
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
                            children: complaints
                                .map(
                                  (complaint) => _buildComplaintCard(complaint),
                                )
                                .toList(),
                          ),
                        ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: null, // () => context.go('/TabScreens/NewComplaints'),
        backgroundColor: colors['primary'],
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        label: const Text(
          'New Complaint',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
