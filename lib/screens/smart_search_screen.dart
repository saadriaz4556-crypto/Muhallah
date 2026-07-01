import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:url_launcher/url_launcher.dart';

// --- DATA MODEL ---
class CommunityPlace {
  final String placeId;
  final String memberId;
  final String memberName;
  final String memberAvatar;
  final String placeName;
  final String description;
  final String category;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? whatsapp;
  final bool isVerified;
  final Timestamp createdAt;
  final String communityId;

  CommunityPlace({
    required this.placeId,
    required this.memberId,
    required this.memberName,
    required this.memberAvatar,
    required this.placeName,
    required this.description,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.whatsapp,
    required this.isVerified,
    required this.createdAt,
    required this.communityId,
  });

  factory CommunityPlace.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CommunityPlace(
      placeId: doc.id,
      memberId: d['memberId'] ?? '',
      memberName: d['memberName'] ?? '',
      memberAvatar: d['memberAvatar'] ?? '',
      placeName: d['placeName'] ?? '',
      description: d['description'] ?? '',
      category: d['category'] ?? 'other',
      address: d['address'] ?? '',
      latitude: (d['latitude'] ?? 0).toDouble(),
      longitude: (d['longitude'] ?? 0).toDouble(),
      phone: d['phone'],
      whatsapp: d['whatsapp'],
      isVerified: d['isVerified'] ?? false,
      createdAt: d['createdAt'] ?? Timestamp.now(),
      communityId: d['communityId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'memberAvatar': memberAvatar,
      'placeName': placeName,
      'description': description,
      'category': category,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'whatsapp': whatsapp,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'communityId': communityId,
    };
  }
}

// --- CATEGORY CONFIGURATION ---
class SearchCategory {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const SearchCategory({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const List<SearchCategory> CATEGORIES = [
  SearchCategory(
      key: 'all',
      label: 'All',
      icon: Icons.grid_view_rounded,
      color: Color(0xFF08D9D6)),
  SearchCategory(
      key: 'shop',
      label: 'Shop',
      icon: Icons.storefront_outlined,
      color: Color(0xFF00B07C)),
  SearchCategory(
      key: 'hospital',
      label: 'Hospital',
      icon: Icons.local_hospital_outlined,
      color: Color(0xFFE53935)),
  SearchCategory(
      key: 'ghar',
      label: 'Ghar',
      icon: Icons.home_outlined,
      color: Color(0xFFFFA726)),
  SearchCategory(
      key: 'office',
      label: 'Office',
      icon: Icons.business_outlined,
      color: Color(0xFF1E88E5)),
  SearchCategory(
      key: 'masjid',
      label: 'Masjid',
      icon: Icons.mosque_outlined,
      color: Color(0xFF43A047)),
  SearchCategory(
      key: 'school',
      label: 'School',
      icon: Icons.school_outlined,
      color: Color(0xFFAB47BC)),
  SearchCategory(
      key: 'events',
      label: 'Events',
      icon: Icons.event_outlined,
      color: Color(0xFFEF5350)),
  SearchCategory(
      key: 'members',
      label: 'Members',
      icon: Icons.person_outlined,
      color: Color(0xFF26C6DA)),
];

// --- MAIN SCREEN ---
class SmartSearchScreen extends StatefulWidget {
  const SmartSearchScreen({super.key});
  static const routeName = '/smart-search';

  @override
  State<SmartSearchScreen> createState() => _SmartSearchScreenState();
}

class _SmartSearchScreenState extends State<SmartSearchScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<CommunityPlace> _allPlaces = [];
  Position? _currentPosition;

  String _currentCommunityId = 'Gulshan Block A';
  String _currentUserName = 'Resident';
  String _currentUserAvatar = '';
  bool _isLoading = true;

  static const _defaultCenter = LatLng(31.5204, 74.3587);

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserCommunity();
    _getCurrentLocation();
  }

  Future<void> _fetchCurrentUserCommunity() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && mounted) {
            setState(() {
              _currentCommunityId =
                  data['area'] ?? data['communityId'] ?? 'Gulshan Block A';
              _currentUserName = data['fullName'] ?? 'Resident';
              _currentUserAvatar = data['passportPhotoUrl'] ?? '';
            });
          }
        }
      }
      _fetchPlaces();
    } catch (e) {
      debugPrint('Error fetching user community: $e');
      _fetchPlaces();
    }
  }

  Future<void> _fetchPlaces() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('community_places')
          .where('communityId', isEqualTo: _currentCommunityId)
          .get();

      final places =
          snapshot.docs.map((d) => CommunityPlace.fromDoc(d)).toList();

      if (mounted) {
        setState(() {
          _allPlaces = places;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching places: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() => _currentPosition = position);
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            14,
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _searchMapLocation(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final locations = await geo.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        _mapController.move(LatLng(loc.latitude, loc.longitude), 14);
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location not found. Try a different area name.'),
            backgroundColor: Color(0xFFFF2E63),
          ),
        );
      }
    }
  }

  Color _colorForCategory(String category) {
    final match = CATEGORIES.where((c) => c.key == category).toList();
    return match.isNotEmpty ? match.first.color : const Color(0xFF08D9D6);
  }


  List<Marker> _buildMarkers() {
    return _allPlaces.map((place) {
      final color = _colorForCategory(place.category);
      return Marker(
        point: LatLng(place.latitude, place.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showPlaceDetail(place),
          child: Icon(Icons.location_on, color: color, size: 36),
        ),
      );
    }).toList();
  }


  void _showPlaceDetail(CommunityPlace place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PlaceDetailSheet(place: place),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF08D9D6);

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude,
                      _currentPosition!.longitude)
                  : _defaultCenter,
              initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.muhallah',
              ),
              MarkerLayer(markers: _buildMarkers()),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude),
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Safe area overlay
          SafeArea(
            child: Column(
              children: [
                // Back button + Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      // Back button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: Colors.black87,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Search bar
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(
                              hintText: 'Search area or place...',
                              hintStyle: TextStyle(color: Colors.black38),
                              prefixIcon:
                                  Icon(Icons.search, color: primaryColor),
                              suffixIcon: Icon(Icons.my_location,
                                  color: primaryColor),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 14),
                            ),
                            onSubmitted: _searchMapLocation,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Loading indicator
                if (_isLoading)
                  Container(
                    margin: const EdgeInsets.only(bottom: 80),
                    child: const CircularProgressIndicator(color: primaryColor),
                  ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

// --- ADD LOCATION SHEET WIDGET ---
class AddLocationSheet extends StatefulWidget {
  final String communityId;
  final String memberName;
  final String memberAvatar;
  final VoidCallback onSubmitted;

  const AddLocationSheet({
    super.key,
    required this.communityId,
    required this.memberName,
    required this.memberAvatar,
    required this.onSubmitted,
  });

  @override
  State<AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends State<AddLocationSheet> {
  final _formKey = GlobalKey<FormState>();
  final MapController _sheetMapController = MapController();
  String _selectedCategory = 'shop';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();

  LatLng? _selectedLocation;
  bool _isSubmitting = false;
  bool _pickingLocation = false;

  final List<Map<String, dynamic>> _sheetCategories = [
    {'key': 'shop', 'label': 'Shop'},
    {'key': 'hospital', 'label': 'Hospital'},
    {'key': 'ghar', 'label': 'Ghar'},
    {'key': 'office', 'label': 'Office'},
    {'key': 'masjid', 'label': 'Masjid'},
    {'key': 'school', 'label': 'School'},
    {'key': 'restaurant', 'label': 'Restaurant'},
    {'key': 'other', 'label': 'Other'},
  ];

  Future<void> _pickCurrentLocation() async {
    try {
      setState(() => _pickingLocation = true);
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = latLng;
        _pickingLocation = false;
      });
      _sheetMapController.move(latLng, 15);
      _reverseGeocode(latLng.latitude, latLng.longitude);
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() => _pickingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Failed to get location. Check app permissions.')),
        );
      }
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        final addressStr = [
          if (pm.name != null && pm.name!.isNotEmpty) pm.name,
          if (pm.street != null && pm.street!.isNotEmpty) pm.street,
          if (pm.subLocality != null && pm.subLocality!.isNotEmpty)
            pm.subLocality,
          if (pm.locality != null && pm.locality!.isNotEmpty) pm.locality,
        ].join(', ');
        if (mounted) {
          setState(() {
            _addressController.text = addressStr;
          });
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
  }

  Future<void> _submitLocation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select your location on the map first.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('You must be logged in to add a place.')),
          );
        }
        return;
      }

      final newPlace = CommunityPlace(
        placeId: '',
        memberId: user.uid,
        memberName: widget.memberName,
        memberAvatar: widget.memberAvatar,
        placeName: _nameController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        address: _addressController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
        isVerified: false,
        createdAt: Timestamp.now(),
        communityId: widget.communityId,
      );

      await FirebaseFirestore.instance
          .collection('community_places')
          .add(newPlace.toMap());

      widget.onSubmitted();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Location pinned to map!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving place: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving location: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: 20,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Add Your Location',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pin your shop, clinic, home or office on the community map',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Step 1: Category Selection
                  const Text(
                    'Step 1 — Select a category:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _sheetCategories.map((cat) {
                      final isSelected = _selectedCategory == cat['key'];
                      final Color catColor = CATEGORIES
                          .firstWhere(
                            (c) => c.key == cat['key'],
                            orElse: () => CATEGORIES[0],
                          )
                          .color;
                      return ChoiceChip(
                        label: Text(cat['label']),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _selectedCategory = cat['key']!);
                        },
                        backgroundColor: const Color(0xFF3A4250),
                        selectedColor: catColor,
                        labelStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Step 2: Map picker
                  const Text(
                    'Step 2 — Pick location on map:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _sheetMapController,
                            options: MapOptions(
                              initialCenter: const LatLng(31.5204, 74.3587),
                              initialZoom: 13,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all &
                                    ~InteractiveFlag.rotate,
                              ),
                              onTap: (tapPosition, point) {
                                setState(() => _selectedLocation = point);
                                _reverseGeocode(
                                    point.latitude, point.longitude);
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.muhallah',
                              ),
                              if (_selectedLocation != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _selectedLocation!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Color(0xFFFF2E63),
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: FloatingActionButton(
                              mini: true,
                              backgroundColor: const Color(0xFF08D9D6),
                              onPressed: _pickCurrentLocation,
                              child: _pickingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Icon(Icons.my_location,
                                      color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedLocation != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Selected: ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Step 3: Form Fields
                  const Text(
                    'Step 3 — Details:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Place name',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF08D9D6))),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Place name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Short description',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF08D9D6))),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Description is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Address / Area',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF08D9D6))),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Address is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Phone number (optional)',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF08D9D6))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp number (optional)',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF08D9D6))),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08D9D6),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSubmitting ? null : _submitLocation,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Add Pin to Map',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- PLACE DETAIL SHEET WIDGET ---
class PlaceDetailSheet extends StatelessWidget {
  final CommunityPlace place;

  const PlaceDetailSheet({super.key, required this.place});

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String whatsapp) async {
    var cleanNumber = whatsapp.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '92${cleanNumber.substring(1)}';
    }
    final Uri whatsappAppUri = Uri.parse("whatsapp://send?phone=$cleanNumber");
    final Uri whatsappWebUri = Uri.parse("https://wa.me/$cleanNumber");
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

  Future<void> _launchMaps() async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252A34),
        title: const Text('Report Location',
            style: TextStyle(color: Colors.white)),
        content: const Text('Kya aap is location ko report karna chahte hain?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2E63)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Report submitted. Admin will review it.')),
              );
            },
            child: const Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Member Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: place.memberAvatar.isNotEmpty
                  ? NetworkImage(place.memberAvatar)
                  : null,
              child: place.memberAvatar.isEmpty
                  ? const Icon(Icons.person, size: 36, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              place.memberName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Verified Community Resident',
              style: TextStyle(color: Color(0xFF08D9D6), fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              "This member's details are verified. You can call or WhatsApp them directly.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close',
                style: TextStyle(color: Color(0xFF08D9D6))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = CATEGORIES.firstWhere(
      (c) => c.key == place.category,
      orElse: () => CATEGORIES[0],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: cat.color.withValues(alpha: 0.15),
                child: Icon(cat.icon, size: 28, color: cat.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.placeName,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showMemberDialog(context),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: place.memberAvatar.isNotEmpty
                                ? NetworkImage(place.memberAvatar)
                                : null,
                            child: place.memberAvatar.isEmpty
                                ? const Icon(Icons.person,
                                    size: 10, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            place.memberName,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF08D9D6),
                                decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTag(cat.label, cat.color),
              if (place.isVerified) ...[
                const SizedBox(width: 8),
                _buildTag('Verified ✓', Colors.green),
              ]
            ],
          ),
          const SizedBox(height: 8),
          Text(
            place.description,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on, color: Color(0xFFFF2E63)),
            title: const Text('Full Address',
                style: TextStyle(color: Colors.grey, fontSize: 11)),
            subtitle: Text(place.address,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          if (place.phone != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Phone Number',
                  style: TextStyle(color: Colors.grey, fontSize: 11)),
              subtitle: Text(place.phone!,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
              onTap: () => _launchPhone(place.phone!),
            ),
          if (place.whatsapp != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
              title: const Text('WhatsApp',
                  style: TextStyle(color: Colors.grey, fontSize: 11)),
              subtitle: Text(place.whatsapp!,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
              onTap: () => _launchWhatsApp(place.whatsapp!),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF08D9D6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: _launchMaps,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF2E63),
                    side: const BorderSide(color: Color(0xFFFF2E63)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.report_problem, size: 16),
                  label: const Text('Report',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _showReportDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
