import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muhallah/features/bill_reminder/services/cloudinary_service.dart';

class ReportLostItemSheet extends StatefulWidget {
  final VoidCallback onSubmitted;
  final String? currentUserId;
  final String? currentUserName;

  const ReportLostItemSheet({
    super.key,
    required this.onSubmitted,
    this.currentUserId,
    this.currentUserName,
  });

  @override
  State<ReportLostItemSheet> createState() => _ReportLostItemSheetState();
}

class _ReportLostItemSheetState extends State<ReportLostItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedCategory = 'Wallet';
  final List<String> _categories = [
    'Wallet',
    'Keys',
    'Phone',
    'Bag',
    'Documents',
    'Electronics',
    'Other'
  ];

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLocating = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A303C),
        title: const Text('Select Image Source', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera', style: TextStyle(color: Color(0xFF08D9D6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery', style: TextStyle(color: Color(0xFF08D9D6))),
          ),
        ],
      ),
    );

    if (source != null) {
      try {
        final pickedFile = await _picker.pickImage(source: source);
        if (pickedFile != null) {
          setState(() {
            _imageFile = pickedFile;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    }

    setState(() {
      _isLocating = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final List<String> parts = [];
          
          if (place.locality != null && place.locality!.isNotEmpty) {
            parts.add(place.locality!);
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty && place.subLocality != place.locality) {
            parts.add(place.subLocality!);
          }
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty && place.administrativeArea != place.locality && place.administrativeArea != place.subLocality) {
            parts.add(place.administrativeArea!);
          }
          if (place.country != null && place.country!.isNotEmpty) {
            parts.add(place.country!);
          }
          
          final String address = parts.join(', ');
          
          _locationController.text = address.isNotEmpty 
              ? address 
              : "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
        } else {
          _locationController.text = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
        }
      } catch (_) {
        _locationController.text = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location fetched successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }

  Future<void> _submit() async {
    debugPrint('DEBUG: _submit() called');
    if (!_formKey.currentState!.validate()) {
      debugPrint('DEBUG: Form validation failed');
      return;
    }
    debugPrint('DEBUG: Form is valid. itemName=${_nameController.text.trim()}');

    // --- Auth guard: use passed-in values first (safest on Flutter Web),
    // fall back to live currentUser, then attempt a reload.
    String uid = widget.currentUserId ?? '';
    String reporterName = widget.currentUserName ?? '';

    if (uid.isEmpty) {
      // Fallback: try live auth state (may still work on native)
      final auth = FirebaseAuth.instance;
      await auth.currentUser?.reload();
      final liveUser = auth.currentUser;
      if (liveUser != null) {
        uid = liveUser.uid;
        reporterName = liveUser.displayName?.isNotEmpty == true
            ? liveUser.displayName!
            : (liveUser.email?.split('@').first ?? 'Resident');
      }
    }

    if (uid.isEmpty) {
      debugPrint('DEBUG: uid is empty — user not authenticated');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (reporterName.isEmpty) reporterName = 'Resident';
    debugPrint('DEBUG: uid=$uid, reporterName=$reporterName');

    setState(() {
      _isSubmitting = true;
    });

    try {
      String imageUrl = '';
      if (_imageFile != null) {
        debugPrint('DEBUG: Uploading image...');
        final uploadedUrl = await CloudinaryService.uploadBillImage(_imageFile!);
        if (uploadedUrl == null) {
          throw Exception('Image upload failed');
        }
        imageUrl = uploadedUrl;
        debugPrint('DEBUG: Image uploaded: $imageUrl');
      }

      debugPrint('DEBUG: Saving to lost_found_reports...');
      final docRef = await FirebaseFirestore.instance
          .collection('lost_found_reports')
          .add({
        'itemName': _nameController.text.trim(),
        'category': _selectedCategory,
        'description': _descController.text.trim(),
        'lastSeenLocation': _locationController.text.trim(),
        'imageUrl': imageUrl,
        'type': 'lost',
        'reportedBy': uid,
        'reporterName': reporterName,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
      });
      final reportId = docRef.id;
      debugPrint('DEBUG: Saved to lost_found_reports, id=$reportId');

      debugPrint('DEBUG: Saving to announcements feed...');
      await FirebaseFirestore.instance.collection('announcements').add({
        'type': 'lost_item',
        'title': 'Lost: ${_nameController.text.trim()}',
        'body': _descController.text.trim(),
        'imageUrl': imageUrl,
        'location': _locationController.text.trim(),
        'category': _selectedCategory,
        'lostItemId': reportId,
        'postedBy': uid,
        'postedByName': reporterName,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'isLostItem': true,
      });
      debugPrint('DEBUG: Saved to announcements feed.');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your lost item has been reported!'),
            backgroundColor: Color(0xFF08D9D6),
          ),
        );
        widget.onSubmitted();
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('DEBUG: Error during submit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF2E63),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF252A34),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Report Lost Item',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Item Name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2A303C),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF08D9D6)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Item name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: const Color(0xFF2A303C),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2A303C),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF08D9D6)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2A303C),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF08D9D6)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Last Seen Location
              TextFormField(
                controller: _locationController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Last Seen Location',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2A303C),
                  suffixIcon: IconButton(
                    icon: _isLocating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF08D9D6),
                            ),
                          )
                        : const Icon(Icons.my_location, color: Color(0xFF08D9D6)),
                    onPressed: _isLocating ? null : _getCurrentLocation,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF08D9D6)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image Selector and Preview Thumbnail
              const Text(
                'Attach Image',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A303C),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: kIsWeb
                                  ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                                  : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                            )
                          : const Icon(Icons.add_a_photo, color: Color(0xFF08D9D6)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _imageFile != null
                          ? 'Image selected. Tap on the preview box to change.'
                          : 'Tap on the box to capture/select a photo.',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF08D9D6),
                        side: const BorderSide(color: Color(0xFF08D9D6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08D9D6),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'SUBMIT',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
  }
}

// Add a standard flutter platform/web check because kIsWeb might not be imported.
// Wait! Let's import it from foundation.
