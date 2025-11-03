import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';

class UsersScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  const UsersScreen({super.key, required this.api, required this.tokens});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _out = '';
  List<Map<String, dynamic>> _users = [];
  final Map<String, String?> _userImages = {};
  bool _showArtists = true;
  bool _showBands = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final resp = await widget.api.getMatchPreference();
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) decoded = jsonDecode(decoded);
        if (decoded is Map) {
          setState(() {
            _showArtists = decoded['showArtists'] is bool ? decoded['showArtists'] : true;
            _showBands = decoded['showBands'] is bool ? decoded['showBands'] : true;
          });
        }
      }
    } catch (_) {
      // ignore, use defaults
    }
    _list();
  }

  Future<void> _savePreference() async {
    try {
      final dto = UpdateMatchPreferenceDto(
        showArtists: _showArtists,
        showBands: _showBands,
        maxDistance: null,
        countryId: null,
        cityId: null,
        artistMinAge: null,
        artistMaxAge: null,
        artistGenderId: null,
        bandMinMembersCount: null,
        bandMaxMembersCount: null,
        filterTagsIds: const [],
      );
      await widget.api.updateMatchPreference(dto);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved'), duration: Duration(seconds: 1)),
        );
      }
      _list();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save preferences'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _list() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _users = [];
      _userImages.clear();
    });

    final List<Map<String, dynamic>> allUsers = [];
    
    // Fetch artists if enabled
    if (_showArtists) {
      try {
        final resp = await widget.api.getPotentialMatchesArtists(limit: 50, offset: 0);
        if (resp.statusCode == 200) {
          var decoded = jsonDecode(resp.body);
          if (decoded is String) decoded = jsonDecode(decoded);
          if (decoded is List) {
            allUsers.addAll(decoded.whereType<Map>().map((m) => Map<String, dynamic>.from(m)));
          }
        }
      } catch (_) {}
    }

    // Fetch bands if enabled
    if (_showBands) {
      try {
        final resp = await widget.api.getPotentialMatchesBands(limit: 50, offset: 0);
        if (resp.statusCode == 200) {
          var decoded = jsonDecode(resp.body);
          if (decoded is String) decoded = jsonDecode(decoded);
          if (decoded is List) {
            allUsers.addAll(decoded.whereType<Map>().map((m) => Map<String, dynamic>.from(m)));
          }
        }
      } catch (_) {}
    }

    setState(() {
      _users = allUsers;
      _isLoading = false;
      _out = 'Loaded ${_users.length} potential matches';
    });

    // Fetch images
    for (final u in _users) {
      final id = u['id']?.toString();
      if (id != null && id.isNotEmpty) _fetchUserImage(id, u);
    }
  }

  Future<void> _fetchUserImage(String userId, Map<String, dynamic> userData) async {
    try {
      // Try to use profilePictures from the user data first
      if (userData['profilePictures'] is List && (userData['profilePictures'] as List).isNotEmpty) {
        final pics = userData['profilePictures'] as List;
        final first = pics.first;
        if (first is Map) {
          final url = first['url']?.toString();
          if (url != null && url.isNotEmpty) {
            _userImages[userId] = url;
            if (mounted) setState(() {});
            return;
          }
        }
      }

      // Fallback: fetch from endpoint
      final resp = await widget.api.getProfilePicturesForUser(userId);
      if (resp.statusCode != 200) return;
      var decoded = jsonDecode(resp.body);
      if (decoded is String) decoded = jsonDecode(decoded);
      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.firstWhere((e) => e is Map, orElse: () => null);
        if (first is Map) {
          // try common fields
          String? url;
          for (final key in ['url', 'fileUrl', 'downloadUrl', 'path', 'file', 'fileName', 'filename', 'id']) {
            if (first.containsKey(key) && first[key] != null) {
              final v = first[key].toString();
              if (key == 'id') {
                // construct a probable download URL: base/profile-pictures/{id}
                final base = widget.api.baseUrl;
                url = Uri.parse(base).resolve('profile-pictures/$v').toString();
              } else {
                url = v;
              }
              break;
            }
          }
          _userImages[userId] = url;
          if (mounted) setState(() {});
        }
      }
    } catch (_) {}
  }

  Future<void> _like(String id) async {
    final resp = await widget.api.like(SwipeDto(receiverId: id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Like: ${resp.statusCode}')));
  }

  Future<void> _dislike(String id) async {
    final resp = await widget.api.dislike(SwipeDto(receiverId: id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dislike: ${resp.statusCode}')));
  }

  Future<void> _showMatches() async {
    final resp = await widget.api.getMatches();
    setState(() => _out = 'Matches: ${resp.statusCode}\n${resp.body}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Matches')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Preference toggles
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Show me:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            dense: true,
                            title: const Text('Artists'),
                            value: _showArtists,
                            onChanged: (v) {
                              setState(() => _showArtists = v ?? true);
                              _savePreference();
                            },
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            dense: true,
                            title: const Text('Bands'),
                            value: _showBands,
                            onChanged: (v) {
                              setState(() => _showBands = v ?? true);
                              _savePreference();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _list,
                  child: _isLoading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Refresh'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _showMatches, child: const Text('Show Matches')),
              ],
            ),
            const SizedBox(height: 12),
            if (_out.isNotEmpty) Text(_out, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 12),
            Expanded(
              child: _users.isEmpty
                  ? Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('No potential matches.\nTry adjusting your preferences.'),
                    )
                  : Stack(
                      children: List.generate(_users.length, (index) {
                        final u = _users[index];
                        final id = u['id']?.toString() ?? '';
                        final name = u['name']?.toString() ?? '(no name)';
                        final imageUrl = _userImages[id];
                        final top = index == _users.length - 1;
                        return Positioned.fill(
                          child: DraggableCard(
                            key: ValueKey(id),
                            name: name,
                            description: u['description']?.toString() ?? '',
                            imageUrl: imageUrl,
                            isBand: u['isBand'] is bool ? u['isBand'] : false,
                            city: u['city']?.toString(),
                            country: u['country']?.toString(),
                            userData: u,
                            onSwipedLeft: () async {
                              await _dislike(id);
                              setState(() => _users.removeAt(index));
                            },
                            onSwipedRight: () async {
                              await _like(id);
                              setState(() => _users.removeAt(index));
                            },
                            isDraggable: top,
                          ),
                        );
                      }),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class DraggableCard extends StatefulWidget {
  final String name;
  final String description;
  final String? imageUrl;
  final bool isBand;
  final String? city;
  final String? country;
  final Map<String, dynamic> userData;
  final VoidCallback onSwipedLeft;
  final VoidCallback onSwipedRight;
  final bool isDraggable;

  const DraggableCard({
    super.key,
    required this.name,
    required this.description,
    this.imageUrl,
    this.isBand = false,
    this.city,
    this.country,
    required this.userData,
    required this.onSwipedLeft,
    required this.onSwipedRight,
    this.isDraggable = true,
  });

  @override
  State<DraggableCard> createState() => _DraggableCardState();
}

class _DraggableCardState extends State<DraggableCard> with SingleTickerProviderStateMixin {
  Offset _pos = Offset.zero;
  double _rot = 0.0;
  late AnimationController _ctrl;
  late Animation<Offset> _animPos;
  late Animation<double> _animRot;
  final ScrollController _scrollController = ScrollController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  List<String> get _allImages {
    final images = <String>[];
    if (widget.imageUrl != null) images.add(widget.imageUrl!);
    
    // Add more images from profilePictures if available
    if (widget.userData['profilePictures'] is List) {
      final pics = widget.userData['profilePictures'] as List;
      for (final pic in pics) {
        if (pic is Map) {
          final url = pic['url']?.toString();
          if (url != null && url.isNotEmpty && !images.contains(url)) {
            images.add(url);
          }
        }
      }
    }
    return images;
  }

  void _runOffScreen(Offset target, double rot, VoidCallback onComplete) {
    _animPos = Tween(begin: _pos, end: target).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _animRot = Tween(begin: _rot, end: rot).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.addListener(() {
      setState(() {
        _pos = _animPos.value;
        _rot = _animRot.value;
      });
    });
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) onComplete();
    });
    _ctrl.forward(from: 0);
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
    final images = _allImages;
    
    // Extract tags
    final tags = <String>[];
    if (widget.userData['tags'] is List) {
      tags.addAll((widget.userData['tags'] as List).map((e) => e.toString()));
    }
    
    // Extract age for artists
    int? age;
    if (widget.userData['birthDate'] != null && !widget.isBand) {
      try {
        final birthDate = DateTime.parse(widget.userData['birthDate'].toString());
        age = DateTime.now().year - birthDate.year;
      } catch (_) {}
    }
    
    // Extract band members
    final bandMembers = <Map<String, dynamic>>[];
    if (widget.isBand && widget.userData['bandMembers'] is List) {
      bandMembers.addAll((widget.userData['bandMembers'] as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)));
    }

    return Transform.translate(
      offset: _pos,
      child: Transform.rotate(
        angle: _rot,
        child: GestureDetector(
          onTap: () {
            // Tap to toggle image
            if (images.length > 1) {
              setState(() {
                _currentImageIndex = (_currentImageIndex + 1) % images.length;
              });
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
                    _runOffScreen(Offset(w * 1.5, _pos.dy), 0.5, widget.onSwipedRight);
                  } else if (_pos.dx < -threshold) {
                    _runOffScreen(Offset(-w * 1.5, _pos.dy), -0.5, widget.onSwipedLeft);
                  } else {
                    // snap back
                    _animPos = Tween(begin: _pos, end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
                    _animRot = Tween(begin: _rot, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: h * 0.75,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main image section with indicators
                      Stack(
                        children: [
                          // Image
                          Container(
                            height: h * 0.5,
                            width: double.infinity,
                            child: images.isNotEmpty
                                ? Image.network(
                                    images[_currentImageIndex],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: Icon(Icons.person, size: 100, color: Colors.grey[500]),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: Icon(Icons.person, size: 100, color: Colors.grey[500]),
                                  ),
                          ),
                          // Image indicators
                          if (images.length > 1)
                            Positioned(
                              top: 8,
                              left: 0,
                              right: 0,
                              child: Row(
                                children: List.generate(
                                  images.length,
                                  (idx) => Expanded(
                                    child: Container(
                                      height: 3,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: idx == _currentImageIndex ? Colors.white : Colors.white.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
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
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Name and location overlay
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${widget.name}${age != null ? ', $age' : ''}',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                                        ),
                                      ),
                                    ),
                                    if (widget.isBand)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.purple,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'BAND',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (widget.city != null || widget.country != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on, color: Colors.white, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          [widget.city, widget.country].where((e) => e != null && e.isNotEmpty).join(', '),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // About section
                      if (widget.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'About',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.description,
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      // Tags section
                      if (tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Genres',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: tags.map((tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor: Colors.purple[50],
                                  labelStyle: TextStyle(color: Colors.purple[700], fontSize: 12),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                      // Band members section
                      if (bandMembers.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Band Members',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...bandMembers.map((member) {
                                final name = member['name']?.toString() ?? '';
                                final age = member['age']?.toString() ?? '';
                                final role = member['bandRole']?.toString() ?? member['bandRoleName']?.toString() ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.purple[100],
                                        child: Icon(Icons.person, color: Colors.purple[700], size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$name${age.isNotEmpty ? ', $age' : ''}',
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            if (role.isNotEmpty)
                                              Text(
                                                role,
                                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                      const SizedBox(height: 80), // Space for swipe indicators
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
