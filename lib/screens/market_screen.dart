import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class MarketplaceModule extends StatefulWidget {
  const MarketplaceModule({super.key});

  @override
  State<MarketplaceModule> createState() => _MarketplaceModuleState();
}

class _MarketplaceModuleState extends State<MarketplaceModule> {
  String activeScreen = 'home';
  String selectedCategory = 'all';
  String sortBy = 'mostRecent';
  bool showFilters = false;
  int currentStep = 1;
  List<double> priceRange = [10, 250];
  Map<String, bool> condition = {
    'new': true,
    'used': true,
    'likeNew': true,
    'refurbished': false,
  };
  bool deliveryRequested = false;

  // Dark Theme Colors
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

  // Mock Data
  final List<Map<String, dynamic>> categories = [
    {'id': 'all', 'label': 'All', 'count': 1234, 'icon': '🛍️'},
    {'id': 'electronics', 'label': 'Electronics', 'count': 234, 'icon': '📱'},
    {'id': 'furniture', 'label': 'Furniture', 'count': 189, 'icon': '🛋️'},
    {'id': 'vehicles', 'label': 'Vehicles', 'count': 67, 'icon': '🚗'},
    {'id': 'books', 'label': 'Books', 'count': 156, 'icon': '📚'},
    {'id': 'services', 'label': 'Services', 'count': 89, 'icon': '🔧'},
    {'id': 'appliances', 'label': 'Appliances', 'count': 123, 'icon': '🏠'},
    {'id': 'others', 'label': 'Others', 'count': 276, 'icon': '📦'},
  ];

  final List<Map<String, String>> sortOptions = [
    {'id': 'mostRecent', 'label': 'Most Recent'},
    {'id': 'priceLow', 'label': 'Price: Low to High'},
    {'id': 'priceHigh', 'label': 'Price: High to Low'},
    {'id': 'mostPopular', 'label': 'Most Popular'},
    {'id': 'nearest', 'label': 'Nearest'},
  ];

  final List<Map<String, dynamic>> listings = [
    {
      'id': '1',
      'title': 'Vintage Leather Sofa',
      'price': 500,
      'seller': 'John Doe',
      'sellerUid': 'seller1_uid',
      'location': 'Islamabad',
      'timestamp': '2 hours ago',
      'category': 'furniture',
      'featured': true,
      'endingSoon': false,
      'verifiedSeller': true,
      'image': 'assets/images/Sofa.jpg', // CHANGED: Local asset
      'condition': 'used',
    },
    {
      'id': '2',
      'title': 'Mountain Bike',
      'price': 250,
      'seller': 'Jane Smith',
      'sellerUid': 'seller2_uid',
      'location': 'Jubilee Hills',
      'timestamp': '1 day ago',
      'category': 'vehicles',
      'featured': false,
      'endingSoon': true,
      'verifiedSeller': false,
      'image': 'assets/images/Bike.jpg', // CHANGED: Local asset
      'condition': 'used',
    },
    {
      'id': '3',
      'title': 'Cycle',
      'price': 45,
      'seller': 'Bookworm',
      'location': 'Jubilee Hills',
      'timestamp': '5 hours ago',
      'category': 'books',
      'featured': false,
      'endingSoon': false,
      'verifiedSeller': true,
      'image': 'assets/images/Cycle.jpg', // CHANGED: Local asset
      'condition': 'likeNew',
    },
    {
      'id': '4',
      'title': 'MacBook Pro 14"',
      'price': 1200,
      'seller': 'Techie Tom',
      'location': 'Jubilee Hills',
      'timestamp': '3 days ago',
      'category': 'electronics',
      'featured': true,
      'endingSoon': false,
      'verifiedSeller': false,
      'image': 'assets/images/MacBook.jpg', // CHANGED: Local asset
      'condition': 'used',
    },
    {
      'id': '5',
      'title': 'Mid-Century Modern Armchair',
      'price': 250,
      'seller': 'Sarah J.',
      'location': 'Jubilee Hills',
      'timestamp': '6 hours ago',
      'category': 'furniture',
      'featured': false,
      'endingSoon': true,
      'verifiedSeller': true,
      'image': 'assets/images/ModernChair.jpg', // CHANGED: Local asset
      'condition': 'likeNew',
    },
    {
      'id': '6',
      'title': 'iPhone 13 Pro',
      'price': 750,
      'seller': 'Tech Guru',
      'location': 'Islamabad',
      'timestamp': '1 day ago',
      'category': 'electronics',
      'featured': false,
      'endingSoon': false,
      'verifiedSeller': true,
      'image': 'assets/images/Iphone.jpg', // CHANGED: Local asset
      'condition': 'refurbished',
    },
  ];

  final Map<String, dynamic> productDetail = {
    'id': '5',
    'title': 'Mid-Century Modern Armchair',
    'price': 250,
    'seller': 'Sarah J.',
    'reviews': 120,
    'joinDate': 2021,
    'description':
        'Beautifully maintained mid-century modern armchair. Perfect accent piece for any living room. Selling because I\'m moving to a smaller apartment. No stains, smoke-free home. Solid wood frame with comfortable, durable upholstery.',
    'condition': 'Used - Like New',
    'category': 'Furniture',
    'dimensions': '32" H × 28" W × 30" D',
    'tags': ['vintage', 'modern', 'wood'],
    'images': [
      'assets/images/ModernChair.jpg', // CHANGED: Local asset
      'assets/images/Sofa.jpg', // CHANGED: Local asset
      'assets/images/Pic.png', // CHANGED: Local asset
    ],
  };

  // Marketplace Home Screen - ULTRA COMPACT VERSION
  Widget _buildMarketplaceHome() {
    return Scaffold(
      backgroundColor: colors['background'],
      appBar: AppBar(
        backgroundColor: colors['cardBackground'],
        elevation: 0,
        title: Text(
          'Marketplace',
          style: TextStyle(
            color: colors['textPrimary'],
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
            color: colors['textPrimary'],
          ),
          IconButton(
            onPressed: () => setState(() => showFilters = true),
            icon: const Icon(Icons.tune),
            color: colors['textPrimary'],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bottomPadding = MediaQuery.of(context).padding.bottom + 90.0;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  // Location & Stats - ULTRA COMPACT
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      8,
                    ), // Reduced top padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Islamabad',
                          style: TextStyle(
                            color: colors['textPrimary'],
                            fontSize: 22, // Reduced from 24
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2), // Reduced from 4
                        Text(
                          '1,234 Listings',
                          style: TextStyle(
                            color: colors['textSecondary'],
                            fontSize: 14, // Reduced from 16
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar - COMPACT
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search items, categories or sellers...',
                        hintStyle: TextStyle(color: colors['textTertiary']),
                        filled: true,
                        fillColor: colors['surface'],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10), // Reduced
                          borderSide: BorderSide(color: colors['border']!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10), // Reduced
                          borderSide: BorderSide(color: colors['border']!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, // Reduced
                          vertical: 12, // Reduced
                        ),
                      ),
                      style: TextStyle(
                        color: colors['textPrimary'],
                        fontSize: 14, // Reduced
                      ),
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced from 16
                  // Categories - ULTRA COMPACT
                  SizedBox(
                    height: 85, // Reduced from 100
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = selectedCategory == category['id'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => selectedCategory = category['id']),
                          child: Container(
                            width: 70, // Reduced from 75
                            margin: const EdgeInsets.only(right: 8), // Reduced
                            padding: const EdgeInsets.all(8), // Reduced
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors['primary']
                                  : colors['surface'],
                              border: Border.all(
                                color: isSelected
                                    ? colors['primary']!
                                    : colors['border']!,
                              ),
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // Reduced
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  category['icon'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ), // Reduced
                                ),
                                const SizedBox(height: 2), // Reduced
                                Text(
                                  category['label'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : colors['textPrimary'],
                                    fontSize: 10, // Reduced from 11
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1), // Reduced
                                Text(
                                  category['count'].toString(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : colors['textTertiary'],
                                    fontSize: 8, // Reduced from 9
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced from 14
                  // Results Header - COMPACT
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${listings.length} items',
                          style: TextStyle(
                            color: colors['textSecondary'],
                            fontSize: 12, // Reduced from 13
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Implement sort modal
                          },
                          child: Text(
                            'Sort by: ${sortOptions.firstWhere((opt) => opt['id'] == sortBy)['label']}',
                            style: TextStyle(
                              color: colors['primary'],
                              fontSize: 12, // Reduced from 13
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8), // Reduced from 10
                  // Featured Tags - COMPACT
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, // Reduced
                            vertical: 4, // Reduced
                          ),
                          decoration: BoxDecoration(
                            color: colors['accent']!.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12), // Reduced
                          ),
                          child: Text(
                            '🔥 Featured',
                            style: TextStyle(
                              color: colors['accent'],
                              fontSize: 10, // Reduced from 11
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4), // Reduced from 6
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, // Reduced
                            vertical: 4, // Reduced
                          ),
                          decoration: BoxDecoration(
                            color: colors['error']!.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12), // Reduced
                          ),
                          child: Text(
                            '⏰ Ending Soon',
                            style: TextStyle(
                              color: colors['error'],
                              fontSize: 10, // Reduced from 11
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced from 14
                  // Listings Grid - ULTRA COMPACT
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                    ), // Reduced
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 4, // Reduced from 6
                      mainAxisSpacing: 4, // Reduced from 6
                      childAspectRatio: 0.65, // Reduced from 0.70
                    ),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      final item = listings[index];
                      return _buildListingCard(item);
                    },
                  ),
                  const SizedBox(height: 16), // Reduced bottom padding
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => activeScreen = 'create'),
        backgroundColor: colors['primary'],
        elevation: 8,
        icon: const Icon(Icons.add, color: Colors.white, size: 18), // Reduced
        label: const Text(
          'Sell Item',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13, // Reduced
          ),
        ),
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> item) {
    return Card(
      color: colors['cardBackground'],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Reduced from 10
        side: BorderSide(color: colors['border']!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Container - ULTRA COMPACT
          Stack(
            children: [
              Container(
                height: 110, // Reduced from 120
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  image: DecorationImage(
                    // CHANGED: NetworkImage to AssetImage
                    image: AssetImage(item['image']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Price Badge
              Positioned(
                top: 4, // Reduced from 6
                right: 4, // Reduced from 6
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5, // Reduced
                    vertical: 2, // Reduced
                  ),
                  decoration: BoxDecoration(
                    color: colors['success'],
                    borderRadius: BorderRadius.circular(4), // Reduced
                  ),
                  child: Text(
                    '\$${item['price']}',
                    style: const TextStyle(
                      fontSize: 10, // Reduced from 11
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Featured Badge
              if (item['featured'])
                Positioned(
                  top: 4, // Reduced
                  left: 4, // Reduced
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4, // Reduced
                      vertical: 1, // Reduced
                    ),
                    decoration: BoxDecoration(
                      color: colors['accent'],
                      borderRadius: BorderRadius.circular(2), // Reduced
                    ),
                    child: const Text(
                      'Featured',
                      style: TextStyle(
                        fontSize: 8, // Reduced from 9
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              // Ending Soon Badge
              if (item['endingSoon'])
                Positioned(
                  bottom: 4, // Reduced
                  left: 4, // Reduced
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4, // Reduced
                      vertical: 1, // Reduced
                    ),
                    decoration: BoxDecoration(
                      color: colors['error'],
                      borderRadius: BorderRadius.circular(2), // Reduced
                    ),
                    child: const Text(
                      'Ending Soon',
                      style: TextStyle(
                        fontSize: 8, // Reduced from 9
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Content - ULTRA COMPACT
          Padding(
            padding: const EdgeInsets.all(8), // Reduced from 10
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: TextStyle(
                    color: colors['textPrimary'],
                    fontSize: 12, // Reduced from 13
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3), // Reduced from 4
                Row(
                  children: [
                    Text(
                      item['seller'],
                      style: TextStyle(
                        color: colors['textSecondary'],
                        fontSize: 10, // Reduced from 11
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item['verifiedSeller']) ...[
                      const SizedBox(width: 2), // Reduced
                      const Text(
                        '💺',
                        style: TextStyle(fontSize: 8),
                      ), // Reduced
                    ],
                  ],
                ),
                const SizedBox(height: 2), // Reduced from 3
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['location'],
                      style: TextStyle(
                        color: colors['textTertiary'],
                        fontSize: 8, // Reduced from 9
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      item['timestamp'],
                      style: TextStyle(
                        color: colors['textTertiary'],
                        fontSize: 8, // Reduced from 9
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quick Actions - ULTRA COMPACT
          Container(
            padding: const EdgeInsets.all(6), // Reduced from 8
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors['border']!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border, size: 16), // Reduced
                  color: colors['textTertiary'],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24), // Smaller
                ),
                GestureDetector(
                  onTap: () {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) return;

                    final currentUid = currentUser.uid;
                    final sellerUid = item['sellerUid'] as String? ?? '';
                    final sellerName = item['seller'] as String? ?? 'Unknown';

                    if (sellerUid.isEmpty) return;

                    // Generate chatId by sorting UIDs alphabetically and joining with underscore
                    final uids = [currentUid, sellerUid]..sort();
                    final chatId = uids.join('_');

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: chatId,
                          otherUserName: sellerName,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Contact',
                    style: TextStyle(
                      color: colors['primary'],
                      fontSize: 10, // Reduced from 11
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Product Detail Screen - ULTRA COMPACT
  Widget _buildProductDetail() {
    int currentImageIndex = 0;

    return Scaffold(
      backgroundColor: colors['background'],
      appBar: AppBar(
        backgroundColor: colors['cardBackground'],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: colors['textPrimary'],
          onPressed: () => setState(() => activeScreen = 'home'),
        ),
        title: Text(
          'Product Details',
          style: TextStyle(
            color: colors['textPrimary'],
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border),
            color: colors['textPrimary'],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share),
            color: colors['textPrimary'],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Image Carousel - ULTRA COMPACT
                      SizedBox(
                        height: 260, // Reduced from 280
                        child: Stack(
                          children: [
                            // CHANGED: NetworkImage to AssetImage
                            Image.asset(
                              productDetail['images'][currentImageIndex],
                              width: double.infinity,
                              height: 260, // Reduced
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 8, // Reduced from 12
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  productDetail['images'].length,
                                  (index) => Container(
                                    width: 5, // Reduced from 6
                                    height: 5, // Reduced from 6
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2, // Reduced from 3
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: index == currentImageIndex
                                          ? colors['primary']
                                          : colors['border'],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Product Info Card - ULTRA COMPACT
                      Container(
                        margin: const EdgeInsets.all(12), // Reduced from 14
                        padding: const EdgeInsets.all(12), // Reduced from 14
                        decoration: BoxDecoration(
                          color: colors['cardBackground'],
                          borderRadius: BorderRadius.circular(8), // Reduced
                          border: Border.all(color: colors['border']!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productDetail['title'],
                              style: TextStyle(
                                color: colors['textPrimary'],
                                fontSize: 20, // Reduced from 22
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4), // Reduced from 6
                            Text(
                              '\$${productDetail['price']}',
                              style: TextStyle(
                                color: colors['success'],
                                fontSize: 22, // Reduced from 24
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12), // Reduced from 14
                            // Seller Info - ULTRA COMPACT
                            Row(
                              children: [
                                Container(
                                  width: 40, // Reduced from 45
                                  height: 40, // Reduced from 45
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF666666),
                                    borderRadius: BorderRadius.circular(
                                      20,
                                    ), // Reduced
                                  ),
                                ),
                                const SizedBox(width: 8), // Reduced from 10
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${productDetail['seller']} 😊',
                                        style: TextStyle(
                                          color: colors['textPrimary'],
                                          fontSize: 15, // Reduced from 16
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '(${productDetail['reviews']} reviews) • Joined ${productDetail['joinDate']}',
                                        style: TextStyle(
                                          color: colors['textSecondary'],
                                          fontSize: 12, // Reduced from 13
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16), // Reduced from 18
                            // Description - ULTRA COMPACT
                            _buildSection(
                              title: 'Description',
                              child: Text(
                                productDetail['description'],
                                style: TextStyle(
                                  color: colors['textSecondary'],
                                  fontSize: 14, // Reduced from 15
                                  height: 1.3, // Reduced from 1.4
                                ),
                              ),
                            ),

                            // Specifications - ULTRA COMPACT
                            _buildSection(
                              title: 'Specifications',
                              child: Column(
                                children: [
                                  _buildSpecRow(
                                    'Condition',
                                    productDetail['condition'],
                                  ),
                                  _buildSpecRow(
                                    'Category',
                                    productDetail['category'],
                                  ),
                                  _buildSpecRow(
                                    'Dimensions',
                                    productDetail['dimensions'],
                                  ),
                                  _buildSpecRow(
                                    'Tags',
                                    productDetail['tags'].join(', '),
                                    isTags: true,
                                  ),
                                ],
                              ),
                            ),

                            // Delivery Option - ULTRA COMPACT
                            _buildSection(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Request Delivery',
                                    style: TextStyle(
                                      color: colors['textPrimary'],
                                      fontSize: 14, // Reduced from 15
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Switch(
                                    value: deliveryRequested,
                                    onChanged: (value) => setState(
                                      () => deliveryRequested = value,
                                    ),
                                    activeThumbColor: colors['primary'],
                                  ),
                                ],
                              ),
                            ),

                            // Safety Tips - ULTRA COMPACT
                            Container(
                              padding: const EdgeInsets.all(
                                10,
                              ), // Reduced from 12
                              decoration: BoxDecoration(
                                color: colors['surface'],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: colors['border']!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Safe Trading Tips',
                                    style: TextStyle(
                                      color: colors['textPrimary'],
                                      fontSize: 14, // Reduced from 15
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4), // Reduced from 6
                                  Text(
                                    'Always meet in a public place. Verify the item before you pay. Never share personal financial information.',
                                    style: TextStyle(
                                      color: colors['textSecondary'],
                                      fontSize: 12, // Reduced from 13
                                      height: 1.3, // Reduced
                                    ),
                                  ),
                                  const SizedBox(height: 4), // Reduced from 6
                                  GestureDetector(
                                    onTap: () {},
                                    child: Text(
                                      'Learn More',
                                      style: TextStyle(
                                        color: colors['primary'],
                                        fontSize: 12, // Reduced from 13
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14), // Reduced from 16
                            // Report Options - ULTRA COMPACT
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Report Listing',
                                    style: TextStyle(
                                      color: colors['textTertiary'],
                                      fontSize: 12, // Reduced from 13
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Block User',
                                    style: TextStyle(
                                      color: colors['textTertiary'],
                                      fontSize: 12, // Reduced from 13
                                      fontWeight: FontWeight.w500,
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

              // Message Seller Button - ULTRA COMPACT
              Container(
                margin: const EdgeInsets.all(12), // Reduced from 14
                child: ElevatedButton(
                  onPressed: () {
                    // Implement chat
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors['primary'],
                    minimumSize: const Size(
                      double.infinity,
                      46,
                    ), // Reduced from 50
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Reduced
                    ),
                  ),
                  child: const Text(
                    'Message Seller',
                    style: TextStyle(
                      fontSize: 15, // Reduced from 16
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({String? title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14), // Reduced from 16
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: TextStyle(
                color: colors['textPrimary'],
                fontSize: 15, // Reduced from 16
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4), // Reduced from 6
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {bool isTags = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Reduced from 10
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(
                color: colors['textSecondary'],
                fontSize: 12, // Reduced from 13
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: isTags
                ? Wrap(
                    spacing: 4, // Reduced from 6
                    children: value.split(', ').map((tag) {
                      return Text(
                        '#$tag',
                        style: TextStyle(
                          color: colors['primary'],
                          fontSize: 12, // Reduced from 13
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      color: colors['textPrimary'],
                      fontSize: 12, // Reduced from 13
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
          ),
        ],
      ),
    );
  }

  // Create Listing Screen (unchanged for brevity)
  Widget _buildCreateListing() {
    return Scaffold(
      backgroundColor: colors['background'],
      appBar: AppBar(
        backgroundColor: colors['cardBackground'],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: colors['textPrimary'],
          onPressed: () => setState(() => activeScreen = 'home'),
        ),
        title: Text(
          'Create New Listing',
          style: TextStyle(
            color: colors['textPrimary'],
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Step $currentStep/5',
                style: TextStyle(
                  color: colors['textTertiary'],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height -
            kToolbarHeight -
            MediaQuery.of(context).padding.top,
        child: Column(
          children: [
            // Progress Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: LinearProgressIndicator(
                value: currentStep / 5,
                backgroundColor: colors['border'],
                color: colors['primary'],
                minHeight: 4,
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildCreateStep(),
              ),
            ),

            // Navigation Buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (currentStep > 1) {
                          setState(() => currentStep--);
                        } else {
                          setState(() => activeScreen = 'home');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: colors['surface'],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        currentStep == 1 ? 'Cancel' : 'Back',
                        style: TextStyle(
                          color: colors['textPrimary'],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (currentStep < 5) {
                          setState(() => currentStep++);
                        } else {
                          _handlePublish();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors['primary'],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        currentStep == 5 ? 'Publish' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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

  Widget _buildCreateStep() {
    if (currentStep == 1) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors['cardBackground'],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors['border']!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: TextStyle(
                color: colors['textPrimary'],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Category Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final category = categories[index + 1];
                return Container(
                  decoration: BoxDecoration(
                    color: colors['surface'],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors['border']!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category['icon'],
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['label'],
                        style: TextStyle(
                          color: colors['textPrimary'],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            Text(
              'Title',
              style: TextStyle(
                color: colors['textPrimary'],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'What are you selling?',
                hintStyle: TextStyle(color: colors['textTertiary']),
                filled: true,
                fillColor: colors['surface'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors['border']!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors['border']!),
                ),
              ),
              style: TextStyle(color: colors['textPrimary']),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '0/60',
                style: TextStyle(
                  color: colors['textTertiary'],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Price',
              style: TextStyle(
                color: colors['textPrimary'],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors['primary'],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Fixed Price',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colors['surface'],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Negotiable',
                      style: TextStyle(
                        color: colors['textPrimary'],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colors['surface'],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Free',
                      style: TextStyle(
                        color: colors['textPrimary'],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              'Condition',
              style: TextStyle(
                color: colors['textPrimary'],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                _buildConditionOption('☑ New'),
                _buildConditionOption('□ Used'),
                _buildConditionOption('□ Like New'),
              ],
            ),
          ],
        ),
      );
    }

    // Placeholder for other steps
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors['cardBackground'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors['border']!),
      ),
      child: Center(
        child: Text(
          'Step $currentStep Content',
          style: TextStyle(
            color: colors['textPrimary'],
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildConditionOption(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: colors['textPrimary'],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePublish() {
    // Handle publish logic
    setState(() {
      activeScreen = 'home';
      currentStep = 1;
    });
  }

  // Filter Modal (unchanged for brevity)
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors['background'],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _buildFilterModalContent();
      },
    );
  }

  Widget _buildFilterModalContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Modal Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors['cardBackground'],
              border: Border(bottom: BorderSide(color: colors['border']!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Results',
                  style: TextStyle(
                    color: colors['textPrimary'],
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: colors['textPrimary'],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for anything',
                      hintStyle: TextStyle(color: colors['textTertiary']),
                      filled: true,
                      fillColor: colors['surface'],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors['border']!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors['border']!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                    ),
                    style: TextStyle(color: colors['textPrimary']),
                  ),
                  const SizedBox(height: 16),

                  // Pricing
                  _buildFilterSection(
                    title: 'Pricing',
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${priceRange[0]}',
                              style: TextStyle(
                                color: colors['textPrimary'],
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '\$${priceRange[1]}',
                              style: TextStyle(
                                color: colors['textPrimary'],
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Simple range slider representation
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors['border'],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            widthFactor: 0.7,
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors['primary'],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Condition
                  _buildFilterSection(
                    title: 'Condition',
                    child: Column(
                      children: condition.entries.map((entry) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              condition[entry.key] = !entry.value;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '${entry.value ? '☑' : '□'} ${entry.key[0].toUpperCase()}${entry.key.substring(1)}',
                              style: TextStyle(
                                color: colors['textPrimary'],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Location
                  _buildFilterSection(
                    title: 'Location',
                    child: Column(
                      children: [
                        _buildFilterOption('☑ Category'),
                        _buildFilterOption('☑ Seller'),
                        _buildFilterOption('☑ Listing'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Modal Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors['cardBackground'],
              border: Border(top: BorderSide(color: colors['border']!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        priceRange = [10, 250];
                        condition = {
                          'new': true,
                          'used': true,
                          'likeNew': true,
                          'refurbished': false,
                        };
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colors['surface'],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: colors['textPrimary'],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => showFilters = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors['primary'],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Apply Filters (234)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors['cardBackground'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors['border']!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors['textPrimary'],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildFilterOption(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: colors['textPrimary'],
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show filter modal if needed
    if (showFilters) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFilterModal();
      });
    }

    // Render appropriate screen
    switch (activeScreen) {
      case 'home':
        return _buildMarketplaceHome();
      case 'detail':
        return _buildProductDetail();
      case 'create':
        return _buildCreateListing();
      default:
        return _buildMarketplaceHome();
    }
  }
}
