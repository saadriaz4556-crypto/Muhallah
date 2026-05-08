import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import '../models/ocr_result_model.dart';

class OcrService {
  /// MAIN METHOD - Call this to extract date from bill image
  Future<OcrResult> extractDueDateFromBillImage(File imageFile) async {
    try {
      // STEP 1: Validate image
      if (!await imageFile.exists()) {
        return OcrResult(
          success: false,
          errorMessage: 'Image file not found',
          extractedText: '',
          confidence: 0.0,
        );
      }

      // STEP 2: Compress/optimize image (ML Kit works better with good quality)
      final optimizedImage = await _optimizeImage(imageFile);

      // STEP 3: Extract text using ML Kit (Google's AI)
      final inputImage = InputImage.fromFile(optimizedImage);
      final TextRecognizer textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      String fullText = recognizedText.text.toLowerCase();
      print('📄 Extracted text from bill:\n$fullText');

      // STEP 4: Close recognizer (important for memory)
      await textRecognizer.close();

      // STEP 5: Search for date in extracted text
      DateTime? detectedDate = _extractDateFromText(fullText);

      if (detectedDate != null) {
        print('✅ Date detected: $detectedDate');
        return OcrResult(
          success: true,
          detectedDate: detectedDate,
          extractedText: fullText,
          confidence: 0.95, // High confidence
        );
      } else {
        print('⚠️ No date found in text');
        return OcrResult(
          success: false,
          extractedText: fullText,
          errorMessage: 'Could not detect date in bill image',
          confidence: 0.0,
        );
      }
    } catch (e) {
      print('❌ OCR Error: $e');
      return OcrResult(
        success: false,
        errorMessage: 'OCR processing failed: $e',
        extractedText: '',
        confidence: 0.0,
      );
    }
  }

  /// Image optimization (makes OCR more accurate)
  Future<File> _optimizeImage(File originalFile) async {
    try {
      // Read image
      final imageBytes = await originalFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        return originalFile; // Return original if decode fails
      }

      // Resize if too large (>1080px width)
      if (image.width > 1080) {
        image = img.copyResize(image, width: 1080);
      }

      // Enhance contrast (helps text recognition)
      image = _enhanceContrast(image);

      // Save optimized image temporarily
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/bill_optimized.jpg');
      await tempFile.writeAsBytes(img.encodeJpg(image, quality: 85));

      return tempFile;
    } catch (e) {
      print('Image optimization failed: $e');
      return originalFile;
    }
  }

  /// Enhance image contrast (better for OCR)
  img.Image _enhanceContrast(img.Image image) {
    // Increase contrast and adjust gamma
    img.Image enhanced = img.contrast(image, contrast: 1.2);
    enhanced = img.gamma(enhanced, gamma: 1.1);
    return enhanced;
  }

  /// EXTRACT DATE FROM TEXT - Multiple patterns
  DateTime? _extractDateFromText(String text) {
    // Remove extra spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // PATTERN 1: "15 april 2025" or "15 april, 2025"
    RegExp pattern1 = RegExp(
      r'(\d{1,2})\s+(january|february|march|april|may|june|july|august|september|october|november|december)[,.\s]*(\d{4})',
      caseSensitive: false,
    );

    Match? match = pattern1.firstMatch(text);
    if (match != null) {
      try {
        int day = int.parse(match.group(1)!);
        String month = match.group(2)!.toLowerCase();
        int year = int.parse(match.group(3)!);
        return _createDateFromMonthName(day, month, year);
      } catch (e) {
        print('Pattern 1 parse error: $e');
      }
    }

    // PATTERN 2: "15/4/2025" or "15-04-2025" or "15.4.2025"
    RegExp pattern2 = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})');
    match = pattern2.firstMatch(text);
    if (match != null) {
      try {
        int day = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);

        // Validate date
        if (_isValidDate(day, month, year)) {
          return DateTime(year, month, day);
        }
      } catch (e) {
        print('Pattern 2 parse error: $e');
      }
    }

    // PATTERN 3: "2025-04-15" (ISO format)
    RegExp pattern3 = RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})');
    match = pattern3.firstMatch(text);
    if (match != null) {
      try {
        int year = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int day = int.parse(match.group(3)!);

        if (_isValidDate(day, month, year)) {
          return DateTime(year, month, day);
        }
      } catch (e) {
        print('Pattern 3 parse error: $e');
      }
    }

    // PATTERN 4: "15th April 2025" or "15th april 2025"
    RegExp pattern4 = RegExp(
      r'(\d{1,2})(?:st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december)[,.\s]*(\d{4})',
      caseSensitive: false,
    );
    match = pattern4.firstMatch(text);
    if (match != null) {
      try {
        int day = int.parse(match.group(1)!);
        String month = match.group(2)!.toLowerCase();
        int year = int.parse(match.group(3)!);
        return _createDateFromMonthName(day, month, year);
      } catch (e) {
        print('Pattern 4 parse error: $e');
      }
    }

    print('⚠️ No date pattern matched in text');
    return null;
  }

  /// Convert month name to number
  DateTime? _createDateFromMonthName(int day, String month, int year) {
    Map<String, int> months = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12
    };

    int? monthNum = months[month];
    if (monthNum != null && _isValidDate(day, monthNum, year)) {
      return DateTime(year, monthNum, day);
    }
    return null;
  }

  /// Validate if date is real
  bool _isValidDate(int day, int month, int year) {
    try {
      DateTime(year, month, day);

      // Also check: date should be in future (not past)
      DateTime today = DateTime.now();
      DateTime dateToCheck = DateTime(year, month, day);

      if (dateToCheck.isBefore(today)) {
        print('⚠️ Detected date is in past: $dateToCheck');
        return false; // Reject past dates
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
