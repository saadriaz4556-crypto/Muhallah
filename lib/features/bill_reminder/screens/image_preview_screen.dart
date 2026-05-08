import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImagePreviewScreen extends StatelessWidget {
  final String imagePath;
  final String title;

  const ImagePreviewScreen({super.key, required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: Hero(
          tag: imagePath, // Still using imagePath variable name but it will be a URL
          child: Image.network(
            imagePath,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Text('Failed to load image', style: TextStyle(color: Colors.white)));
            },
          ),
        ),
      ),
    );
  }
}
