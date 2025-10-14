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

  Future<void> _list() async {
    final resp = await widget.api.getUsers();
    setState(() => _out = 'Status: ${resp.statusCode}\n${resp.body}');
    try {
      var decoded = jsonDecode(resp.body);
      if (decoded is String) decoded = jsonDecode(decoded);
      if (decoded is List) {
        _users = decoded.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        // kick off image fetches for users
        for (final u in _users) {
          final id = u['id']?.toString();
          if (id != null && id.isNotEmpty) _fetchUserImage(id);
        }
      } else {
        _users = [];
      }
    } catch (_) {
      _users = [];
    }
    setState(() {});
  }

  Future<void> _fetchUserImage(String userId) async {
    try {
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
      appBar: AppBar(title: const Text('Users')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [ElevatedButton(onPressed: _list, child: const Text('List Users')), const SizedBox(width: 8), ElevatedButton(onPressed: _showMatches, child: const Text('Show Matches'))]),
            const SizedBox(height: 12),
            Text(_out),
            const SizedBox(height: 12),
            Expanded(
              child: _users.isEmpty
                  ? const Center(child: Text('No users.'))
                  : Stack(
                      children: List.generate(_users.length, (index) {
                        final u = _users[index];
                        final id = u['id']?.toString() ?? '';
                        final name = u['name']?.toString() ?? '(no name)';
                        final top = index == _users.length - 1;
                        return Positioned.fill(
                          child: DraggableCard(
                            key: ValueKey(id),
                            name: name,
                            description: u['description']?.toString() ?? '',
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
  final VoidCallback onSwipedLeft;
  final VoidCallback onSwipedRight;
  final bool isDraggable;

  const DraggableCard({super.key, required this.name, required this.description, required this.onSwipedLeft, required this.onSwipedRight, this.isDraggable = true});

  @override
  State<DraggableCard> createState() => _DraggableCardState();
}

class _DraggableCardState extends State<DraggableCard> with SingleTickerProviderStateMixin {
  Offset _pos = Offset.zero;
  double _rot = 0.0;
  late AnimationController _ctrl;
  late Animation<Offset> _animPos;
  late Animation<double> _animRot;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Transform.translate(
      offset: _pos,
      child: Transform.rotate(
        angle: _rot,
        child: GestureDetector(
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
            elevation: 6,
            child: Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Column(mainAxisSize: MainAxisSize.min, children: [Text(widget.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(widget.description)]),
            ),
          ),
        ),
      ),
    );
  }
}
