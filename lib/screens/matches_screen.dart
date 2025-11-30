import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:intl/intl.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/pulsing_logo_loader.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';
import '../api/event_hub_service.dart';
import 'dart:convert';
import 'dart:async';
import 'visit_profile/visit_profile_screen.dart';
import 'chat_screen.dart';
import 'dart:ui';
import '../theme/app_design_system.dart';

class MatchesScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  final EventHubService? eventHubService;

  const MatchesScreen({
    super.key,
    required this.api,
    required this.tokens,
    this.eventHubService,
  });

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<OtherUserProfileDto> _matches = [];
  bool _loading = true;
  final Map<String, MessageDto> _lastMessages = {};
  String? _currentUserId;
  Map<String, String> _tagNames = {};

  @override
  void initState() {
    super.initState();
    _loadMatches();
    _loadCurrentUserId();
    _loadTags();
    _setupSignalRCallbacks();
  }

  void _setupSignalRCallbacks() {
    final eventHub = widget.eventHubService;
    if (eventHub == null) {
      print("⚠️ EventHubService is null in MatchesScreen - no real-time updates");
      return;
    }

    print("🔧 Setting up SignalR callbacks for MatchesScreen");

    // Reload message previews when new message arrives
    eventHub.addMessageListener((messageData) {
      print("📩 MessageReceived in MatchesScreen - refreshing previews");
      if (mounted) {
        _loadLastMessages();
      }
    });

    // Reload when conversation is marked as seen
    eventHub.onConversationSeen = (payload) {
      print("👁️ ConversationSeen in MatchesScreen - refreshing previews");
      if (mounted) {
        _loadLastMessages();
      }
    };
  }

  @override
  void dispose() {
    // Clean up callbacks if needed
    super.dispose();
  }

  Future<void> _loadTags() async {
    try {
      final resp = await widget.api.getTags();
      if (resp.statusCode == 200) {
        final List<dynamic> tags = jsonDecode(resp.body);
        final Map<String, String> tagMap = {};
        for (var t in tags) {
          if (t is Map) {
            final id = t['id']?.toString();
            final name = t['name']?.toString();
            if (id != null && name != null) {
              tagMap[id] = name;
            }
          }
        }
        if (mounted) {
          setState(() {
            _tagNames = tagMap;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading tags: $e');
    }
  }

  Future<void> _loadMatches() async {
    setState(() => _loading = true);
    try {
      final resp = await widget.api.getMatches(limit: 50);
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final list = decoded is List ? decoded : [];
        final matches = <OtherUserProfileDto>[];
        for (final item in list) {
          try {
            if (item is Map) {
              final json = Map<String, dynamic>.from(item);
              final isBand = json['isBand'] == true;
              if (isBand) {
                matches.add(OtherUserProfileBandDto.fromJson(json));
              } else {
                matches.add(OtherUserProfileArtistDto.fromJson(json));
              }
            }
          } catch (e) {
            print('Error parsing match: $e');
          }
        }
        setState(() {
          _matches = matches;
          _loading = false;
        });

        await _loadLastMessages();
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Error loading matches: $e');
      setState(() => _loading = false);
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

  Future<void> _loadLastMessages() async {
    try {
      final resp = await widget.api.getMessagePreviews(limit: 20);
      debugPrint('Message previews response: ${resp.statusCode} ${resp.body}');

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List) {
          final messages = decoded.map((m) => MessageDto.fromJson(m)).toList();

          if (mounted) {
            setState(() {
              _lastMessages.clear();

              for (final match in _matches) {
                final matchMessage = messages.firstWhere(
                  (msg) =>
                      (msg.senderId == _currentUserId &&
                          msg.receiverId == match.id) ||
                      (msg.senderId == match.id &&
                          msg.receiverId == _currentUserId),
                  orElse: () => MessageDto(
                    id: '',
                    content: '',
                    timestamp: DateTime.now(),
                    senderId: '',
                    receiverId: '',
                  ),
                );

                if (matchMessage.content.isNotEmpty) {
                  _lastMessages[match.id] = matchMessage;
                }
              }

              // Sort matches by last message timestamp (most recent first)
              _matches.sort((a, b) {
                final aMessage = _lastMessages[a.id];
                final bMessage = _lastMessages[b.id];

                if (aMessage == null && bMessage == null) return 0;
                if (aMessage == null) return 1;
                if (bMessage == null) return -1;

                return bMessage.timestamp.compareTo(aMessage.timestamp);
              });
            });
          }
        }
      }
    } catch (e) {
      print('Error loading message previews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversations = _matches
        .where((m) => _lastMessages.containsKey(m.id))
        .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDarkAlt : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // No back arrow on navbar screen
        title: Text(
          'Messages',
          style: AppTextStyles.appBarTitle.copyWith(
            color: isDark ? AppColors.textWhite : AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textWhite,
            ),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 62,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                          border: Border(
                            right: BorderSide(
                              color: isDark ? Colors.white10 : Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: _buildContent(conversations, isDesktop: true),
                      ),
                    ),
                    Expanded(
                      flex: 38,
                      child: _DesktopRightPanel(
                        matches: _matches,
                        api: widget.api,
                        tokens: widget.tokens,
                        eventHubService: widget.eventHubService,
                        tagNames: _tagNames,
                      ),
                    ),
                  ],
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: AppBottomNav(current: BottomNavItem.messages),
                ),
              ],
            );
          }
          return Stack(
            children: [
              _buildContent(conversations),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: AppBottomNav(current: BottomNavItem.messages),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(List<OtherUserProfileDto> conversations, {bool isDesktop = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _loading
        ? Container(
            color: isDark ? AppColors.backgroundDarkAlt : AppColors.backgroundLight,
            child: const PulsingLogoLoader(
              message: 'Loading your matches...',
              size: 140,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Recent Matches',
                  style: isDesktop 
                      ? AppTextStyles.sectionTitle.copyWith(
                          color: isDark ? AppColors.textWhite : Colors.black87,
                        )
                      : AppTextStyles.sectionTitle.copyWith(
                          color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                        ),
                ),
              ),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _matches.length,
                  itemBuilder: (context, index) => _RecentMatchCard(
                    match: _matches[index],
                    api: widget.api,
                    tokens: widget.tokens,
                    eventHubService: widget.eventHubService,
                    isDesktop: isDesktop,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDarkAlt : AppColors.surfaceWhite,
                    borderRadius: AppBorderRadius.topLarge,
                  ),
                  child: conversations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: AppTheme.getAdaptiveGrey(context, lightShade: 400, darkShade: 600),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No conversations yet',
                                style: AppTextStyles.emptyStateTitle.copyWith(
                                  color: isDark ? AppColors.textWhite70 : null,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: conversations.length,
                          itemBuilder: (context, index) => _MatchListItem(
                            match: conversations[index],
                            lastMessage:
                                _lastMessages[conversations[index].id],
                            api: widget.api,
                            tokens: widget.tokens,
                            onRefresh: _loadLastMessages,
                            eventHubService: widget.eventHubService,
                            currentUserId: _currentUserId,
                          ),
                        ),
                ),
              ),
            ],
          );
  }
}

class _RecentMatchCard extends StatelessWidget {
  final OtherUserProfileDto match;
  final ApiClient api;
  final TokenStore tokens;
  final EventHubService? eventHubService;
  final bool isDesktop;

  const _RecentMatchCard({
    required this.match,
    required this.api,
    required this.tokens,
    this.eventHubService,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = match.profilePictures.isNotEmpty
        ? match.profilePictures.first.getAbsoluteUrl(api.baseUrl)
        : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VisitProfileScreen(
                  api: api,
                  tokens: tokens,
                  userId: match.id,
                  eventHubService: eventHubService,
                ),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.profilePictureBorderGradient,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      backgroundImage: imageUrl != null
                          ? NetworkImage(imageUrl)
                          : null,
                      backgroundColor: AppTheme.getAdaptiveGrey(context, lightShade: 200, darkShade: 800),
                      child: imageUrl == null
                          ? Text(
                              (match.name ?? 'U').substring(0, 1).toUpperCase(),
                              style: AppTextStyles.avatarInitialMedium,
                            )
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDarkAlt,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceDarkAlt,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: AppColors.textWhite,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              match.name ?? 'User',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.recentMatchName.copyWith(
                color: AppTheme.getTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchListItem extends StatelessWidget {
  final OtherUserProfileDto match;
  final MessageDto? lastMessage;
  final ApiClient api;
  final TokenStore tokens;
  final VoidCallback onRefresh;
  final EventHubService? eventHubService;
  final String? currentUserId;

  const _MatchListItem({
    required this.match,
    this.lastMessage,
    required this.api,
    required this.tokens,
    required this.onRefresh,
    this.eventHubService,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = match.profilePictures.isNotEmpty
        ? match.profilePictures.first.getAbsoluteUrl(api.baseUrl)
        : null;

    final isMe = currentUserId != null && lastMessage?.senderId == currentUserId;
    final isUnread = lastMessage != null && !isMe && !lastMessage!.isSeen;

    String displayContent = lastMessage?.content ??
        (match.description.isNotEmpty ? match.description : 'New match');

    if (lastMessage != null && isMe) {
      displayContent = 'You: $displayContent';
    }

    final timestamp = lastMessage?.timestamp;
    final timeText = timestamp != null
        ? DateFormat('HH:mm').format(timestamp.toLocal())
        : '';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              api: api,
              tokens: tokens,
              userId: match.id,
              userName: match.name ?? 'User',
              userImageUrl: imageUrl,
              eventHubService: eventHubService,
            ),
          ),
        );
        onRefresh();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              backgroundColor: AppTheme.getAdaptiveGrey(context, lightShade: 300, darkShade: 700),
              child: imageUrl == null
                  ? Text(
                      (match.name ?? 'U').substring(0, 1).toUpperCase(),
                      style: AppTextStyles.avatarInitialMedium,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.name ?? 'User',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayContent,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyRegular.copyWith(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                            color: isUnread ? AppTheme.getAdaptiveText(context) : null,
                          ),
                        ),
                      ),
                      if (timestamp != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          timeText,
                          style: AppTextStyles.bodyRegular.copyWith(
                            fontSize: 12,
                            color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _DesktopRightPanel extends StatefulWidget {
  final List<OtherUserProfileDto> matches;
  final ApiClient api;
  final TokenStore tokens;
  final EventHubService? eventHubService;
  final Map<String, String> tagNames;

  const _DesktopRightPanel({
    required this.matches,
    required this.api,
    required this.tokens,
    this.eventHubService,
    required this.tagNames,
  });

  @override
  State<_DesktopRightPanel> createState() => _DesktopRightPanelState();
}

class _DesktopRightPanelState extends State<_DesktopRightPanel> {
  OtherUserProfileDto? _featuredMatch;
  Timer? _shuffleTimer;

  @override
  void initState() {
    super.initState();
    _pickRandomMatch();
    // Auto-shuffle every 30 seconds to keep it dynamic
    _shuffleTimer = Timer.periodic(const Duration(seconds: 30), (_) => _pickRandomMatch());
  }

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    super.dispose();
  }

  void _pickRandomMatch() {
    if (widget.matches.isNotEmpty) {
      if (mounted) {
        setState(() {
          _featuredMatch = widget.matches[DateTime.now().millisecondsSinceEpoch % widget.matches.length];
        });
      }
    }
  }

  @override
  void didUpdateWidget(_DesktopRightPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.matches != oldWidget.matches && _featuredMatch == null) {
      _pickRandomMatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_featuredMatch == null) {
      return Container(
        color: AppColors.backgroundDark,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_note, size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                'No matches to feature yet',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    final match = _featuredMatch!;
    final imageUrl = match.profilePictures.isNotEmpty
        ? match.profilePictures.first.getAbsoluteUrl(widget.api.baseUrl)
        : null;

    // Determine subtitle (Artist/Band + Age/Members)
    String subtitle = match.isBand ? 'Band' : 'Artist';
    if (!match.isBand && match is OtherUserProfileArtistDto && match.age != null) {
      subtitle += ' • ${match.age} yo';
    } else if (match.isBand && match is OtherUserProfileBandDto) {
      subtitle += ' • ${match.bandMembers.length} Members';
    }

    // Check for location (simple check if it looks like a UUID or not)
    // If it's a UUID (36 chars with dashes), we skip it to avoid ugliness.
    // This is a heuristic since we don't have the city name resolved.
    final city = match.city;
    final showCity = city != null && city.length < 30; 

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Dynamic Blurred Background
          if (imageUrl != null)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.6),
              colorBlendMode: BlendMode.darken,
            ),
          if (imageUrl == null)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1525), Color(0xFF2A2438)],
                ),
              ),
            ),
          
          // Blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // 2. Content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SPOTLIGHT',
                    style: AppTextStyles.sectionLabel.copyWith(
                      color: AppColors.accentPurpleLight,
                      letterSpacing: 4,
                      fontSize: 14,
                    ),
                  ),
                  // Glass Card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: double.infinity,
                    padding: const EdgeInsets.all(24), // Slightly smaller padding
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 0,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar
                        Container(
                          width: 120, // Slightly smaller avatar
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accentPurple,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentPurple.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                            image: imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: imageUrl == null
                              ? Center(
                                  child: Text(
                                    (match.name ?? 'U').substring(0, 1).toUpperCase(),
                                    style: AppTextStyles.avatarInitialLarge.copyWith(fontSize: 40),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 20),
                        
                        // Name
                        Text(
                          match.name ?? 'Unknown',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headingLarge.copyWith(
                            fontSize: 28, // Slightly smaller font
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        
                        // Subtitle (Type • Age/Members)
                        Text(
                          subtitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.accentPurpleLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        if (showCity) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                city,
                                style: AppTextStyles.bodyRegular.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 20),
                        
                        // Tags
                        if (match.tags.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: match.tags.take(5).map((tagId) {
                              final tagName = widget.tagNames[tagId] ?? tagId;
                              // If it still looks like a UUID, try to shorten it or skip
                              final displayTag = (tagName.length > 20 && tagName.contains('-')) 
                                  ? 'Tag' 
                                  : tagName;
                                  
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Text(
                                  displayTag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        
                        if (match.tags.isNotEmpty) const SizedBox(height: 20),

                        // Description
                        if (match.description.isNotEmpty)
                          Text(
                            match.description,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyRegular.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              height: 1.5,
                            ),
                          ),

                        const SizedBox(height: 28),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VisitProfileScreen(
                                          api: widget.api,
                                          tokens: widget.tokens,
                                          userId: match.id,
                                          eventHubService: widget.eventHubService,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                    ),
                                  ),
                                  child: const Text('Profile'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          api: widget.api,
                                          tokens: widget.tokens,
                                          userId: match.id,
                                          userName: match.name ?? 'User',
                                          userImageUrl: imageUrl,
                                          eventHubService: widget.eventHubService,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.purpleGradient,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: AppShadows.purpleShadow,
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'Message',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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

          // Shuffle Button
          Positioned(
            bottom: 40,
            right: 40,
            child: FloatingActionButton(
              onPressed: _pickRandomMatch,
              backgroundColor: Colors.white.withOpacity(0.1),
              elevation: 0,
              hoverElevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.shuffle, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
