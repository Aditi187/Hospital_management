import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme.dart';

/// A simple Firestore-backed chat widget for two users (doctor <-> patient).
///
/// Usage: provide the currentUserId and otherUserId. The widget creates a
/// chat document under `chats/{chatId}` and stores messages in
/// `chats/{chatId}/messages`.
class UserChatWidget extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;

  const UserChatWidget({
    Key? key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<UserChatWidget> createState() => _UserChatWidgetState();
}

class _UserChatWidgetState extends State<UserChatWidget> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final String chatId;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    chatId = _computeChatId(widget.currentUserId, widget.otherUserId);
    _ensureChatDocExists();
  }

  static String _computeChatId(String a, String b) {
    // deterministic chat id: doctor_{doctorId}_patient_{patientId}
    // but we don't assume role here; sort to keep unique
    final parts = [a, b]..sort();
    return 'chat_${parts[0]}_${parts[1]}';
  }

  Future<void> _ensureChatDocExists() async {
    final ref = _firestore.collection('chats').doc(chatId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participants': [widget.currentUserId, widget.otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final msgRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final payload = {
      'senderId': widget.currentUserId,
      'receiverId': widget.otherUserId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    };

    await msgRef.set(payload);

    // update last message on chat doc
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // push a simple notification to recipient
    await _firestore
        .collection('users')
        .doc(widget.otherUserId)
        .collection('notifications')
        .add({
          'title': 'New message',
          'body': text.length > 120 ? '${text.substring(0, 120)}...' : text,
          'type': 'message',
          'chatId': chatId,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.chat, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.otherUserName,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              Text(
                'Private',
                style: TextStyle(color: Colors.green.shade100, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return const Center(child: Text('Error'));
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (c, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final isUser = d['senderId'] == widget.currentUserId;
                  final text = d['text'] ?? '';
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? AppTheme.primary : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: isUser ? AppTheme.onPrimary : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: 'Write a message to ${'doctor/patient'}',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: AppTheme.primary),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
