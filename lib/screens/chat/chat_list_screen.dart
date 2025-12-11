import 'dart:async';
import 'package:ecom_frontend/models/conversation.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/services/chat_service.dart';
import 'package:ecom_frontend/services/socket_service.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ecom_frontend/screens/chat/chat_screen.dart';
import 'package:ecom_frontend/l10n/app_localizations.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isLoading = true;
  String? _error;
  List<Conversation> _conversations = [];
  Timer? _pollingTimer;
  SocketService? _socketService;
  StreamSubscription<Map<String, dynamic>>? _conversationUpdateSubscription;

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormatter = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _setupSocket();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _conversationUpdateSubscription?.cancel();
    _socketService?.dispose();
    super.dispose();
  }

  void _setupSocket() {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.accessToken;

    if (token != null && token.isNotEmpty) {
      print('🔌 Setting up socket for chat list');
      _socketService = SocketService();
      _socketService!.connect(token);

      // Listen for conversation updates từ tất cả conversations
          _conversationUpdateSubscription = _socketService!.conversationUpdateStream
          .listen((data) {
            if (mounted) {
              _updateConversationFromSocket(data);
            }
          });
    }
  }

  void _updateConversationFromSocket(Map<String, dynamic> data) {
    final conversationId = data['id']?.toString();
    if (conversationId == null) return;

    setState(() {
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        // Cập nhật conversation hiện có
        final existing = _conversations[index];
        final authProvider = context.read<AuthProvider>();
        final userRole = authProvider.currentUser?.role;
        final isSeller = userRole == 'SELLER';

        // Xác định unread count dựa trên role
        final unreadCount = isSeller
            ? (data['seller_unread_count'] ?? existing.unreadCount)
            : (data['buyer_unread_count'] ?? existing.unreadCount);

        _conversations[index] = Conversation(
          id: existing.id,
          buyerId: existing.buyerId,
          sellerId: existing.sellerId,
          storeId: existing.storeId,
          storeName: existing.storeName,
          otherUser: existing.otherUser,
          product: existing.product,
          lastMessage: data['last_message'] ?? existing.lastMessage,
          lastMessageAt: data['last_message_at'] != null
              ? DateTime.parse(data['last_message_at'])
              : existing.lastMessageAt,
          unreadCount: unreadCount,
          createdAt: existing.createdAt,
          updatedAt: existing.updatedAt,
        );

        // Sắp xếp lại theo last_message_at (tin nhắn mới nhất lên đầu)
        _conversations.sort((a, b) {
          final aTime =
              a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime =
              b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

      } else {
        // Nếu conversation chưa có trong list, reload toàn bộ
        _loadConversations(silent: true);
      }
    });
  }

  void _startAutoRefresh() {
    _pollingTimer?.cancel();
    // Polling như backup với interval ngắn hơn (5 giây) để nhận cập nhật nhanh hơn
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isLoading && _error == null) {
        // Chỉ poll nếu socket không connected
        if (_socketService == null || !_socketService!.isConnected) {
          print('🔄 Auto refreshing conversations (socket disconnected)');
          _loadConversations(silent: true);
        }
      }
    });
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final chatService = context.read<ChatService>();
      final conversations = await chatService.getConversations();

      if (mounted) {
        setState(() {
          _conversations = conversations;
          if (!silent) {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatLastMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    // Chuyển đổi UTC sang local time nếu cần
    final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final now = DateTime.now();
    final difference = now.difference(localDateTime);

    if (difference.inDays == 0) {
      return _timeFormatter.format(localDateTime);
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return _dateFormatter.format(localDateTime);
    } else {
      return _dateFormatter.format(localDateTime);
    }
  }

  Future<void> _performDeleteConversation(String conversationId) async {
    if (!mounted) return;

    try {
      final chatService = context.read<ChatService>();
      await chatService.deleteConversation(conversationId);

      // Reload danh sách conversations
      await _loadConversations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa cuộc trò chuyện'),
            backgroundColor: kSuccessColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cuộc trò chuyện'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa cuộc trò chuyện này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performDeleteConversation(conversation.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userRole = authProvider.currentUser?.role;
    final isSeller = userRole == 'SELLER';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSeller
              ? AppLocalizations.of(context)!.messagesFromCustomers
              : AppLocalizations.of(context)!.conversations,
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: kErrorColor),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: kErrorColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadConversations,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : _conversations.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadConversations,
              child: ListView.builder(
                padding: const EdgeInsets.all(kDefaultPadding),
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final conversation = _conversations[index];
                  return Dismissible(
                    key: ValueKey(conversation.id),
                    direction:
                        DismissDirection.endToStart, // Swipe từ phải sang trái
                    confirmDismiss: (direction) async {
                      // Hiển thị dialog xác nhận trước khi xóa
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xóa cuộc trò chuyện'),
                          content: const Text(
                            'Bạn có chắc chắn muốn xóa cuộc trò chuyện này? Hành động này không thể hoàn tác.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kErrorColor,
                              ),
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                      );
                      return confirmed ?? false;
                    },
                    onDismissed: (direction) async {
                      // Xóa conversation sau khi đã xác nhận
                      await _performDeleteConversation(conversation.id);
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      margin: const EdgeInsets.only(bottom: kDefaultPadding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kErrorColor.withOpacity(0.8), kErrorColor],
                        ),
                        borderRadius: BorderRadius.circular(kBorderRadius),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Xóa',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    child: _buildConversationCard(conversation),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: kSecondaryTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noConversations,
            style: TextStyle(fontSize: 16, color: kSecondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(Conversation conversation) {
    return Container(
      margin: const EdgeInsets.only(bottom: kDefaultPadding),
      decoration: kCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(conversationId: conversation.id),
              ),
            ).then((_) => _loadConversations()); // Refresh khi quay lại
          },
          borderRadius: BorderRadius.circular(kBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: kPrimaryColor, size: 28),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.otherUser.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: kTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conversation.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conversation.storeName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: kSecondaryTextColor,
                        ),
                      ),
                      if (conversation.lastMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          conversation.lastMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            color: conversation.unreadCount > 0
                                ? kTextColor
                                : kSecondaryTextColor,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatLastMessageTime(conversation.lastMessageAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: conversation.unreadCount > 0
                            ? kPrimaryColor
                            : kSecondaryTextColor,
                        fontWeight: conversation.unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (conversation.product != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          conversation.product!.imageUrl ?? '',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 40,
                              height: 40,
                              color: kOffWhiteColor,
                              child: const Icon(Icons.image, size: 20),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
