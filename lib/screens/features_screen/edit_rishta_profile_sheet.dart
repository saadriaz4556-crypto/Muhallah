import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muhallah/features/bill_reminder/services/cloudinary_service.dart';

class EditRishtaProfileSheet extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditRishtaProfileSheet({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<EditRishtaProfileSheet> createState() => _EditRishtaProfileSheetState();
}

class _EditRishtaProfileSheetState extends State<EditRishtaProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  XFile? _selectedImage;
  Uint8List? _pickedImageBytes;

  // Form controllers
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _professionController;
  late final TextEditingController _educationController;
  late final TextEditingController _cityController;
  late final TextEditingController _shortIntroController;
  late final TextEditingController _familyBackgroundController;
  late final TextEditingController _casteController;
  late final TextEditingController _heightController;
  late final TextEditingController _partnerExpectationsController;
  late final TextEditingController _contactNumberController;

  late String _selectedGender;
  late String _selectedMaritalStatus;
  late String _selectedComplexion;
  late String _selectedSect;
  late String _currentPhotoUrl;

  final Color _primaryColor = const Color(0xFF08d9d6);
  final Color _darkBackground = const Color(0xFF252a34);
  final Color _darkCardColor = const Color(0xFF2a303c);
  final Color _darkTextColor = const Color(0xFFe0e0e0);
  final Color _darkSecondaryText = const Color(0xFF9e9e9e);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.data['name'] ?? '');
    _ageController =
        TextEditingController(text: (widget.data['age'] ?? '').toString());
    _professionController =
        TextEditingController(text: widget.data['profession'] ?? '');
    _educationController =
        TextEditingController(text: widget.data['education'] ?? '');
    _cityController = TextEditingController(text: widget.data['city'] ?? '');
    _shortIntroController =
        TextEditingController(text: widget.data['shortIntro'] ?? '');
    _familyBackgroundController =
        TextEditingController(text: widget.data['familyBackground'] ?? '');
    _casteController = TextEditingController(text: widget.data['caste'] ?? '');
    _heightController =
        TextEditingController(text: widget.data['height'] ?? '');
    _partnerExpectationsController =
        TextEditingController(text: widget.data['partnerExpectations'] ?? '');
    _contactNumberController =
        TextEditingController(text: widget.data['contactNumber'] ?? '');

    _selectedGender = _normalizeGender(widget.data['gender'] ?? 'Male');
    _selectedMaritalStatus = _normalizeMaritalStatus(widget.data['maritalStatus'] ?? 'Single');
    _selectedComplexion = widget.data['complexion'] ?? 'Fair';
    _selectedSect = widget.data['sect'] ?? 'Sunni';
    _currentPhotoUrl = widget.data['photoUrl'] ?? '';
  }

  /// Normalise legacy Firestore values to new labels.
  String _normalizeGender(String value) {
    if (value == 'Brother') return 'Male';
    if (value == 'Sister') return 'Female';
    return value;
  }

  String _normalizeMaritalStatus(String value) {
    if (value == 'Never Married') return 'Single';
    return value;
  }

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
      String photoUrl = _currentPhotoUrl;

      // Upload new photo if selected
      if (_selectedImage != null) {
        photoUrl = await CloudinaryService.uploadBillImage(_selectedImage!) ??
            _currentPhotoUrl;
      }

      // Update to Firestore
      await FirebaseFirestore.instance
          .collection('rishta_profiles')
          .doc(widget.docId)
          .update({
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
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
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
                            'Edit Rishta Profile',
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
                              if (value?.isEmpty ?? true) {
                                return 'Name is required';
                              }
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
                              if (value?.isEmpty ?? true) {
                                return 'Age is required';
                              }
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
                              if (value?.isEmpty ?? true) {
                                return 'Profession is required';
                              }
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
                              if (value?.isEmpty ?? true) {
                                return 'Education is required';
                              }
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
                              if (value?.isEmpty ?? true) {
                                return 'City is required';
                              }
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
                              if (value?.isEmpty ?? true) {
                                return 'Short intro is required';
                              }
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
                              if (value?.isEmpty ?? true) {
                                return 'Contact number is required';
                              }
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
                                      'Save Changes',
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
    // Determine what to show in the circular preview
    final bool hasNewImage = _selectedImage != null;
    final bool hasExistingPhoto = _currentPhotoUrl.isNotEmpty;
    final bool showingAPhoto = hasNewImage || hasExistingPhoto;

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
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular photo / placeholder
              Container(
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: (_pickedImageBytes != null)
                      // Newly picked local file — use Image.memory, not Image.file
                      ? Image.memory(
                          _pickedImageBytes!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.camera_alt,
                              color: _primaryColor,
                              size: 40,
                            );
                          },
                        )
                      : hasExistingPhoto
                          // Existing Cloudinary URL
                          ? Image.network(
                              _currentPhotoUrl,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: _primaryColor,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.camera_alt,
                                  color: _primaryColor,
                                  size: 40,
                                );
                              },
                            )
                          // No photo yet
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
              // Camera icon overlay when a photo is already showing
              if (showingAPhoto)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: _darkCardColor, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showingAPhoto)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Tap to change photo',
              style: TextStyle(
                color: _darkSecondaryText,
                fontSize: 11,
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
          initialValue: value,
          dropdownColor: _darkCardColor,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 14),
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
