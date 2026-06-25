import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessModel {
  final String userId;
  final String businessName;
  final String category;
  final String subCategory;
  final String ownerName;
  final String address;
  final String phone;
  final String whatsapp;
  final String openTime;
  final String closeTime;
  final bool homeDelivery;
  final String imageUrl;
  final Timestamp createdAt;

  BusinessModel({
    required this.userId,
    required this.businessName,
    required this.category,
    required this.subCategory,
    required this.ownerName,
    required this.address,
    required this.phone,
    required this.whatsapp,
    required this.openTime,
    required this.closeTime,
    required this.homeDelivery,
    required this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'businessName': businessName,
      'category': category,
      'subCategory': subCategory,
      'ownerName': ownerName,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      'openTime': openTime,
      'closeTime': closeTime,
      'homeDelivery': homeDelivery,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
    };
  }

  factory BusinessModel.fromMap(Map<String, dynamic> map) {
    return BusinessModel(
      userId: map['userId'] ?? '',
      businessName: map['businessName'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      ownerName: map['ownerName'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      openTime: map['openTime'] ?? '',
      closeTime: map['closeTime'] ?? '',
      homeDelivery: map['homeDelivery'] ?? false,
      imageUrl: map['imageUrl'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}
