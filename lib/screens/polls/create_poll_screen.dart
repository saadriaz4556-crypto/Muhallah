import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/poll_model.dart';
import '../../services/polls_service.dart';

class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({super.key});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pollsService = PollsService();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  String _pollType = 'single';
  String _targetAudience = 'All Residents';
  bool _isAnonymous = false;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF08D9D6),
              onPrimary: Colors.black,
              surface: Color(0xFF2A303C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFF252A34);
    const Color accent = Color(0xFF08D9D6);

    return Scaffold(
      backgroundColor: background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Poll Details'),
              _buildTextField(
                  _titleController, 'Poll Title', 'Enter title', Icons.title),
              _buildTextField(_descController, 'Poll Description',
                  'Enter description', Icons.description,
                  maxLines: 3),
              const SizedBox(height: 20),
              _buildSectionTitle('Options'),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _optionControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _optionControllers[index],
                            'Option ${index + 1}',
                            'Enter option text',
                            Icons.list,
                          ),
                        ),
                        if (_optionControllers.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.redAccent),
                            onPressed: () => _removeOption(index),
                          ),
                      ],
                    ),
                  );
                },
              ),
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add, color: accent),
                label:
                    const Text('Add Option', style: TextStyle(color: accent)),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Settings'),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      'Poll Type',
                      _pollType,
                      ['single', 'multiple'],
                      (val) => setState(() => _pollType = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      'Target Audience',
                      _targetAudience,
                      ['All Residents', 'Block A', 'Block B', 'Block C'],
                      (val) => setState(() => _targetAudience = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePickerTile('Start Date', _startDate,
                        () => _selectDate(context, true)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDatePickerTile('End Date', _endDate,
                        () => _selectDate(context, false)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Anonymous Voting',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text(
                    'Users can vote without revealing their identity',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12)),
                value: _isAnonymous,
                onChanged: (val) => setState(() => _isAnonymous = val),
                activeColor: accent,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPoll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Create Poll',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      String hint, IconData icon,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
        prefixIcon: Icon(icon, color: const Color(0xFF08D9D6), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF08D9D6), width: 1),
        ),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF2A303C),
              items: items
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerTile(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Color(0xFF08D9D6), size: 16),
                const SizedBox(width: 8),
                Text(DateFormat('MMM dd, yyyy').format(date),
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPoll() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final poll = PollModel(
        pollId: '', // Firestore will generate
        title: _titleController.text,
        description: _descController.text,
        options: _optionControllers
            .where((c) => c.text.isNotEmpty)
            .map((c) => PollOption(
                  optionId: const Uuid().v4(),
                  text: c.text,
                  voteCount: 0,
                ))
            .toList(),
        pollType: _pollType,
        startDate: _startDate,
        endDate: _endDate,
        targetAudience: _targetAudience,
        isAnonymous: _isAnonymous,
        createdBy: user.uid,
        createdAt: DateTime.now(),
        status: 'active',
      );

      await _pollsService.createPoll(poll);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Poll created successfully!'),
              backgroundColor: Colors.green),
        );
        // Reset form
        _titleController.clear();
        _descController.clear();
        for (var c in _optionControllers) {
          c.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
