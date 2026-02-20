import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/chat_provider.dart';
import '../../../../core/providers/items_provider.dart'; // For firestoreServiceProvider
// To fetch item/user details if needed
import '../../../../core/models/chat_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/product_model.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(userChatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: chatsAsync.when(
        data: (chats) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) {
            return const Center(child: Text('Please log in'));
          }

          if (chats.isEmpty) {
            return const Center(child: Text('No messages yet'));
          }

          // Sort chats by last message time (descending)
          final sortedChats = List<ChatModel>.from(chats)
            ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

          return ListView.separated(
            itemCount: sortedChats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = sortedChats[index];
              return _ChatListItem(chat: chat);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }



}

class _ChatListItem extends ConsumerWidget {
  final ChatModel chat;

  const _ChatListItem({required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == chat.ownerId;

    // Denormalized data
    String? name = isOwner ? chat.renterName : chat.ownerName;
    String? image = isOwner ? chat.renterImage : chat.ownerImage;
    String? itemName = chat.itemName;

    // Check if data is present and NOT the default placeholders
    bool hasData =
        name.isNotEmpty &&
        name != 'Renter' &&
        name != 'Owner' &&
        itemName.isNotEmpty &&
        itemName != 'Item';

    if (hasData) {
      return _buildTile(context, ref, name, image, itemName);
    }

    // Fallback for old chats: Fetch data
    final otherUserId = isOwner ? chat.renterId : chat.ownerId;

    return FutureBuilder(
      future: Future.wait<Object?>([
        ref.read(firestoreServiceProvider).getUserModel(otherUserId),
        ref.read(firestoreServiceProvider).getProductById(chat.itemId),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final user = snapshot.data![0] as UserModel?;
          final item = snapshot.data![1] as ProductModel?;

          final fetchedName = user?.displayName ?? 'Unknown User';
          final fetchedItemName = item?.title ?? 'Unknown Item';
          final fetchedImage = user?.photoURL;

          return _buildTile(
            context,
            ref,
            fetchedName,
            fetchedImage,
            fetchedItemName,
          );
        }
        // Loading state
        return const ListTile(
          leading: CircleAvatar(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('Loading...'),
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context,
    WidgetRef ref,
    String name,
    String? imageUrl,
    String itemName,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
            ? NetworkImage(imageUrl)
            : null,
        child: (imageUrl == null || imageUrl.isEmpty)
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(
        '$name ($itemName)',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Builder(
        builder: (context) {
          final currentUser = FirebaseAuth.instance.currentUser;
          final isMe = currentUser?.uid == chat.lastMessageSenderId;
          final prefix = isMe ? 'You: ' : '';
          return Text(
            '$prefix${chat.lastMessage}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey),
          );
        }
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('MM/dd').format(chat.lastMessageAt),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          // Unread Badge
          Builder(
            builder: (context) {
              final currentUser = FirebaseAuth.instance.currentUser;
              // FIX: Use exclusive if/else — a user is either owner OR renter, not both
              int myUnreadCount = 0;
              if (currentUser?.uid == chat.ownerId) {
                myUnreadCount = chat.ownerUnreadCount;
              } else if (currentUser?.uid == chat.renterId) {
                myUnreadCount = chat.renterUnreadCount;
              }

              if (myUnreadCount > 0) {
                return Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$myUnreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      onTap: () async {
        // Mark as read immediately before opening chat
        await ref.read(chatServiceProvider).markChatAsRead(chat.id);
        if (!context.mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chat.id,
              otherUserName: name,
              itemName: itemName,
            ),
          ),
        );
        // Mark as read again after returning, in case new messages arrived while in chat
        ref.read(chatServiceProvider).markChatAsRead(chat.id);
      },
    );
  }
}
