import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/rental_listing_model.dart';
import '../../services/rental_listing_service.dart';
import '../../widgets/fullscreen_image_viewer.dart';

// --- THEME COLORS ---
const Color bgDeepNavy = Color(0xFF252A34);
const Color accentTeal = Color(0xFF08D9D6);
const Color lightText = Color(0xFFEAEAEA);
const Color cardBg = Color(0xFF1A1F2E);
const Color statusGreen = Color(0xFF10B981);
const Color statusRed = Color(0xFFFF2E63);

class RentalDetailScreen extends StatefulWidget {
  final RentalListing listing;

  const RentalDetailScreen({super.key, required this.listing});

  @override
  State<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends State<RentalDetailScreen> {
  final RentalListingService _service = RentalListingService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isUpdating = false;
  late RentalListing _listing;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
  }

  Future<void> _makeCall() async {
    final Uri url = Uri.parse('tel:${_listing.ownerPhone}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWhatsApp() async {
    // Standardize phone number (remove leading zero, add 92 for Pakistan if needed)
    String phone = _listing.ownerPhone;
    if (phone.startsWith('0')) {
      phone = '92${phone.substring(1)}';
    }
    final Uri whatsappAppUri = Uri.parse("whatsapp://send?phone=$phone");
    final Uri whatsappWebUri = Uri.parse("https://wa.me/$phone");
    try {
      if (await canLaunchUrl(whatsappAppUri)) {
        await launchUrl(whatsappAppUri);
      } else if (await canLaunchUrl(whatsappWebUri)) {
        await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      try {
        await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  Future<void> _markAsRented() async {
    setState(() => _isUpdating = true);
    try {
      await _service.markAsRented(_listing.listingId);
      setState(() {
        _listing = RentalListing(
          listingId: _listing.listingId,
          type: _listing.type,
          rentAmount: _listing.rentAmount,
          location: _listing.location,
          availableFrom: _listing.availableFrom,
          furnishingStatus: _listing.furnishingStatus,
          rooms: _listing.rooms,
          bathrooms: _listing.bathrooms,
          attachedBath: _listing.attachedBath,
          gasAvailable: _listing.gasAvailable,
          parkingAvailable: _listing.parkingAvailable,
          imageUrls: _listing.imageUrls,
          ownerUid: _listing.ownerUid,
          ownerName: _listing.ownerName,
          ownerPhone: _listing.ownerPhone,
          status: 'rented',
          isApproved: _listing.isApproved,
          createdAt: _listing.createdAt,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing marked as rented.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: statusRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteListing() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgDeepNavy,
        title:
            const Text('Delete Listing', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this listing?',
          style: TextStyle(color: lightText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: lightText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: statusRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() => _isUpdating = true);
    try {
      await _service.deleteListing(_listing.listingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing deleted successfully.'),
            backgroundColor: statusGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete listing: $e'),
              backgroundColor: statusRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = _currentUid == _listing.ownerUid;

    return Scaffold(
      backgroundColor: bgDeepNavy,
      body: CustomScrollView(
        slivers: [
          // Collapsible Image Gallery Header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: bgDeepNavy,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: isOwner ? [] : null,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageGallery(),
            ),
          ),

          // Listing Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title / Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBadge(
                          _listing.type.replaceAll('_', ' ').toUpperCase(),
                          _getTypeColor(_listing.type)),
                      _buildBadge(
                          _listing.status.toUpperCase(),
                          _listing.status == 'available'
                              ? statusGreen
                              : statusRed),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PKR ${NumberFormat('#,###').format(_listing.rentAmount)} / month',
                    style: const TextStyle(
                      color: accentTeal,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _listing.location,
                          style:
                              const TextStyle(color: lightText, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 40),

                  // Main Specs Grid
                  const Text('Property Details',
                      style: TextStyle(
                          color: accentTeal,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    children: [
                      _buildSpecItem(
                          Icons.king_bed, 'Rooms', _listing.rooms.toString()),
                      _buildSpecItem(Icons.bathtub, 'Bathrooms',
                          _listing.bathrooms.toString()),
                      _buildSpecItem(Icons.chair, 'Furnishing',
                          _listing.furnishingStatus.toUpperCase()),
                      _buildSpecItem(Icons.calendar_today, 'Available',
                          DateFormat('dd MMM').format(_listing.availableFrom)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Amenities
                  const Text('Amenities',
                      style: TextStyle(
                          color: accentTeal,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildAmenityRow(Icons.check_circle, 'Attached Bath',
                      _listing.attachedBath),
                  _buildAmenityRow(Icons.check_circle, 'Gas Available',
                      _listing.gasAvailable),
                  _buildAmenityRow(Icons.check_circle, 'Parking Available',
                      _listing.parkingAvailable),

                  const Divider(color: Colors.white10, height: 40),

                  // Owner Info
                  const Text('Listed By',
                      style: TextStyle(
                          color: accentTeal,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: accentTeal.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, color: accentTeal),
                    ),
                    title: Text(_listing.ownerName,
                        style: const TextStyle(
                            color: lightText, fontWeight: FontWeight.bold)),
                    subtitle: Text('Contact: ${_listing.ownerPhone}',
                        style: const TextStyle(color: Colors.white70)),
                  ),

                  if (isOwner) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isUpdating ? null : _deleteListing,
                        icon: _isUpdating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.delete_outline),
                        label: const Text('Delete Post'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: bgDeepNavy,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _makeCall,
                    icon: const Icon(Icons.call),
                    label: const Text('Call Owner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openWhatsApp,
                    icon: const Icon(Icons.message),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (isOwner && _listing.status == 'available') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _markAsRented,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUpdating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Mark as Rented',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          )),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    return PageView.builder(
      itemCount: _listing.imageUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullscreenImageViewer(
                  imageUrl: _listing.imageUrls[index],
                ),
              ),
            );
          },
          child: Image.network(
            _listing.imageUrls[index],
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                  child: CircularProgressIndicator(color: accentTeal));
            },
            errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentTeal, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 10)),
                Text(
                  value,
                  style: const TextStyle(
                      color: lightText,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityRow(IconData icon, String label, bool available) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: available ? statusGreen : Colors.white30, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: lightText, fontSize: 14)),
        ],
      ),
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
