import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicketModel {
  final String id;
  final String userId;
  final String userEmail;
  final String subject;
  final String message;
  final String category;
  final String status; // pending, in_progress, resolved
  final String priority; // low, normal, high
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastResponse;
  final String? lastResponder;

  const SupportTicketModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.subject,
    required this.message,
    required this.category,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.lastResponse,
    this.lastResponder,
  });

  factory SupportTicketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SupportTicketModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      category: data['category'] ?? 'general',
      status: data['status'] ?? 'pending',
      priority: data['priority'] ?? 'normal',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastResponse: data['lastResponse'],
      lastResponder: data['lastResponder'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'subject': subject,
      'message': message,
      'category': category,
      'status': status,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastResponse': lastResponse,
      'lastResponder': lastResponder,
    };
  }
}
