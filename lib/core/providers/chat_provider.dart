import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(FirebaseFirestore.instance, FirebaseAuth.instance);
});

final userChatsProvider = StreamProvider<List<ChatModel>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getUserChats();
});

final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getMessages(chatId);
});
