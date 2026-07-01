import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/kalimat_constants.dart';

class SixKalimatScreen extends StatefulWidget {
  const SixKalimatScreen({super.key});

  @override
  State<SixKalimatScreen> createState() => _SixKalimatScreenState();
}

class _SixKalimatScreenState extends State<SixKalimatScreen> {
  static const Color deepNavy = Color(0xFF252A34);
  static const Color sectionBg = Color(0xFF2A303C);
  static const Color teal = Color(0xFF08D9D6);
  static const Color premiumWhite = Color(0xFFEAEAEA);

  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<bool> _favorites = List.generate(6, (index) => false);

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = List.generate(6, (index) {
        return prefs.getBool('kalima_fav_$index') ?? false;
      });
    });
  }

  Future<void> _toggleFavorite(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites[index] = !_favorites[index];
    });
    await prefs.setBool('kalima_fav_$index', _favorites[index]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        backgroundColor: deepNavy,
        elevation: 0,
        title: const Text(
          '6 Kalimat',
          style: TextStyle(color: premiumWhite, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: teal),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Page indicator dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(allKalimat.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? teal : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Main PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: allKalimat.length,
                itemBuilder: (context, index) {
                  final kalima = allKalimat[index];
                  final isFav = _favorites[index];

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: sectionBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Title and Favorite Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: teal.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Kalima ${kalima.number}/6',
                                        style: const TextStyle(
                                          color: teal,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _toggleFavorite(index),
                                      icon: Icon(
                                        isFav ? Icons.favorite : Icons.favorite_border,
                                        color: isFav ? Colors.redAccent : Colors.white38,
                                        size: 28,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // English name and Urdu name in Header
                                Text(
                                  kalima.nameEnglish,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: premiumWhite,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  kalima.nameUrdu,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: teal.withValues(alpha: 0.8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(color: Colors.white12, height: 32),

                                // Arabic text (Scrollable inside the card)
                                Expanded(
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          kalima.arabicText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            height: 2.0,
                                          ),
                                          textAlign: TextAlign.center,
                                          textDirection: TextDirection.rtl,
                                        ),
                                        const SizedBox(height: 24),

                                        // Transliteration
                                        const Text(
                                          'Transliteration',
                                          style: TextStyle(
                                            color: teal,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          kalima.transliteration,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        // Urdu Translation
                                        const Text(
                                          'Urdu Translation',
                                          style: TextStyle(
                                            color: teal,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          kalima.urduTranslation,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            height: 1.5,
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                        const SizedBox(height: 20),

                                        // English Translation
                                        const Text(
                                          'English Translation',
                                          style: TextStyle(
                                            color: teal,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          kalima.englishTranslation,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Arrows
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _currentPage > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: _currentPage > 0 ? teal : Colors.white12,
                    ),
                  ),
                  Text(
                    'Swipe to read more',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                    ),
                  ),
                  IconButton(
                    onPressed: _currentPage < allKalimat.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: _currentPage < allKalimat.length - 1 ? teal : Colors.white12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
