import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';
import 'change_password_screen.dart';
import '../theme/app_design_system.dart';
import '../theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  final ApiClient api;
  final TokenStore tokens;
  const SettingsScreen({super.key, required this.api, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = Divider(
      height: 1, 
      color: isDark ? AppColors.surfaceDarkGrey : AppColors.borderLight,
    );
    
    return Scaffold(
      backgroundColor: isDark 
          ? AppColors.backgroundDark 
          : AppColors.backgroundLightPurple,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, 
            color: isDark ? AppColors.textWhite : AppColors.textPrimaryAlt,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: isDark ? AppColors.textWhite : AppColors.textPrimaryAlt,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          divider,
          const SizedBox(height: 12),
          // Dark Mode
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            leading: Icon(
              Icons.dark_mode_outlined,
              color: isDark ? AppColors.textWhite : AppColors.textPrimaryAlt,
            ),
            title: Text(
              'Dark Mode',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              themeProvider.isDarkMode 
                  ? 'Dark mode enabled' 
                  : 'Light mode enabled',
              style: TextStyle(
                color: isDark 
                    ? AppColors.textWhite70 
                    : AppColors.textGrey,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
            ),
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
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to profile edit step 1
              Navigator.pushNamed(context, '/profile/edit');
            },
          ),
          const SizedBox(height: 8),
          divider,
          const SizedBox(height: 8),
          _SettingsItem(
            icon: Icons.lock_outline,
            text: 'Change Password',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChangePasswordScreen(api: api, tokens: tokens),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          divider,
          const SizedBox(height: 8),

          _SettingsItem(
            icon: Icons.logout,
            text: 'Log out',
            onTap: () async {
              final confirmed = await _confirm(
                context,
                title: 'Log out',
                message: 'Do you really want to log out?',
              );
              if (confirmed != true) return;
              final resp = await api.logout();
              if (resp.statusCode >= 200 && resp.statusCode < 300) {
                // Clear tokens and go to login
                await tokens.clear();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (r) => false,
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: ${resp.statusCode}')),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          divider,
          const SizedBox(height: 8),
          _SettingsItem(
            icon: Icons.delete_forever_outlined,
            text: 'Delete account',
            color: AppColors.accentRed,
            onTap: () async {
              final confirmed = await _confirm(
                context,
                title: 'Delete account',
                message:
                    'This will permanently remove your profile, media and matches. Continue?',
              );
              if (confirmed != true) return;
              final pwd = await _askPassword(context);
              if (pwd == null || pwd.isEmpty) return;
              final resp = await api.deleteUser(PasswordDto(password: pwd));
              if (resp.statusCode >= 200 && resp.statusCode < 300) {
                await tokens.clear();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (r) => false,
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: ${resp.statusCode}')),
                );
              }
            },
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
  final Color? color;

  const _SettingsItem({
    required this.icon,
    required this.text,
    this.trailing,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppColors.textWhite : AppColors.textPrimaryAlt;
    
    return ListTile(
      leading: Icon(icon, color: color ?? defaultColor),
      title: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color ?? defaultColor,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}

Future<String?> _askPassword(BuildContext context) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirm Deletion'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your password to confirm account deletion:'),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
