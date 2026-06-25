import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const AnnouncementApp());
}

class AnnouncementApp extends StatelessWidget {
  const AnnouncementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Community Announcements',
      theme: ThemeData(
        primaryColor: const Color(0xFF08D9D6),
        scaffoldBackgroundColor: const Color(0xFF252A34),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const AnnouncementTypeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AnnouncementTypeScreen extends StatefulWidget {
  const AnnouncementTypeScreen({super.key});

  @override
  State<AnnouncementTypeScreen> createState() => _AnnouncementTypeScreenState();
}

class _AnnouncementTypeScreenState extends State<AnnouncementTypeScreen> {
  String selectedType = '';
  final announcementTypes = [
    {'title': 'General', 'icon': Icons.campaign},
    {'title': 'Pool', 'icon': Icons.pool},
    {'title': 'Security', 'icon': Icons.shield},
    {'title': 'Events', 'icon': Icons.event},
  ];

  AnnouncementData data = AnnouncementData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Announcements'),
        backgroundColor: const Color(0xFF2A303C),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Gradient Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF2E63), Color(0xFF08D9D6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: const Text(
              'What would you like to share?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFB0B0B0)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select the type that best fits your announcement so it reaches the right people.',
                    style: TextStyle(color: Color(0xFFB0B0B0)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Category Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: announcementTypes.length,
              itemBuilder: (context, index) {
                final type = announcementTypes[index];
                final isSelected = selectedType == type['title'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedType = type['title'] as String;
                      data.type = type['title'] as String;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF08D9D6)
                          : const Color(0xFF2A303C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3A3F48)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          type['icon'] as IconData,
                          color: isSelected ? Colors.black : Colors.white,
                          size: 28,
                        ),
                        const Spacer(),
                        Text(
                          type['title'] as String,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : const Color(0xFFEAEAEA),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Sticky Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF252A34),
          border: Border(top: BorderSide(color: Colors.grey[800]!)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            //buttom with navitaon
            onPressed: selectedType.isNotEmpty
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailsContentScreen(data: data),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF08D9D6),
              disabledBackgroundColor: Colors.grey[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'NEXT: CRAFT MESSAGE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ----------------- Details Content Screen ----------------- */

class DetailsContentScreen extends StatefulWidget {
  final AnnouncementData data;

  const DetailsContentScreen({super.key, required this.data});

  @override
  State<DetailsContentScreen> createState() => _DetailsContentScreenState();
}

class _DetailsContentScreenState extends State<DetailsContentScreen> {
  final TextEditingController _headlineController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _headlineController.text = widget.data.headline ?? '';
    _descriptionController.text = widget.data.description ?? '';
    _headlineController.addListener(() {
      setState(() {
        widget.data.headline = _headlineController.text;
      });
    });
    _descriptionController.addListener(() {
      setState(() {
        widget.data.description = _descriptionController.text;
      });
    });
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String?> _uploadToCloudinary(XFile file) async {
    const cloudName = 'drposqmf0';
    const uploadPreset = 'flutter_uploads';

    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;
    request.headers['X-Requested-With'] = 'XMLHttpRequest';

    final bytes = await file.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: file.name,
    ));

    try {
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        widget.data.isImageUploading = true;
      });

      final url = await _uploadToCloudinary(image);
      
      if (mounted) {
        setState(() {
          if (url != null) {
            widget.data.imageUrl = url;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image.')),
            );
          }
          widget.data.isImageUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Craft Announcement'),
        backgroundColor: const Color(0xFF2A303C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type',
              style: TextStyle(
                color: Color(0xFF08D9D6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.data.type ?? '—',
              style: const TextStyle(
                color: Color(0xFFEAEAEA),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Headline
            const Text(
              'Headline',
              style: TextStyle(
                color: Color(0xFF08D9D6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _headlineController,
              style: const TextStyle(color: Color(0xFFEAEAEA)),
              decoration: InputDecoration(
                hintText: 'e.g., Pool Closure for Annual Maintenance',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF08D9D6)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  widget.data.headline = value;
                });
              },
            ),
            const SizedBox(height: 12),

            // Description
            const Text(
              'Details',
              style: TextStyle(
                color: Color(0xFF08D9D6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 6,
              style: const TextStyle(color: Color(0xFFEAEAEA)),
              decoration: InputDecoration(
                hintText: 'Write what residents need to know (max 300 chars)',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF08D9D6)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  widget.data.description = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${_descriptionController.text.length}/300',
                  style: TextStyle(
                    color: _descriptionController.text.length > 300
                        ? Colors.red
                        : const Color(0xFFB0B0B0),
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            // Contextual Hint
            if (_descriptionController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF252A34),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: const Text(
                  'Tip: include date, time and location if relevant.',
                  style: TextStyle(color: Color(0xFFB0B0B0)),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Text(
              'Add Image (Optional)',
              style: TextStyle(
                color: Color(0xFF08D9D6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: widget.data.isImageUploading ? null : _pickAndUploadImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF252A34),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Center(
                  child: widget.data.isImageUploading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFF08D9D6),
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.data.imageUrl != null
                                  ? Icons.check_circle
                                  : Icons.add_photo_alternate,
                              color: widget.data.imageUrl != null
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEAEAEA),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.data.imageUrl != null
                                  ? 'Image Uploaded'
                                  : 'Tap to pick an image',
                              style: TextStyle(
                                color: widget.data.imageUrl != null
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEAEAEA),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: widget.data.isStep2Valid
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PreviewPublishScreen(data: widget.data),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF08D9D6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'PREVIEW & PUBLISH',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
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

/* ----------------- Preview & Publish Screen ----------------- */

class PreviewPublishScreen extends StatefulWidget {
  final AnnouncementData data;
  const PreviewPublishScreen({super.key, required this.data});

  @override
  State<PreviewPublishScreen> createState() => _PreviewPublishScreenState();
}

class _PreviewPublishScreenState extends State<PreviewPublishScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Announcement'),
        backgroundColor: const Color(0xFF2A303C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: const Color(0xFF2A303C),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.data.imageUrl != null &&
                        widget.data.imageUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.data.imageUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              color: const Color(0xFF3A4250),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: const Color(0xFF08D9D6),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      widget.data.headline ?? '(No headline)',
                      style: const TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.data.description ?? '(No details)',
                      style: const TextStyle(color: Color(0xFFB0B0B0)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF252A34),
          border: Border(top: BorderSide(color: Colors.grey[800]!)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF08D9D6),
                  side: const BorderSide(color: Color(0xFF08D9D6)),
                ),
                child: const Text('CANCEL'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);
                        try {
                          await FirebaseFirestore.instance
                              .collection('announcements')
                              .add({
                            'headline': widget.data.headline?.trim() ?? '',
                            'description': widget.data.description?.trim() ?? '',
                            'type': widget.data.type ?? 'General',
                            'postType': 'announcement',
                            'authorId':
                                FirebaseAuth.instance.currentUser?.uid ?? '',
                            'authorName': FirebaseAuth.instance.currentUser?.displayName?.isNotEmpty == true
                                ? FirebaseAuth.instance.currentUser!.displayName!
                                : (FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'Resident'),
                            'createdAt': FieldValue.serverTimestamp(),
                            'imageUrl': widget.data.imageUrl ?? '',
                            'pinned': false,
                            'likes': 0,
                            'comments': 0,
                            'shares': 0,
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Announcement published successfully!'),
                              ),
                            );
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF08D9D6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('CONFIRM & SEND'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------- Data model ----------------- */

class AnnouncementData {
  String? type;
  String? headline;
  String? description;
  String? imageUrl;
  bool isImageUploading = false;

  bool get isStep2Valid =>
      (headline != null && headline!.trim().isNotEmpty) &&
      (description != null && description!.trim().isNotEmpty) &&
      !isImageUploading;
}
