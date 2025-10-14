import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';

class MessagesScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  const MessagesScreen({super.key, required this.api, required this.tokens});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _out = '';
  Future<void> _preview() async {
    final resp = await widget.api.getMessagePreviews();
    setState(() => _out = 'Status: ${resp.statusCode}\n${resp.body}');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Messages')), body: Padding(padding: const EdgeInsets.all(12), child: Column(children: [ElevatedButton(onPressed: _preview, child: const Text('Preview')), const SizedBox(height: 12), Expanded(child: SingleChildScrollView(child: SelectableText(_out)))])));
  }
}
