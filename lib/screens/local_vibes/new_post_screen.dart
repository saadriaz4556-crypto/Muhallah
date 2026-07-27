import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muhallah/services/local_vibes_service.dart';

// --- THEME COLORS ---
const Color bgDeepNavy = Color(0xFF252A34);
const Color accentTeal = Color(0xFF08D9D6);
const Color lightText = Color(0xFFEAEAEA);
const Color cardBg = Color(0xFF1A1F2E);

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _service = LocalVibesService();

  Map<String, dynamic> _limits = {'jokesLeft': 5};
  bool _isLoadingLimits = true;
  bool _isUploading = false;

  final TextEditingController _jokeController = TextEditingController();
  File? _selectedFile;

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  @override
  void dispose() {
    _jokeController.dispose();
    super.dispose();
  }

  Future<void> _loadLimits() async {
    try {
      final limits = await _service.checkDailyLimits();
      if (mounted) {
        setState(() {
          _limits = limits;
          _isLoadingLimits = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading limits: $e");
      if (mounted) {
        setState(() {
          _limits = {'jokesLeft': 5};
          _isLoadingLimits = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) {
        return;
      }

      final file = File(picked.path);
      final size = await file.length();
      if (size > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo size must be under 5MB')),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _submit() async {
    final jokesLeft = _limits['jokesLeft'] ?? 5;
    if (jokesLeft <= 0) return;

    final text = _jokeController.text.trim();
    if (text.isEmpty && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please write something or select a photo!')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      bool success = await _service.createPost(
        postType: _selectedFile != null ? 'photo' : 'joke',
        contentText: text,
        mediaFile: _selectedFile,
      );

      if (mounted) {
        setState(() => _isUploading = false);
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vibe posted! It will disappear in 24 hours 🔥'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to post vibe. Try again.'),
              backgroundColor: Color(0xFFFF2E63),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF2E63),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLimits) {
      return const Scaffold(
        backgroundColor: bgDeepNavy,
        body: Center(child: CircularProgressIndicator(color: accentTeal)),
      );
    }

    final jokesLeft = _limits['jokesLeft'] ?? 5;

    return Scaffold(
      backgroundColor: bgDeepNavy,
      appBar: AppBar(
        backgroundColor: bgDeepNavy,
        elevation: 0,
        title: const Text('Add a Funny Vibe 🔥',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: jokesLeft <= 0
          ? const Center(
              child: Text(
                'Aaj ki limit poori ho gayi!\nKal wapas aao 😊',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remaining posts today: $jokesLeft',
                    style: const TextStyle(
                        color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _jokeController,
                    maxLines: 6,
                    maxLength: 500,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Share a joke or funny thought...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedFile != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedFile!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedFile = null),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.6),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedFile == null
                                ? Icons.add_photo_alternate_outlined
                                : Icons.cached,
                            color: accentTeal,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedFile == null
                                ? 'Add Photo (Optional)'
                                : 'Change Photo',
                            style: const TextStyle(
                                color: accentTeal, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: jokesLeft <= 0
          ? null
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '⚠️ Yeh post 24 hours baad delete ho jayegi',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentTeal,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: _isUploading
                          ? const CircularProgressIndicator(color: bgDeepNavy)
                          : const Text('Post Vibe',
                              style: TextStyle(
                                  color: bgDeepNavy,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
