import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muhallah/screens/features_screen/found_item_detail_screen.dart';
import 'package:muhallah/screens/features_screen/lost_item_detail_screen.dart';
import 'package:muhallah/screens/features_screen/lost_items_list_screen.dart';
import 'package:muhallah/screens/features_screen/report_found_item_sheet.dart';
import 'package:muhallah/screens/features_screen/report_lost_item_sheet.dart';
import 'package:muhallah/services/lost_found_service.dart';

void main() {
  runApp(const LostFoundApp());
}

class LostFoundApp extends StatelessWidget {
  const LostFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lost & Found (Demo)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF08D9D6),
        scaffoldBackgroundColor: const Color(0xFF252A34),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const LostFoundHome(),
    );
  }
}

class LostFoundHome extends StatefulWidget {
  const LostFoundHome({super.key});

  @override
  State<LostFoundHome> createState() => _LostFoundHomeState();
}

class _LostFoundHomeState extends State<LostFoundHome>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> categories = [
    {'title': 'Lost', 'icon': Icons.search_off},
    {'title': 'Found', 'icon': Icons.check_circle_outline},
  ];

  String selectedCategory = 'Lost';
  final LostFoundData _data = LostFoundData();

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Sample data for lost items
  final List<Map<String, dynamic>> lostItems = [
    {
      'name': 'Black Wallet',
      'image': Icons.wallet,
      'description': 'Lost near cafeteria',
      'color': Colors.brown,
    },
    {
      'name': 'Car Keys',
      'image': Icons.key,
      'description': 'Toyota key with keychain',
      'color': Colors.amber,
    },
    {
      'name': 'iPhone 14',
      'image': Icons.phone_iphone,
      'description': 'Black case, cracked screen',
      'color': Colors.grey,
    },
    {
      'name': 'Water Bottle',
      'image': Icons.water_drop,
      'description': 'Blue Hydroflask',
      'color': Colors.blue,
    },
    {
      'name': 'Backpack',
      'image': Icons.backpack,
      'description': 'Red Jansport backpack',
      'color': Colors.red,
    },
    {
      'name': 'Glasses',
      'image': Icons.visibility,
      'description': 'Black rimmed glasses',
      'color': Colors.black,
    },
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onCategoryTap(String title) {
    setState(() {
      selectedCategory = title;
      _data.category = selectedCategory;

      // Reset and restart animation when category changes
      _animationController.reset();
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF252A34),
      body: Column(
        children: [
          // Top Header Box (same style as other screens)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF252A34),
                  const Color(0xFF08D9D6).withValues(alpha: 0.2),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A303C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.arrow_back, color: Color(0xFFEAEAEA)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Lost & Found',
                  style: TextStyle(
                    color: Color(0xFFEAEAEA),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Sub-header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: const Text(
              'Report or browse lost & found items',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Category selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: categories.map((c) {
                final title = c['title'] as String;
                final isSelected = selectedCategory == title;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onCategoryTap(title),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF08D9D6)
                            : const Color(0xFF2A303C),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF33343A)),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF08D9D6,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            c['icon'] as IconData,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.black
                                  : const Color(0xFFEAEAEA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Animated list area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: selectedCategory == 'Lost'
                          ? _buildLostItemsStreamList()
                          : _buildFoundItemsStreamList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // Bottom action bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF252A34),
          border: Border(top: BorderSide(color: Colors.grey[800]!)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LostItemsListScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF08D9D6),
                  side: const BorderSide(color: Color(0xFF08D9D6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('VIEW ALL'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please log in first'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: const Color(0xFF1E1E2E),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) {
                      if (selectedCategory.toLowerCase() == 'lost') {
                        return ReportLostItemSheet(
                          onSubmitted: () {},
                          currentUserId: user.uid,
                          currentUserName:
                              user.displayName ?? user.email ?? 'Anonymous',
                        );
                      }

                      return ReportFoundItemSheet(
                        currentUserId: user.uid,
                        currentUserName:
                            user.displayName ?? user.email ?? 'Anonymous',
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF08D9D6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'REPORT ITEM',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLostItemsStreamList() {
    final lostFoundService = LostFoundService();
    return StreamBuilder<QuerySnapshot>(
      stream: lostFoundService.getLostItemsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF08D9D6),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No lost items reported yet',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final int itemCount = docs.length > 5 ? 5 : docs.length;

        return ListView.separated(
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;

            final category = data['category'] ?? 'Other';
            final itemName = data['itemName'] ?? 'Unnamed Item';
            final description = data['description'] ?? '';

            return Card(
              color: const Color(0xFF2A303C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LostItemDetailScreen(itemData: data),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(category),
                  child: Icon(_getCategoryIcon(category), color: Colors.black),
                ),
                title: Text(
                  itemName,
                  style: const TextStyle(
                    color: Color(0xFFEAEAEA),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFB0B0B0)),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFB0B0B0),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'wallet':
        return Icons.wallet;
      case 'keys':
        return Icons.key;
      case 'phone':
        return Icons.phone_iphone;
      case 'bag':
        return Icons.backpack;
      case 'documents':
        return Icons.description;
      case 'electronics':
        return Icons.devices;
      default:
        return Icons.help_outline;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'wallet':
        return Colors.brown;
      case 'keys':
        return Colors.amber;
      case 'phone':
        return Colors.grey;
      case 'bag':
        return Colors.red;
      case 'documents':
        return Colors.blue;
      case 'electronics':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildFoundItemsStreamList() {
    final lostFoundService = LostFoundService();
    return StreamBuilder<QuerySnapshot>(
      stream: lostFoundService.getFoundItemsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00D4C8)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No found items reported yet',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final docs = snapshot.data!.docs.toList();

        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTs = aData['timestamp'] as Timestamp?;
          final bTs = bData['timestamp'] as Timestamp?;
          return (bTs?.compareTo(aTs ??
                  Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(0))) ??
              0);
        });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final category = data['category'] ?? 'Other';
            final categoryColors = {
              'Umbrella': Colors.purple,
              'Notebook': Colors.green,
              'Electronics': Colors.blue,
              'Clothing': Colors.orange,
              'Keys': Colors.amber,
              'Wallet': Colors.brown,
              'Jewelry': Colors.pink,
              'Documents': Colors.indigo,
              'Other': Colors.teal,
            };
            final color = categoryColors[category] ?? Colors.teal;

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FoundItemDetailScreen(
                    itemId: docs[index].id,
                    data: data,
                  ),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color,
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['itemName'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data['description'] ?? '',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/* ----------------- Form Screen (placeholder image logic) ----------------- */

class LostFoundFormScreen extends StatefulWidget {
  final LostFoundData data;
  const LostFoundFormScreen({super.key, required this.data});

  @override
  State<LostFoundFormScreen> createState() => _LostFoundFormScreenState();
}

class _LostFoundFormScreenState extends State<LostFoundFormScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleC = TextEditingController();
  final TextEditingController _descC = TextEditingController();
  final TextEditingController _locationC = TextEditingController();

  bool _hasPickedPlaceholder = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _titleC.text = widget.data.title ?? '';
    _descC.text = widget.data.description ?? '';
    _locationC.text = widget.data.location ?? '';

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    _locationC.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _titleC.text.trim().isNotEmpty && _descC.text.trim().isNotEmpty;

  Future<void> _pickFromGalleryPlaceholder() async {
    setState(() {
      _hasPickedPlaceholder = true;
      widget.data.imagePlaceholder = true;
    });

    // Add animation feedback
    _animationController.reset();
    _animationController.forward();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Using placeholder image (gallery) — demo mode)'),
      ),
    );
  }

  Future<void> _takePhotoPlaceholder() async {
    setState(() {
      _hasPickedPlaceholder = true;
      widget.data.imagePlaceholder = true;
    });

    // Add animation feedback
    _animationController.reset();
    _animationController.forward();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Using placeholder image (camera) — demo mode)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Item'),
        backgroundColor: const Color(0xFF252A34),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category: ${widget.data.category ?? '—'}',
                      style: const TextStyle(
                        color: Color(0xFF08D9D6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleC,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF3A4250),
                        hintText: 'Brief title (e.g., Black Wallet)',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(color: Color(0xFFEAEAEA)),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _descC,
                      maxLines: 5,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF3A4250),
                        hintText: 'Describe item and circumstances',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(color: Color(0xFFEAEAEA)),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _locationC,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF3A4250),
                        hintText: 'Location (e.g., Block A lobby)',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(color: Color(0xFFEAEAEA)),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Image picker area (placeholder approach)
                    Text(
                      'Attach image (optional)',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (_hasPickedPlaceholder)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 96,
                                height: 96,
                                color: const Color(0xFF2A303C),
                                child: const Icon(
                                  Icons.photo,
                                  size: 44,
                                  color: Color(0xFF08D9D6),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A4250),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[800]!),
                            ),
                            child: const Icon(
                              Icons.image,
                              color: Color(0xFF666666),
                            ),
                          ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickFromGalleryPlaceholder,
                              icon: const Icon(Icons.photo),
                              label: const Text('Gallery'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF08D9D6),
                                foregroundColor: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _takePhotoPlaceholder,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF08D9D6),
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF08D9D6),
                              side: const BorderSide(color: Color(0xFF08D9D6)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('CANCEL'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isValid
                                ? () {
                                    widget.data.title = _titleC.text.trim();
                                    widget.data.description =
                                        _descC.text.trim();
                                    widget.data.location =
                                        _locationC.text.trim();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LostFoundPreviewScreen(
                                          data: widget.data,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF08D9D6),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'NEXT',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
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
          );
        },
      ),
    );
  }
}

/* ----------------- Preview Screen ----------------- */

class LostFoundPreviewScreen extends StatelessWidget {
  final LostFoundData data;
  const LostFoundPreviewScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (data.imagePlaceholder == true) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 200,
          color: const Color(0xFF2A303C),
          child: const Center(
            child: Icon(Icons.photo, size: 80, color: Color(0xFF08D9D6)),
          ),
        ),
      );
    } else {
      imageWidget = Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF3A4250),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: const Center(
          child: Icon(Icons.image, size: 56, color: Color(0xFF666666)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Report'),
        backgroundColor: const Color(0xFF252A34),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: const Color(0xFF2A303C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    imageWidget,
                    const SizedBox(height: 12),
                    Text(
                      data.title ?? '(No title)',
                      style: const TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.description ?? '(No description)',
                      style: const TextStyle(color: Color(0xFFB0B0B0)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Location: ${data.location ?? '—'}',
                      style: const TextStyle(color: Color(0xFFB0B0B0)),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF08D9D6),
                      side: const BorderSide(color: Color(0xFF08D9D6)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('EDIT'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // publish/demo submit
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report submitted')),
                      );
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08D9D6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'SUBMIT',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------- Simple Data Model ----------------- */

class LostFoundData {
  String? category;
  String? title;
  String? description;
  String? location;
  bool? imagePlaceholder; // demo-only flag, no real file path
}
