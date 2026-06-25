import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rental_listing_model.dart';

class RentalListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'rental_listings';

  // Fetch only approved listings
  Stream<List<RentalListing>> fetchApprovedListings() {
    return _firestore
        .collection(_collection)
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentalListing.fromFirestore(doc))
            .toList());
  }

  // Add a new listing (isApproved = false by default)
  Future<void> addListing(RentalListing listing) async {
    await _firestore.collection(_collection).add(listing.toMap());
  }

  // Mark listing as rented
  Future<void> markAsRented(String listingId) async {
    await _firestore.collection(_collection).doc(listingId).update({
      'status': 'rented',
    });
  }
}
