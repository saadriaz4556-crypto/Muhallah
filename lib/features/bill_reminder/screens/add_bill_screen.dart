import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../controllers/bill_controller.dart';
import '../models/bill_model.dart';
import '../services/cloudinary_service.dart';

class AddBillScreen extends StatefulWidget {
  const AddBillScreen({super.key});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  // Form data
  String selectedBillType = '';
  String? customBillName;
  double? amount;
  DateTime? dueDate;
  int reminderDaysBefore = 3;
  String? billImageUrl; // Cloudinary URL
  bool isUploading = false;

  // Errors
  String? billTypeError;
  String? amountError;
  String? dueDateError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F36),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F36),
        elevation: 0,
        title: const Text('Add Bill', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Bill Information
            const Text(
              'Bill Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),

            // Bill Type Selector
            _buildBillTypeSelector(),
            if (billTypeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(billTypeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 20),

            // Custom Name (if Custom selected)
            if (selectedBillType == 'Custom') ...[
              _buildTextField(
                label: 'Bill Name',
                placeholder: 'e.g., School Fee',
                onChanged: (val) => customBillName = val,
              ),
              const SizedBox(height: 20),
            ],

            // Amount
            _buildTextField(
              label: 'Amount (PKR)',
              placeholder: '0',
              keyboardType: TextInputType.number,
              onChanged: (val) {
                try {
                  amount = double.parse(val);
                  setState(() => amountError = null);
                } catch (e) {
                  amount = null;
                }
              },
            ),
            if (amountError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(amountError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 20),

            // Due Date
            GestureDetector(
              onTap: _selectDueDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF252C42),
                  border: Border.all(
                    color: dueDateError != null ? Colors.red : Colors.grey.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Due Date', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          dueDate != null
                              ? DateFormat('d MMMM, yyyy').format(dueDate!)
                              : 'Select date',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                    const Icon(Icons.calendar_today, color: Color(0xFF00BCD4)),
                  ],
                ),
              ),
            ),
            if (dueDateError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(dueDateError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 32),

            // Section 2: Bill Image Upload
            const Text(
              'Upload Bill Image (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload bill photo - AI will auto-detect date and amount (optional)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),

            if (billImageUrl == null)
              _buildUploadImageButton()
            else
              _buildImagePreview(),

            const SizedBox(height: 32),

            // Section 3: Reminder
            const Text(
              'When should we remind you?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildReminderSelector(),
            const SizedBox(height: 40),

            // Save Button
            ElevatedButton(
              onPressed: _saveBill,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save & Set Reminder',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBillTypeSelector() {
    final types = ['Electricity', 'Gas', 'Water', 'Internet', 'Phone', 'Rent', 'Custom'];
    return SizedBox(
      height: 45,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: types.map((type) {
          final isSelected = selectedBillType == type;
          return GestureDetector(
            onTap: () => setState(() {
              selectedBillType = type;
              billTypeError = null;
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFF252C42),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00BCD4) : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Text(
                  type,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
  }) {
    return TextField(
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        labelStyle: const TextStyle(color: Colors.grey),
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF252C42),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF00BCD4)),
        ),
      ),
    );
  }

  Widget _buildUploadImageButton() {
    return ElevatedButton.icon(
      onPressed: isUploading ? null : _pickAndUploadImage,
      icon: isUploading 
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00BCD4)))
        : const Icon(Icons.photo_camera),
      label: Text(isUploading ? 'Uploading...' : '📷 Upload Bill Image'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: const Color(0xFF00BCD4).withOpacity(0.1),
        foregroundColor: const Color(0xFF00BCD4),
        side: const BorderSide(color: Color(0xFF00BCD4), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF252C42),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  billImageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('Image loaded', style: TextStyle(color: Colors.grey)),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => billImageUrl = null),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
            SizedBox(width: 4),
            Text(
              'Image uploaded to cloud',
              style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReminderSelector() {
    final options = [
      {'label': '30 Min', 'value': 0},
      {'label': '1 Day', 'value': 1},
      {'label': '3 Days', 'value': 3},
      {'label': '7 Days', 'value': 7},
    ];

    return Row(
      children: options.map((option) {
        final isSelected = reminderDaysBefore == option['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => reminderDaysBefore = option['value'] as int),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFF252C42),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00BCD4) : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Text(
                  option['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00BCD4),
              onPrimary: Colors.black,
              surface: Color(0xFF1A1F36),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => dueDate = date);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (file == null) return;

      setState(() => isUploading = true);

      // Upload to Cloudinary (EXACT same method as registration)
      final url = await CloudinaryService.uploadBillImage(file);

      if (url != null) {
        setState(() {
          billImageUrl = url;
          isUploading = false;
        });
        
        Get.snackbar(
          '✅ Image Uploaded!',
          'Image saved to cloud: ${file.name}',
          backgroundColor: const Color(0xFF4CAF50),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        setState(() => isUploading = false);
        Get.snackbar(
          '❌ Upload Failed',
          'Cloudinary upload failed. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      setState(() => isUploading = false);
      Get.snackbar(
        '❌ Image Picker Error',
        'Error picking image: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _saveBill() {
    // Validation
    if (selectedBillType.isEmpty) {
      setState(() => billTypeError = 'Select bill type');
      return;
    }

    if (amount == null || amount! <= 0) {
      setState(() => amountError = 'Enter valid amount');
      return;
    }

    if (dueDate == null) {
      setState(() => dueDateError = 'Select due date');
      return;
    }

    // Create bill
    final bill = BillModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      billType: selectedBillType,
      customBillName: customBillName,
      amount: amount!,
      dueDate: dueDate!,
      reminderDaysBefore: reminderDaysBefore,
      createdAt: DateTime.now(),
      billImageUrl: billImageUrl, // Cloudinary URL
      dueDateAutoDetected: false,
      amountAutoDetected: false,
    );

    // Get controller and save
    final controller = Get.find<BillController>();
    controller.addBill(bill).then((success) {
      if (success) {
        Get.back();
      }
    });
  }
}
