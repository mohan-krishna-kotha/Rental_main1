import 'package:cloud_firestore/cloud_firestore.dart';

class SupportFaqModel {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int displayOrder;
  final DateTime? updatedAt;

  const SupportFaqModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.displayOrder,
    this.updatedAt,
  });

  factory SupportFaqModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SupportFaqModel(
      id: doc.id,
      question: data['question'] ?? 'Untitled question',
      answer: data['answer'] ?? 'Details will be added soon.',
      category: data['category'] ?? 'General',
      displayOrder: (data['displayOrder'] is int)
          ? data['displayOrder'] as int
          : int.tryParse('${data['displayOrder']}') ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'answer': answer,
      'category': category,
      'displayOrder': displayOrder,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
