
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String phoneNumber;
  final String? photoURL;
  final double balance;
  final bool isAdmin;
  final Timestamp createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phoneNumber,
    this.photoURL,
    required this.balance,
    this.isAdmin = false,
    required this.createdAt,
  });

  // Factory constructor to create a UserModel from a Firestore DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      photoURL: data['photoURL'],
      balance: (data['balance'] ?? 0.0).toDouble(),
      isAdmin: data['isAdmin'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
