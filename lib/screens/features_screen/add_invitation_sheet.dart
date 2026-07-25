import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:muhallah/features/bill_reminder/services/cloudinary_service.dart';

class AddInvitationSheet extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String? initialCategoryCode;

  const AddInvitationSheet({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    this.initialCategoryCode,
  });

  @override
  State<AddInvitationSheet> createState() => _AddInvitationSheetState();
}

class _AddInvitationSheetState extends State<AddInvitationSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Image Upload
  XFile? _selectedImage;
  Uint8List? _pickedImageBytes;

  // Categories Mapping
  final List<Map<String, String>> _categoryOptions = [
    {'code': 'wedding', 'label': 'Shaadi / Valima'},
    {'code': 'dua_khawani', 'label': 'Dua / Qur\'an Khawani'},
    {'code': 'mehndi_dholki', 'label': 'Mehndi / Dholki'},
    {'code': 'aqeeqa_bismillah', 'label': 'Aqeeqa / Bismillah'},
    {'code': 'condolence_majlis', 'label': 'Condolence / Majlis'},
    {'code': 'community_event', 'label': 'Community Events'},
  ];

  late String _selectedCategory;

  // Common Field Controllers
  final _titleController = TextEditingController();
  final _venueController = TextEditingController();
  final _mapLocationController = TextEditingController(); // TODO: Add actual map picker
  final _descriptionController = TextEditingController();
  DateTime? _selectedDateTime;

  // Category-specific controllers (dynamic map to hold values)
  final Map<String, TextEditingController> _dynamicControllers = {};
  bool _rsvpEnabled = false;
  bool _genderSpecificSessions = false;
  String _occasionType = 'Aqeeqa';
  String _eventType = 'Sports';

  // Colors based on Rishta dark theme
  final Color _primaryColor = const Color(0xFF08d9d6);
  final Color _darkBackground = const Color(0xFF252a34);
  final Color _darkCardColor = const Color(0xFF2a303c);
  final Color _darkTextColor = const Color(0xFFe0e0e0);
  final Color _darkSecondaryText = const Color(0xFF9e9e9e);

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategoryCode ?? 'wedding';
    _initDynamicControllers();
  }

  void _initDynamicControllers() {
    // Clear and initialize needed controllers
    for (var controller in _dynamicControllers.values) {
      controller.dispose();
    }
    _dynamicControllers.clear();

    final keys = _getFieldsForCategory(_selectedCategory);
    for (var key in keys) {
      _dynamicControllers[key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _mapLocationController.dispose();
    _descriptionController.dispose();
    for (var controller in _dynamicControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> _getFieldsForCategory(String category) {
    switch (category) {
      case 'wedding':
        return ['groomName', 'brideName', 'venueTime', 'religiousQuote'];
      case 'dua_khawani':
        return ['duaPurpose', 'venueDetails', 'religiousQuote'];
      case 'mehndi_dholki':
        return ['dressCode', 'entertainmentInfo', 'hostName'];
      case 'aqeeqa_bismillah':
        return ['childName', 'fatherName', 'motherName'];
      case 'condolence_majlis':
        return ['marhoomName', 'majlisDetails', 'religiousVerses', 'organizerContact'];
      case 'community_event':
        return ['purpose', 'organizerDetails'];
      default:
        return [];
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
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
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Date & Time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String coverImageUrl = '';
      if (_selectedImage != null) {
        coverImageUrl = await CloudinaryService.uploadBillImage(_selectedImage!) ?? '';
      }

      // Collect category-specific data
      Map<String, dynamic> categoryData = {};
      for (var entry in _dynamicControllers.entries) {
        categoryData[entry.key] = entry.value.text.trim();
      }

      // Add booleans & dropdowns based on category
      if (_selectedCategory == 'wedding') {
        categoryData['rsvpEnabled'] = _rsvpEnabled;
        categoryData['genderSpecificSessions'] = _genderSpecificSessions;
      } else if (_selectedCategory == 'dua_khawani') {
        categoryData['genderSpecificSessions'] = _genderSpecificSessions;
      } else if (_selectedCategory == 'aqeeqa_bismillah') {
        categoryData['occasionType'] = _occasionType;
      } else if (_selectedCategory == 'community_event') {
        categoryData['eventType'] = _eventType;
      }

      final docData = {
        'category': _selectedCategory,
        'title': _titleController.text.trim(),
        'dateTime': Timestamp.fromDate(_selectedDateTime!),
        'venue': _venueController.text.trim(),
        'mapLocation': _mapLocationController.text.trim(), // Can be converted to GeoPoint later
        'description': _descriptionController.text.trim(),
        'coverImageUrl': coverImageUrl,
        'postedBy': widget.currentUserId,
        'postedByName': widget.currentUserName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'categoryData': categoryData,
      };

      await FirebaseFirestore.instance.collection('invitations').add(docData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating invitation: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: _darkBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategorySelector(),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    Text(
                      'Common Details',
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCommonFields(),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    Text(
                      'Event Specific Details',
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCategorySpecificFields(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _darkCardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Create Invitation',
            style: TextStyle(
              color: _darkTextColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: _darkTextColor),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Category',
          style: TextStyle(
            color: _darkTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          dropdownColor: _darkCardColor,
          items: _categoryOptions.map((cat) {
            return DropdownMenuItem(
              value: cat['code'],
              child: Text(cat['label']!, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null && val != _selectedCategory) {
              setState(() {
                _selectedCategory = val;
                _initDynamicControllers();
              });
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: _darkCardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCommonFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _titleController,
          label: 'Invitation Title',
          hint: 'e.g. Ali & Fatima Wedding',
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        // DateTime Picker
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date & Time',
              style: TextStyle(
                color: _darkTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _darkCardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: _primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDateTime != null
                          ? '${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year} at ${_selectedDateTime!.hour}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}'
                          : 'Select Date & Time',
                      style: TextStyle(
                        color: _selectedDateTime != null ? Colors.white : _darkSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _venueController,
          label: 'Venue / Location',
          hint: 'e.g. Grand Palace Hotel',
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _mapLocationController,
          label: 'Map Location Link (Optional)',
          hint: 'e.g. Google Maps link',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: 'Description / Message',
          hint: 'Add a short message for your guests',
          maxLines: 3,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildPhotoUploadSection(),
      ],
    );
  }

  Widget _buildPhotoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cover Image (Optional)',
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
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _darkCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _primaryColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: _pickedImageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      _pickedImageBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          color: _primaryColor,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add cover image',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 14,
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

  Widget _buildCategorySpecificFields() {
    List<Widget> fields = [];

    // Names
    if (_selectedCategory == 'wedding') {
      fields.add(_buildTextField(controller: _dynamicControllers['groomName']!, label: 'Groom Name'));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildTextField(controller: _dynamicControllers['brideName']!, label: 'Bride Name'));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildTextField(controller: _dynamicControllers['venueTime']!, label: 'Specific Venue Time (Optional)', hint: 'If different from main event time'));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildSwitch(label: 'Enable RSVP', value: _rsvpEnabled, onChanged: (v) => setState(() => _rsvpEnabled = v)));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildSwitch(label: 'Separate Gender Sessions', value: _genderSpecificSessions, onChanged: (v) => setState(() => _genderSpecificSessions = v)));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildTextField(controller: _dynamicControllers['religiousQuote']!, label: 'Religious Quote (Optional)', maxLines: 2));
    } else if (_selectedCategory == 'dua_khawani') {
      fields.add(_buildTextField(controller: _dynamicControllers['duaPurpose']!, label: 'Purpose (Niyat)'));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildTextField(controller: _dynamicControllers['venueDetails']!, label: 'Specific Venue Details (Optional)', maxLines: 2));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildSwitch(label: 'Separate Gender Sessions', value: _genderSpecificSessions, onChanged: (v) => setState(() => _genderSpecificSessions = v)));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildTextField(controller: _dynamicControllers['religiousQuote']!, label: 'Ayat / Dua Text (Optional)', maxLines: 2));
    } else if (_selectedCategory == 'mehndi_dholki') {
      fields.add(_buildTextField(controller: _dynamicControllers['dressCode']!, label: 'Dress Code / Colors'));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildTextField(controller: _dynamicControllers['entertainmentInfo']!, label: 'Entertainment Info (e.g. Dhol, Dance)'));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildTextField(controller: _dynamicControllers['hostName']!, label: 'Host Name'));
    } else if (_selectedCategory == 'aqeeqa_bismillah') {
      fields.add(_buildTextField(controller: _dynamicControllers['childName']!, label: 'Child Name'));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildTextField(controller: _dynamicControllers['fatherName']!, label: 'Father Name'));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildTextField(controller: _dynamicControllers['motherName']!, label: 'Mother Name'));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildDropdown(
        label: 'Occasion Type',
        value: _occasionType,
        items: const ['Aqeeqa', 'Bismillah'],
        onChanged: (v) => setState(() => _occasionType = v!),
      ));
    } else if (_selectedCategory == 'condolence_majlis') {
      fields.add(_buildTextField(controller: _dynamicControllers['marhoomName']!, label: 'Marhoom Name (Deceased)'));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildTextField(controller: _dynamicControllers['majlisDetails']!, label: 'Majlis Details (Optional)', maxLines: 2));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildTextField(controller: _dynamicControllers['religiousVerses']!, label: 'Religious Verses (Optional)', maxLines: 2));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildTextField(controller: _dynamicControllers['organizerContact']!, label: 'Organizer Contact'));
    } else if (_selectedCategory == 'community_event') {
      fields.add(_buildDropdown(
        label: 'Event Type',
        value: _eventType,
        items: const ['Sports', 'Meeting', 'Festival', 'Other'],
        onChanged: (v) => setState(() => _eventType = v!),
      ));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildTextField(controller: _dynamicControllers['purpose']!, label: 'Purpose', maxLines: 2));
      fields.add(const SizedBox(height: 16));
      fields.add(_buildTextField(controller: _dynamicControllers['organizerDetails']!, label: 'Organizer Details'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
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
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _darkSecondaryText),
            filled: true,
            fillColor: _darkCardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _darkTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: _primaryColor,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
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
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: _darkCardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(_primaryColor),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        onPressed: _isLoading ? null : _submitForm,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Create Invitation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
