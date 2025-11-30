import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zpi_test/screens/visit_profile/visit_profile_screen.dart';
import '../widgets/pulsing_logo_loader.dart';
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
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _currentUserId;
  bool _showEmojiPicker = false;
  void Function(dynamic)? _hubMessageListener;
  bool _isMatched = false;
  bool _checkingMatch = true;

  @override
  void initState() {
    super.initState();
    _updateActiveConversation(isActive: true);
    _scrollController.addListener(_onScroll);
    _initialize();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (maxScroll - currentScroll <= 200) {
        _loadMoreMessages();
      }
    }
  }

  Future<void> _initialize() async {
    await _loadCurrentUserId();
    await _checkMatchStatus();
    await _loadMessages();
    await _markConversationAsViewed();
    await _ensureSignalRConnection();
    _setupSignalRCallback();
  }

  Future<void> _checkMatchStatus() async {
    try {
      print('🔍 Checking match status with ${widget.userId}...');
      final resp = await widget.api.checkMatchExists(widget.userId);
      if (resp.statusCode == 200) {
        final isMatched = jsonDecode(resp.body) as bool;
        if (mounted) {
          setState(() {
            _isMatched = isMatched;
            _checkingMatch = false;
          });
          print('✅ Match status: $_isMatched');
        }
      } else {
        print('⚠️ Failed to check match status: ${resp.statusCode}');
        if (mounted) {
          setState(() {
            _checkingMatch = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error checking match status: $e');
      if (mounted) {
        setState(() {
          _checkingMatch = false;
        });
      }
    }
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
    if (eventHub.connection?.state.toString() ==
        'HubConnectionState.Connected') {
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

    // Set callback for ConversationSeen
    eventHub.onConversationSeen = (payload) {
      try {
        print("👁️ ConversationSeen callback in chat: $payload");

        if (payload is Map<String, dynamic>) {
          final userId = payload['userId']?.toString();

          // If this is notification about our conversation being seen by the other user
          if (userId == _currentUserId) {
            print("✅ Our messages were seen - updating message status");
            if (mounted) {
              setState(() {
                _messages = _messages.map((m) {
                  if (m.senderId == _currentUserId && !m.isSeen) {
                    return MessageDto(
                      id: m.id,
                      content: m.content,
                      timestamp: m.timestamp,
                      senderId: m.senderId,
                      receiverId: m.receiverId,
                      isSeen: true,
                    );
                  }
                  return m;
                }).toList();
              });
            }
          }
        }
      } catch (e) {
        print('❌ Error processing ConversationSeen: $e');
      }
    };

    // Set callback for MessageReceived
    _hubMessageListener = (messageData) {
      try {
        print("📩 MessageReceived callback in chat: $messageData");

        // Check if message is for this chat
        if (messageData is Map<String, dynamic>) {
          final senderId = messageData['senderId']?.toString();

          print("🔍 Checking message: senderId=$senderId");
          print(
            "🔍 Current chat: userId=${widget.userId}, currentUserId=$_currentUserId",
          );

          // Message is for this chat if sender is either:
          // 1. The user we're chatting with (they sent us a message)
          // 2. Current user (we sent a message - for optimistic UI update)
          if (senderId == widget.userId || senderId == _currentUserId) {
            print("✅ Message is for this chat - updating list");

            try {
              final msg = MessageDto.fromJson(messageData);
              if (mounted) {
                setState(() {
                  // Check if we already have this message (by ID)
                  if (!_messages.any((m) => m.id == msg.id)) {
                    // If it's from me, check if we have a temp message to replace?
                    // It's hard to match temp message without correlation ID.
                    // But if _sendMessage handled it, we might have the real ID already.
                    // If we don't have the real ID yet, we might add a duplicate.
                    // However, usually _sendMessage response is faster.

                    // If it's from the other user, just add it.
                    _messages.add(msg);
                    _scrollToBottom();

                    // If message is from the other user, mark as viewed
                    if (senderId == widget.userId) {
                      _markConversationAsViewed();
                      _audioNotifier.playMessage();
                    }
                  }
                });
              }
            } catch (e) {
              print('Error parsing SignalR message: $e');
              // Fallback to reload if parsing fails
              if (mounted) _loadMessages();
            }
          } else {
            print(
              "❌ Message is not for this chat - ignoring (senderId doesn't match)",
            );
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

  Future<void> _loadMessages({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    } else {
      print("🔄 Loading messages from API...");
      // Only show full loading screen if we have no messages
      if (_messages.isEmpty) {
        setState(() {
          _loading = true;
          _hasMore = true;
        });
      }
    }

    try {
      final offset = isLoadMore
          ? _messages.where((m) => !m.id.startsWith('temp-')).length
          : 0;
      final resp = await widget.api.getMessages(
        widget.userId,
        limit: 50,
        offset: offset,
      );
      print("📥 API response: ${resp.statusCode}");

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final list = decoded is List ? decoded : [];
        final newMessages = <MessageDto>[];

        for (final item in list) {
          try {
            final msg = MessageDto.fromJson(item);
            newMessages.add(msg);
          } catch (e) {
            print('Error parsing message: $e');
          }
        }

        if (newMessages.length < 50) {
          _hasMore = false;
        }

        if (mounted) {
          setState(() {
            if (isLoadMore) {
              // Filter out duplicates if any
              final existingIds = _messages.map((m) => m.id).toSet();
              final uniqueNew = newMessages
                  .where((m) => !existingIds.contains(m.id))
                  .toList();

              // Insert before temp messages
              final tempMessages = _messages
                  .where((m) => m.id.startsWith('temp-'))
                  .toList();
              final realMessages = _messages
                  .where((m) => !m.id.startsWith('temp-'))
                  .toList();

              _messages = [...realMessages, ...uniqueNew, ...tempMessages];
              _loadingMore = false;
            } else {
              _messages = newMessages;
              _loading = false;
              // Scroll to bottom on initial load
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(
                    _scrollController.position.maxScrollExtent,
                  );
                }
              });
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            if (isLoadMore)
              _loadingMore = false;
            else
              _loading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() {
          if (isLoadMore)
            _loadingMore = false;
          else
            _loading = false;
        });
      }
    }
  }

  Future<void> _loadMoreMessages() => _loadMessages(isLoadMore: true);

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
        // Try to parse the response to get the real message
        try {
          if (resp.body.isNotEmpty) {
            final json = jsonDecode(resp.body);
            final newMessage = MessageDto.fromJson(json);

            if (mounted) {
              setState(() {
                // Replace the temp message with the real one
                final index = _messages.indexWhere(
                  (m) => m.id == tempMessage.id,
                );
                if (index != -1) {
                  _messages[index] = newMessage;
                } else {
                  // If temp message not found (weird), just add real one if not duplicate
                  if (!_messages.any((m) => m.id == newMessage.id)) {
                    _messages.add(newMessage);
                    _scrollToBottom();
                  }
                }
              });
            }
          }
        } catch (e) {
          print('Error parsing send response: $e');
          // If we can't parse, we might leave the temp message or reload silently
          // For now, we leave the temp message as it is visually correct
        }
      } else {
        // Remove the optimistic message if send failed
        if (mounted) {
          setState(() {
            _messages.removeWhere((m) => m.id == tempMessage.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send message')),
          );
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      // Remove the optimistic message on error
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == tempMessage.id);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error sending message')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: 72,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.textWhite : AppColors.textBlack87,
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
                backgroundColor: isDark
                    ? AppColors.surfaceDarkAlt
                    : AppColors.surfaceWhite,
                child: widget.userImageUrl == null
                    ? Text(
                        widget.userName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          color: isDark
                              ? AppColors.textWhite
                              : AppColors.textPrimary,
                        ),
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
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textWhite
                            : AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.backgroundDark, AppColors.backgroundDarkAlt]
                : [AppColors.surfaceWhite, AppColors.textWhite],
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
                      ? const PulsingLogoLoader(
                          message: 'Loading messages...',
                          size: 120,
                        )
                      : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: AppTheme.getAdaptiveGrey(
                                  context,
                                  lightShade: 300,
                                  darkShade: 700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppTheme.getAdaptiveGrey(
                                    context,
                                    lightShade: 500,
                                    darkShade: 500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _messages.length + (_loadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            }
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
                          backgroundColor: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceWhite,
                          buttonMode: ButtonMode.MATERIAL,
                          recentsLimit: 28,
                          noRecents: const Text(
                            'No Recents',
                            style: TextStyle(fontSize: 20),
                          ),
                          loadingIndicator: const CircularProgressIndicator(
                            color: AppColors.accentPurple,
                          ),
                          gridPadding: EdgeInsets.zero,
                          horizontalSpacing: 0,
                          verticalSpacing: 0,
                          replaceEmojiOnLimitExceed: false,
                        ),
                        categoryViewConfig: CategoryViewConfig(
                          initCategory: Category.RECENT,
                          backgroundColor: AppTheme.getAdaptiveSurface(context),
                          indicatorColor: AppColors.accentPurpleBlue,
                          iconColor: AppTheme.getAdaptiveGrey(
                            context,
                            lightShade: 600,
                            darkShade: 400,
                          ),
                          iconColorSelected: AppColors.accentPurple,
                          dividerColor: AppTheme.getAdaptiveGrey(
                            context,
                            lightShade: 200,
                            darkShade: 800,
                          ),
                          categoryIcons: const CategoryIcons(),
                          recentTabBehavior: RecentTabBehavior.RECENT,
                        ),
                        bottomActionBarConfig: BottomActionBarConfig(
                          backgroundColor: AppTheme.getAdaptiveSurface(context),
                          buttonColor: AppTheme.getAdaptiveGrey(
                            context,
                            lightShade: 200,
                            darkShade: 800,
                          ),
                          buttonIconColor: AppColors.accentPurple,
                        ),
                        searchViewConfig: SearchViewConfig(
                          backgroundColor: AppTheme.getAdaptiveSurface(context),
                          buttonIconColor: AppColors.accentPurple,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBlocked = !_isMatched && !_checkingMatch;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show warning banner when not matched
        if (isBlocked)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDarkAlt.withOpacity(0.7)
                  : AppColors.surfaceWhite.withOpacity(0.9),
              border: Border(
                top: BorderSide(
                  color: AppTheme.getAdaptiveGrey(
                    context,
                    lightShade: 300,
                    darkShade: 700,
                  ),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppTheme.getAdaptiveGrey(
                    context,
                    lightShade: 600,
                    darkShade: 400,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "You can't send messages because you're no longer matched with this user",
                    style: TextStyle(
                      color: AppTheme.getAdaptiveGrey(
                        context,
                        lightShade: 600,
                        darkShade: 400,
                      ),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Message input row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showEmojiPicker
                        ? Icons.keyboard
                        : Icons.emoji_emotions_outlined,
                    color: isBlocked
                        ? AppTheme.getAdaptiveGrey(
                            context,
                            lightShade: 400,
                            darkShade: 700,
                          )
                        : AppTheme.getAdaptiveGrey(
                            context,
                            lightShade: 600,
                            darkShade: 400,
                          ),
                  ),
                  onPressed: isBlocked
                      ? null
                      : () {
                          setState(() {
                            _showEmojiPicker = !_showEmojiPicker;
                          });
                        },
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isBlocked
                          ? (isDark
                                ? AppColors.surfaceDarkAlt.withOpacity(0.5)
                                : AppColors.surfaceWhite.withOpacity(0.5))
                          : (isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceWhite),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceWhite,
                      ),
                    ),
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.enter): () =>
                            isBlocked ? null : _sendMessage(),
                      },
                      child: TextField(
                        controller: _messageController,
                        enabled: !isBlocked,
                        decoration: InputDecoration(
                          hintText: isBlocked
                              ? "Can't send messages"
                              : 'Type a message...',
                          hintStyle: TextStyle(
                            color: isBlocked
                                ? AppTheme.getAdaptiveGrey(
                                    context,
                                    lightShade: 400,
                                    darkShade: 700,
                                  )
                                : AppColors.textGrey,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          isCollapsed: true,
                        ),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textWhite
                              : AppColors.textPrimary,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: isBlocked ? null : (_) => _sendMessage(),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: isBlocked ? null : _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isBlocked
                          ? LinearGradient(
                              colors: [
                                AppTheme.getAdaptiveGrey(
                                  context,
                                  lightShade: 300,
                                  darkShade: 800,
                                ),
                                AppTheme.getAdaptiveGrey(
                                  context,
                                  lightShade: 400,
                                  darkShade: 700,
                                ),
                              ],
                            )
                          : const LinearGradient(
                              colors: [
                                AppColors.accentPurple,
                                AppColors.accentPurpleBlue,
                              ],
                            ),
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: isBlocked
                          ? AppTheme.getAdaptiveGrey(
                              context,
                              lightShade: 500,
                              darkShade: 600,
                            )
                          : AppColors.textWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMe = currentUserId != null && message.senderId == currentUserId;
    final timestamp = message.timestamp.toLocal();
    final timeLabel = DateFormat('h:mm a').format(timestamp);
    final bubbleGradient = const LinearGradient(
      colors: [AppColors.accentPurple, AppColors.accentPurpleBlue],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                      eventHubService: eventHubService,
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 16,
                backgroundImage: userImageUrl != null
                    ? NetworkImage(userImageUrl!)
                    : null,
                backgroundColor: AppTheme.getAdaptiveGrey(
                  context,
                  lightShade: 300,
                  darkShade: 700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe ? bubbleGradient : null,
                    color: isMe
                        ? null
                        : (isDark ? AppColors.surfaceDark : Colors.white),
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
                      color: isMe
                          ? AppColors.textWhite
                          : (isDark
                                ? AppColors.textWhite
                                : const Color(0xFF1F2430)),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                if (showTimestamp || (isMe && showStatus)) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showTimestamp)
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.getAdaptiveGrey(
                                context,
                                lightShade: 600,
                                darkShade: 400,
                              ),
                              letterSpacing: 0.2,
                            ),
                          ),
                        if (isMe && showStatus) ...[
                          if (showTimestamp) const SizedBox(width: 8),
                          Icon(
                            message.isSeen ? Icons.done_all : Icons.done,
                            size: 16,
                            color: message.isSeen
                                ? AppColors.accentPurpleBlue
                                : AppColors.textGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            message.isSeen ? 'Seen' : 'Sent',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.getAdaptiveGrey(
                                context,
                                lightShade: 600,
                                darkShade: 400,
                              ),
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
