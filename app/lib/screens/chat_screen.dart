import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../services/database_service.dart';
import '../services/llm_service.dart';


class ChatScreen extends StatefulWidget {
  /// Null on platforms where SQLite is unavailable (e.g. web).
  /// When null, messages exist only in memory and are not persisted.
  final DatabaseService? databaseService;

  /// The LLM service for generating responses.
  /// When null, placeholder responses are used instead.
  final LlmService? llmService;

  const ChatScreen({
    super.key,
    required this.databaseService,
    this.llmService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Conversation? _conversation;
  List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _messageCounter = 0;
  bool _isSending = false;
  bool _welcomePersisted = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Conversation> _conversations = [];
  bool _drawerLoading = false;

  @override
  void initState() {
    super.initState();
    // Add a welcome system bubble so the chat never feels empty.
    _messages.add(ChatMessage(
      id: 'msg_welcome',
      text: 'Welcome. I am here to help you reflect.\n'
          'Tell me what is on your mind.',
      sender: MessageSender.system,
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSubmit() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() => _isSending = true);

    try {
      // Create conversation on first message with date-time title.
      if (_conversation == null) {
        final now = DateTime.now();
        final title =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')} '
            '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}';
        if (widget.databaseService != null) {
          _conversation =
              await widget.databaseService!.createConversation(title);
          // Persist the welcome message now that a conversation exists.
          if (!_welcomePersisted) {
            _welcomePersisted = true;
            final welcomeMsg = _messages.firstWhere(
              (m) => m.id == 'msg_welcome',
              orElse: () => _messages.first,
            );
            if (welcomeMsg.id == 'msg_welcome') {
              final saved = await widget.databaseService!
                  .addMessage(_conversation!.id!, welcomeMsg);
              // Replace the in-memory welcome with the persisted version.
              final idx = _messages.indexWhere((m) => m.id == 'msg_welcome');
              if (idx >= 0) {
                _messages[idx] = saved;
              }
            }
          }
        } else {
          _conversation = Conversation(
            id: 0,
            title: title,
          );
        }
      }

      // Persist or add user message.
      final userMsg = ChatMessage(
        id: 'msg_${_messageCounter++}',
        text: text,
        sender: MessageSender.user,
      );
      if (widget.databaseService != null) {
        final saved = await widget.databaseService!
            .addMessage(_conversation!.id!, userMsg);
        setState(() => _messages.add(saved));
      } else {
        setState(() => _messages.add(userMsg));
      }
      _scrollToBottom();

      // Generate response — use LLM if available, fall back to placeholder.
      String responseText;
      if (widget.llmService != null && widget.llmService!.isReady) {
        // Show a brief delay to indicate the model is thinking.
        await Future.delayed(const Duration(milliseconds: 300));
        responseText = await widget.llmService!.sendMessage(text);
      } else {
        // Simulate system thinking delay.
        await Future.delayed(const Duration(milliseconds: 600));
        responseText = _generatePlaceholderResponse(text);
      }

      // Persist, and display system response.
      final systemMsg = ChatMessage(
        id: 'msg_${_messageCounter++}',
        text: responseText,
        sender: MessageSender.system,
      );
      if (widget.databaseService != null) {
        final saved = await widget.databaseService!
            .addMessage(_conversation!.id!, systemMsg);
        setState(() => _messages.add(saved));
      } else {
        setState(() => _messages.add(systemMsg));
      }
      _scrollToBottom();
    } finally {
      setState(() => _isSending = false);
    }
  }

  /// Load conversations from the database for the drawer list.
  Future<void> _loadConversations() async {
    if (widget.databaseService == null) return;
    setState(() => _drawerLoading = true);
    try {
      final list = await widget.databaseService!.getAllConversations();
      if (mounted) setState(() => _conversations = list);
    } catch (_) {
      // silently fail
    } finally {
      if (mounted) setState(() => _drawerLoading = false);
    }
  }

  /// Load a past conversation into the main chat.
  Future<void> _openConversation(Conversation conv) async {
    // Close the drawer.
    Navigator.of(context).pop();

    if (widget.databaseService != null && conv.id != null) {
      try {
        final msgs =
            await widget.databaseService!.getMessages(conv.id!);
        if (mounted) {
          setState(() {
            _conversation = conv;
            _messages = msgs;
            _messageCounter = msgs.length;
            _welcomePersisted = true; // welcome already in DB
          });
        }
      } catch (_) {
        // silently fail
      }
    }
    _scrollToBottom();
  }

  /// Build the drawer with the conversation list.
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conversations',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_conversations.length} conversation${_conversations.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: _drawerLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _conversations.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No past conversations',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) {
                            final conv = _conversations[index];
                            final isActive = _conversation?.id == conv.id;
                            return ListTile(
                              title: Text(
                                conv.title,
                                style: TextStyle(
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                _formatTimestamp(conv.updatedAt),
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: isActive
                                  ? const Icon(Icons.chat_bubble,
                                      size: 18)
                                  : null,
                              selected: isActive,
                              onTap: () => _openConversation(conv),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }

  /// Placeholder response generator when LLM is unavailable.
  String _generatePlaceholderResponse(String userText) {
    final lower = userText.toLowerCase();
    if (lower.contains('gua') || lower.contains('hexagram')) {
      return 'You mentioned a hexagram. The Gua will reveal itself.\n'
          'How does this moment feel to you?';
    }
    if (lower.contains('hello') || lower.contains('hi')) {
      return 'Greetings. Take a breath and tell me what brings you here today.';
    }
    return 'Thank you for sharing. The wisdom of the I-Ching '
        'may offer perspective on what you describe.\n'
        'Could you tell me more about how this situation makes you feel?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Past conversations',
          onPressed: () {
            _loadConversations();
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(_conversation?.title ?? 'I-Ching'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // Chat message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          // Input area
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 6,
                  color: Colors.black.withValues(alpha: 0.1),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Share your thoughts...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSubmit(),
                      maxLines: 4,
                      minLines: 1,
                      enabled: !_isSending,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _handleSubmit,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    tooltip: 'Send',
                    style: IconButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
