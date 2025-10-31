import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalRequest {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final String userIban;
  final DateTime requestDate;
  final String status; // pending, completed, rejected

  WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.userIban,
    required this.requestDate,
    this.status = 'pending',
  });

  factory WithdrawalRequest.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return WithdrawalRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      userIban: data['userIban'] ?? '',
      requestDate: (data['requestDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'userIban': userIban,
      'requestDate': Timestamp.fromDate(requestDate),
      'status': status,
    };
  }
}
