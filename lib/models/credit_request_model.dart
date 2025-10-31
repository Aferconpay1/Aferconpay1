import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum CreditRequestStatus {
  pending,
  approved,
  rejected,
  expired;

  String get statusDisplay {
    switch (this) {
      case CreditRequestStatus.pending:
        return 'Pendente';
      case CreditRequestStatus.approved:
        return 'Aprovado';
      case CreditRequestStatus.rejected:
        return 'Rejeitado';
      case CreditRequestStatus.expired:
        return 'Expirado';
    }
  }

  Color color(ThemeData theme) {
    switch (this) {
      case CreditRequestStatus.pending:
        return Colors.orange;
      case CreditRequestStatus.approved:
        return Colors.green;
      case CreditRequestStatus.rejected:
      case CreditRequestStatus.expired:
        return theme.colorScheme.error;
    }
  }
}

class CreditRequestModel {
  final String id;
  final String userId;
  final double amount;
  final String reason;
  final CreditRequestStatus status;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  CreditRequestModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory CreditRequestModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CreditRequestModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      reason: data['reason'] ?? 'N/A',
      status: _parseStatus(data['status']),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  static CreditRequestStatus _parseStatus(String? status) {
    if (status == null) return CreditRequestStatus.pending;
    return CreditRequestStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => CreditRequestStatus.pending,
    );
  }
}
