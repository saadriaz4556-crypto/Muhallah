import 'package:flutter/material.dart';

// Brand Colors (Matching RegistrationScreen)
const Color deepNavy = Color(0xFF252A34);
const Color sectionBg = Color(0xFF2A303C);
const Color inputBg = Color(0xFF3A4250);
const Color teal = Color(0xFF08D9D6);
const Color coral = Color(0xFFFF2E63);
const Color whiteish = Color(0xFFEAEAEA);
const Color successGreen = Color(0xFF10B981);
const Color warningAmber = Color(0xFFF59E0B);
const Color errorRed = Color(0xFFDC2626);

// Gradients
const LinearGradient primaryGradient = LinearGradient(
  colors: [Color(0xFF08D9D6), Color(0xFF00B4B2)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient secondaryGradient = LinearGradient(
  colors: [Color(0xFFFF2E63), Color(0xFFE01E5A)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient cardGradient = LinearGradient(
  colors: [Color(0xFF2A303C), Color(0xFF363D4C)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Text Styles
const TextStyle headingStyle = TextStyle(
  color: whiteish,
  fontSize: 20,
  fontWeight: FontWeight.bold,
);

const TextStyle subHeadingStyle = TextStyle(
  color: Colors.white70,
  fontSize: 14,
);

const TextStyle labelStyle = TextStyle(
  color: teal,
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.5,
);

const TextStyle inputTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 16,
);
