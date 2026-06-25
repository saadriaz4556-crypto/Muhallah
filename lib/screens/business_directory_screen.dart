import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muhallah/models/business_model.dart';
import 'package:muhallah/widgets/business_card_widget.dart';

const Color deepNavy = Color(0xFF252A34);
const Color sectionBg = Color(0xFF2A303C);
const Color inputBg = Color(0xFF3A4250);
const Color teal = Color(0xFF08D9D6);
const Color coral = Color(0xFFFF2E63);
const Color whiteish = Color(0xFFEAEAEA);

class BusinessDirectoryScreen extends StatefulWidget {
  const BusinessDirectoryScreen({super.key});

  @override
  State<BusinessDirectoryScreen> createState() => _BusinessDirectoryScreenState();
}

class _BusinessDirectoryScreenState extends State<BusinessDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeCategoryKey = 'All';

  final List<Map<String, String>> _tabs = [
    {'label': 'All', 'key': 'All'},
    {'label': 'Shop', 'key': 'Dukaan/Shop'},
    {'label': 'Medical', 'key': 'Medical/Health'},
    {'label': 'Food', 'key': 'Food & Restaurant'},
    {'label': 'Services', 'key': 'Services/Kaam'},
    {'label': 'Grooming', 'key': 'Beauty & Grooming'},
    {'label': 'Education', 'key': 'Education'},
    {'label': 'Transport', 'key': 'Transport'},
    {'label': 'Others', 'key': 'Others'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        title: const Text('Business Directory'),
        backgroundColor: deepNavy,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: whiteish, fontSize: 14),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by business name or category...',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white30, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white30, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Horizontal Category Tabs
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tabs.length,
                itemBuilder: (context, index) {
                  final tab = _tabs[index];
                  final label = tab['label']!;
                  final key = tab['key']!;
                  final isSelected = _activeCategoryKey == key;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _activeCategoryKey = key);
                        }
                      },
                      labelStyle: TextStyle(
                        color: isSelected ? deepNavy : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      selectedColor: teal,
                      backgroundColor: sectionBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      side: BorderSide(
                        color: isSelected ? teal : Colors.white12,
                        width: 1,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Directory List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('businesses')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading directory: ${snapshot.error}',
                        style: const TextStyle(color: coral),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: teal));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront_outlined, size: 64, color: Colors.white24),
                          SizedBox(height: 12),
                          Text(
                            'No businesses registered yet.',
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  // Convert docs and filter in-memory
                  final List<_BusinessWithId> allItems = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _BusinessWithId(
                      id: doc.id,
                      model: BusinessModel.fromMap(data),
                    );
                  }).toList();

                  final filteredItems = allItems.where((item) {
                    // Category Filter
                    if (_activeCategoryKey != 'All' && item.model.category != _activeCategoryKey) {
                      return false;
                    }
                    // Search Query Filter
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      final matchesName = item.model.businessName.toLowerCase().contains(q);
                      final matchesCategory = item.model.category.toLowerCase().contains(q);
                      final matchesSubCategory = item.model.subCategory.toLowerCase().contains(q);
                      final matchesOwner = item.model.ownerName.toLowerCase().contains(q);
                      if (!matchesName && !matchesCategory && !matchesSubCategory && !matchesOwner) {
                        return false;
                      }
                    }
                    return true;
                  }).toList();

                  if (filteredItems.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: Colors.white24),
                          SizedBox(height: 12),
                          Text(
                            'No matching businesses found.',
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return BusinessCardWidget(business: item.model);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessWithId {
  final String id;
  final BusinessModel model;

  _BusinessWithId({required this.id, required this.model});
}
