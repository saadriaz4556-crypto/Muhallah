import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MasjidFinderScreen extends StatefulWidget {
  const MasjidFinderScreen({super.key});

  @override
  State<MasjidFinderScreen> createState() => _MasjidFinderScreenState();
}

class _MasjidFinderScreenState extends State<MasjidFinderScreen> {
  static const Color deepNavy = Color(0xFF252A34);
  static const Color teal = Color(0xFF08D9D6);
  static const Color premiumWhite = Color(0xFFEAEAEA);

  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      );
    });

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
      LatLng(position.latitude, position.longitude),
      15.0,
    ));

    _fetchNearbyMosques(position);
  }

  void _fetchNearbyMosques(Position pos) {
    // Implement Google Places API or Custom Backend Call here
    // For now, let's just show a mock marker nearby
    setState(() {
      _markers.add(Marker(
        markerId: const MarkerId('mosque_1'),
        position: LatLng(pos.latitude + 0.002, pos.longitude + 0.002),
        infoWindow: const InfoWindow(title: 'Jamia Masjid Mock'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        backgroundColor: deepNavy,
        title:
            const Text('Masjid Finder', style: TextStyle(color: premiumWhite)),
        iconTheme: const IconThemeData(color: teal),
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator(color: teal))
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    _currentPosition!.latitude, _currentPosition!.longitude),
                zoom: 15.0,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
    );
  }
}
