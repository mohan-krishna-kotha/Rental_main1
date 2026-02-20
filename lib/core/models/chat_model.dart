import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String itemId;
  final String ownerId;
  final String renterId;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageAt;
  final DateTime createdAt;

  final int ownerUnreadCount;
  final int renterUnreadCount;
  
  // Denormalized Data
  final String ownerName;
  final String? ownerImage;
  final String renterName;
  final String? renterImage;
  final String itemName;
  final String? itemImage;

  ChatModel({
    required this.id,
    required this.itemId,
    required this.ownerId,
    required this.renterId,
    required this.lastMessage,
    this.lastMessageSenderId = '',
    required this.lastMessageAt,
    required this.createdAt,
    this.ownerUnreadCount = 0,
    this.renterUnreadCount = 0,
    this.ownerName = '',
    this.ownerImage,
    this.renterName = '',
    this.renterImage,
    this.itemName = '',
    this.itemImage,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      renterId: data['renterId'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ownerUnreadCount: data['ownerUnreadCount'] ?? 0,
      renterUnreadCount: data['renterUnreadCount'] ?? 0,
      ownerName: data['ownerName'] ?? 'Owner',
      ownerImage: data['ownerImage'],
      renterName: data['renterName'] ?? 'Renter',
      renterImage: data['renterImage'],
      itemName: data['itemName'] ?? 'Item',
      itemImage: data['itemImage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'ownerId': ownerId,
      'renterId': renterId,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'ownerUnreadCount': ownerUnreadCount,
      'renterUnreadCount': renterUnreadCount,
      'ownerName': ownerName,
      'ownerImage': ownerImage,
      'renterName': renterName,
      'renterImage': renterImage,
      'itemName': itemName,
      'itemImage': itemImage,
    };
  }

  ChatModel copyWith({
    String? id,
    String? itemId,
    String? ownerId,
    String? renterId,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    int? ownerUnreadCount,
    int? renterUnreadCount,
    String? ownerName,
    String? ownerImage,
    String? renterName,
    String? renterImage,
    String? itemName,
    String? itemImage,
  }) {
    return ChatModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      ownerId: ownerId ?? this.ownerId,
      renterId: renterId ?? this.renterId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      ownerUnreadCount: ownerUnreadCount ?? this.ownerUnreadCount,
      renterUnreadCount: renterUnreadCount ?? this.renterUnreadCount,
      ownerName: ownerName ?? this.ownerName,
      ownerImage: ownerImage ?? this.ownerImage,
      renterName: renterName ?? this.renterName,
      renterImage: renterImage ?? this.renterImage,
      itemName: itemName ?? this.itemName,
      itemImage: itemImage ?? this.itemImage,
    );
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}
