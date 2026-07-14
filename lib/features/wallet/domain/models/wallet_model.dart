import 'package:asood/core/money/money.dart';

class WalletModel {
  final String id;
  final int balance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WalletModel({
    required this.id,
    required this.balance,
    this.createdAt,
    this.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id']?.toString() ?? '',
      balance: parseWholeMoney(json['balance'] ?? 0),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balance': encodeWholeMoney(balance),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class TransactionModel {
  final String id;
  final String type;
  final int amount;
  final String? description;
  final DateTime createdAt;
  final String? targetContent;
  final String? targetId;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    required this.createdAt,
    this.targetContent,
    this.targetId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      type: (json['action'] ?? json['type'])?.toString() ?? '',
      amount: parseWholeMoney(json['amount'] ?? 0),
      description: json['description']?.toString(),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      targetContent: json['target_content']?.toString(),
      targetId: json['target_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': type,
      'amount': encodeWholeMoney(amount),
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'target_content': targetContent,
      'target_id': targetId,
    };
  }
}
