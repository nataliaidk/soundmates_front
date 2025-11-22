import 'package:flutter/material.dart';
import 'package:zpi_test/screens/visit_profile/visit_profile_screen.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';
import '../api/event_hub_service.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final EventHubService? eventHubService;

  const ChatScreen({
    super.key,
    required this.api,
    required this.tokens,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    this.eventHubService,
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
  bool _showEmojiPicker = false;
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _loadCurrentUserId();
    await _loadMessages();
    await _markConversationAsViewed();
    await _ensureSignalRConnection();
    _setupSignalRCallback();
    _startStatusChecking();
  }
  
  void _startStatusChecking() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      
      if (_messages.isNotEmpty) {
        // Check if we have any unseen messages sent by us
        final hasUnseenMyMessages = _messages.any(
          (msg) => msg.senderId == _currentUserId && !msg.isSeen
        );
        
        if (hasUnseenMyMessages) {
          print('🔄 Checking message status...');
          _loadMessages();
        }
      }
    });
  }
  
  Future<void> _markConversationAsViewed() async {
    try {
      print('📖 Marking conversation with ${widget.userId} as viewed...');
      final resp = await widget.api.viewConversation(widget.userId);
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        print('✅ Conversation marked as viewed');
      } else {
        print('⚠️ Failed to mark conversation as viewed: ${resp.statusCode}');
      }
    } catch (e) {
      print('❌ Error marking conversation as viewed: $e');
    }
  }
  
  Future<void> _ensureSignalRConnection() async {
    final eventHub = widget.eventHubService;
    if (eventHub == null) return;
    
    // Check if already connected
    if (eventHub.connection?.state.toString() == 'HubConnectionState.Connected') {
      print('✅ SignalR already connected');
      return;
    }
    
    // Try to connect if not connected
    try {
      print('🔄 Connecting SignalR for chat...');
      await eventHub.connect();
      print('✅ SignalR connected for chat');
    } catch (e) {
      print('❌ Failed to connect SignalR: $e');
    }
  }
  
  void _setupSignalRCallback() {
    final eventHub = widget.eventHubService;
    if (eventHub == null) {
      print("⚠️ EventHubService is null - no real-time updates");
      return;
    }
    
    print("🔧 Setting up SignalR callback for chat with user ${widget.userId}");
    print("🔧 Current user ID: $_currentUserId");
    
    // Set callback for MessageReceived
    eventHub.onMessageReceived = (messageData) {
      try {
        print("📩 MessageReceived callback in chat: $messageData");
        
        // Check if message is for this chat
        if (messageData is Map<String, dynamic>) {
          final senderId = messageData['senderId']?.toString();
          
          print("🔍 Checking message: senderId=$senderId");
          print("🔍 Current chat: userId=${widget.userId}, currentUserId=$_currentUserId");
          
          // Message is for this chat if sender is either:
          // 1. The user we're chatting with (they sent us a message)
          // 2. Current user (we sent a message - for optimistic UI update)
          if (senderId == widget.userId || senderId == _currentUserId) {
            print("✅ Message is for this chat - reloading messages NOW");
            if (mounted) {
              _loadMessages();
              // If message is from the other user, mark as viewed
              if (senderId == widget.userId) {
                _markConversationAsViewed();
              }
            }
          } else {
            print("❌ Message is not for this chat - ignoring (senderId doesn't match)");
          }
        }
      } catch (e) {
        print('❌ Error processing MessageReceived: $e');
      }
    };
    
    print("✅ SignalR callback setup complete");
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _statusCheckTimer?.cancel();
    
    // Clear callback to avoid memory leaks
    if (widget.eventHubService != null) {
      widget.eventHubService!.onMessageReceived = null;
    }
    
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
    print("🔄 Loading messages from API...");
    // Don't show loading indicator on periodic refreshes
    final isInitialLoad = _messages.isEmpty;
    if (isInitialLoad) {
      setState(() => _loading = true);
    }

    try {
      final resp = await widget.api.getMessages(widget.userId, limit: 50);
      print("📥 API response: ${resp.statusCode}");
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        print("📦 Raw API response: $decoded");
        final list = decoded is List ? decoded : [];
        final messages = <MessageDto>[];
        for (final item in list) {
          try {
            print("🔍 Raw message item: $item");
            print("🔍 isSeen field value: ${item['isSeen']}, IsSeen field value: ${item['IsSeen']}");
            final msg = MessageDto.fromJson(item);
            print("📧 Message: id=${msg.id}, content=${msg.content}, isSeen=${msg.isSeen}, senderId=${msg.senderId}");
            messages.add(msg);
          } catch (e) {
            print('Error parsing message: $e');
          }
        }

        // Only update if messages have changed
        if (_hasMessagesChanged(messages)) {
          print("✅ Messages changed - updating UI (old: ${_messages.length}, new: ${messages.length})");
          // Save scroll position
          final shouldScrollToBottom =
              _scrollController.hasClients &&
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
        } else {
          print("ℹ️ Messages unchanged - skipping UI update");
          if (isInitialLoad) {
            setState(() => _loading = false);
          }
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
          newMessages[i].senderId != _messages[i].senderId ||
          newMessages[i].isSeen != _messages[i].isSeen) {
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
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      content: text,
      timestamp: DateTime.now(),
      senderId: _currentUserId ?? '',
      receiverId: widget.userId,
      isSeen: false,
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
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VisitProfileScreen(
                  api: widget.api,
                  tokens: widget.tokens,
                  userId: widget.userId,
                ),
              ),
            );
          },
          child: Row(
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
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
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
      ): ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          // Find the last message sent by current user
          final lastMyMessageIndex = _messages.lastIndexWhere(
            (msg) => msg.senderId == _currentUserId
          );
          final isLastMyMessage = index == lastMyMessageIndex;
          
          return _MessageBubble(
            message: _messages[index],
            userImageUrl: widget.userImageUrl,
            currentUserId: _currentUserId,
            userId: widget.userId,
            api: widget.api,
            tokens: widget.tokens,
            showStatus: isLastMyMessage,
          );
        },
      ),
      ),
            _buildMessageInput(),
            if (_showEmojiPicker)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    _messageController.text += emoji.emoji;
                  },
                  config: Config(
                    emojiViewConfig: EmojiViewConfig(
                      columns: 7,
                      emojiSizeMax: 32.0,
                      backgroundColor: Colors.white,
                      buttonMode: ButtonMode.MATERIAL,
                      recentsLimit: 28,
                      noRecents: const Text('No Recents', style: TextStyle(fontSize: 20)),
                      loadingIndicator: const CircularProgressIndicator(
                        color: Color(0xFF6B4CE6),
                      ),
                      gridPadding: EdgeInsets.zero,
                      horizontalSpacing: 0,
                      verticalSpacing: 0,
                      replaceEmojiOnLimitExceed: false,
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
                      userId: widget.userId,
                      api: widget.api,
                      tokens: widget.tokens,
                    ),
                  ),
          ),
          _buildMessageInput(),
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _messageController.text += emoji.emoji;
                },
                config: Config(
                  emojiViewConfig: EmojiViewConfig(
                    columns: 7,
                    emojiSizeMax: 32.0,
                    backgroundColor: Colors.white,
                    buttonMode: ButtonMode.MATERIAL,
                    recentsLimit: 28,
                    noRecents: const Text(
                      'No Recents',
                      style: TextStyle(fontSize: 20),
                    ),
                    loadingIndicator: const CircularProgressIndicator(
                      color: Color(0xFF6B4CE6),
                    ),
                    gridPadding: EdgeInsets.zero,
                    horizontalSpacing: 0,
                    verticalSpacing: 0,
                    replaceEmojiOnLimitExceed: false,
                  ),
                  categoryViewConfig: CategoryViewConfig(
                    initCategory: Category.RECENT,
                    backgroundColor: Colors.white,
                    indicatorColor: const Color(0xFF6B4CE6),
                    iconColor: Colors.grey,
                    iconColorSelected: const Color(0xFF6B4CE6),
                    dividerColor: Colors.grey.shade200,
                    categoryIcons: const CategoryIcons(),
                    recentTabBehavior: RecentTabBehavior.RECENT,
                  ),
                  bottomActionBarConfig: BottomActionBarConfig(
                    backgroundColor: Colors.white,
                    buttonColor: Colors.grey.shade200,
                    buttonIconColor: const Color(0xFF6B4CE6),
                  ),
                  searchViewConfig: SearchViewConfig(
                    backgroundColor: Colors.white,
                    buttonIconColor: const Color(0xFF6B4CE6),
                    hintText: 'Search emoji',
                  ),
                ),
              ),
            ),
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
              icon: Icon(
                _showEmojiPicker
                    ? Icons.keyboard
                    : Icons.emoji_emotions_outlined,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _showEmojiPicker = !_showEmojiPicker;
                });
              },
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
  final String userId;
  final ApiClient api;
  final TokenStore tokens;
  final bool showStatus;

  const _MessageBubble({
    required this.message,
    this.userImageUrl,
    this.currentUserId,
    required this.userId,
    required this.api,
    required this.tokens,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = currentUserId != null && message.senderId == currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VisitProfileScreen(
                      api: api,
                      tokens: tokens,
                      userId: userId,
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 16,
                backgroundImage: userImageUrl != null
                    ? NetworkImage(userImageUrl!)
                    : null,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
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
                if (isMe && showStatus) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        message.isSeen ? Icons.done_all : Icons.done,
                        size: 16,
                        color: message.isSeen ? const Color(0xFF6B4CE6) : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        message.isSeen ? 'Zobaczone' : 'Wysłane',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
