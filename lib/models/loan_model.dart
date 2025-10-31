import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';

enum LoanType {
  personal,
  automovel,
  habitacao,
  formacao,
  negocios,
}

enum LoanStatus { 
  pending, 
  approved, 
  rejected, 
  paid 
}

// --- Extensões para Enums ---

extension LoanTypeExtension on LoanType {
  String get typeDisplay {
    switch (this) {
      case LoanType.personal: return 'Crédito Pessoal';
      case LoanType.automovel: return 'Crédito Automóvel';
      case LoanType.habitacao: return 'Crédito Habitação';
      case LoanType.formacao: return 'Crédito Formação';
      case LoanType.negocios: return 'Crédito Negócios';
    }
  }

  IconData get icon {
     switch (this) {
      case LoanType.personal: return Iconsax.user;
      case LoanType.automovel: return Iconsax.car;
      case LoanType.habitacao: return Iconsax.home_2;
      case LoanType.formacao: return Iconsax.book;
      case LoanType.negocios: return Iconsax.briefcase;
    }
  }
}

extension LoanStatusExtension on LoanStatus {
  String get statusDisplay {
    switch (this) {
      case LoanStatus.pending: return 'Pendente';
      case LoanStatus.approved: return 'Aprovado';
      case LoanStatus.rejected: return 'Rejeitado';
      case LoanStatus.paid: return 'Liquidado';
    }
  }

  IconData get icon {
     switch (this) {
      case LoanStatus.approved: return Iconsax.tick_circle;
      case LoanStatus.rejected: return Iconsax.close_circle;
      case LoanStatus.paid: return Iconsax.like_1;
      case LoanStatus.pending: return Iconsax.clock;
    }
  }

  Color color(ThemeData theme) {
     switch (this) {
      case LoanStatus.approved: return Colors.green.shade600;
      case LoanStatus.rejected: return theme.colorScheme.error;
      case LoanStatus.paid: return theme.colorScheme.primary;
      case LoanStatus.pending: return Colors.orange.shade600;
    }
  }
}

// --- Modelo de Dados ---

class LoanModel {
  final String id;
  final String userId;
  final double amount;
  final LoanType type;
  final int termInMonths; // Prazo em meses
  final LoanStatus status;
  final Timestamp requestedAt;
  final Timestamp? updatedAt;

  LoanModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.termInMonths,
    this.status = LoanStatus.pending,
    required this.requestedAt,
    this.updatedAt,
  });

  factory LoanModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LoanModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] as num? ?? 0).toDouble(),
      type: LoanType.values.firstWhere((e) => e.name == data['type'], orElse: () => LoanType.personal),
      termInMonths: (data['termInMonths'] as int? ?? 2), // Default de 2 meses se não existir
      status: LoanStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => LoanStatus.pending),
      requestedAt: data['requestedAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'termInMonths': termInMonths,
      'status': status.name,
      'requestedAt': requestedAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }
}
