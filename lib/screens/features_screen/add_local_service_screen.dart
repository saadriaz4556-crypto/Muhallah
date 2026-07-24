import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muhallah/services/marketplace_service.dart';

class AddLocalServiceScreen extends StatefulWidget {
  const AddLocalServiceScreen({super.key});

  @override
  State<AddLocalServiceScreen> createState() => _AddLocalServiceScreenState();
}

class _AddLocalServiceScreenState extends State<AddLocalServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _professionController = TextEditingController();
  final _educationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _locationController = TextEditingController();

  final MarketplaceService _marketplaceService = MarketplaceService();
  final ImagePicker _picker = ImagePicker();

  String _category = 'Plumber';
  String _gender = 'Male';
  File? _imageFile;
  bool _isUploading = false;

  final List<String> _categories = [
    'Plumber',
    'Electrician',
    'Carpenter',
    'AC Technician',
    'Mechanic',
    'Doctor',
    'Painter',
    'Mason',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _educationController.dispose();
    _experienceController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _openImagePreview() {
    if (_imageFile == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ZoomableImagePreview(imageFile: _imageFile!),
      ),
    );
  }

  Future<void> _submitService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isUploading = true);

    try {
      String imageUrl = '';
      if (_imageFile != null) {
        imageUrl = await _marketplaceService.uploadImageToCloudinary(_imageFile!);
      }

      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'anonymous';
      final userEmail = user?.email ?? '';
      final userName = user?.displayName ?? user?.email ?? 'Anonymous User';

      final serviceData = {
        'name': _nameController.text.trim(),
        'profession': _professionController.text.trim(),
        'category': _category,
        'education': _educationController.text.trim(),
        'gender': _gender,
        'experienceYears': int.tryParse(_experienceController.text.trim()) ?? 0,
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'phone': _contactController.text.trim(),
        'location': _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : 'Local Area',
        'imageUrl': imageUrl,
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('local_services').add(serviceData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service listed successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add service: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Local Service'),
        backgroundColor: const Color(0xFF252A34),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF08D9D6)),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF252A34),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture (DP) Upload Circle
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _imageFile != null ? _openImagePreview : _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: const Color(0xFF2A303C),
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : null,
                              child: _imageFile == null
                                  ? const Icon(
                                      Icons.add_a_photo,
                                      color: Color(0xFF08D9D6),
                                      size: 32,
                                    )
                                  : null,
                            ),
                            if (_imageFile != null)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF08D9D6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.black,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _imageFile == null
                            ? 'Tap to upload profile picture'
                            : 'Tap image to zoom preview',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Full Name'),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 16),

                // Profession
                TextFormField(
                  controller: _professionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Profession / Specialization'),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Enter profession'
                      : null,
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  dropdownColor: const Color(0xFF2A303C),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Category'),
                  items: _categories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _category = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Education
                TextFormField(
                  controller: _educationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Education / Certification'),
                ),
                const SizedBox(height: 16),

                // Gender Selector
                const Text(
                  'Gender',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['Male', 'Female'].map((g) {
                    final isSelected = _gender == g;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _gender = g),
                        child: Container(
                          margin: EdgeInsets.only(
                              right: g == 'Male' ? 8.0 : 0.0,
                              left: g == 'Female' ? 8.0 : 0.0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF08D9D6)
                                : const Color(0xFF2A303C),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF08D9D6)
                                  : Colors.white10,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            g,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Experience & Age in Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _experienceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Experience (Years)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Age'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location / Area
                TextFormField(
                  controller: _locationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Location / Area'),
                ),
                const SizedBox(height: 16),

                // Contact Number
                TextFormField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Contact Number'),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Enter contact number'
                      : null,
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _submitService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08D9D6),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Submit Service',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

class _ZoomableImagePreview extends StatelessWidget {
  final File imageFile;

  const _ZoomableImagePreview({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.file(
                imageFile,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
