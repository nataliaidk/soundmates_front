import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../widgets/app_bottom_nav.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';
import '../api/event_hub_service.dart';
import 'dart:convert';
import 'visit_profile/visit_profile_screen.dart';
import 'chat_screen.dart';
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
  Map<String, MessageDto> _lastMessages = {};
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadMatches();
    _loadCurrentUserId();
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
    return Scaffold(
      backgroundColor: AppColors.backgroundDarkAlt,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        automaticallyImplyLeading: false, // No back arrow on navbar screen
        title: Text('Messages', style: AppTextStyles.appBarTitle),
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
      body: Stack(
        children: [
          _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.textWhite),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Recent Matches',
                        style: AppTextStyles.sectionTitle,
                      ),
                    ),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _matches.length,
                        itemBuilder: (context, index) => _RecentMatchCard(
                          match: _matches[index],
                          api: widget.api,
                          tokens: widget.tokens,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: AppBorderRadius.topLarge,
                        ),
                        child: _matches.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No matches yet',
                                      style: AppTextStyles.emptyStateTitle,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _matches.length,
                                itemBuilder: (context, index) => _MatchListItem(
                                  match: _matches[index],
                                  lastMessage:
                                      _lastMessages[_matches[index].id],
                                  api: widget.api,
                                  tokens: widget.tokens,
                                  onRefresh: _loadLastMessages,
                                  eventHubService: widget.eventHubService,
                                ),
                              ),
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
      ),
    );
  }
}

class _RecentMatchCard extends StatelessWidget {
  final OtherUserProfileDto match;
  final ApiClient api;
  final TokenStore tokens;

  const _RecentMatchCard({
    required this.match,
    required this.api,
    required this.tokens,
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
                VisitProfileScreen(api: api, tokens: tokens, userId: match.id),
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
                  width: 70,
                  height: 70,
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
                      backgroundColor: Colors.grey.shade800,
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
            const SizedBox(height: 8),
            Text(
              match.name ?? 'User',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.recentMatchName,
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

  const _MatchListItem({
    required this.match,
    this.lastMessage,
    required this.api,
    required this.tokens,
    required this.onRefresh,
    this.eventHubService,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = match.profilePictures.isNotEmpty
        ? match.profilePictures.first.getAbsoluteUrl(api.baseUrl)
        : null;

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
              backgroundColor: Colors.grey.shade300,
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
                  Text(match.name ?? 'User', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage?.content ??
                        (match.description.isNotEmpty
                            ? match.description
                            : 'New match'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyRegular,
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
