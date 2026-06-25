import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PostCreationScreen extends StatefulWidget {
  const PostCreationScreen({super.key});

  @override
  State<PostCreationScreen> createState() => _PostCreationScreenState();
}

class _PostCreationScreenState extends State<PostCreationScreen> {
  File? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _isLoading = false;
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();

  // Theme colors matching app
  static const Color _background = Color(0xFF252A34);
  static const Color _card = Color(0xFF2A303C);
  static const Color _primary = Color(0xFF08D9D6);

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = kIsWeb ? null : File(picked.path);
        _pickedImageBytes = bytes;
      });
    }
  }

  Future<void> _submitPost() async {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a caption')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = '';

      // Upload image to Cloudinary if one was picked
      if (_pickedImageBytes != null || _pickedImage != null) {
        final uri = Uri.parse(
            'https://api.cloudinary.com/v1_1/drposqmf0/image/upload');
        final request = http.MultipartRequest('POST', uri);
        request.fields['upload_preset'] = 'flutter_uploads';
        
        if (kIsWeb && _pickedImageBytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            _pickedImageBytes!,
            filename: 'upload.jpg',
          ));
        } else if (_pickedImage != null) {
          request.files.add(
              await http.MultipartFile.fromPath('file', _pickedImage!.path));
        }
        
        final response = await request.send();
        final responseData = await response.stream.toBytes();
        final jsonData = json.decode(String.fromCharCodes(responseData));
        imageUrl = jsonData['secure_url'] ?? '';
      }

      // Save to Firestore collection 'announcements'
      await FirebaseFirestore.instance.collection('announcements').add({
        'headline': _captionController.text.trim(),
        'description': _captionController.text.trim(),
        'location': _locationController.text.trim(),
        'postType': 'announcement',
        'authorId': FirebaseAuth.instance.currentUser?.uid ?? '',
        'authorName':
            FirebaseAuth.instance.currentUser?.displayName?.isNotEmpty == true
                ? FirebaseAuth.instance.currentUser!.displayName!
                : (FirebaseAuth.instance.currentUser?.email?.split('@').first ??
                    'Resident'),
        'createdAt': Timestamp.now(),
        'imageUrl': imageUrl,
        'pinned': false,
        'likes': 0,
        'comments': 0,
        'shares': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post shared successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _card,
        title: const Text(
          'Create Post',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section 1: Caption ---
            const Text(
              'Caption',
              style: TextStyle(
                color: _primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _captionController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'What do you want to share?',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: _card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _primary),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Section 2: Image (Optional) ---
            const Text(
              'Add Image (Optional)',
              style: TextStyle(
                color: _primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                ),
                child: (_pickedImage == null && _pickedImageBytes == null)
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              color: Colors.grey, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'Tap to add image',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.memory(
                                _pickedImageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 150,
                              )
                            : Image.file(
                                _pickedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 150,
                              ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Section 3: Location ---
            const Text(
              'Location',
              style: TextStyle(
                color: _primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Gulshan Block A, Karachi',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: _card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _primary),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- Bottom: Share Post Button ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'SHARE POST',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
