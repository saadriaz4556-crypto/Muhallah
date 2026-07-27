import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single document in the `panic_alerts` Firestore collection.
class PanicAlertModel {
  final String id;
  final String userId;
  final String userName;
  final String phoneNumber;
  final String houseNumber;
  final String mohallahId;
  final double latitude;
  final double longitude;

  /// "community" or "admin_only"
  final String alertType;

  /// "active" or "resolved"
  final String status;

  final DateTime createdAt;
  final DateTime? resolvedAt;

  const PanicAlertModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.phoneNumber,
    required this.houseNumber,
    required this.mohallahId,
    required this.latitude,
    required this.longitude,
    required this.alertType,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  factory PanicAlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PanicAlertModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Unknown',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      houseNumber: data['houseNumber'] as String? ?? '',
      mohallahId: data['mohallahId'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      alertType: data['alertType'] as String? ?? 'community',
      status: data['status'] as String? ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'phoneNumber': phoneNumber,
      'houseNumber': houseNumber,
      'mohallahId': mohallahId,
      'latitude': latitude,
      'longitude': longitude,
      'alertType': alertType,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
    };
  }
}
