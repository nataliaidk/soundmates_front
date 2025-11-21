import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'dart:async';

import 'token_store.dart';

class EventHubService {
  HubConnection? _connection;
  final TokenStore tokenStore;
  
  // Callbacks for events
  Function(dynamic)? onMessageReceived;
  Function(dynamic)? onMatchReceived;
  Function(dynamic)? onMatchCreated;

  EventHubService({required this.tokenStore});

  String? get connectionId => _connection?.connectionId;
  HubConnection? get connection => _connection;

  Future<void> connect() async {
    await disconnect(); // Ensure any existing connection is closed

    final accessToken = await tokenStore.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      print("EventHubService: No access token found. Cannot connect.");
      return;
    }

    // Add this line to debug the token
    print("EventHubService: Attempting to connect with token: $accessToken");

    final baseUrl = dotenv.get('API_BASE_URL', fallback: 'http://localhost:5000');
    final hubUrl = "${baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl}/eventHub";

    _connection = HubConnectionBuilder()
        .withUrl(
      hubUrl,
      options: HttpConnectionOptions(
        accessTokenFactory: () async => accessToken,
      ),
    )
        .withAutomaticReconnect()
        .build();

    _connection!.onclose(({error}) {
      print("SignalR connection closed. Error: ${error?.toString() ?? 'No error info'}");
    });

    _setupListeners();

    try {
      await _connection!.start();
      print("SignalR connected successfully. ConnectionId: ${_connection?.connectionId}");
    } catch (e) {
      print("SignalR connection failed to start: $e");
    }
  }

  void _setupListeners() {
    if (_connection == null) return;
    
    // When a message comes from someone
    _connection!.on("MessageReceived", (args) {
      print("📩 MessageReceived: $args");
      if (onMessageReceived != null && args != null && args.isNotEmpty) {
        onMessageReceived!(args[0]);
      }
    });

    // When user gets matched by someone else
    _connection!.on("MatchReceived", (args) {
      print("❤️ MatchReceived: $args");
      print("❤️ onMatchReceived callback: ${onMatchReceived != null ? 'SET' : 'NULL'}");
      if (onMatchReceived != null && args != null && args.isNotEmpty) {
        print("❤️ Invoking onMatchReceived callback with: ${args[0]}");
        onMatchReceived!(args[0]);
      } else {
        print("⚠️ Cannot invoke callback - onMatchReceived is null or args empty");
      }
    });

    // When both users match each other
    _connection!.on("MatchCreated", (args) {
      print("🔥 MatchCreated: $args");
      print("🔥 onMatchCreated callback: ${onMatchCreated != null ? 'SET' : 'NULL'}");
      if (onMatchCreated != null && args != null && args.isNotEmpty) {
        print("🔥 Invoking onMatchCreated callback with: ${args[0]}");
        onMatchCreated!(args[0]);
      } else {
        print("⚠️ Cannot invoke callback - onMatchCreated is null or args empty");
      }
    });
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      if (_connection!.state == HubConnectionState.Connected) {
        await _connection!.stop();
        print("SignalR disconnected");
      }
      _connection = null;
    }
  }
}
