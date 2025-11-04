import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';
import 'dart:convert';
import 'visit_profile_screen.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;

  const MatchesScreen({super.key, required this.api, required this.tokens});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<OtherUserProfileDto> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
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
            final userType = item['userType']?.toString();
            final isBand = userType == 'band' || (item['isBand'] is bool ? item['isBand'] as bool : false);
            if (isBand) {
              matches.add(OtherUserProfileBandDto.fromJson(item));
            } else {
              matches.add(OtherUserProfileArtistDto.fromJson(item));
            }
          } catch (e) {
            print('Error parsing match: $e');
          }
        }
        setState(() {
          _matches = matches;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading matches: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1525),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2D3E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              // Settings action
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Recent Matches',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: _matches.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No matches yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _matches.length,
                itemBuilder: (context, index) => _MatchListItem(
                  match: _matches[index],
                  api: widget.api,
                  tokens: widget.tokens,
                ),
              ),
            ),
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
            builder: (context) => VisitProfileScreen(
              api: api,
              tokens: tokens,
              userId: match.id,
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
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade300, Colors.blue.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                      backgroundColor: Colors.grey.shade800,
                      child: imageUrl == null
                          ? Text(
                        (match.name ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 24, color: Colors.white),
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
                      color: const Color(0xFF2A2438),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2A2438), width: 2),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
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
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
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
  final ApiClient api;
  final TokenStore tokens;

  const _MatchListItem({
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
            builder: (context) => ChatScreen(
              api: api,
              tokens: tokens,
              userId: match.id,
              userName: match.name ?? 'User',
              userImageUrl: imageUrl,
            ),
          ),
        );
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
                style: const TextStyle(fontSize: 24, color: Colors.white),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    match.description.isNotEmpty
                        ? match.description
                        : 'New match',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
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
