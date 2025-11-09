import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';

class SettingsScreen extends StatelessWidget {
  final ApiClient api;
  final TokenStore tokens;
  const SettingsScreen({super.key, required this.api, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final divider = Divider(height: 1, color: Colors.grey.shade300);
    return Scaffold(
      backgroundColor: const Color(0xFFF9F4FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          divider,
          const SizedBox(height: 12),
          // Dark Mode (coming soon)
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('COMING SOON', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 0.3)),
                  ],
                ),
              ),
              Switch(
                value: false,
                onChanged: (_) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dark mode coming soon')));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          divider,
          const SizedBox(height: 8),

          _SettingsItem(
            icon: Icons.gavel_outlined,
            text: 'Terms of Service',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/terms'),
          ),
          const SizedBox(height: 8),
          divider,
          const SizedBox(height: 8),

          _SettingsItem(
            icon: Icons.account_circle_outlined,
            text: 'Account',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account editing not implemented yet')));
            },
          ),
          const SizedBox(height: 8),
          divider,
          const SizedBox(height: 8),

          _SettingsItem(
            icon: Icons.logout,
            text: 'Log out',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log out (mock)')));
            },
          ),
          const SizedBox(height: 8),
          divider,
          const SizedBox(height: 16),

          // Delete account
          Center(
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete account (mock)')));
              },
              child: const Text('Delete account', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.text,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
