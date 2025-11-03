import 'package:flutter/material.dart';

class ProfileSummaryScreen extends StatelessWidget {
  final String accountType;
  final String name;
  final String country;
  final String city;
  final List<String> tags;
  final String about;
  final void Function()? onAddMedia;
  const ProfileSummaryScreen({super.key, required this.accountType, required this.name, required this.country, required this.city, required this.tags, required this.about, this.onAddMedia});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(city.toUpperCase()),
                    Text(country),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: tags.map((t) => Chip(label: Text(t))).toList(),
            ),
            const SizedBox(height: 16),
            const Text('About:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(about),
            const SizedBox(height: 24),
            const Divider(),
            const Text('Multimedia:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onAddMedia,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add photo / media'),
            ),
            // TODO: wyświetlanie dodanych multimediów
          ],
        ),
      ),
    );
  }
}
