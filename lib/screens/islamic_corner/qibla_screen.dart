import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' show pi, sin, cos;

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  static const Color deepNavy = Color(0xFF252A34);
  static const Color sectionBg = Color(0xFF2A303C);
  static const Color teal = Color(0xFF08D9D6);
  static const Color premiumWhite = Color(0xFFEAEAEA);

  bool _hasPermission = false;
  bool _isLoading = true;
  String _statusText = 'Checking location permissions...';
  String _currentLocationText = 'Fetching coordinates...';

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Checking location permissions...';
    });

    try {
      var status = await Permission.locationWhenInUse.status;
      if (status.isDenied) {
        status = await Permission.locationWhenInUse.request();
      }

      if (status.isGranted) {
        // Fetch current coordinates to show in UI
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 4),
          );
          setState(() {
            _currentLocationText =
                'Lat: ${position.latitude.toStringAsFixed(4)}°, Lng: ${position.longitude.toStringAsFixed(4)}°';
          });
        } else {
          setState(() {
            _currentLocationText = 'Location services disabled. Using default.';
          });
        }

        setState(() {
          _hasPermission = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
          _statusText = 'Location permission is required for Qibla direction.';
          _currentLocationText = 'Permission Denied';
        });
      }
    } catch (e) {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
        _statusText = 'Error: ${e.toString()}';
        _currentLocationText = 'Unknown Location';
      });
    }
  }

  String _getDirectionName(double degree) {
    double deg = degree % 360;
    if (deg < 0) deg += 360;

    if (deg >= 337.5 || deg < 22.5) return 'North (شمال)';
    if (deg >= 22.5 && deg < 67.5) return 'Northeast (شمال مشرق)';
    if (deg >= 67.5 && deg < 112.5) return 'East (مشرق)';
    if (deg >= 112.5 && deg < 157.5) return 'Southeast (جنوب مشرق)';
    if (deg >= 157.5 && deg < 202.5) return 'South (جنوب)';
    if (deg >= 202.5 && deg < 247.5) return 'Southwest (جنوب مغرب)';
    if (deg >= 247.5 && deg < 292.5) return 'West (مغرب)';
    return 'Northwest (شمال مغرب)';
  }

  void _showCalibrationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: sectionBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.compass_calibration, color: teal),
              SizedBox(width: 10),
              Text(
                'Compass Calibration',
                style: TextStyle(color: premiumWhite, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To improve compass accuracy and stabilize the needle, please tilt and rotate your device in a figure-8 motion several times.',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),
              // Figure-8 illustration or icon animation placeholder
              Icon(
                Icons.screen_rotation,
                size: 64,
                color: teal.withValues(alpha: 0.8),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: teal, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
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
          'Qibla Direction',
          style: TextStyle(color: premiumWhite, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: teal),
        actions: [
          IconButton(
            onPressed: _showCalibrationDialog,
            icon: const Icon(Icons.compass_calibration, color: teal),
            tooltip: 'Calibrate Compass',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: teal))
            : !_hasPermission
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_off_outlined, color: Colors.orange, size: 72),
                          const SizedBox(height: 24),
                          Text(
                            _statusText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: premiumWhite, fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _checkLocationPermission,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: teal,
                              foregroundColor: deepNavy,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Grant Location Permission'),
                          ),
                        ],
                      ),
                    ),
                  )
                : StreamBuilder(
                    stream: FlutterQiblah.qiblahStream,
                    builder: (context, AsyncSnapshot<QiblahDirection> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: teal));
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Sensor Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }

                      final qiblahDirection = snapshot.data;
                      if (qiblahDirection == null) {
                        return const Center(
                          child: Text(
                            'No compass sensor detected or data unavailable',
                            style: TextStyle(color: Colors.white60),
                          ),
                        );
                      }

                      final qiblaAngle = qiblahDirection.offset;
                      final directionName = _getDirectionName(qiblaAngle);

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Location indicator bar
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: sectionBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, color: teal, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Compass Center',
                                            style: TextStyle(color: Colors.white30, fontSize: 11),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _currentLocationText,
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
                              const SizedBox(height: 24),

                              // Main Compass Display
                              Center(
                                child: Container(
                                  height: 310,
                                  width: 310,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: sectionBg,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // 1. Cardinal Directions Outer Dial (rotates as phone turns)
                                      Transform.rotate(
                                        angle: (qiblahDirection.direction * (pi / 180) * -1),
                                        child: CustomPaint(
                                          size: const Size(290, 290),
                                          painter: CompassDialPainter(teal: teal),
                                        ),
                                      ),

                                      // 2. Qibla Needle Pointer (rotates relative to phone & offset)
                                      Transform.rotate(
                                        angle: (qiblahDirection.qiblah * (pi / 180) * -1),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Stylized indicator needle
                                            CustomPaint(
                                              size: const Size(280, 280),
                                              painter: CompassNeedlePainter(teal: teal),
                                            ),
                                            // Kaaba/Masjid top-anchor icon inside compass
                                            Positioned(
                                              top: 20,
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: teal,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.mosque,
                                                  color: deepNavy,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Center Cap
                                      Container(
                                        height: 20,
                                        width: 20,
                                        decoration: BoxDecoration(
                                          color: deepNavy,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: teal, width: 3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Degree value & direction name display cards
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        color: sectionBg,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Qibla Offset',
                                            style: TextStyle(color: Colors.white38, fontSize: 12),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${qiblaAngle.toStringAsFixed(1)}°',
                                            style: const TextStyle(
                                              color: teal,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        color: sectionBg,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Device Heading',
                                            style: TextStyle(color: Colors.white38, fontSize: 12),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${qiblahDirection.direction.toInt()}°',
                                            style: const TextStyle(
                                              color: premiumWhite,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Direction Text Banner
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF08D9D6), Color(0xFF00B4B2)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: teal.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.explore, color: deepNavy, size: 28),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Qibla is in the $directionName direction',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: deepNavy,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Instructions Text
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  '• Keep your phone flat on a level surface.\n'
                                  '• Move away from metal objects or electromagnetic interference (computers, cars).\n'
                                  '• Rotate your phone until the needle matches the mosque indicator.',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

// Painter to draw the outer compass dial (N, E, S, W, ticks)
class CompassDialPainter extends CustomPainter {
  final Color teal;
  CompassDialPainter({required this.teal});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw main circle
    canvas.drawCircle(center, radius - 15, paint);

    // Draw cardinal direction markers
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final Map<String, double> markers = {
      'N': 0.0,
      'E': 90.0,
      'S': 180.0,
      'W': 270.0,
    };

    markers.forEach((label, angleDeg) {
      final angleRad = (angleDeg - 90) * (pi / 180); // Adjust so N is at top
      final x = center.dx + (radius - 30) * cos(angleRad);
      final y = center.dy + (radius - 30) * sin(angleRad);

      final isNorth = label == 'N';

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: isNorth ? teal : Colors.white60,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      
      final textOffset = Offset(
        x - (textPainter.width / 2),
        y - (textPainter.height / 2),
      );
      textPainter.paint(canvas, textOffset);
    });

    // Draw tick marks
    final tickPaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1.5;

    for (int i = 0; i < 360; i += 30) {
      if (i % 90 == 0) continue; // skip cardinal positions

      final rad = (i - 90) * (pi / 180); // Adjust so 0 is at top
      final x1 = center.dx + (radius - 20) * cos(rad);
      final y1 = center.dy + (radius - 20) * sin(rad);
      final x2 = center.dx + (radius - 12) * cos(rad);
      final y2 = center.dy + (radius - 12) * sin(rad);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter to draw the Qibla needle pointer
class CompassNeedlePainter extends CustomPainter {
  final Color teal;
  CompassNeedlePainter({required this.teal});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw a sleek indicator needle
    final Paint needlePaint = Paint()
      ..color = teal
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;

    final Path path = Path();
    // Needle tip (pointing up, which represents Qibla direction)
    path.moveTo(center.dx, center.dy - radius + 25);
    // Right flare
    path.lineTo(center.dx + 8, center.dy);
    // Center point
    path.lineTo(center.dx, center.dy);
    // Left flare
    path.lineTo(center.dx - 8, center.dy);
    path.close();

    canvas.drawPath(path, needlePaint);

    // Draw the tail needle (opposite side) for balance
    final Paint tailPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final Path tailPath = Path();
    tailPath.moveTo(center.dx, center.dy + radius - 25);
    tailPath.lineTo(center.dx + 5, center.dy);
    tailPath.lineTo(center.dx, center.dy);
    tailPath.lineTo(center.dx - 5, center.dy);
    tailPath.close();

    canvas.drawPath(tailPath, tailPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
