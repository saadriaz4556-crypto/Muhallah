import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:muhallah/models/panic_alert_model.dart';

/// Service for all Firestore interactions with the `panic_alerts` collection.
/// This service is READ-ONLY for the `users` collection — it never modifies
/// any existing collection or document field.
class PanicAlertService {
  PanicAlertService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ─────────────────────────────────────────────
  // Location helpers
  // ─────────────────────────────────────────────

  /// Requests permission (if needed) and returns the current GPS position.
  /// Throws a descriptive [Exception] if permission is denied or GPS is off.
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable GPS and try again.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission was denied. Please allow location access to send an alert.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Please enable it from device settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // User profile helpers (READ-ONLY on `users`)
  // ─────────────────────────────────────────────

  /// Fetches the current user's profile fields needed for a panic alert.
  /// Returns a map with keys: userName, phoneNumber, houseNumber, mohallahId, isAdmin.
  Future<Map<String, dynamic>> fetchCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('You must be logged in to send an alert.');

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      // Graceful fallback — still allow alert with minimal data
      return {
        'userName': user.displayName ?? user.email ?? 'Resident',
        'phoneNumber': '',
        'houseNumber': '',
        'mohallahId': 'default',
        'isAdmin': false,
      };
    }

    final data = doc.data()!;
    return {
      'userName': data['fullName'] as String? ?? 'Resident',
      // Registration stores phone as 'phone'
      'phoneNumber': data['phone'] as String? ?? '',
      // Use fullAddress as house/location identifier
      'houseNumber': data['fullAddress'] as String? ?? '',
      // Use 'area' (Tehsil/Town) as the mohallah grouping key
      'mohallahId': data['area'] as String? ?? 'default',
      'isAdmin': data['isAdmin'] as bool? ?? false,
    };
  }

  // ─────────────────────────────────────────────
  // Write: Create panic alert
  // ─────────────────────────────────────────────

  /// Creates a new panic alert document in the `panic_alerts` collection.
  /// [alertType] must be either "community" or "admin_only".
  Future<String> sendPanicAlert({
    required String alertType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('You must be logged in to send an alert.');

    // 1. Fetch GPS + user profile in parallel
    final results = await Future.wait([
      getCurrentLocation(),
      fetchCurrentUserProfile(),
    ]);

    final position = results[0] as Position;
    final profile = results[1] as Map<String, dynamic>;

    // 2. Build the alert document
    final alertData = {
      'userId': user.uid,
      'userName': profile['userName'],
      'phoneNumber': profile['phoneNumber'],
      'houseNumber': profile['houseNumber'],
      'mohallahId': profile['mohallahId'],
      'latitude': position.latitude,
      'longitude': position.longitude,
      'alertType': alertType, // "community" | "admin_only"
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
    };

    // 3. Write to Firestore
    final ref = await _firestore.collection('panic_alerts').add(alertData);
    return ref.id;
  }

  // ─────────────────────────────────────────────
  // Write: Resolve alert
  // ─────────────────────────────────────────────

  /// Updates status to "resolved" and sets resolvedAt timestamp.
  /// Only the original creator should call this (enforced by Firestore rules).
  Future<void> resolveAlert(String alertId) async {
    await _firestore.collection('panic_alerts').doc(alertId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes the alert document from the `panic_alerts` collection.
  Future<void> deleteAlert(String alertId) async {
    await _firestore.collection('panic_alerts').doc(alertId).delete();
  }

  // ─────────────────────────────────────────────
  // Read: Real-time streams
  // ─────────────────────────────────────────────

  /// Returns a real-time stream of ACTIVE alerts for a given mohallahId.
  /// - If [isAdmin] is true → returns both "community" and "admin_only" alerts.
  /// - If [isAdmin] is false → returns only "community" alerts.
  Stream<List<PanicAlertModel>> activeAlertsStream({
    required String mohallahId,
    required bool isAdmin,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('panic_alerts')
        .where('mohallahId', isEqualTo: mohallahId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true);

    if (!isAdmin) {
      // Non-admin residents only see community alerts
      query = query.where('alertType', isEqualTo: 'community');
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => PanicAlertModel.fromFirestore(doc))
              .toList(),
        );
  }
}
