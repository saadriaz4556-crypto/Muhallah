import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const QuickReportApp());
}

/// Enhanced Color Palette
const Color kPrimaryTeal = Color(0xFF08D9D6);
const Color kPrimaryVibrant = Color(0xFF00F5FF);
const Color kBackgroundDark = Color(0xFF1A1F2B);
const Color kBackgroundCard = Color(0xFF2D3748);
const Color kAccentDanger = Color(0xFFFF2E63);
const Color kAccentSuccess = Color(0xFF00E676);
const Color kAccentWarning = Color(0xFFFF9800);
const Color kAccentPurple = Color(0xFF9C27B0);
const Color kAccentBlue = Color(0xFF2196F3);
const Color kNeutralText = Color(0xFFEAEAEA);
const Color kNeutralLight = Color(0xFF94A3B8);

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
          secondary: kAccentPurple,
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
  ReportImage({required this.id, required this.color});
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
      kAccentDanger,
      Colors.redAccent,
    ),
    _CategoryItem(
      'Noise',
      Icons.volume_up,
      'Loud noise or disturbance',
      kAccentWarning,
      Colors.orangeAccent,
    ),
    _CategoryItem(
      'Trash',
      Icons.delete,
      'Garbage, overflowing bins',
      kAccentSuccess,
      Colors.greenAccent,
    ),
    _CategoryItem(
      'Lost Item',
      Icons.search,
      'Lost or found items',
      kAccentBlue,
      Colors.blueAccent,
    ),
    _CategoryItem(
      'Road',
      Icons.directions_car,
      'Road issues & potholes',
      kPrimaryTeal,
      Colors.cyanAccent,
    ),
    _CategoryItem(
      'Other',
      Icons.more_horiz,
      'Anything else',
      kAccentPurple,
      Colors.purpleAccent,
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
          onPressed: () => Navigator.of(context).maybePop(),
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
                        colors: [kPrimaryVibrant, kAccentPurple],
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
                                      kBackgroundCard.withOpacity(0.8),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: cat.gradientStart.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
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
                                            ? Colors.white.withOpacity(0.2)
                                            : cat.color.withOpacity(0.2),
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
                                            ? Colors.white.withOpacity(0.8)
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
                            color: kNeutralLight.withOpacity(0.3),
                          ),
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: kNeutralText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).maybePop(),
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
                                  colors: [kPrimaryVibrant, kAccentPurple],
                                ),
                          color:
                              _selected == null ? Colors.grey.shade800 : null,
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
                  color: kPrimaryTeal.withOpacity(0.1),
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
                    colors: [kPrimaryVibrant, kAccentPurple],
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

  String _urgency = 'Medium';
  String _locationLabel = 'Tap "Use My Location" to set location';

  @override
  void initState() {
    super.initState();
    _headlineCtrl.text = widget.report.headline;
    _descCtrl.text = widget.report.description;
  }

  @override
  void dispose() {
    _headlineCtrl.dispose();
    _descCtrl.dispose();
    _headlineFocus.dispose();
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

  Future<void> _useMyLocation() async {
    setState(() {
      // Location using logic could be added here
      _locationLabel = '📍 F-8/3, Islamabad (simulated)';
    });
    widget.report.useMyLocation = true;
    widget.report.locationLabel = _locationLabel;
  }

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
                    colors: [kPrimaryVibrant, kAccentPurple],
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
                          color: Colors.black.withOpacity(0.3),
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
                                    colors: [kPrimaryVibrant, kAccentBlue],
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

                          // Urgency section
                          _buildSectionHeader(
                            'Urgency Level',
                            Icons.priority_high,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildUrgencyChip(
                                'Low',
                                Icons.low_priority,
                                Colors.green,
                              ),
                              const SizedBox(width: 8),
                              _buildUrgencyChip(
                                'Medium',
                                Icons.warning,
                                Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              _buildUrgencyChip(
                                'High',
                                Icons.error,
                                Colors.red,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Location section
                          _buildSectionHeader('Location', Icons.location_on),
                          const SizedBox(height: 12),
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  kBackgroundDark,
                                  kBackgroundDark.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Map placeholder
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      color: kAccentBlue.withOpacity(0.1),
                                      child: const Center(
                                        child: Icon(
                                          Icons.map,
                                          size: 48,
                                          color: kAccentBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Location info overlay
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.8),
                                          Colors.transparent,
                                        ],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(20),
                                        bottomRight: Radius.circular(20),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _locationLabel,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Accuracy: simulated',
                                          style: TextStyle(
                                            color: kNeutralLight,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Action buttons
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Row(
                                    children: [
                                      FloatingActionButton.small(
                                        heroTag: 'location_btn',
                                        backgroundColor: kPrimaryTeal,
                                        onPressed: _useMyLocation,
                                        child: const Icon(
                                          Icons.my_location,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      FloatingActionButton.small(
                                        heroTag: 'edit_btn',
                                        backgroundColor: kBackgroundCard,
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (c) => Dialog(
                                              backgroundColor: kBackgroundCard,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  24,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.map,
                                                      size: 48,
                                                      color: kPrimaryTeal,
                                                    ),
                                                    const SizedBox(height: 16),
                                                    const Text(
                                                      'Map Editor',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    const Text(
                                                      'Map editing will be implemented with google_maps_flutter package',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: kNeutralLight,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 24),
                                                    Container(
                                                      width: double.infinity,
                                                      height: 48,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                          colors: [
                                                            kPrimaryVibrant,
                                                            kAccentPurple,
                                                          ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          16,
                                                        ),
                                                      ),
                                                      child: TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                          c,
                                                        ).pop(),
                                                        child: const Text(
                                                          'OK',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Icon(
                                          Icons.edit_location,
                                          size: 18,
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
                              color: kNeutralLight.withOpacity(0.3),
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
                                    colors: [kPrimaryVibrant, kAccentPurple],
                                  ),
                            color: (_headlineCtrl.text.trim().isEmpty ||
                                    _descCtrl.text.trim().isEmpty)
                                ? Colors.grey.shade800
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
                                    widget.report.urgency = _urgency;
                                    widget.report.locationLabel =
                                        _locationLabel;
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

  Widget _buildUrgencyChip(String level, IconData icon, Color color) {
    final isSelected = _urgency == level;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _urgency = level;
              widget.report.urgency = level;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : kBackgroundDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: isSelected ? color : kNeutralLight, size: 20),
                const SizedBox(height: 4),
                Text(
                  level,
                  style: TextStyle(
                    color: isSelected ? color : kNeutralLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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

/// Screen 3: Media & Privacy
class MediaPrivacyScreen extends StatefulWidget {
  final QuickReport report;
  const MediaPrivacyScreen({super.key, required this.report});

  @override
  State<MediaPrivacyScreen> createState() => _MediaPrivacyScreenState();
}

class _MediaPrivacyScreenState extends State<MediaPrivacyScreen> {
  bool _anonymous = false;
  bool _simulateOffline = false;

  @override
  void initState() {
    super.initState();
    _anonymous = widget.report.anonymous;
  }

  void _addSampleImage() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final color = Colors.primaries[Random().nextInt(Colors.primaries.length)];
    setState(() {
      widget.report.attachments.add(ReportImage(id: id, color: color));
    });
    HapticFeedback.lightImpact();
  }

  void _removeImage(String id) {
    setState(() {
      widget.report.attachments.removeWhere((i) => i.id == id);
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _recordVoiceNote() async {
    showDialog(
      context: context,
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
                  color: kAccentPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: kAccentPurple, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Voice Recording',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Voice recording will be implemented with permission + recorder package',
                textAlign: TextAlign.center,
                style: TextStyle(color: kNeutralLight),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimaryVibrant, kAccentPurple],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextButton(
                  onPressed: () => Navigator.of(c).pop(),
                  child: const Text(
                    'OK',
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
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kBackgroundCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi, size: 16, color: kNeutralLight),
                const SizedBox(width: 6),
                const Text('Offline', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Switch.adaptive(
                  value: _simulateOffline,
                  onChanged: (v) => setState(() => _simulateOffline = v),
                  activeColor: kAccentDanger,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ],
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
                      color: Colors.black.withOpacity(0.3),
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
                                colors: [kAccentPurple, kAccentBlue],
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

                      // Media action buttons
                      Row(
                        children: [
                          _buildMediaButton(
                            'Take Photo',
                            Icons.camera_alt,
                            kPrimaryTeal,
                            _addSampleImage,
                          ),
                          const SizedBox(width: 12),
                          _buildMediaButton(
                            'Gallery',
                            Icons.photo_library,
                            kAccentBlue,
                            _addSampleImage,
                          ),
                          const SizedBox(width: 12),
                          _buildMediaButton(
                            'Record Voice',
                            Icons.mic,
                            kAccentPurple,
                            _recordVoiceNote,
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
                                          color: img.color.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.image,
                                        size: 36,
                                        color: Colors.white,
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
                              color: kNeutralLight.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _addSampleImage,
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

              // Privacy Section
              Container(
                decoration: BoxDecoration(
                  color: kBackgroundCard,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
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
                                colors: [kAccentSuccess, kPrimaryTeal],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.privacy_tip,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Privacy Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: kNeutralText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Anonymous toggle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kBackgroundDark,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _anonymous
                                  ? kAccentSuccess.withOpacity(0.2)
                                  : kPrimaryTeal.withOpacity(0.2),
                              child: Icon(
                                _anonymous
                                    ? Icons.visibility_off
                                    : Icons.person,
                                color:
                                    _anonymous ? kAccentSuccess : kPrimaryTeal,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _anonymous
                                        ? 'Anonymous Report'
                                        : 'Public Report',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: kNeutralText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _anonymous
                                        ? 'Your name will be hidden from admins and the public'
                                        : 'This report will be linked to your profile',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: kNeutralLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Transform.scale(
                              scale: 1.2,
                              child: Switch.adaptive(
                                value: _anonymous,
                                onChanged: (v) {
                                  setState(() {
                                    _anonymous = v;
                                    widget.report.anonymous = v;
                                  });
                                  HapticFeedback.lightImpact();
                                },
                                activeColor: kAccentSuccess,
                                activeTrackColor: kAccentSuccess.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                          color: kNeutralLight.withOpacity(0.3),
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
                          colors: [kPrimaryVibrant, kAccentPurple],
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
                          widget.report.anonymous = _anonymous;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PreviewSendScreen(
                                report: widget.report,
                                simulateOffline: _simulateOffline,
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
                    color: color.withOpacity(0.1),
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
                    border: Border.all(color: kNeutralLight.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(c).pop();
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
    );

    await Future.delayed(const Duration(seconds: 2));

    final offline = widget.simulateOffline;
    final randomFail = Random().nextInt(100) < 8;

    Navigator.of(context).pop();

    if (offline || randomFail) {
      _showFailureSaved();
    } else {
      _showSuccess();
    }
    setState(() => _sending = false);
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
                  color: kAccentSuccess.withOpacity(0.1),
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
                  border: Border.all(color: kPrimaryTeal.withOpacity(0.3)),
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
                          color: kNeutralLight.withOpacity(0.3),
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
                          colors: [kPrimaryVibrant, kAccentPurple],
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
                  color: kAccentWarning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off,
                  color: kAccentWarning,
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
                    colors: [kPrimaryVibrant, kAccentPurple],
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
                              color: Colors.black.withOpacity(0.3),
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
                                        colors: [kPrimaryVibrant, kAccentBlue],
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
                                            ).withOpacity(0.2),
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
                                              ? kAccentSuccess.withOpacity(0.2)
                                              : kPrimaryTeal.withOpacity(0.2),
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
                                color: kAccentSuccess.withOpacity(0.1),
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
                          color: kNeutralLight.withOpacity(0.3),
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
                                colors: [kPrimaryVibrant, kAccentPurple],
                              ),
                        color: _sending ? Colors.grey.shade800 : null,
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
