import 'package:flutter/material.dart';

class ProfileStep2Screen extends StatefulWidget {
  final String accountType;
  final String name;
  final String country;
  final String city;
  final void Function({required List<String> tags, required String about}) onNext;
  const ProfileStep2Screen({super.key, required this.accountType, required this.name, required this.country, required this.city, required this.onNext});

  @override
  State<ProfileStep2Screen> createState() => _ProfileStep2ScreenState();
}

class _ProfileStep2ScreenState extends State<ProfileStep2Screen> {
  final _about = TextEditingController();
  final List<String> _allTags = [
    'Bass guitar', 'Piano', 'Drums', 'Guitar', 'Vocal', 'Violin', 'Trumpet', 'Musician', 'Producer',
  ]; // TODO: fetch from API
  final Set<String> _selectedTags = {};
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('What is your jam?')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Instruments / Activity', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allTags.map((tag) => FilterChip(
                label: Text(tag),
                selected: _selectedTags.contains(tag),
                onSelected: (v) => setState(() {
                  if (v) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                }),
              )).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _about,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'About you',
                hintText: 'Tell us a fun fact about you! What do you like?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: () {
                if (_selectedTags.isEmpty || _about.text.trim().isEmpty) {
                  setState(() => _error = 'Fill all fields');
                  return;
                }
                widget.onNext(tags: _selectedTags.toList(), about: _about.text.trim());
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
