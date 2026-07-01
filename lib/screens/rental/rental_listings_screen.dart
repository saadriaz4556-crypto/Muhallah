import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/rental_listing_model.dart';
import '../../services/rental_listing_service.dart';
import 'add_rental_listing_screen.dart';
import 'rental_detail_screen.dart';

// --- THEME COLORS ---
const Color bgDeepNavy = Color(0xFF252A34);
const Color accentTeal = Color(0xFF08D9D6);
const Color lightText = Color(0xFFEAEAEA);
const Color cardBg = Color(0xFF1A1F2E);
const Color statusGreen = Color(0xFF10B981);
const Color statusRed = Color(0xFFFF2E63);

class RentalListingsScreen extends StatefulWidget {
  const RentalListingsScreen({super.key});

  @override
  State<RentalListingsScreen> createState() => _RentalListingsScreenState();
}

class _RentalListingsScreenState extends State<RentalListingsScreen> {
  final RentalListingService _service = RentalListingService();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Room', 'Portion', 'Full House'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeepNavy,
      appBar: AppBar(
        backgroundColor: bgDeepNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: accentTeal),
        title: const Text(
          'House for Rent',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: accentTeal, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddRentalListingScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal Filter Row
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter);
                      }
                    },
                    selectedColor: accentTeal,
                    backgroundColor: cardBg,
                    labelStyle: TextStyle(
                      color: isSelected ? bgDeepNavy : lightText,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),

          // Listings ListView
          Expanded(
            child: StreamBuilder<List<RentalListing>>(
              stream: _service.fetchApprovedListings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: accentTeal),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: statusRed),
                    ),
                  );
                }

                final allListings = snapshot.data ?? [];
                
                // Filter listings based on type
                final filteredListings = allListings.where((listing) {
                  if (_selectedFilter == 'All') return true;
                  String mappedType = listing.type.replaceAll('_', ' ').toLowerCase();
                  return mappedType == _selectedFilter.toLowerCase();
                }).toList();

                if (filteredListings.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredListings.length,
                  itemBuilder: (context, index) {
                    return RentalListingCard(listing: filteredListings[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_outlined, color: accentTeal.withValues(alpha: 0.5), size: 80),
          const SizedBox(height: 16),
          const Text(
            'No listings found',
            style: TextStyle(color: lightText, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to list a property!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class RentalListingCard extends StatelessWidget {
  final RentalListing listing;

  const RentalListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    String typeLabel = listing.type.replaceAll('_', ' ').toUpperCase();
    Color typeColor = _getTypeColor(listing.type);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RentalDetailScreen(listing: listing),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                listing.imageUrls.isNotEmpty
                    ? Image.network(
                        listing.imageUrls[0],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.white10,
                            child: const Center(
                              child: CircularProgressIndicator(color: accentTeal),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.white10,
                            child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                          );
                        },
                      )
                    : Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.white10,
                        child: const Icon(Icons.image, color: Colors.grey, size: 50),
                      ),
                // Type Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      typeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: listing.status == 'available' ? statusGreen : statusRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      listing.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rent
                  Text(
                    'PKR ${NumberFormat('#,###').format(listing.rentAmount)} / month',
                    style: const TextStyle(
                      color: accentTeal,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.location,
                          style: const TextStyle(color: lightText, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Info Row (Rooms, Baths, Furnished)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIconInfo(Icons.king_bed_outlined, '${listing.rooms} Rooms'),
                      _buildIconInfo(Icons.bathtub_outlined, '${listing.bathrooms} Baths'),
                      _buildIconInfo(Icons.chair_outlined, listing.furnishingStatus.toUpperCase()),
                    ],
                  ),
                  
                  const Divider(color: Colors.white10, height: 24),
                  
                  // Available From
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available From:',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      Text(
                        DateFormat('dd MMM, yyyy').format(listing.availableFrom),
                        style: const TextStyle(color: lightText, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: accentTeal, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'room':
        return Colors.blue;
      case 'portion':
        return Colors.orange;
      case 'full_house':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
