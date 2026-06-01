import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../services/database_service.dart';

/// Shows the full chat log for a single conversation.
class ConversationDetailScreen extends StatefulWidget {
  final Conversation conversation;
  final DatabaseService? databaseService;

  const ConversationDetailScreen({
    super.key,
    required this.conversation,
    required this.databaseService,
  });

  @override
  State<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final List<ChatMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (widget.databaseService != null && widget.conversation.id != null) {
      try {
        final msgs = await widget.databaseService!
            .getMessages(widget.conversation.id!);
        if (mounted) {
          setState(() {
            _messages.addAll(msgs);
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? const Center(child: Text('No messages'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildBubble(_messages[index]);
                  },
                ),
    );
  }

  Widget _buildBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: Icon(
                Icons.auto_awesome,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Icon(
                Icons.person,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
