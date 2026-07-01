import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const QuickReportApp());
}

/// Islamic Corner color palette
const Color kBackgroundDark = Color(0xFF252A34);
const Color kBackgroundCard = Color(0xFF2A303C);
const Color kPrimaryTeal = Color(0xFF08D9D6);
const Color kPrimaryVibrant = kPrimaryTeal;
const Color kAccentPurple = kPrimaryTeal;
const Color kAccentBlue = kPrimaryTeal;
const Color kAccentDanger = Color(0xFFFF2E63);
const Color kAccentWarning = Color(0xFFFF9800);
const Color kAccentSuccess = Color(0xFF00E676);
const Color kNeutralText = Color(0xFFEAEAEA);
const Color kNeutralLight = kNeutralText;

class QuickReportApp extends StatelessWidget {
  const QuickReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Report',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBackgroundDark,
        canvasColor: kBackgroundDark,
        cardColor: kBackgroundCard,
        primaryColor: kPrimaryTeal,
        colorScheme: const ColorScheme.dark(
          primary: kPrimaryTeal,
          secondary: kPrimaryTeal,
          surface: kBackgroundCard,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: kNeutralText,
              displayColor: kNeutralText,
            ),
      ),
      home: const CategorySelectionScreen(),
    );
  }
}

/// Simple model to carry the report state through the flow
class QuickReport {
  String? category;
  String headline = '';
  String description = '';
  String urgency = 'Medium'; // Low, Medium, High
  String locationLabel = 'Unknown location';
  bool useMyLocation = false;
  List<ReportImage> attachments = [];
  bool anonymous = false;
}

class ReportImage {
  final String id;
  final Color color;
  String? url;
  bool uploading;
  ReportImage(
      {required this.id,
      required this.color,
      this.url,
      this.uploading = false});
}

/// Screen 1: Category Selection
class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen>
    with SingleTickerProviderStateMixin {
  final QuickReport _report = QuickReport();

  final List<_CategoryItem> _categories = [
    _CategoryItem(
      'Safety',
      Icons.security,
      'Security & safety issues',
      kPrimaryTeal,
      kPrimaryTeal,
    ),
    _CategoryItem(
      'Noise',
      Icons.volume_up,
      'Loud noise or disturbance',
      kPrimaryTeal,
      kPrimaryTeal,
    ),
    _CategoryItem(
      'Trash',
      Icons.delete,
      'Garbage, overflowing bins',
      kPrimaryTeal,
      kPrimaryTeal,
    ),
    _CategoryItem(
      'Lost Item',
      Icons.search,
      'Lost or found items',
      kPrimaryTeal,
      kPrimaryTeal,
    ),
    _CategoryItem(
      'Road',
      Icons.directions_car,
      'Road issues & potholes',
      kPrimaryTeal,
      kPrimaryTeal,
    ),
    _CategoryItem(
      'Other',
      Icons.more_horiz,
      'Anything else',
      kPrimaryTeal,
      kPrimaryTeal,
    ),
  ];

  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundDark,
      appBar: AppBar(
        title: const Text('Quick Report'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kBackgroundCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.close, size: 20),
          ),
          onPressed: () async {
            // Try to pop inner navigator first; if that didn't pop anything,
            // pop the outer/root navigator that opened this Quick Report flow.
            final popped = await Navigator.of(context).maybePop();
            if (!popped) {
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kBackgroundCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.help_outline, size: 20),
            ),
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Header with gradient text
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [kPrimaryTeal, kPrimaryTeal],
                      ).createShader(bounds),
                      child: const Text(
                        'What would you like\nto report?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap to select. This helps us route your report correctly.',
                      style: TextStyle(color: kNeutralLight, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _categories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final bool selected = cat.title == _selected;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            gradient: selected
                                ? LinearGradient(
                                    colors: [
                                      cat.gradientStart,
                                      cat.gradientEnd,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      kBackgroundCard,
                                      kBackgroundCard.withValues(alpha: 0.8),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: kPrimaryTeal.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                            border: Border.all(
                              color:
                                  selected ? Colors.white : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _selected = cat.title;
                                  _report.category = cat.title;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? Colors.white.withValues(alpha: 0.2)
                                            : cat.color.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        cat.icon,
                                        color:
                                            selected ? Colors.white : cat.color,
                                        size: 20,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      cat.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: selected
                                            ? Colors.white
                                            : kNeutralText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cat.sub,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: selected
                                            ? Colors.white.withValues(alpha: 0.8)
                                            : kNeutralLight,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom buttons - Fixed at bottom
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              color: kBackgroundDark,
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: kNeutralLight.withValues(alpha: 0.3),
                          ),
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: kNeutralText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            final popped =
                                await Navigator.of(context).maybePop();
                            if (!popped) {
                              Navigator.of(context, rootNavigator: true).pop();
                            }
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: _selected == null
                              ? null
                              : const LinearGradient(
                                  colors: [kPrimaryTeal, kPrimaryTeal],
                                ),
                          color: _selected == null
                              ? kBackgroundCard.withValues(alpha: 0.7)
                              : null,
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _selected == null
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DetailsLocationScreen(
                                        report: _report,
                                      ),
                                    ),
                                  );
                                },
                          child: const Text(
                            'Next: Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: kBackgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kPrimaryTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help, color: kPrimaryTeal, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'How Quick Report Works',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kNeutralText,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select a category to help route your report. You will fill a short headline, details, location and optional media. You can send anonymously.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kNeutralLight, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimaryTeal, kPrimaryTeal],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String title;
  final IconData icon;
  final String sub;
  final Color color;
  final Color gradientStart;
  final Color gradientEnd;

  _CategoryItem(this.title, this.icon, this.sub, this.color, this.gradientEnd)
      : gradientStart = color;
}

/// Screen 2: Details & Location
class DetailsLocationScreen extends StatefulWidget {
  final QuickReport report;
  const DetailsLocationScreen({super.key, required this.report});

  @override
  State<DetailsLocationScreen> createState() => _DetailsLocationScreenState();
}

class _DetailsLocationScreenState extends State<DetailsLocationScreen> {
  final TextEditingController _headlineCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final FocusNode _headlineFocus = FocusNode();

  // Enhanced headline suggestions with emojis
  Map<String, List<String>> headlineSuggestions = {
    'Safety': [
      '🚨 Suspicious person near gate',
      '👀 Possible theft attempt',
      '⚔️ Altercation at market',
    ],
    'Noise': [
      '🔊 Loud music after midnight',
      '🏗️ Construction noise at 3am',
      '🔌 Continuous generator noise',
    ],
    'Trash': [
      '🗑️ Overflowing bin near park',
      '🚛 Dumping on the roadside',
      '📦 Uncollected garbage',
    ],
    'Lost Item': [
      '💰 Lost: black wallet near mosque',
      '🧸 Found: child\'s toy at market',
      '💍 Lost: gold bracelet in park',
    ],
    'Road': [
      '🕳️ Huge pothole on Main St',
      '🚦 Broken traffic light at X',
      '🚧 Road blocked by debris',
    ],
    'Other': [
      '💧 Community water issue',
      '⚡ Public fountain leaking',
      '🐕 Stray animal problem',
    ],
  };

  final TextEditingController _locationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _headlineCtrl.text = widget.report.headline;
    _descCtrl.text = widget.report.description;
    _locationCtrl.text = (widget.report.locationLabel == 'Unknown location')
        ? ''
        : widget.report.locationLabel;
    // Keep report fields and UI in sync as user types so the Next button updates
    _headlineCtrl.addListener(() {
      widget.report.headline = _headlineCtrl.text;
      setState(() {});
    });
    _descCtrl.addListener(() {
      widget.report.description = _descCtrl.text;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _headlineCtrl.dispose();
    _descCtrl.dispose();
    _headlineFocus.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  List<String> get _suggestions {
    final cat = widget.report.category ?? 'Other';
    return headlineSuggestions[cat] ?? [];
  }

  void _applySuggestion(String s) {
    _headlineCtrl.text = s;
    _headlineCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: s.length),
    );
    HapticFeedback.selectionClick();
  }

  // Location is now entered manually by the user via a text field.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundDark,
      appBar: AppBar(
        title: Text('Report ${widget.report.category ?? ''}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kBackgroundCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Column(
        children: [
          // Animated progress bar
          Container(
            height: 6,
            width: double.infinity,
            color: kBackgroundCard,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 500),
              widthFactor: 0.66,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimaryTeal, kPrimaryTeal],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Main content card
                  Container(
                    decoration: BoxDecoration(
                      color: kBackgroundCard,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with icon
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [kPrimaryTeal, kPrimaryTeal],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Report Details',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: kNeutralText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Headline section
                          _buildSectionHeader('Headline', Icons.title),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: kBackgroundDark,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _headlineCtrl,
                              focusNode: _headlineFocus,
                              maxLength: 60,
                              style: const TextStyle(color: kNeutralText),
                              decoration: const InputDecoration(
                                hintText: 'e.g., Broken streetlight on F-8/3',
                                hintStyle: TextStyle(color: kNeutralLight),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                              onChanged: (v) => widget.report.headline = v,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Suggestions
                          if (_headlineCtrl.text.isEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _suggestions.take(3).map((s) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: kBackgroundDark,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => _applySuggestion(s),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        child: Text(
                                          s,
                                          style: const TextStyle(
                                            color: kNeutralLight,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Description section
                          _buildSectionHeader('Description', Icons.description),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: kBackgroundDark,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _descCtrl,
                              maxLines: 4,
                              minLines: 3,
                              style: const TextStyle(color: kNeutralText),
                              decoration: const InputDecoration(
                                hintText:
                                    'Please describe what happened and any important details...',
                                hintStyle: TextStyle(color: kNeutralLight),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                              onChanged: (v) => widget.report.description = v,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kBackgroundDark,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_descCtrl.text.length} chars',
                                  style: const TextStyle(
                                    color: kNeutralLight,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Location section (manual input)
                          _buildSectionHeader('Location', Icons.location_on),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: kBackgroundDark,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _locationCtrl,
                              style: const TextStyle(color: kNeutralText),
                              decoration: const InputDecoration(
                                hintText:
                                    'Enter your location, e.g. F-8/3, Rawalpindi',
                                hintStyle: TextStyle(color: kNeutralLight),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                              onChanged: (v) => widget.report.locationLabel = v,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Navigation buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: kNeutralLight.withValues(alpha: 0.3),
                            ),
                          ),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: kNeutralText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: (_headlineCtrl.text.trim().isEmpty ||
                                    _descCtrl.text.trim().isEmpty)
                                ? null
                                : const LinearGradient(
                                    colors: [kPrimaryTeal, kPrimaryTeal],
                                  ),
                            color: (_headlineCtrl.text.trim().isEmpty ||
                                    _descCtrl.text.trim().isEmpty)
                                ? kBackgroundCard.withValues(alpha: 0.7)
                                : null,
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: (_headlineCtrl.text.trim().isEmpty ||
                                    _descCtrl.text.trim().isEmpty)
                                ? null
                                : () {
                                    widget.report.headline =
                                        _headlineCtrl.text.trim();
                                    widget.report.description =
                                        _descCtrl.text.trim();
                                    // Use manual location input if provided
                                    final loc = _locationCtrl.text.trim();
                                    if (loc.isNotEmpty) {
                                      widget.report.locationLabel = loc;
                                    }
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MediaPrivacyScreen(
                                          report: widget.report,
                                        ),
                                      ),
                                    );
                                  },
                            child: const Text(
                              'Next: Add Media',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryTeal, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kNeutralText,
          ),
        ),
      ],
    );
  }
}

/// Screen 3: Media & Privacy
class MediaPrivacyScreen extends StatefulWidget {
  final QuickReport report;
  const MediaPrivacyScreen({super.key, required this.report});

  @override
  State<MediaPrivacyScreen> createState() => _MediaPrivacyScreenState();
}

class _MediaPrivacyScreenState extends State<MediaPrivacyScreen> {
  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: source);
      if (file == null) return;

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final color = Colors.primaries[Random().nextInt(Colors.primaries.length)];
      final img = ReportImage(id: id, color: color, uploading: true);
      setState(() {
        widget.report.attachments.add(img);
      });

      // Start upload
      final secureUrl = await _uploadToCloudinary(file);
      if (secureUrl != null) {
        setState(() {
          final idx = widget.report.attachments.indexWhere((a) => a.id == id);
          if (idx != -1) {
            widget.report.attachments[idx].url = secureUrl;
            widget.report.attachments[idx].uploading = false;
          }
        });
      } else {
        // upload failed
        setState(() {
          widget.report.attachments.removeWhere((a) => a.id == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    } catch (e) {
      debugPrint('Image pick/upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error while picking image')),
      );
    }
    HapticFeedback.lightImpact();
  }

  void _removeImage(String id) {
    setState(() {
      widget.report.attachments.removeWhere((i) => i.id == id);
    });
    HapticFeedback.lightImpact();
  }

  // Voice recording removed from this flow.

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
      debugPrint('Starting Cloudinary upload for ${file.name}...');
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200) {
        final secureUrl = jsonResponse['secure_url'];
        debugPrint('Cloudinary Upload Success: $secureUrl');
        return secureUrl;
      } else {
        debugPrint(
            'Cloudinary Upload Failed: ${response.statusCode} - $responseString');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary Upload Error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imgs = widget.report.attachments;
    return Scaffold(
      backgroundColor: kBackgroundDark,
      appBar: AppBar(
        title: const Text('Media & Privacy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kBackgroundCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Media Section
              Container(
                decoration: BoxDecoration(
                  color: kBackgroundCard,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [kPrimaryTeal, kPrimaryTeal],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.photo_library,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add Media (Optional)',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: kNeutralText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Media action buttons (photo & gallery)
                      Row(
                        children: [
                          _buildMediaButton(
                            'Take Photo',
                            Icons.camera_alt,
                            kPrimaryTeal,
                            () => _pickAndUpload(ImageSource.camera),
                          ),
                          const SizedBox(width: 12),
                          _buildMediaButton(
                            'Gallery',
                            Icons.photo_library,
                            kPrimaryTeal,
                            () => _pickAndUpload(ImageSource.gallery),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Media preview grid
                      if (imgs.isNotEmpty) ...[
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: imgs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final img = imgs[index];
                              return Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: img.color,
                                      boxShadow: [
                                        BoxShadow(
                                          color: img.color.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: img.url != null
                                                ? Image.network(
                                                    img.url!,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    color: img.color,
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.image,
                                                        size: 36,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                          if (img.uploading)
                                            const Positioned.fill(
                                              child: ColoredBox(
                                                color: Colors.black45,
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(img.id),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Add more button
                      if (imgs.length < 5)
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: kBackgroundDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: kNeutralLight.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _pickAndUpload(ImageSource.gallery),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: kNeutralLight,
                                    size: 24,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Add More',
                                    style: TextStyle(
                                      color: kNeutralLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Spacer(),

              // Navigation buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: kNeutralLight.withValues(alpha: 0.3),
                        ),
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: kNeutralText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [kPrimaryTeal, kPrimaryTeal],
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PreviewSendScreen(
                                report: widget.report,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Preview Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: kBackgroundDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: kNeutralLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen 4: Preview & Send
class PreviewSendScreen extends StatefulWidget {
  final QuickReport report;
  final bool simulateOffline;
  const PreviewSendScreen({
    super.key,
    required this.report,
    this.simulateOffline = false,
  });

  @override
  State<PreviewSendScreen> createState() => _PreviewSendScreenState();
}

class _PreviewSendScreenState extends State<PreviewSendScreen> {
  bool _sending = false;

  Map<String, String> recipientsForCategory = {
    'Safety': 'Community Feed & Security',
    'Noise': 'Community Feed',
    'Trash': 'Municipal Services & Community Feed',
    'Lost Item': 'Community Feed',
    'Road': 'Municipal Services',
    'Other': 'Community Feed & Admins',
  };

  Map<String, int> estimateCounts = {
    'Safety': 45,
    'Noise': 18,
    'Trash': 6,
    'Lost Item': 25,
    'Road': 12,
    'Other': 8,
  };

  Future<void> _sendReport() async {
    setState(() => _sending = true);
    bool dialogOpen = false;

    // Do not proceed if uploads are still in progress
    if (widget.report.attachments.any((a) => a.uploading)) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for uploads to finish')),
      );
      return;
    }

    dialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: kBackgroundCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 80,
                  width: 80,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(kPrimaryTeal),
                        strokeWidth: 4,
                      ),
                      Center(
                        child: Icon(Icons.send, color: kPrimaryTeal, size: 30),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sending your report...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: kNeutralLight.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      dialogOpen = false;
                      setState(() => _sending = false);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      dialogOpen = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final authorId = user?.uid ?? 'unknown';
      final authorName =
          user?.displayName ?? (user?.email?.split('@').first ?? 'Resident');
      final firstImage = widget.report.attachments.firstWhere(
        (a) => a.url != null,
        orElse: () => ReportImage(id: '', color: Colors.black),
      );
      final imageUrl = firstImage.url;

      final data = {
        'postType': 'announcement',
        'authorName': authorName,
        'authorId': authorId,
        'headline': widget.report.headline,
        'description': widget.report.description,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'pinned': false,
        'verified': false,
        'location': widget.report.locationLabel,
        'category': widget.report.category,
      };

      await FirebaseFirestore.instance.collection('announcements').add(data);

      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully')),
      );
      _showSuccess();
    } catch (e) {
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      debugPrint('Failed to send report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send report: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _showSuccess() {
    final refId =
        'QR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Dialog(
        backgroundColor: kBackgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kAccentSuccess.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: kAccentSuccess, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Report Submitted!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your community has been notified',
                textAlign: TextAlign.center,
                style: TextStyle(color: kNeutralLight),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kBackgroundDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPrimaryTeal.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Reference ID: $refId',
                  style: const TextStyle(
                    fontSize: 12,
                    color: kPrimaryTeal,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: kNeutralLight.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(c).pop();
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                        child: const Text('Done'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kPrimaryTeal, kPrimaryTeal],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(c).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Opening feed (placeholder)'),
                              backgroundColor: kBackgroundCard,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                        child: const Text(
                          'View in Feed',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFailureSaved() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Dialog(
        backgroundColor: kBackgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kPrimaryTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off,
                  color: kPrimaryTeal,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Connection Lost',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'We saved your report to Drafts and will send it automatically when you\'re back online',
                textAlign: TextAlign.center,
                style: TextStyle(color: kNeutralLight),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimaryTeal, kPrimaryTeal],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(c).pop();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  child: const Text(
                    'View Drafts',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    final recipients = recipientsForCategory[r.category] ?? 'Community Feed';
    final estCount = estimateCounts[r.category] ?? 10;

    return Scaffold(
      backgroundColor: kBackgroundDark,
      appBar: AppBar(
        title: const Text('Preview Report'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kBackgroundCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Report Preview Card
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: kBackgroundCard,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Report header with urgency
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [kPrimaryTeal, kPrimaryTeal],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.report,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.headline.isEmpty
                                              ? '(No headline)'
                                              : r.headline,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: kNeutralText,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getUrgencyColor(
                                              r.urgency,
                                            ).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: _getUrgencyColor(
                                                r.urgency,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            r.urgency,
                                            style: TextStyle(
                                              color: _getUrgencyColor(
                                                r.urgency,
                                              ),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Description
                              Text(
                                r.description,
                                style: const TextStyle(
                                  color: kNeutralLight,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Attachments preview
                              if (r.attachments.isNotEmpty) ...[
                                const Text(
                                  'Attachments',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: kNeutralText,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 80,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: min(r.attachments.length, 3),
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (c, i) {
                                      final img = r.attachments[i];
                                      return Container(
                                        width: 80,
                                        decoration: BoxDecoration(
                                          color: img.color,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.image,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Location and author info
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: kBackgroundDark,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: kNeutralLight,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            r.locationLabel,
                                            style: const TextStyle(
                                              color: kNeutralLight,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: r.anonymous
                                              ? kAccentSuccess.withValues(alpha: 0.2)
                                              : kPrimaryTeal.withValues(alpha: 0.2),
                                          radius: 16,
                                          child: Icon(
                                            r.anonymous
                                                ? Icons.visibility_off
                                                : Icons.person,
                                            size: 16,
                                            color: r.anonymous
                                                ? kAccentSuccess
                                                : kPrimaryTeal,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          r.anonymous
                                              ? 'Anonymous Report'
                                              : 'Saad Riaz',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: kNeutralText,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Text(
                                          'Now',
                                          style: TextStyle(
                                            color: kNeutralLight,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Recipients info
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kBackgroundCard,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kAccentSuccess.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.campaign,
                                color: kAccentSuccess,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sending to: $recipients',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: kNeutralText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Notifying approximately $estCount residents',
                                    style: const TextStyle(
                                      color: kNeutralLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: kNeutralLight.withValues(alpha: 0.3),
                        ),
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: kNeutralText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: _sending
                            ? null
                            : const LinearGradient(
                                colors: [kPrimaryTeal, kPrimaryTeal],
                              ),
                        color:
                            _sending ? kBackgroundCard.withValues(alpha: 0.7) : null,
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _sending ? null : _sendReport,
                        child: _sending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Send Quick Report',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'High':
        return kAccentDanger;
      case 'Medium':
        return kAccentWarning;
      case 'Low':
        return kAccentSuccess;
      default:
        return kNeutralLight;
    }
  }
}
