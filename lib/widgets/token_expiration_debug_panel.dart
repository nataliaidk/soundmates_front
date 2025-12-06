import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';

/// Debug widget for testing token expiration without waiting
///
/// Add this to any screen during development:
/// ```dart
/// // At the top of your screen's build method:
/// if (kDebugMode) TokenExpirationDebugPanel(api: api),
/// ```
class TokenExpirationDebugPanel extends StatefulWidget {
  final ApiClient api;
  final TokenStore? tokens;

  const TokenExpirationDebugPanel({
    super.key,
    required this.api,
    this.tokens,
  });

  @override
  State<TokenExpirationDebugPanel> createState() =>
      _TokenExpirationDebugPanelState();
}

class _TokenExpirationDebugPanelState
    extends State<TokenExpirationDebugPanel> {
  Map<String, dynamic>? _tokenStatus;
  bool _isExpanded = false;

  Future<void> _refreshStatus() async {
    final status = await widget.api.debugGetTokenStatus();
    setState(() {
      _tokenStatus = status;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(
                    Icons.bug_report,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Token Expiration Testing',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_isExpanded) ...[
            const Divider(color: Colors.white54, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Token Status
                  if (_tokenStatus != null) ...[
                    _StatusRow(
                      label: 'Access Token:',
                      value: _tokenStatus!['hasAccessToken'] == true
                          ? '✅ Valid'
                          : '❌ Missing',
                      color: _tokenStatus!['hasAccessToken'] == true
                          ? Colors.green
                          : Colors.red,
                    ),
                    _StatusRow(
                      label: 'Refresh Token:',
                      value: _tokenStatus!['hasRefreshToken'] == true
                          ? '✅ Valid'
                          : '❌ Missing',
                      color: _tokenStatus!['hasRefreshToken'] == true
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Test Buttons
                  const Text(
                    'Test Scenarios:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Test 1: Auto-refresh
                  _DebugButton(
                    label: '1. Test Auto-Refresh',
                    subtitle: 'Expires access token only',
                    icon: Icons.refresh,
                    color: Colors.blue,
                    onPressed: () async {
                      await widget.api.debugSimulateAccessTokenExpired();
                      await _refreshStatus();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '🧪 Access token expired. Next API call will auto-refresh!',
                            ),
                            backgroundColor: Colors.blue,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  // Test 2: Manual refresh dialog
                  _DebugButton(
                    label: '2. Test Refresh Dialog',
                    subtitle: 'Expires both tokens',
                    icon: Icons.sync_problem,
                    color: Colors.deepOrange,
                    onPressed: () async {
                      await widget.api.debugSimulateBothTokensExpired();
                      await _refreshStatus();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '🧪 Both tokens expired. Next API call will show dialog!',
                            ),
                            backgroundColor: Colors.deepOrange,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  // Test 3: Immediate dialog
                  _DebugButton(
                    label: '3. Show Dialog Now',
                    subtitle: 'Trigger dialog immediately',
                    icon: Icons.announcement,
                    color: Colors.red,
                    onPressed: () async {
                      await widget.api.debugTriggerAuthFailureDialog();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Refresh status button
                  OutlinedButton.icon(
                    onPressed: _refreshStatus,
                    icon: const Icon(Icons.update, size: 16),
                    label: const Text('Refresh Status'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'After clicking a test button, make any API call '
                      '(like navigating screens, loading data, etc.) '
                      'to trigger the behavior.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _DebugButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

