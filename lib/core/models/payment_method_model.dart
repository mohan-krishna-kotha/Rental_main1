import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

enum PaymentMethodType { card, upi, netbanking, wallet }

class PaymentMethodModel {
  final String id;
  final String userId;
  final PaymentMethodType type;

  // Card fields (masked for security — only last 4 digits stored)
  final String? cardLast4;
  final String? cardBrand; // Visa, Mastercard, Rupay
  final String? cardExpiry; // MM/YY
  final String? cardHolderName;

  // UPI fields
  final String? upiId;
  final String? upiApp; // Google Pay, PhonePe, etc.

  // Netbanking fields
  final String? bankName;

  // Wallet fields
  final String? walletName; // Amazon Pay, Paytm, etc.

  final bool isDefault;
  final DateTime createdAt;

  PaymentMethodModel({
    String? id,
    required this.userId,
    required this.type,
    this.cardLast4,
    this.cardBrand,
    this.cardExpiry,
    this.cardHolderName,
    this.upiId,
    this.upiApp,
    this.bankName,
    this.walletName,
    this.isDefault = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // ---- Display helpers ----
  String get displayTitle {
    switch (type) {
      case PaymentMethodType.card:
        return '${cardBrand ?? 'Card'} •••• ${cardLast4 ?? '****'}';
      case PaymentMethodType.upi:
        return upiId ?? 'UPI';
      case PaymentMethodType.netbanking:
        return bankName ?? 'Netbanking';
      case PaymentMethodType.wallet:
        return walletName ?? 'Wallet';
    }
  }

  String get displaySubtitle {
    switch (type) {
      case PaymentMethodType.card:
        return 'Expires ${cardExpiry ?? 'N/A'} · ${cardHolderName ?? ''}';
      case PaymentMethodType.upi:
        return upiApp ?? 'UPI Payment';
      case PaymentMethodType.netbanking:
        return 'Net Banking';
      case PaymentMethodType.wallet:
        return 'Digital Wallet';
    }
  }

  String get typeString {
    switch (type) {
      case PaymentMethodType.card:
        return 'card';
      case PaymentMethodType.upi:
        return 'upi';
      case PaymentMethodType.netbanking:
        return 'netbanking';
      case PaymentMethodType.wallet:
        return 'wallet';
    }
  }

  static PaymentMethodType typeFromString(String s) {
    switch (s) {
      case 'upi':
        return PaymentMethodType.upi;
      case 'netbanking':
        return PaymentMethodType.netbanking;
      case 'wallet':
        return PaymentMethodType.wallet;
      default:
        return PaymentMethodType.card;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'type': typeString,
      'cardLast4': cardLast4,
      'cardBrand': cardBrand,
      'cardExpiry': cardExpiry,
      'cardHolderName': cardHolderName,
      'upiId': upiId,
      'upiApp': upiApp,
      'bankName': bankName,
      'walletName': walletName,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PaymentMethodModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentMethodModel(
      id: data['id'] ?? doc.id,
      userId: data['userId'] ?? '',
      type: PaymentMethodModel.typeFromString(data['type'] ?? 'card'),
      cardLast4: data['cardLast4'],
      cardBrand: data['cardBrand'],
      cardExpiry: data['cardExpiry'],
      cardHolderName: data['cardHolderName'],
      upiId: data['upiId'],
      upiApp: data['upiApp'],
      bankName: data['bankName'],
      walletName: data['walletName'],
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  PaymentMethodModel copyWith({bool? isDefault}) {
    return PaymentMethodModel(
      id: id,
      userId: userId,
      type: type,
      cardLast4: cardLast4,
      cardBrand: cardBrand,
      cardExpiry: cardExpiry,
      cardHolderName: cardHolderName,
      upiId: upiId,
      upiApp: upiApp,
      bankName: bankName,
      walletName: walletName,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
    );
  }
}
