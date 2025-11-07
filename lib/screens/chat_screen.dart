import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  final String userId;
  final String userName;
  final String? userImageUrl;

  const ChatScreen({
    super.key,
    required this.api,
    required this.tokens,
    required this.userId,
    required this.userName,
    this.userImageUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<MessageDto> _messages = [];
  bool _loading = true;
  String? _currentUserId;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadMessages();

    // Start periodic refresh
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
          (timer) => _loadMessages(),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final token = await widget.tokens.readAccessToken();
      if (token != null) {
        final decoded = JwtDecoder.decode(token);


        final userId = decoded['sub'] ?? decoded['userId'] ?? decoded['id'];


        setState(() {
          _currentUserId = userId;
        });
      }
    } catch (e) {
      debugPrint('Error decoding token: $e');
    }
  }

  Future<void> _loadMessages() async {
    // Don't show loading indicator on periodic refreshes
    final isInitialLoad = _messages.isEmpty;
    if (isInitialLoad) {
      setState(() => _loading = true);
    }

    try {
      final resp = await widget.api.getMessages(widget.userId, limit: 50);
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final list = decoded is List ? decoded : [];
        final messages = <MessageDto>[];
        for (final item in list) {
          try {
            messages.add(MessageDto.fromJson(item));
          } catch (e) {
            print('Error parsing message: $e');
          }
        }

        // Only update if messages have changed
        if (_hasMessagesChanged(messages)) {
          // Save scroll position
          final shouldScrollToBottom = _scrollController.hasClients &&
              _scrollController.position.pixels >=
                  _scrollController.position.maxScrollExtent - 100;

          setState(() {
            _messages = messages;
            _loading = false;
          });

          // Only auto-scroll if user was already at bottom
          if (shouldScrollToBottom) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        } else if (isInitialLoad) {
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (isInitialLoad) {
        setState(() => _loading = false);
      }
    }
  }

  bool _hasMessagesChanged(List<MessageDto> newMessages) {
    if (newMessages.length != _messages.length) return true;

    for (int i = 0; i < newMessages.length; i++) {
      if (newMessages[i].content != _messages[i].content ||
          newMessages[i].senderId != _messages[i].senderId) {
        return true;
      }
    }

    return false;
  }



  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }



  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    // Optimistically add the message to the list
    final tempMessage = MessageDto(
      content: text,
      timestamp: DateTime.now(),
      senderId: _currentUserId ?? '',
      receiverId: widget.userId,
    );

    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      final dto = SendMessageDto(receiverId: widget.userId, content: text);
      final resp = await widget.api.sendMessage(dto);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // Reload to get the actual message from server
        await _loadMessages();
      } else {
        // Remove the optimistic message if send failed
        setState(() {
          _messages.removeLast();
        });
      }
    } catch (e) {
      print('Error sending message: $e');
      // Remove the optimistic message on error
      setState(() {
        _messages.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.userImageUrl != null
                  ? NetworkImage(widget.userImageUrl!)
                  : null,
              backgroundColor: Colors.grey.shade300,
              child: widget.userImageUrl == null
                  ? Text(
                widget.userName.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 16, color: Colors.white),
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              widget.userName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B4CE6),
              ),
            )
                : _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _MessageBubble(
                message: _messages[index],
                userImageUrl: widget.userImageUrl,
                currentUserId: _currentUserId,
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF6B4CE6)),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageDto message;
  final String? userImageUrl;
  final String? currentUserId;

  const _MessageBubble({
    required this.message,
    this.userImageUrl,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = currentUserId != null && message.senderId == currentUserId;


    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage:
              userImageUrl != null ? NetworkImage(userImageUrl!) : null,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF6B4CE6) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

}
