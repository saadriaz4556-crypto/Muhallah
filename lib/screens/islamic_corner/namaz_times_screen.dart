import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'azan_notification_service.dart';

class NamazTimesScreen extends StatefulWidget {
  const NamazTimesScreen({super.key});

  @override
  State<NamazTimesScreen> createState() => _NamazTimesScreenState();
}

class _NamazTimesScreenState extends State<NamazTimesScreen> {
  static const Color deepNavy = Color(0xFF252A34);
  static const Color sectionBg = Color(0xFF2A303C);
  static const Color teal = Color(0xFF08D9D6);
  static const Color premiumWhite = Color(0xFFEAEAEA);

  PrayerTimes? _prayerTimes;
  bool _isLoading = true;
  String _statusMessage = 'Initializing...';
  String _currentAddress = 'Fetching location...';

  // Timer for live countdown
  Timer? _countdownTimer;
  String _nextPrayerName = '';
  String _countdownString = '--:--:--';

  // Toggle states for azan reminders
  final Map<String, bool> _azanToggles = {
    'Fajr': false,
    'Dhuhr': false,
    'Asr': false,
    'Maghrib': false,
    'Isha': false,
  };

  @override
  void initState() {
    super.initState();
    AzanNotificationService.init();
    _loadData();
    // Start countdown timer updates
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_prayerTimes != null) {
        _updateCountdown();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Requesting GPS permission...';
    });

    try {
      // 1. Check & Request Permissions using permission_handler
      var status = await Permission.locationWhenInUse.status;
      if (status.isDenied) {
        status = await Permission.locationWhenInUse.request();
      }

      double lat = 24.8607; // Default: Karachi
      double lng = 67.0011;
      _currentAddress = 'Karachi, Pakistan (Default)';

      // 2. Fetch Position if granted
      if (status.isGranted) {
        setState(() => _statusMessage = 'Checking GPS Status...');
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

        if (serviceEnabled) {
          setState(() => _statusMessage = 'Getting precise GPS Coordinates...');
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5),
          );
          lat = position.latitude;
          lng = position.longitude;
          _currentAddress =
              'GPS Coordinates: ${lat.toStringAsFixed(4)}°, ${lng.toStringAsFixed(4)}°';
        } else {
          _currentAddress = 'GPS disabled. Using Karachi (Default)';
        }
      } else {
        _currentAddress = 'Location Denied. Using Karachi (Default)';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'GPS permission denied. Showing prayer times for Karachi, Pakistan.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // 3. Calculate Prayer Times using Adhan
      setState(() => _statusMessage = 'Calculating prayer times...');
      final coordinates = Coordinates(lat, lng);
      final params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.hanafi;

      final todayTimes = PrayerTimes.today(coordinates, params);

      // 4. Load saved notification toggle states
      for (String prayer in _azanToggles.keys) {
        _azanToggles[prayer] =
            await AzanNotificationService.isPrayerEnabled(prayer);
      }

      setState(() {
        _prayerTimes = todayTimes;
        _isLoading = false;
      });

      // Sync/schedule active notification reminders
      _scheduleActiveToggles();
    } catch (e) {
      print('Error in loadData: $e');
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Schedule all notifications that are enabled
  void _scheduleActiveToggles() {
    if (_prayerTimes == null) return;

    final Map<String, DateTime> times = {
      'Fajr': _prayerTimes!.fajr,
      'Dhuhr': _prayerTimes!.dhuhr,
      'Asr': _prayerTimes!.asr,
      'Maghrib': _prayerTimes!.maghrib,
      'Isha': _prayerTimes!.isha,
    };

    final Map<String, String> urduNames = {
      'Fajr': 'فجر',
      'Dhuhr': 'ظہر',
      'Asr': 'عصر',
      'Maghrib': 'مغرب',
      'Isha': 'عشاء',
    };

    times.forEach((prayerName, prayerTime) {
      final isEnabled = _azanToggles[prayerName] ?? false;
      final int id = prayerName.hashCode;
      if (isEnabled) {
        AzanNotificationService.schedulePrayerReminder(
          id: id,
          prayerName: prayerName,
          prayerUrdu: urduNames[prayerName]!,
          prayerTime: prayerTime,
        );
      } else {
        AzanNotificationService.cancelPrayerReminder(id);
      }
    });
  }

  void _updateCountdown() {
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
        // No more prayers today. Next is tomorrow's Fajr!
        name = 'Fajr (Tomorrow)';
        nextTime = _prayerTimes!.fajr.add(const Duration(days: 1));
        break;
    }

    final diff = nextTime.difference(DateTime.now());
    if (diff.isNegative) {
      setState(() {
        _countdownString = '00:00:00';
        _nextPrayerName = name;
      });
    } else {
      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
      setState(() {
        _countdownString = '$hours:$minutes:$seconds';
        _nextPrayerName = name;
      });
    }
  }

  Future<void> _onToggleChanged(String prayerName, bool value) async {
    setState(() {
      _azanToggles[prayerName] = value;
    });
    await AzanNotificationService.setPrayerEnabled(prayerName, value);

    if (_prayerTimes == null) return;
    final int id = prayerName.hashCode;

    if (value) {
      DateTime? prayerTime;
      String urdu = '';
      switch (prayerName) {
        case 'Fajr':
          prayerTime = _prayerTimes!.fajr;
          urdu = 'فجر';
          break;
        case 'Dhuhr':
          prayerTime = _prayerTimes!.dhuhr;
          urdu = 'ظہر';
          break;
        case 'Asr':
          prayerTime = _prayerTimes!.asr;
          urdu = 'عصر';
          break;
        case 'Maghrib':
          prayerTime = _prayerTimes!.maghrib;
          urdu = 'مغرب';
          break;
        case 'Isha':
          prayerTime = _prayerTimes!.isha;
          urdu = 'عشاء';
          break;
      }

      if (prayerTime != null) {
        await AzanNotificationService.schedulePrayerReminder(
          id: id,
          prayerName: prayerName,
          prayerUrdu: urdu,
          prayerTime: prayerTime,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 Azan reminder enabled for $prayerName'),
            backgroundColor: teal,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await AzanNotificationService.cancelPrayerReminder(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔕 Azan reminder disabled for $prayerName'),
          backgroundColor: Colors.white24,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildPrayerCard({
    required String nameEng,
    required String nameUrdu,
    required DateTime prayerTime,
    required bool isNext,
  }) {
    final String formattedTime = DateFormat('h:mm a').format(prayerTime);
    final String label = '$nameEng / $nameUrdu';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isNext ? teal.withValues(alpha: 0.12) : sectionBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNext ? teal : Colors.white.withValues(alpha: 0.05),
          width: isNext ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Active dot / icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isNext
                  ? teal.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time_filled,
              color: isNext ? teal : Colors.white30,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Prayer Names
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isNext ? teal : premiumWhite,
                    fontSize: 18,
                    fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                if (isNext)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Next Prayer (in $_countdownString)',
                      style: const TextStyle(
                        color: teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Time and Toggle
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedTime,
                style: TextStyle(
                  color: isNext ? teal : premiumWhite,
                  fontSize: 18,
                  fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // Azan notification toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _azanToggles[nameEng] == true
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    size: 14,
                    color:
                        _azanToggles[nameEng] == true ? teal : Colors.white24,
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 24,
                    width: 40,
                    child: Switch(
                      value: _azanToggles[nameEng] ?? false,
                      onChanged: (val) => _onToggleChanged(nameEng, val),
                      activeThumbColor: teal,
                      activeTrackColor: teal.withValues(alpha: 0.3),
                      inactiveThumbColor: Colors.white38,
                      inactiveTrackColor: Colors.white10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final next = _prayerTimes?.nextPrayer();

    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        backgroundColor: deepNavy,
        elevation: 0,
        title: const Text(
          'Namaz Times',
          style: TextStyle(color: premiumWhite, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: teal),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: teal),
            tooltip: 'Refresh Location',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: teal),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ],
                ),
              )
            : _prayerTimes == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_off,
                            color: Colors.white24, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'Could not calculate prayer times.',
                          style: TextStyle(color: premiumWhite, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: teal,
                            foregroundColor: deepNavy,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: teal,
                    backgroundColor: sectionBg,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Location Banner
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: sectionBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.03)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.my_location,
                                  color: teal, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Location',
                                      style: TextStyle(
                                          color: Colors.white38, fontSize: 11),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _currentAddress,
                                      style: const TextStyle(
                                        color: premiumWhite,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Countdown Banner
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF08D9D6), Color(0xFF00B4B2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: teal.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'NEXT PRAYER',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _nextPrayerName.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 28,
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _countdownString,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 24,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Prayer Cards
                        _buildPrayerCard(
                          nameEng: 'Fajr',
                          nameUrdu: 'فجر',
                          prayerTime: _prayerTimes!.fajr,
                          isNext: next == Prayer.fajr,
                        ),
                        _buildPrayerCard(
                          nameEng: 'Dhuhr',
                          nameUrdu: 'ظہر',
                          prayerTime: _prayerTimes!.dhuhr,
                          isNext: next == Prayer.dhuhr,
                        ),
                        _buildPrayerCard(
                          nameEng: 'Asr',
                          nameUrdu: 'عصر',
                          prayerTime: _prayerTimes!.asr,
                          isNext: next == Prayer.asr,
                        ),
                        _buildPrayerCard(
                          nameEng: 'Maghrib',
                          nameUrdu: 'مغرب',
                          prayerTime: _prayerTimes!.maghrib,
                          isNext: next == Prayer.maghrib,
                        ),
                        _buildPrayerCard(
                          nameEng: 'Isha',
                          nameUrdu: 'عشاء',
                          prayerTime: _prayerTimes!.isha,
                          isNext: next == Prayer.isha,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
