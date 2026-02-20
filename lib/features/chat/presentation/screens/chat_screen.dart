import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserName;
  final String? otherUserImage;
  final String itemName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    this.otherUserImage,
    required this.itemName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark chat as read when opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatServiceProvider).markChatAsRead(widget.chatId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    try {
      await ref.read(chatServiceProvider).sendMessage(widget.chatId, text);
      // Wait a bit for local optimistic update or just stream update
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0, // Reverse list, 0 is bottom
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final currentUser = FirebaseAuth.instance.currentUser;

    messagesAsync.whenData((messages) {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) return;
      final hasUnreadFromOther = messages.any(
        (message) => message.senderId != currentUserId && !message.isRead,
      );
      if (hasUnreadFromOther) {
        Future.microtask(
          () => ref.read(chatServiceProvider).markChatAsRead(widget.chatId),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName, style: const TextStyle(fontSize: 16)),
            Text(
              widget.itemName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('Start the conversation!'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Show newest at bottom (classic chat)
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.uid;
                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFF781C2E)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: isMe
                                    ? const Radius.circular(12)
                                    : Radius.zero,
                                bottomRight: isMe
                                    ? Radius.zero
                                    : const Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              message.text,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat(
                                    'hh:mm a',
                                  ).format(message.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe
                                        ? Colors.black54
                                        : Colors.black54,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    message.isRead
                                        ? Icons.done_all
                                        : Icons
                                              .check, // Double tick if read, single if sent
                                    size: 16,
                                    color: message.isRead
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF781C2E),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
