import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muhallah/features/bill_reminder/services/cloudinary_service.dart';

class AddRishtaProfileSheet extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;

  const AddRishtaProfileSheet({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<AddRishtaProfileSheet> createState() => _AddRishtaProfileSheetState();
}

class _AddRishtaProfileSheetState extends State<AddRishtaProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  XFile? _selectedImage;       // kept for Cloudinary upload
  Uint8List? _pickedImageBytes; // used for cross-platform local preview
  String? _uploadedPhotoUrl;

  // Form controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _professionController = TextEditingController();
  final _educationController = TextEditingController();
  final _cityController = TextEditingController();
  final _shortIntroController = TextEditingController();
  final _familyBackgroundController = TextEditingController();
  final _casteController = TextEditingController();
  final _heightController = TextEditingController();
  final _partnerExpectationsController = TextEditingController();
  final _contactNumberController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedMaritalStatus = 'Single';
  String _selectedComplexion = 'Fair';
  String _selectedSect = 'Sunni';

  final Color _primaryColor = const Color(0xFF08d9d6);
  final Color _darkBackground = const Color(0xFF252a34);
  final Color _darkCardColor = const Color(0xFF2a303c);
  final Color _darkTextColor = const Color(0xFFe0e0e0);
  final Color _darkSecondaryText = const Color(0xFF9e9e9e);

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _professionController.dispose();
    _educationController.dispose();
    _cityController.dispose();
    _shortIntroController.dispose();
    _familyBackgroundController.dispose();
    _casteController.dispose();
    _heightController.dispose();
    _partnerExpectationsController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      // Read bytes immediately — works on Web + Mobile (no dart:io File needed)
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = pickedFile;
        _pickedImageBytes = bytes;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload photo to Cloudinary if selected
      String photoUrl = '';
      if (_selectedImage != null) {
        photoUrl =
            await CloudinaryService.uploadBillImage(_selectedImage!) ?? '';
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection('rishta_profiles').add({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'gender': _selectedGender,
        'profession': _professionController.text.trim(),
        'education': _educationController.text.trim(),
        'city': _cityController.text.trim(),
        'shortIntro': _shortIntroController.text.trim(),
        'maritalStatus': _selectedMaritalStatus,
        'familyBackground': _familyBackgroundController.text.trim(),
        'caste': _casteController.text.trim(),
        'height': _heightController.text.trim(),
        'complexion': _selectedComplexion,
        'sect': _selectedSect,
        'partnerExpectations': _partnerExpectationsController.text.trim(),
        'contactNumber': _contactNumberController.text.trim(),
        'photoUrl': photoUrl,
        'postedBy': widget.currentUserId,
        'postedByName': widget.currentUserName,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rishta profile posted successfully!'),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _darkBackground,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: _darkCardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _darkSecondaryText,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add Rishta Profile',
                            style: TextStyle(
                              color: _darkTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(
                              Icons.close,
                              color: _darkSecondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo Upload
                          _buildPhotoUploadSection(),
                          const SizedBox(height: 20),
                          // Name
                          _buildTextField(
                            controller: _nameController,
                            label: 'Name *',
                            hint: 'Enter your name',
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Name is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Age
                          _buildTextField(
                            controller: _ageController,
                            label: 'Age *',
                            hint: 'Enter your age',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Age is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Gender
                          _buildDropdown(
                            label: 'Gender *',
                            value: _selectedGender,
                            items: ['Male', 'Female'],
                            onChanged: (value) {
                              setState(() => _selectedGender = value!);
                            },
                          ),
                          const SizedBox(height: 16),
                          // Profession
                          _buildTextField(
                            controller: _professionController,
                            label: 'Profession/Occupation *',
                            hint: 'Enter your profession',
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Profession is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Education
                          _buildTextField(
                            controller: _educationController,
                            label: 'Education *',
                            hint: 'Enter your education level',
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Education is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // City
                          _buildTextField(
                            controller: _cityController,
                            label: 'City/Location *',
                            hint: 'Enter your city',
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'City is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Short Intro
                          _buildTextField(
                            controller: _shortIntroController,
                            label: 'Short Intro *',
                            hint:
                                'A brief intro about yourself or your family...',
                            maxLines: 2,
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Short intro is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Marital Status
                          _buildDropdown(
                            label: 'Marital Status',
                            value: _selectedMaritalStatus,
                            items: [
                              'Single',
                              'Divorced',
                              'Widow/Widower'
                            ],
                            onChanged: (value) {
                              setState(() => _selectedMaritalStatus = value!);
                            },
                          ),
                          const SizedBox(height: 16),
                          // Family Background
                          _buildTextField(
                            controller: _familyBackgroundController,
                            label: 'Family Background',
                            hint: 'Describe your family background...',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          // Caste
                          _buildTextField(
                            controller: _casteController,
                            label: 'Caste/Biradari',
                            hint: 'Optional - e.g. Rajput, Jatt, Syed...',
                          ),
                          const SizedBox(height: 16),
                          // Height
                          _buildTextField(
                            controller: _heightController,
                            label: 'Height',
                            hint: 'e.g. 5\'6"',
                          ),
                          const SizedBox(height: 16),
                          // Complexion
                          _buildDropdown(
                            label: 'Complexion',
                            value: _selectedComplexion,
                            items: ['Fair', 'Medium', 'Wheatish', 'Dark', 'None'],
                            onChanged: (value) {
                              setState(() => _selectedComplexion = value!);
                            },
                          ),
                          const SizedBox(height: 16),
                          // Sect
                          _buildDropdown(
                            label: 'Sect',
                            value: _selectedSect,
                            items: [
                              'Sunni',
                              'Shia',
                              'Other',
                              'Prefer not to say'
                            ],
                            onChanged: (value) {
                              setState(() => _selectedSect = value!);
                            },
                          ),
                          const SizedBox(height: 16),
                          // Partner Expectations
                          _buildTextField(
                            controller: _partnerExpectationsController,
                            label: 'Partner Expectations',
                            hint: 'Age range, education, values you prefer...',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          // Contact Number
                          _buildTextField(
                            controller: _contactNumberController,
                            label: 'Contact Number *',
                            hint: 'Family/Guardian contact number',
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Contact number is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          // Submit Button
                          _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                      color: _primaryColor),
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Post Profile',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 12),
                          // Cancel Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryColor,
                                side: BorderSide(color: _primaryColor),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Photo (Optional)',
          style: TextStyle(
            color: _darkTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: _darkBackground,
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: _primaryColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: _pickedImageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    // Image.memory works on Web + Mobile — no dart:io File needed
                    child: Image.memory(
                      _pickedImageBytes!,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          color: _primaryColor,
                          size: 40,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _darkTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(color: _darkTextColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _darkSecondaryText),
            filled: true,
            fillColor: _darkBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: _primaryColor.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: _primaryColor.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _primaryColor),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _darkTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: _darkCardColor,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(color: Colors.white),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          style: TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: _darkBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: _primaryColor.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: _primaryColor.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _primaryColor),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
