import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zpi_test/screens/visit_profile/visit_profile_screen.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';
import '../api/event_hub_service.dart';
import '../theme/app_design_system.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../utils/audio_notifier.dart';

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
  final AudioNotifier _audioNotifier = AudioNotifier.instance;
  List<MessageDto> _messages = [];
  bool _loading = true;
  String? _currentUserId;
  bool _showEmojiPicker = false;
  Timer? _statusCheckTimer;
  bool _isOnlineRecently = false;
  DateTime? _lastSeenAckTime;
  DateTime? _lastIncomingMessageTime;
  DateTime? _lastActiveAt;
  String? _lastSeenMessageId;
  void Function(dynamic)? _hubMessageListener;

  @override
  void initState() {
    super.initState();
    _updateActiveConversation(isActive: true);
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
    _hubMessageListener = (messageData) {
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
                _audioNotifier.playMessage();
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

    eventHub.addMessageListener(_hubMessageListener!);
    
    print("✅ SignalR callback setup complete");
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _statusCheckTimer?.cancel();
    _updateActiveConversation(isActive: false);
    if (widget.eventHubService != null && _hubMessageListener != null) {
      widget.eventHubService!.removeMessageListener(_hubMessageListener!);
    }
    
    super.dispose();
  }

  void _updateActiveConversation({required bool isActive}) {
    final eventHub = widget.eventHubService;
    if (eventHub == null) return;
    if (isActive) {
      eventHub.setActiveConversationUser(widget.userId);
    } else if (eventHub.activeConversationUserId == widget.userId) {
      eventHub.setActiveConversationUser(null);
    }
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
          final seenAckUpdate = _captureSeenAcknowledgement(messages);
          final latestIncoming = _latestTimestamp(messages, (msg) => msg.senderId == widget.userId);
          final seenReference = seenAckUpdate ?? _lastSeenAckTime;
          final isOnline = _computeOnlineStatus(seenReference, latestIncoming);
          final lastActive = _computeLastActive(seenReference, latestIncoming);

          print("✅ Messages changed - updating UI (old: ${_messages.length}, new: ${messages.length})");
          // Save scroll position
          final shouldScrollToBottom = _scrollController.hasClients &&
              _scrollController.position.pixels >=
                  _scrollController.position.maxScrollExtent - 100;

          setState(() {
            _messages = messages;
            _loading = false;
            if (seenAckUpdate != null) {
              _lastSeenAckTime = seenAckUpdate;
            }
            _lastIncomingMessageTime = latestIncoming;
            _isOnlineRecently = isOnline;
            _lastActiveAt = lastActive;
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

  DateTime? _latestTimestamp(List<MessageDto> source, bool Function(MessageDto) predicate) {
    DateTime? latest;
    for (final msg in source) {
      if (predicate(msg)) {
        if (latest == null || msg.timestamp.isAfter(latest)) {
          latest = msg.timestamp;
        }
      }
    }
    return latest;
  }

  MessageDto? _latestMessage(List<MessageDto> source, bool Function(MessageDto) predicate) {
    MessageDto? latest;
    for (final msg in source) {
      if (predicate(msg)) {
        if (latest == null || msg.timestamp.isAfter(latest.timestamp)) {
          latest = msg;
        }
      }
    }
    return latest;
  }

  DateTime? _captureSeenAcknowledgement(List<MessageDto> newMessages) {
    if (_currentUserId == null) return null;
    final latestSeen = _latestMessage(
      newMessages,
      (msg) => msg.senderId == _currentUserId && msg.isSeen,
    );
    if (latestSeen != null && latestSeen.id != _lastSeenMessageId) {
      _lastSeenMessageId = latestSeen.id;
      return DateTime.now();
    }
    return null;
  }

  bool _computeOnlineStatus(DateTime? seenAck, DateTime? lastIncoming) {
    final threshold = DateTime.now().subtract(const Duration(minutes: 10));
    if (seenAck != null && seenAck.isAfter(threshold)) return true;
    if (lastIncoming != null && lastIncoming.isAfter(threshold)) return true;
    return false;
  }

  DateTime? _computeLastActive(DateTime? seenAck, DateTime? lastIncoming) {
    if (seenAck == null) return lastIncoming;
    if (lastIncoming == null) return seenAck;
    return seenAck.isAfter(lastIncoming) ? seenAck : lastIncoming;
  }

  String _formatLastActive() {
    final reference = _lastActiveAt ?? _lastIncomingMessageTime;
    if (reference == null) return 'Offline';
    final diff = DateTime.now().difference(reference);
    if (diff.inMinutes < 1) return 'Active just now';
    if (diff.inMinutes < 60) return 'Active ${diff.inMinutes} min ago';
    if (diff.inHours < 24) return 'Active ${diff.inHours} h ago';
    return 'Active on ${DateFormat('MMM d, h:mm a').format(reference)}';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F6FB),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: 72,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.textWhite : Colors.black87,
          ),
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
                  eventHubService: widget.eventHubService,
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: widget.userImageUrl != null
                    ? NetworkImage(widget.userImageUrl!)
                    : null,
                backgroundColor: const Color(0xFFE0E7FF),
                child: widget.userImageUrl == null
                    ? Text(
                        widget.userName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 18, color: Color(0xFF4C4F72)),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        color: Color(0xFF1F2430),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isOnlineRecently ? const Color(0xFF40C057) : Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isOnlineRecently ? 'Online now' : _formatLastActive(),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFEEF1FB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7C4DFF),
                          ),
                        )
                      : _messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No messages yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final isLastMessage = index == _messages.length - 1;

                                return _MessageBubble(
                                  message: _messages[index],
                                  userImageUrl: widget.userImageUrl,
                                  currentUserId: _currentUserId,
                                  userId: widget.userId,
                                  api: widget.api,
                                  tokens: widget.tokens,
                                  eventHubService: widget.eventHubService,
                                  showStatus: isLastMessage,
                                  showTimestamp: isLastMessage,
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
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                color: Colors.grey.shade600,
              ),
              onPressed: () {
                setState(() {
                  _showEmojiPicker = !_showEmojiPicker;
                });
              },
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FB),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE0E4F0)),
                ),
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.enter): () => _sendMessage(),
                  },
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Color(0xFF9EA3B5)),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      isCollapsed: true,
                    ),
                    style: const TextStyle(color: Color(0xFF1F2430)),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF9C6BFF)],
                  ),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
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
  final EventHubService? eventHubService;
  final bool showStatus;
  final bool showTimestamp;

  const _MessageBubble({
    required this.message,
    this.userImageUrl,
    this.currentUserId,
    required this.userId,
    required this.api,
    required this.tokens,
    this.eventHubService,
    this.showStatus = false,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = currentUserId != null && message.senderId == currentUserId;
    final timestamp = message.timestamp.toLocal();
    final timeLabel = DateFormat('h:mm a').format(timestamp);
    final bubbleGradient = const LinearGradient(
      colors: [Color(0xFF7C4DFF), Color(0xFF9C6BFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                      eventHubService: eventHubService,
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 16,
                backgroundImage:
                userImageUrl != null ? NetworkImage(userImageUrl!) : null,
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: isMe ? bubbleGradient : null,
                    color: isMe ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomLeft: Radius.circular(isMe ? 24 : 8),
                      bottomRight: Radius.circular(isMe ? 8 : 24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : const Color(0xFF1F2430),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                if (showTimestamp || (isMe && showStatus)) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showTimestamp)
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        if (isMe && showStatus) ...[
                          if (showTimestamp) const SizedBox(width: 8),
                          Icon(
                            message.isSeen ? Icons.done_all : Icons.done,
                            size: 16,
                            color:
                                message.isSeen ? const Color(0xFF7C4DFF) : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            message.isSeen ? 'Seen' : 'Sent',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
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
