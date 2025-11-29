import 'package:flutter/material.dart';
import 'package:zpi_test/screens/visit_profile/visit_profile_screen.dart';
import '../../../api/api_client.dart';
import '../../../api/token_store.dart';
import '../../../api/models.dart';
import '../../../api/event_hub_service.dart';
import 'swiping_action_buttons.dart';
import '../../shared/native_audio_player.dart';
import '../../shared/instagram_post_viewer.dart';
import '../../shared/media_models.dart';
import '../../shared/video_thumbnail.dart';
import '../../../theme/app_design_system.dart';

/// Draggable user card widget with swipe functionality.
/// Displays user profile information and handles swipe gestures for like/dislike actions.
class DraggableCard extends StatefulWidget {
  final String name;
  final String description;
  final String? imageUrl;
  final bool isBand;
  final String? city;
  final String? country;
  final String? gender;
  final Map<String, dynamic> userData;
  final Map<String, TagDto> tagById;
  final Map<String, String> categoryNames;
  final VoidCallback onSwipedLeft;
  final VoidCallback onSwipedRight;
  final bool isDraggable;
  final ApiClient api;
  final TokenStore tokens;
  final EventHubService? eventHubService;
  final bool showPrimaryActions;
  final VoidCallback? onPrimaryLike;
  final VoidCallback? onPrimaryDislike;
  final VoidCallback? onPrimaryFilter;
  final bool isWideLayout;

  const DraggableCard({
    super.key,
    required this.name,
    required this.description,
    this.imageUrl,
    this.isBand = false,
    this.city,
    this.country,
    this.gender,
    required this.userData,
    required this.tagById,
    required this.categoryNames,
    required this.onSwipedLeft,
    required this.onSwipedRight,
    this.isDraggable = true,
    required this.api,
    required this.tokens,
    this.eventHubService,
    this.showPrimaryActions = false,
    this.onPrimaryLike,
    this.onPrimaryDislike,
    this.onPrimaryFilter,
    this.isWideLayout = false,
  });

  @override
  State<DraggableCard> createState() => DraggableCardState();
}

class DraggableCardState extends State<DraggableCard>
    with SingleTickerProviderStateMixin {
  Offset _pos = Offset.zero;
  double _rot = 0.0;
  late AnimationController _ctrl;
  late Animation<Offset> _animPos;
  late Animation<double> _animRot;
  final ScrollController _scrollController = ScrollController();
  int _currentImageIndex = 0;
  bool _isAnimating = false;
  _Decision _decision = _Decision.none;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  List<Map<String, dynamic>> get _allMedia {
    final media = <Map<String, dynamic>>[];

    // Main image
    if (widget.imageUrl != null) {
      media.add({'type': 'image', 'url': widget.imageUrl!});
    }

    // Profile pictures
    if (widget.userData['profilePictures'] is List) {
      final pics = widget.userData['profilePictures'] as List;
      for (final pic in pics) {
        if (pic is Map) {
          String? url = pic['url']?.toString() ?? pic['fileUrl']?.toString();
          if (url != null && url.isNotEmpty) {
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              url = Uri.parse(widget.api.baseUrl)
                  .resolve(url.startsWith('/') ? url.substring(1) : url)
                  .toString();
            }
            media.add({'type': 'image', 'url': url});
          }
        }
      }
    }

    // Music samples (videos)
    if (widget.userData['musicSamples'] is List) {
      final samples = widget.userData['musicSamples'] as List;
      for (final sample in samples) {
        if (sample is Map) {
          final url = sample['fileUrl']?.toString();
          if (url != null && url.isNotEmpty) {
            final isVideo =
                url.toLowerCase().endsWith('.mp4') ||
                url.toLowerCase().endsWith('.mov');
            String absoluteUrl = url;
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              absoluteUrl = Uri.parse(widget.api.baseUrl)
                  .resolve(url.startsWith('/') ? url.substring(1) : url)
                  .toString();
            }
            if (isVideo) {
              media.add({'type': 'video', 'url': absoluteUrl});
            }
          }
        }
      }
    }

    return media;
  }

  void _runOffScreen(Offset target, double rot, VoidCallback onComplete) {
    _animPos = Tween(
      begin: _pos,
      end: target,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _animRot = Tween(
      begin: _rot,
      end: rot,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.addListener(() {
      setState(() {
        _pos = _animPos.value;
        _rot = _animRot.value;
      });
    });
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _isAnimating = false;
        _decision = _Decision.none;
        onComplete();
      }
    });
    _ctrl.forward(from: 0);
  }

  /// Programmatic swipe controls (used by arrow keys)
  void swipeRight() {
    if (_isAnimating || !widget.isDraggable) return;
    _isAnimating = true;
    _decision = _Decision.like;
    final w = MediaQuery.of(context).size.width;
    _runOffScreen(Offset(w * 1.5, _pos.dy), 0.5, widget.onSwipedRight);
  }

  void swipeLeft() {
    if (_isAnimating || !widget.isDraggable) return;
    _isAnimating = true;
    _decision = _Decision.nope;
    final w = MediaQuery.of(context).size.width;
    _runOffScreen(Offset(-w * 1.5, _pos.dy), -0.5, widget.onSwipedLeft);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final media = _allMedia;
    final bool isWide = widget.isWideLayout;
    final double heroHeight = isWide ? h * 0.48 : h * 0.45;
    final double actionButtonSize = isWide ? 44 : 50;
    final double actionIconSize = isWide ? 20 : 22;
    final double actionSpacing = isWide ? 12 : 16;
    final double contentBottomPadding = widget.showPrimaryActions
        ? (isWide ? 150 : 190)
        : (isWide ? 110 : 140);
    final threshold = w * 0.25;
    final dragLike = (_pos.dx / threshold).clamp(0.0, 1.0);
    final dragNope = (-_pos.dx / threshold).clamp(0.0, 1.0);
    final likeOpacity = _decision == _Decision.like ? 1.0 : dragLike;
    final nopeOpacity = _decision == _Decision.nope ? 1.0 : dragNope;

    // Extract tags grouped by category
    final Map<String, List<String>> groupedTags = {};
    if (widget.userData['tagsIds'] is List) {
      for (final raw in (widget.userData['tagsIds'] as List)) {
        final id = raw?.toString();
        if (id == null) continue;
        final tag = widget.tagById[id];
        if (tag == null) continue;
        final catId = tag.tagCategoryId ?? '';
        final catName = widget.categoryNames[catId] ?? 'Other';
        groupedTags.putIfAbsent(catName, () => []);
        groupedTags[catName]!.add(tag.name);
      }
    } else if (widget.userData['tags'] is List) {
      // Fallback: when backend returns names directly
      groupedTags['Tags'] = (widget.userData['tags'] as List)
          .map((e) => e.toString())
          .toList();
    }

    // Extract age for artists
    int? age;
    if (widget.userData['birthDate'] != null && !widget.isBand) {
      try {
        final birthDate = DateTime.parse(
          widget.userData['birthDate'].toString(),
        );
        age = DateTime.now().year - birthDate.year;
      } catch (_) {}
    }

    // Extract band members
    final bandMembers = <Map<String, dynamic>>[];
    if (widget.isBand && widget.userData['bandMembers'] is List) {
      bandMembers.addAll(
        (widget.userData['bandMembers'] as List).whereType<Map>().map(
          (m) => Map<String, dynamic>.from(m),
        ),
      );
    }

    return Transform.translate(
      offset: _pos,
      child: Transform.rotate(
        angle: _rot,
        child: GestureDetector(
          onTapUp: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final width = box.size.width;
            final dx = details.localPosition.dx;

            // Left 25%: Previous image
            if (dx < width * 0.25) {
              if (media.length > 1) {
                setState(() {
                  _currentImageIndex =
                      (_currentImageIndex - 1 + media.length) % media.length;
                });
              }
            }
            // Right 25%: Next image
            else if (dx > width * 0.75) {
              if (media.length > 1) {
                setState(() {
                  _currentImageIndex = (_currentImageIndex + 1) % media.length;
                });
              }
            }
            // Center 50%: Open full screen viewer
            else {
              if (media.isNotEmpty) {
                final mediaItems = media
                    .map(
                      (item) => MediaItem(
                        url: item['url'],
                        type: item['type'] == 'video'
                            ? MediaType.video
                            : MediaType.image,
                        fileName: item['url'].split('/').last,
                      ),
                    )
                    .toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InstagramPostViewer(
                      items: mediaItems,
                      initialIndex: _currentImageIndex,
                      accentColor: AppColors.accentPurpleBlue,
                    ),
                  ),
                );
              }
            }
          },
          onPanUpdate: widget.isDraggable
              ? (d) {
                  setState(() {
                    _pos += d.delta;
                    _rot = _pos.dx / (w * 4);
                  });
                }
              : null,
          onPanEnd: widget.isDraggable
              ? (e) {
                  final threshold = w * 0.25;
                  if (_pos.dx > threshold) {
                    _runOffScreen(
                      Offset(w * 1.5, _pos.dy),
                      0.5,
                      widget.onSwipedRight,
                    );
                  } else if (_pos.dx < -threshold) {
                    _runOffScreen(
                      Offset(-w * 1.5, _pos.dy),
                      -0.5,
                      widget.onSwipedLeft,
                    );
                  } else {
                    // snap back
                    _animPos = Tween(begin: _pos, end: Offset.zero).animate(
                      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
                    );
                    _animRot = Tween(begin: _rot, end: 0.0).animate(
                      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
                    );
                    _ctrl.addListener(() {
                      setState(() {
                        _pos = _animPos.value;
                        _rot = _animRot.value;
                      });
                    });
                    _ctrl.forward(from: 0);
                  }
                }
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isWide ? 32 : 0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(isWide ? 32 : 0),
                boxShadow: isWide
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 20),
                        ),
                      ]
                    : null,
              ),
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    // Scrollable content
                    Positioned.fill(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.only(bottom: contentBottomPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main image section with indicators
                            Stack(
                              children: [
                                // Image
                                SizedBox(
                                  height: heroHeight,
                                  width: double.infinity,
                                  child: media.isNotEmpty
                                      ? media[_currentImageIndex]['type'] ==
                                                'image'
                                            ? Image.network(
                                                media[_currentImageIndex]['url'],
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Container(
                                                        color: AppColors
                                                            .borderLight,
                                                        child: Icon(
                                                          Icons.person,
                                                          size: 100,
                                                          color: AppColors
                                                              .textPlaceholder,
                                                        ),
                                                      );
                                                    },
                                              )
                                            : VideoThumbnail(
                                                videoUrl:
                                                    media[_currentImageIndex]['url'],
                                              )
                                      : Container(
                                          color: AppColors.borderLight,
                                          child: Icon(
                                            Icons.person,
                                            size: 100,
                                            color: AppColors.textPlaceholder,
                                          ),
                                        ),
                                ),
                                // Image indicators
                                if (media.length > 1)
                                  Positioned(
                                    top: 8,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      children: List.generate(
                                        media.length,
                                        (idx) => Expanded(
                                          child: Container(
                                            height: 3,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: idx == _currentImageIndex
                                                  ? AppColors.surfaceWhite
                                                  : AppColors.surfaceWhite
                                                        .withOpacity(0.5),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                // Artist/Band Tag (Top Right)
                                Positioned(
                                  top: 24,
                                  right: 20,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isWide ? 12 : 16,
                                      vertical: isWide ? 6 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceWhite.withOpacity(
                                        0.2,
                                      ),
                                      border: Border.all(
                                        color: AppColors.surfaceWhite
                                            .withOpacity(0.4),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      widget.isBand ? 'BAND' : 'ARTIST',
                                      style: TextStyle(
                                        color: AppColors.textWhite,
                                        fontSize: isWide ? 11 : 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                                // Gradient overlay at bottom
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: heroHeight * 0.8,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          AppColors.backgroundFilterEnd
                                              .withOpacity(0.2),
                                          AppColors.backgroundFilterEnd
                                              .withOpacity(0.8),
                                          AppColors.backgroundFilterEnd,
                                        ],
                                        stops: const [0.0, 0.3, 0.75, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                // Name and location overlay
                                Positioned(
                                  bottom: 12,
                                  left: 20,
                                  right: 20,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          final userId =
                                              widget.userData['id']
                                                  ?.toString() ??
                                              '';
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  VisitProfileScreen(
                                                    api: widget.api,
                                                    tokens: widget.tokens,
                                                    userId: userId,
                                                    eventHubService:
                                                        widget.eventHubService,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          '${widget.name}${age != null ? ', $age' : ''}',
                                          style: TextStyle(
                                            fontSize: isWide ? 22 : 24,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textWhite,
                                            letterSpacing: 0.3,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(
                                                  0.5,
                                                ),
                                                blurRadius: 12,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if ((widget.city ?? '').isNotEmpty ||
                                          (widget.country ?? '').isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            [widget.city, widget.country]
                                                .where(
                                                  (e) =>
                                                      e != null && e.isNotEmpty,
                                                )
                                                .join(', ')
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: AppColors.textWhite
                                                  .withOpacity(0.95),
                                              fontSize: isWide ? 11 : 12,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.0,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (widget.showPrimaryActions) ...[
                                        const SizedBox(height: 18),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            RoundActionButton(
                                              icon: Icons.close,
                                              backgroundColor: AppColors
                                                  .surfaceWhite
                                                  .withOpacity(0.92),
                                              iconColor:
                                                  AppColors.accentPurpleVibrant,
                                              onTap:
                                                  widget.onPrimaryDislike ??
                                                  () {},
                                              size: actionButtonSize,
                                              iconSize: actionIconSize,
                                            ),
                                            SizedBox(width: actionSpacing),
                                            RoundActionButton(
                                              icon: Icons.tune,
                                              backgroundColor: AppColors
                                                  .surfaceWhite
                                                  .withOpacity(0.92),
                                              iconColor:
                                                  AppColors.accentPurpleDeep,
                                              onTap:
                                                  widget.onPrimaryFilter ??
                                                  () {},
                                              size: actionButtonSize,
                                              iconSize: actionIconSize,
                                              isElevated: true,
                                            ),
                                            SizedBox(width: actionSpacing),
                                            RoundActionButton(
                                              icon: Icons.favorite,
                                              backgroundColor: AppColors
                                                  .surfaceWhite
                                                  .withOpacity(0.92),
                                              iconColor: AppColors.accentPink,
                                              onTap:
                                                  widget.onPrimaryLike ?? () {},
                                              size: actionButtonSize,
                                              iconSize: actionIconSize,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // About section
                            if (widget.description.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 18 : 20,
                                  vertical: isWide ? 16 : 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ABOUT',
                                      style: TextStyle(
                                        fontSize: isWide ? 12 : 13,
                                        letterSpacing: 1.0,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPurpleVibrant,
                                      ),
                                    ),
                                    SizedBox(height: isWide ? 8 : 10),
                                    Text(
                                      widget.description,
                                      style: TextStyle(
                                        fontSize: isWide ? 13 : 14,
                                        height: 1.45,
                                        color: AppColors.textDarkGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Audio player section
                            Builder(
                              builder: (context) {
                                // Extract audio tracks from userData
                                final List<AudioTrack> audioTracks = [];
                                int audioIndex = 0; // Track audio file index
                                if (widget.userData['musicSamples'] is List) {
                                  for (final sample
                                      in (widget.userData['musicSamples']
                                          as List)) {
                                    if (sample is Map) {
                                      final url = sample['fileUrl']?.toString();
                                      if (url != null && url.isNotEmpty) {
                                        // Check if this is an audio file (not video)
                                        final fileName = url.split('/').last;
                                        final lowerName = fileName
                                            .toLowerCase();
                                        final isAudio =
                                            lowerName.endsWith('.mp3') ||
                                            lowerName.endsWith('.wav') ||
                                            lowerName.endsWith('.m4a');

                                        // Only add audio files to the player
                                        if (isAudio) {
                                          audioIndex++; // Increment for audio files only
                                          // Normalize to absolute URL if needed
                                          String absoluteUrl = url;
                                          if (!url.startsWith('http://') &&
                                              !url.startsWith('https://')) {
                                            absoluteUrl =
                                                Uri.parse(widget.api.baseUrl)
                                                    .resolve(
                                                      url.startsWith('/')
                                                          ? url.substring(1)
                                                          : url,
                                                    )
                                                    .toString();
                                          }
                                          audioTracks.add(
                                            AudioTrack(
                                              title:
                                                  '${widget.name} Audio $audioIndex',
                                              fileUrl: absoluteUrl,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  }
                                }

                                if (audioTracks.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isWide ? 18 : 20,
                                    vertical: isWide ? 12 : 16,
                                  ),
                                  child: NativeAudioPlayer(
                                    tracks: audioTracks,
                                    accentColor: AppColors.textPurpleVibrant,
                                  ),
                                );
                              },
                            ),
                            // Tag sections
                            if (groupedTags.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 18 : 20,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: groupedTags.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 18,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.key.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: isWide ? 12 : 13,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.0,
                                              color:
                                                  AppColors.textPurpleVibrant,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: isWide ? 6 : 8,
                                            runSpacing: isWide ? 8 : 10,
                                            children: entry.value
                                                .map(
                                                  (tagName) => Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: isWide
                                                              ? 12
                                                              : 16,
                                                          vertical: isWide
                                                              ? 8
                                                              : 10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .accentPurple,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      tagName,
                                                      style: TextStyle(
                                                        fontSize: isWide
                                                            ? 11
                                                            : 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            AppColors.textWhite,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            // Gender section
                            if (widget.gender != null &&
                                widget.gender!.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 18 : 16,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GENDER',
                                      style: TextStyle(
                                        fontSize: isWide ? 12 : 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                        color: AppColors.textPurpleVibrant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.gender!,
                                      style: TextStyle(
                                        fontSize: isWide ? 13 : 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Band members section
                            if (bandMembers.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 18 : 16,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'BAND MEMBERS',
                                      style: TextStyle(
                                        fontSize: isWide ? 12 : 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                        color: AppColors.textPurpleVibrant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...bandMembers.map((member) {
                                      final name =
                                          member['name']?.toString() ?? '';
                                      final age =
                                          member['age']?.toString() ?? '';
                                      final role =
                                          member['bandRole']?.toString() ??
                                          member['bandRoleName']?.toString() ??
                                          '';
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor:
                                                  AppColors.avatarBackground,
                                              child: Icon(
                                                Icons.person,
                                                color:
                                                    AppColors.accentPurpleDark,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '$name${age.isNotEmpty ? ', $age' : ''}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: isWide
                                                          ? 13
                                                          : 14,
                                                    ),
                                                  ),
                                                  if (role.isNotEmpty)
                                                    Text(
                                                      role,
                                                      style: TextStyle(
                                                        fontSize: isWide
                                                            ? 11
                                                            : 12,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    // Tinted decision overlay
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: likeOpacity > 0
                                ? AppColors.statusOnline.withOpacity(
                                    (isWide ? 0.06 : 0.10) * likeOpacity + 0.04,
                                  )
                                : nopeOpacity > 0
                                ? AppColors.accentRed.withOpacity(
                                    (isWide ? 0.06 : 0.10) * nopeOpacity + 0.04,
                                  )
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    // Large LIKE stamp
                    Positioned(
                      top: isWide ? 20 : 28,
                      right: isWide ? 18 : 24,
                      child: Opacity(
                        opacity: likeOpacity,
                        child: Transform.rotate(
                          angle: 0.18,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 14 : 18,
                              vertical: isWide ? 8 : 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite.withOpacity(0.85),
                              border: Border.all(
                                color: AppColors.statusOnline,
                                width: 4,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'LIKE',
                              style: TextStyle(
                                color: AppColors.statusOnline,
                                fontSize: isWide ? 30 : 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Large NOPE stamp
                    Positioned(
                      top: isWide ? 20 : 28,
                      left: isWide ? 18 : 24,
                      child: Opacity(
                        opacity: nopeOpacity,
                        child: Transform.rotate(
                          angle: -0.18,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 14 : 18,
                              vertical: isWide ? 8 : 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite.withOpacity(0.85),
                              border: Border.all(
                                color: AppColors.accentRed,
                                width: 4,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'NOPE',
                              style: TextStyle(
                                color: AppColors.accentRed,
                                fontSize: isWide ? 30 : 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Decision { none, like, nope }
