import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'namaz_times_screen.dart';
import 'qibla_screen.dart';
import 'six_kalimat_screen.dart';
class IslamicCornerScreen extends StatefulWidget {
  const IslamicCornerScreen({super.key});

  @override
  State<IslamicCornerScreen> createState() => _IslamicCornerScreenState();
}

class _IslamicCornerScreenState extends State<IslamicCornerScreen> {
  static const Color deepNavy = Color(0xFF252A34);
  static const Color sectionBg = Color(0xFF2A303C);
  static const Color teal = Color(0xFF08D9D6);
  static const Color premiumWhite = Color(0xFFEAEAEA);

  PrayerTimes? _prayerTimes;
  Timer? _homeTimer;
  String _hijriDateString = '';
  String _nextPrayerString = 'Loading...';
  String _countdownString = '--:--:--';

  @override
  void initState() {
    super.initState();
    _hijriDateString = _calculateHijriDate();
    _loadPrayerTimes();

    // Refresh times and countdown every second
    _homeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateLiveHomeBanner();
    });
  }

  @override
  void dispose() {
    _homeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      double lat = 24.8607; // Default: Karachi
      double lng = 67.0011;

      // Silent location check
      final status = await Permission.locationWhenInUse.status;
      if (status.isGranted) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 2),
          );
          lat = position.latitude;
          lng = position.longitude;
        }
      }

      final coordinates = Coordinates(lat, lng);
      final params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.hanafi;

      setState(() {
        _prayerTimes = PrayerTimes.today(coordinates, params);
      });
      _updateLiveHomeBanner();
    } catch (e) {
      print('Silent prayer calculation failed: $e');
      // Fallback calculation
      final coordinates = Coordinates(24.8607, 67.0011);
      final params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.hanafi;
      setState(() {
        _prayerTimes = PrayerTimes.today(coordinates, params);
      });
    }
  }

  void _updateLiveHomeBanner() {
    if (_prayerTimes == null) return;

    final next = _prayerTimes!.nextPrayer();
    DateTime? nextTime;
    String name = '';

    switch (next) {
      case Prayer.fajr:
        nextTime = _prayerTimes!.fajr;
        name = 'Fajr';
        break;
      case Prayer.sunrise:
        nextTime = _prayerTimes!.sunrise;
        name = 'Sunrise';
        break;
      case Prayer.dhuhr:
        nextTime = _prayerTimes!.dhuhr;
        name = 'Dhuhr';
        break;
      case Prayer.asr:
        nextTime = _prayerTimes!.asr;
        name = 'Asr';
        break;
      case Prayer.maghrib:
        nextTime = _prayerTimes!.maghrib;
        name = 'Maghrib';
        break;
      case Prayer.isha:
        nextTime = _prayerTimes!.isha;
        name = 'Isha';
        break;
      case Prayer.none:
      default:
        name = 'Fajr';
        nextTime = _prayerTimes!.fajr.add(const Duration(days: 1));
        break;
    }

    final diff = nextTime.difference(DateTime.now());
    if (diff.isNegative) {
      setState(() {
        _nextPrayerString = name;
        _countdownString = '00:00:00';
      });
    } else {
      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
      setState(() {
        _nextPrayerString = name;
        _countdownString = '$hours:$minutes:$seconds';
      });
    }
  }

  // Robust Gregorian to Hijri converter algorithm
  String _calculateHijriDate() {
    final date = DateTime.now();
    int day = date.day;
    int month = date.month;
    int year = date.year;

    int jd;
    if ((year > 1582) ||
        ((year == 1582) && (month > 10)) ||
        ((year == 1582) && (month == 10) && (day >= 15))) {
      jd = ((1461 * (year + 4800 + ((month - 14) / 12).toInt())) / 4).toInt() +
          ((367 * (month - 2 - 12 * (((month - 14) / 12).toInt()))) / 12)
              .toInt() -
          ((3 * (((year + 4900 + ((month - 14) / 12).toInt()) / 100).toInt())) /
                  4)
              .toInt() +
          day -
          32075;
    } else {
      jd = 367 * year -
          ((7 * (year + 5001 + ((month - 9) / 7).toInt())) / 4).toInt() +
          ((275 * month) / 9).toInt() +
          day +
          1729777;
    }

    int l = jd - 1948440 + 10632;
    int n = ((l - 1) / 10631).toInt();
    l = l - 10631 * n + 354;
    int j = (((10985 - l) / 5316).toInt() * ((50 * l) / 17719).toInt() +
            ((l / 5670).toInt() * ((43 * l) / 15238).toInt()))
        .toInt();
    l = l -
        ((30 - j) / 15).toInt() * ((17719 * j) / 50).toInt() -
        ((j / 16).toInt() * ((15238 * j) / 43).toInt()) +
        29;
    int m = ((24 * l) / 709).toInt();
    int d = l - ((709 * m) / 24).toInt();
    int y = 30 * n + j - 30;

    final months = [
      'Muharram',
      'Safar',
      'Rabi\' al-Awwal',
      'Rabi\' al-Thani',
      'Jumada al-Awwal',
      'Jumada al-Thani',
      'Rajab',
      'Sha\'ban',
      'Ramadan',
      'Shawwal',
      'Dhu al-Qi\'dah',
      'Dhu al-Hijjah'
    ];

    if (m < 1 || m > 12) return '${day}th Hijri Month';
    String monthName = months[m - 1];
    return "$d $monthName $y AH";
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Widget targetPage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: sectionBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => targetPage),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Icon wrapper with nice gradient or color tint
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: teal.withValues(alpha: 0.15)),
                  ),
                  child: Icon(
                    icon,
                    color: teal,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 20),

                // Text labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: premiumWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow indicator
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        backgroundColor: deepNavy,
        elevation: 0,
        title: const Text(
          'Islamic Corner',
          style: TextStyle(color: premiumWhite, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: teal),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Welcome greeting
              const Text(
                'Digital Mohallah',
                style: TextStyle(
                    color: teal,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              const Text(
                'Islamic Hub',
                style: TextStyle(
                    color: premiumWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),

              // Dynamic Home Live Banner
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF08D9D6), Color(0xFF00B4B2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: teal.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calendar_month,
                                size: 16, color: Colors.black54),
                            SizedBox(width: 6),
                            Text(
                              'HIJRI DATE',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hijriDateString,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Divider(
                        color: Colors.black12, height: 28, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NEXT PRAYER',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _nextPrayerString.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'COUNTDOWN',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _countdownString,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 20,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Feature Grid Section Title
              const Text(
                'Core Features',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // 3-Tile List / Cards
              _buildFeatureCard(
                title: 'Namaz Times',
                description:
                    'Accurate local prayer timings and dynamic countdowns',
                icon: Icons.access_time_rounded,
                targetPage: const NamazTimesScreen(),
              ),
              _buildFeatureCard(
                title: 'Qibla Direction',
                description:
                    'Real-time compass indicator pointing directly to Kaaba',
                icon: Icons.explore_rounded,
                targetPage: const QiblaScreen(),
              ),
              _buildFeatureCard(
                title: '6 Kalimat',
                description:
                    'Read and bookmark 6 Islamic Kalimas with translations',
                icon: Icons.auto_stories_rounded,
                targetPage: const SixKalimatScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
