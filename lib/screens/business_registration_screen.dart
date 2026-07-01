import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muhallah/models/business_model.dart';
import 'package:muhallah/services/business_service.dart';
import 'package:muhallah/features/bill_reminder/services/cloudinary_service.dart';

// Match app theme colors
const Color deepNavy = Color(0xFF252A34);
const Color sectionBg = Color(0xFF2A303C);
const Color inputBg = Color(0xFF3A4250);
const Color teal = Color(0xFF08D9D6);
const Color coral = Color(0xFFFF2E63);
const Color whiteish = Color(0xFFEAEAEA);
const Color successGreen = Color(0xFF10B981);

const LinearGradient primaryGradient = LinearGradient(
  colors: [Color(0xFF08D9D6), Color(0xFF00B4B2)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class BusinessRegistrationScreen extends StatefulWidget {
  final BusinessModel? existingBusiness;
  final String? documentId;

  const BusinessRegistrationScreen({
    super.key,
    this.existingBusiness,
    this.documentId,
  });

  @override
  State<BusinessRegistrationScreen> createState() => _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState extends State<BusinessRegistrationScreen> {
  int _step = 1;

  // Step 1: Category selection
  String? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {
      'key': 'Dukaan/Shop',
      'icon': Icons.storefront,
      'desc': 'kiryana, bakery, fruit, meat, sweet shop'
    },
    {
      'key': 'Medical/Health',
      'icon': Icons.local_hospital,
      'desc': 'pharmacy, clinic, dentist, lab, hakeem'
    },
    {
      'key': 'Food & Restaurant',
      'icon': Icons.restaurant,
      'desc': 'hotel, dhaba, tiffin, juice corner'
    },
    {
      'key': 'Services/Kaam',
      'icon': Icons.construction,
      'desc': 'electrician, plumber, carpenter, AC repair'
    },
    {
      'key': 'Beauty & Grooming',
      'icon': Icons.content_cut,
      'desc': 'saloon, parlour, tailor/darzi'
    },
    {
      'key': 'Education',
      'icon': Icons.school,
      'desc': 'tuition, Quran teacher, computer institute'
    },
    {
      'key': 'Transport',
      'icon': Icons.directions_car,
      'desc': 'rickshaw, car wash, puncture, tyre shop'
    },
    {
      'key': 'Property/Rent',
      'icon': Icons.home,
      'desc': 'property dealer, rental rooms'
    },
    {
      'key': 'Others',
      'icon': Icons.more_horiz,
      'desc': 'dairy, laundry, event organizer'
    },
  ];

  // Step 2: Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _subCategoryController = TextEditingController();
  
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;
  bool _homeDelivery = false;

  // Step 3: Photo
  XFile? _imageFile;
  String? _imageUrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingBusiness != null) {
      final bus = widget.existingBusiness!;
      _selectedCategory = bus.category;
      _businessNameController.text = bus.businessName;
      _ownerNameController.text = bus.ownerName;
      _addressController.text = bus.address;
      _phoneController.text = bus.phone;
      _whatsappController.text = bus.whatsapp;
      _subCategoryController.text = bus.subCategory;
      _homeDelivery = bus.homeDelivery;
      _imageUrl = bus.imageUrl;
      
      _openTime = _parseTime(bus.openTime);
      _closeTime = _parseTime(bus.closeTime);
    }
  }

  TimeOfDay? _parseTime(String timeStr) {
    if (timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      debugPrint('Error parsing time string $timeStr: $e');
    }
    return null;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _subCategoryController.dispose();
    super.dispose();
  }

  void _selectCategory(String key) {
    setState(() => _selectedCategory = key);
  }

  Future<void> _pickTime(bool isOpen) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: teal,
            onPrimary: deepNavy,
            surface: sectionBg,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: deepNavy),
        ),
        child: child!,
      ),
    );
    if (t != null) {
      setState(() {
        if (isOpen) {
          _openTime = t;
        } else {
          _closeTime = t;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          _imageFile = file;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload image using Cloudinary Service if present
      if (_imageFile != null) {
        final uploaded = await CloudinaryService.uploadBillImage(_imageFile!);
        if (uploaded != null) {
          _imageUrl = uploaded;
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? '';

      // 2. Prepare model
      final model = BusinessModel(
        userId: uid,
        businessName: _businessNameController.text.trim(),
        category: _selectedCategory ?? '',
        subCategory: _subCategoryController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        openTime: _formatTime(_openTime),
        closeTime: _formatTime(_closeTime),
        homeDelivery: _homeDelivery,
        imageUrl: _imageUrl ?? '',
        createdAt: Timestamp.now(),
      );

      // 3. Save to Firestore
      if (widget.documentId != null) {
        await FirebaseFirestore.instance
            .collection('businesses')
            .doc(widget.documentId)
            .update(model.toMap());
      } else {
        await BusinessService.createBusiness(model);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Business registered! Ab directory mein visible hai.'),
        backgroundColor: successGreen,
      ));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: coral,
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _validateStep2() {
    if (!_formKey.currentState!.validate()) return;
    if (_openTime == null || _closeTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select opening and closing times'),
        backgroundColor: coral,
      ));
      return;
    }
    setState(() => _step = 3);
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.documentId != null ? 'Edit Your Business' : 'Register Your Business';
    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        title: Text(titleText),
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
          onPressed: () {
            if (_step > 1) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Category',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select the category that best represents your business',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final key = cat['key'] as String;
              final icon = cat['icon'] as IconData;
              final desc = cat['desc'] as String;
              final selected = _selectedCategory == key;

              return InkWell(
                onTap: () => _selectCategory(key),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected ? teal.withValues(alpha: 0.1) : sectionBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? teal : Colors.white12,
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: teal.withValues(alpha: 0.2), blurRadius: 8)]
                        : [],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: selected ? teal : Colors.white70, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        key,
                        style: TextStyle(
                          color: selected ? teal : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? teal.withValues(alpha: 0.7) : Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _selectedCategory == null ? null : () => setState(() => _step = 2),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: deepNavy,
                disabledBackgroundColor: Colors.white12,
                disabledForegroundColor: Colors.white30,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Business Details',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  _fieldLabel('Business Name *'),
                  _textInput(_businessNameController, hint: 'Enter business name', validator: _requiredValidator),
                  const SizedBox(height: 16),

                  _fieldLabel('Owner Name *'),
                  _textInput(_ownerNameController, hint: 'Enter owner name', validator: _requiredValidator),
                  const SizedBox(height: 16),

                  _fieldLabel('Address in Muhallah *'),
                  _textInput(_addressController, hint: 'e.g. Street 3, Block B', validator: _requiredValidator),
                  const SizedBox(height: 16),

                  _fieldLabel('Phone Number *'),
                  _textInput(
                    _phoneController,
                    hint: '0300-1234567',
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.replaceAll(RegExp(r'\D'), '').length < 11) return 'Enter 11-digit phone number';
                      return null;
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                      _PakistaniPhoneFormatter(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('WhatsApp Number (Optional)'),
                  _textInput(_whatsappController, hint: 'e.g. 0300-1234567'),
                  const SizedBox(height: 16),

                  _fieldLabel('Sub-category / Items or Services *'),
                  _textInput(
                    _subCategoryController,
                    hint: 'Example: Fresh fruits, vegetables, seasonal items',
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('Business Hours *'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePickerTile(
                          label: 'Opening Time',
                          time: _openTime,
                          onTap: () => _pickTime(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimePickerTile(
                          label: 'Closing Time',
                          time: _closeTime,
                          onTap: () => _pickTime(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: sectionBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Home Delivery Available',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Switch(
                          value: _homeDelivery,
                          onChanged: (v) => setState(() => _homeDelivery = v),
                          activeThumbColor: teal,
                          activeTrackColor: teal.withValues(alpha: 0.3),
                          inactiveThumbColor: Colors.white30,
                          inactiveTrackColor: Colors.white10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _step = 1),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: _validateStep2,
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: deepNavy,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Optional Shop Photo',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Add a photo of your storefront to make it stand out in the directory',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              if (_imageFile != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _imageFile!.path,
                    height: 180,
                    width: 280,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        width: 280,
                        color: sectionBg,
                        child: const Icon(Icons.broken_image, color: Colors.white30, size: 48),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (_imageUrl != null && _imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _imageUrl!,
                    height: 180,
                    width: 280,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        width: 280,
                        color: sectionBg,
                        child: const Icon(Icons.broken_image, color: Colors.white30, size: 48),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_camera, color: teal),
                label: Text(
                  (_imageFile == null && (_imageUrl == null || _imageUrl!.isEmpty))
                      ? 'Add Shop Photo'
                      : 'Change Shop Photo',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: teal),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _step = 2),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: deepNavy,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: deepNavy),
                    )
                  : const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: whiteish,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _textInput(
    TextEditingController controller, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: whiteish, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          border: InputBorder.none,
          errorStyle: const TextStyle(color: coral, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildTimePickerTile({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: teal, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time != null ? time.format(context) : 'Not set',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }
}

class _PakistaniPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    String formatted;
    if (limited.length <= 4) {
      formatted = limited;
    } else {
      formatted = '${limited.substring(0, 4)}-${limited.substring(4)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
