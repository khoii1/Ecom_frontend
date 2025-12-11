import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:ecom_frontend/models/message.dart';
import 'package:ecom_frontend/utils/app_config.dart';
import 'dart:async';

class SocketService {
  IO.Socket? _socket;
  String? _currentConversationId;
  String? _pendingConversationId; // Thêm để lưu conversationId chờ join
  
  final StreamController<Message> _messageController = StreamController<Message>.broadcast();
  final StreamController<Map<String, dynamic>> _readController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _conversationUpdateController = 
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Message> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get readStream => _readController.stream;
  Stream<Map<String, dynamic>> get conversationUpdateStream => _conversationUpdateController.stream;

  bool get isConnected => _socket != null && _socket!.connected;

  void connect(String token) {
    if (_socket != null && _socket!.connected) {
      disconnect();
    }
    
    // Socket.io tự động xử lý URL, không cần convert
    String serverUrl = AppConfig.baseUrl;

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .setQuery({'token': token}) // Thêm vào query string
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) {
      // Nếu có conversationId đang chờ, join ngay
      if (_pendingConversationId != null) {
        joinConversation(_pendingConversationId!);
        _pendingConversationId = null;
      }
    });

    _socket!.onDisconnect((_) {
      // Socket disconnected
    });

    _socket!.onError((error) {
      // Socket error occurred
    });

    _socket!.onConnectError((error) {
      // Socket connection error occurred
    });

    // Listen for new messages
    _socket!.on('new_message', (data) {
      try {
        if (data is Map<String, dynamic>) {
          final message = Message.fromJson(data);
          _messageController.add(message);
        }
      } catch (e, stackTrace) {
        // Error parsing message
      }
    });

    // Listen for read receipts
    _socket!.on('message_read', (data) {
      try {
        if (data is Map<String, dynamic>) {
          _readController.add(data);
        }
      } catch (e) {
        // Error parsing read receipt
      }
    });

    // Listen for conversation updates
    _socket!.on('conversation_update', (data) {
      try {
        if (data is Map<String, dynamic>) {
          _conversationUpdateController.add(data);
        }
      } catch (e) {
        // Error parsing conversation update
      }
    });
  }

  void joinConversation(String conversationId) {
    if (_socket != null && _socket!.connected) {
      _currentConversationId = conversationId;
      _socket!.emit('join_conversation', conversationId);
    } else {
      _pendingConversationId = conversationId; // Lưu lại để join sau khi connect
    }
  }

  void leaveConversation(String conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave_conversation', conversationId);
      if (_currentConversationId == conversationId) {
        _currentConversationId = null;
      }
    }
  }

  void disconnect() {
    if (_currentConversationId != null) {
      leaveConversation(_currentConversationId!);
    }
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _pendingConversationId = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _readController.close();
    _conversationUpdateController.close();
  }
}

