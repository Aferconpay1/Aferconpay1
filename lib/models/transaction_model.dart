import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { credit, debit, withdrawalPending, unknown }

extension TransactionTypeExtension on TransactionType {
  String toDisplayString() {
    switch (this) {
      case TransactionType.credit:
        return 'Crédito';
      case TransactionType.debit:
        return 'Débito';
      case TransactionType.withdrawalPending:
        return 'Levantamento Pendente';
      default:
        return 'Desconhecido';
    }
  }
}

class Transaction {
  final String? id;
  final double amount;
  final String description;
  final TransactionType type;
  final DateTime timestamp;
  final String? relatedUserId;

  Transaction({
    this.id,
    required this.amount,
    required this.description,
    required this.type,
    required this.timestamp,
    this.relatedUserId,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    TransactionType type;
    switch (data['type']) {
      case 'credit':
        type = TransactionType.credit;
        break;
      case 'debit':
        type = TransactionType.debit;
        break;
      case 'withdrawal_pending':
        type = TransactionType.withdrawalPending;
        break;
      default:
        type = TransactionType.unknown;
        break;
    }

    return Transaction(
      id: doc.id,
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] ?? 'Transação desconhecida',
      type: type,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      relatedUserId: data['relatedUserId'] as String?,
    );
  }
}
