import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muhallah/models/business_model.dart';

class BusinessService {
  static Future<void> createBusiness(BusinessModel business) async {
    final firestore = FirebaseFirestore.instance;

    // Ensure userId exists (should be provided by caller)
    await firestore.collection('businesses').add(business.toMap());
  }

  static String? currentUid() => FirebaseAuth.instance.currentUser?.uid;
}
