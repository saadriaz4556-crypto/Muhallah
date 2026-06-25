import 'package:cloud_firestore/cloud_firestore.dart';

class RentalListing {
  final String listingId;
  final String type; // "room" | "portion" | "full_house"
  final int rentAmount;
  final String location;
  final DateTime availableFrom;
  final String furnishingStatus; // "furnished" | "semi" | "unfurnished"
  final int rooms;
  final int bathrooms;
  final bool attachedBath;
  final bool gasAvailable;
  final bool parkingAvailable;
  final List<String> imageUrls;
  final String ownerUid;
  final String ownerName;
  final String ownerPhone;
  final String status; // "available" | "rented"
  final bool isApproved;
  final DateTime createdAt;

  RentalListing({
    required this.listingId,
    required this.type,
    required this.rentAmount,
    required this.location,
    required this.availableFrom,
    required this.furnishingStatus,
    required this.rooms,
    required this.bathrooms,
    required this.attachedBath,
    required this.gasAvailable,
    required this.parkingAvailable,
    required this.imageUrls,
    required this.ownerUid,
    required this.ownerName,
    required this.ownerPhone,
    required this.status,
    this.isApproved = false,
    required this.createdAt,
  });

  factory RentalListing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RentalListing(
      listingId: doc.id,
      type: data['type'] ?? 'room',
      rentAmount: data['rentAmount'] ?? 0,
      location: data['location'] ?? '',
      availableFrom: (data['availableFrom'] as Timestamp).toDate(),
      furnishingStatus: data['furnishingStatus'] ?? 'unfurnished',
      rooms: data['rooms'] ?? 0,
      bathrooms: data['bathrooms'] ?? 0,
      attachedBath: data['attachedBath'] ?? false,
      gasAvailable: data['gasAvailable'] ?? false,
      parkingAvailable: data['parkingAvailable'] ?? false,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      ownerUid: data['ownerUid'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerPhone: data['ownerPhone'] ?? '',
      status: data['status'] ?? 'available',
      isApproved: data['isApproved'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'rentAmount': rentAmount,
      'location': location,
      'availableFrom': Timestamp.fromDate(availableFrom),
      'furnishingStatus': furnishingStatus,
      'rooms': rooms,
      'bathrooms': bathrooms,
      'attachedBath': attachedBath,
      'gasAvailable': gasAvailable,
      'parkingAvailable': parkingAvailable,
      'imageUrls': imageUrls,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'status': status,
      'isApproved': isApproved,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
