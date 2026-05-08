class OcrResult {
  final bool success; // Was OCR successful?
  final DateTime? detectedDate; // Extracted date (if found)
  final String extractedText; // All text from image
  final String? errorMessage; // Error details
  final double confidence; // Confidence level (0.0 - 1.0)

  OcrResult({
    required this.success,
    this.detectedDate,
    required this.extractedText,
    this.errorMessage,
    required this.confidence,
  });
}
