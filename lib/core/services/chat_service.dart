import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
// Import for ProductModel if needed, though passing IDs is cleaner

class ChatService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChatService(this._firestore, this._auth);

  /// Creates a new chat or returns existing one between current user and owner for an item
  Future<String> createOrGetChat({
    required String itemId,
    required String ownerId,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not logged in');

    // Check for existing chat
    // Note: This query requires a composite index: itemId ASC, renterId ASC (or ownerId ASC)
    // To avoid index creation during dev, we can query by itemId and filter client side or just one field.
    // Given the constraints and likely low volume per item/user pair, querying by itemId and filtering is safer for now
    // OR query where 'itemId' == itemId AND 'renterId' == currentUserId

    // Let's try to query by itemId and members (renterId/ownerId)
    // Case 1: Current user is Renter. OwnerId is item owner.
    // Case 2: Current user is Owner. (Should typically be initiated by renter, but let's handle generic)

    // We assume RENTER initiates.
    final renterId = currentUserId;

    final query = await _firestore
        .collection('chats')
        .where('itemId', isEqualTo: itemId)
        .where('renterId', isEqualTo: renterId)
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    // Create new chat
    // Optimization: Fetch details to denormalize
    final renterDoc = await _firestore.collection('users').doc(renterId).get();
    final ownerDoc = await _firestore.collection('users').doc(ownerId).get();
    final productDoc = await _firestore
        .collection('products')
        .doc(itemId)
        .get();

    final renterData = renterDoc.data();
    final ownerData = ownerDoc.data();
    final productData = productDoc.data();

    // Safely extract data
    final String renterName = renterData?['displayName'] ?? 'Renter';
    final String? renterImage = renterData?['photoURL'];
    final String ownerName = ownerData?['displayName'] ?? 'Owner';
    final String? ownerImage = ownerData?['photoURL'];
    // Product data fields might vary, checking ProductModel
    final String itemName = productData?['title'] ?? 'Item';
    final List<dynamic>? images = productData?['imageUrls'];
    final String? itemImage = (images != null && images.isNotEmpty)
        ? images.first as String
        : null;

    final chatDoc = _firestore.collection('chats').doc();
    final chat = ChatModel(
      id: chatDoc.id,
      itemId: itemId,
      ownerId: ownerId,
      renterId: renterId,
      lastMessage: '',
      lastMessageAt: DateTime.now(),
      createdAt: DateTime.now(),
      ownerName: ownerName,
      ownerImage: ownerImage,
      renterName: renterName,
      renterImage: renterImage,
      itemName: itemName,
      itemImage: itemImage,
    );

    await chatDoc.set(chat.toMap());
    return chatDoc.id;
  }

  /// Sends a message and updates the chat metadata
  Future<void> sendMessage(String chatId, String text) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not logged in');

    final messageDoc = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final message = MessageModel(
      id: messageDoc.id,
      senderId: currentUserId,
      text: text,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();

    // Add message
    batch.set(messageDoc, message.toMap());

    // Update chat last message and UNREAD COUNTS
    // We need to know if current user is owner or renter to increment the OTHER counter.
    // However, simplest way effectively is to read the chat first or blindly increment based on field check?
    // Firestore increment requires knowing the field name.
    // Optimization: We can't know which field to increment without knowing if I am owner or renter.
    // Fetch chat doc first? Or assume the caller passes this info?
    // Let's fetch the chat doc briefly or use a transaction if critical.
    // For simplicity, let's just fetch it in this method (it's fast).

    final chatDocRef = _firestore.collection('chats').doc(chatId);
    final chatSnap = await chatDocRef.get();
    if (!chatSnap.exists) throw Exception('Chat not found');

    final chatData = chatSnap.data()!;
    final ownerId = chatData['ownerId'];
    final renterId =
        chatData['renterId']; // Although redundant if we knew who we were.

    // Determine who is the receiver
    String fieldToIncrement = '';
    if (currentUserId == ownerId) {
      fieldToIncrement = 'renterUnreadCount';
    } else if (currentUserId == renterId) {
      fieldToIncrement = 'ownerUnreadCount';
    }

    final updates = <String, dynamic>{
      'lastMessage': text,
      'lastMessageSenderId': currentUserId,
      'lastMessageAt': FieldValue.serverTimestamp(),
    };

    if (fieldToIncrement.isNotEmpty) {
      updates[fieldToIncrement] = FieldValue.increment(1);
    }

    batch.update(chatDocRef, updates);

    await batch.commit();
  }

  /// Marks a chat as read for the current user
  Future<void> markChatAsRead(String chatId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final chatDocRef = _firestore.collection('chats').doc(chatId);

    // 1. Reset Unread Count on Chat Document
    final chatSnap = await chatDocRef.get();
    if (!chatSnap.exists) return;

    final chatData = chatSnap.data()!;
    final ownerId = chatData['ownerId'];
    final renterId = chatData['renterId'];

    final batch = _firestore.batch();

    // Reset Owner Count if I am the owner
    if (currentUserId == ownerId) {
      batch.update(chatDocRef, {'ownerUnreadCount': 0});
    }

    // Reset Renter Count if I am the renter
    if (currentUserId == renterId) {
      batch.update(chatDocRef, {'renterUnreadCount': 0});
    }

    // 2. Mark individual messages as read
    // We want to mark messages sent by the *other* person as read.
    // Query: messages where senderId != currentUserId AND isRead == false
    // Firestore != queries are limited. Better: senderId == otherUserId

    final otherUserId = (currentUserId == ownerId) ? renterId : ownerId;

    final unreadMessagesQuery = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isEqualTo: otherUserId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadMessagesQuery.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Stream of messages for a specific chat
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        // .orderBy('createdAt', descending: true) // Removed to avoid Index requirement
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();
          // Client-side sort
          messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return messages;
        });
  }

  /// Stream of chats for the current user
  Stream<List<ChatModel>> getUserChats() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    final asRenterStream = _firestore
        .collection('chats')
        .where('renterId', isEqualTo: currentUserId)
        // .orderBy('lastMessageAt', descending: true) // Removed to avoid Index requirement for now
        .snapshots();

    final asOwnerStream = _firestore
        .collection('chats')
        .where('ownerId', isEqualTo: currentUserId)
        // .orderBy('lastMessageAt', descending: true) // Removed to avoid Index requirement for now
        .snapshots();

    // Merge streams using custom logic
    return _combineStreams(asRenterStream, asOwnerStream);
  }

  Stream<List<ChatModel>> _combineStreams(
    Stream<QuerySnapshot> streamA,
    Stream<QuerySnapshot> streamB,
  ) {
    return Stream<List<ChatModel>>.multi((controller) {
      List<ChatModel> listA = [];
      List<ChatModel> listB = [];

      void emit() {
        final allChats = [...listA, ...listB];
        // Deduplicate
        final uniqueChats = <String, ChatModel>{};
        for (var chat in allChats) {
          uniqueChats[chat.id] = chat;
        }

        final result = uniqueChats.values.toList();
        // Client-side sort
        result.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

        controller.add(result);
      }

      final subA = streamA.listen(
        (snap) {
          listA = snap.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
          emit();
        },
        onError: (e) {
          print('Stream A Error: $e');
          controller.addError(e);
        },
      );

      final subB = streamB.listen(
        (snap) {
          listB = snap.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
          emit();
        },
        onError: (e) {
          print('Stream B Error: $e');
          controller.addError(e);
        },
      );

      controller.onCancel = () {
        subA.cancel();
        subB.cancel();
      };
    });
  }
}
