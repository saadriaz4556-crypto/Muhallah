import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muhallah/features/bill_reminder/services/cloudinary_service.dart';

class ReportFoundItemSheet extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;

  const ReportFoundItemSheet({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<ReportFoundItemSheet> createState() => _ReportFoundItemSheetState();
}

class _ReportFoundItemSheetState extends State<ReportFoundItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  bool _isLoading = false;

  final List<String> _categories = [
    'Umbrella',
    'Notebook',
    'Electronics',
    'Clothing',
    'Keys',
    'Wallet',
    'Jewelry',
    'Documents',
    'Other',
  ];
  String _selectedCategory = 'Other';

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && _selectedImages.length < 5) {
        setState(() {
          _selectedImages.add(pickedFile);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image pick failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final List<String> uploadedImageUrls = [];
      for (final image in _selectedImages) {
        final uploadedUrl = await CloudinaryService.uploadBillImage(image);
        if (uploadedUrl == null) {
          throw Exception('Cloudinary upload failed.');
        }
        uploadedImageUrls.add(uploadedUrl);
      }

      final newReport = {
        'itemName': _itemNameController.text.trim(),
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'foundLocation': _locationController.text.trim(),
        'imageUrls': uploadedImageUrls,
        'type': 'found',
        'reportedBy': widget.currentUserId,
        'reporterName': widget.currentUserName,
        'contactNumber': _phoneController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
      };

      final reportRef = await FirebaseFirestore.instance
          .collection('lost_found_reports')
          .add(newReport);

      await FirebaseFirestore.instance.collection('announcements').add({
        'type': 'found_item',
        'title': 'Found: ${_itemNameController.text.trim()}',
        'body': _descriptionController.text.trim(),
        'imageUrls': uploadedImageUrls,
        'location': _locationController.text.trim(),
        'category': _selectedCategory,
        'foundItemId': reportRef.id,
        'postedBy': widget.currentUserId,
        'postedByName': widget.currentUserName,
        'contactNumber': _phoneController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isFoundItem': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Found item reported successfully!'),
            backgroundColor: Color(0xFF00D4C8),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImagePreview(XFile xfile, {double size = 80}) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: xfile.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              width: size,
              height: size,
              fit: BoxFit.cover,
            );
          }
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00D4C8),
                strokeWidth: 2,
              ),
            ),
          );
        },
      );
    }

    return Image.file(
      File(xfile.path),
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  Widget _buildImagePicker() {
    final tiles = <Widget>[];
    for (var i = 0; i < _selectedImages.length; i++) {
      tiles.add(Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImagePreview(_selectedImages[i]),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => setState(() => _selectedImages.removeAt(i)),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ));
    }

    if (_selectedImages.length < 5) {
      tiles.add(GestureDetector(
        onTap: _isLoading ? null : _pickImage,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00D4C8)),
          ),
          child: const Center(
            child: Icon(Icons.add, color: Color(0xFF00D4C8), size: 32),
          ),
        ),
      ));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tiles,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E2E),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Report Found Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _itemNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Color(0xFF2A2A3E),
                          hintText: 'Item Name',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter item name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        dropdownColor: const Color(0xFF2A2A3E),
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Color(0xFF2A2A3E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        iconEnabledColor: Colors.white,
                        items: _categories
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Color(0xFF2A2A3E),
                          hintText: 'Description',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        minLines: 3,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Color(0xFF2A2A3E),
                          hintText: 'Found Location',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter found location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Your Contact Number',
                          hintStyle: TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Color(0xFF2A2A3E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your contact number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Images (max 5)',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      _buildImagePicker(),
                      const SizedBox(height: 24),
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00D4C8),
                          ),
                        ),
                      if (!_isLoading)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ButtonStyle(
                                  foregroundColor: MaterialStateProperty.all(
                                      const Color(0xFF00D4C8)),
                                  overlayColor: MaterialStateProperty.all(
                                      Colors.transparent),
                                  side: MaterialStateProperty.all(
                                    const BorderSide(
                                        color: Color(0xFF00D4C8)),
                                  ),
                                ),
                                child: const Text('CANCEL'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submitReport,
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      const Color(0xFF00D4C8)),
                                  foregroundColor: MaterialStateProperty.all(
                                      Colors.white),
                                  overlayColor: MaterialStateProperty.all(
                                      const Color(0xFF00D4C8)),
                                ),
                                child: const Text('SUBMIT'),
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
      ),
    );
  }
}
