import 'dart:async';
import 'dart:io';
import 'package:ecom_frontend/models/conversation.dart';
import 'package:ecom_frontend/models/message.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/services/chat_service.dart';
import 'package:ecom_frontend/services/socket_service.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ecom_frontend/screens/product/product_detail_screen.dart';
import 'package:ecom_frontend/services/product_service.dart';
import 'package:ecom_frontend/models/product.dart' as product_model;
import 'package:ecom_frontend/l10n/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isLoading = true;
  String? _error;
  Conversation? _conversation;
  List<Message> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  File? _selectedImage;
  bool _isUploadingImage = false;
  DateTime? _lastMessageTime;
  Timer? _pollingTimer;
  SocketService? _socketService;
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _conversationUpdateSubscription;

  final DateFormat _timeFormatter = DateFormat('HH:mm');
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupSocket();
    // Polling như backup (interval dài hơn)
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _conversationUpdateSubscription?.cancel();
    _socketService?.leaveConversation(widget.conversationId);
    _socketService?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _setupSocket() {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.accessToken;

    if (token != null && token.isNotEmpty) {
      print('🔌 Setting up socket with token: ${token.substring(0, 20)}...');
      _socketService = SocketService();
      _socketService!.connect(token);
      // Join conversation ngay, socket sẽ tự động join khi connected
      _socketService!.joinConversation(widget.conversationId);

      // Listen for real-time messages
      _messageSubscription = _socketService!.messageStream.listen((message) {
        print('📨 Received message via socket: ${message.id}');
        if (mounted) {
          setState(() {
            // Chỉ thêm nếu message chưa có trong list (tránh duplicate)
            if (!_messages.any((m) => m.id == message.id)) {
              _messages.add(message);
              _lastMessageTime = DateTime.now();
              // Sort messages theo thời gian
              _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            }
          });
          _scrollToBottom();
        }
      });

      // Listen for conversation updates
      _conversationUpdateSubscription = _socketService!.conversationUpdateStream
          .listen((data) {
            if (mounted && _conversation != null) {
              setState(() {
                if (data['last_message'] != null) {
                  _conversation = Conversation(
                    id: _conversation!.id,
                    buyerId: _conversation!.buyerId,
                    sellerId: _conversation!.sellerId,
                    storeId: _conversation!.storeId,
                    storeName: _conversation!.storeName,
                    otherUser: _conversation!.otherUser,
                    product: _conversation!.product,
                    lastMessage: data['last_message'],
                    lastMessageAt: data['last_message_at'] != null
                        ? DateTime.parse(data['last_message_at'])
                        : _conversation!.lastMessageAt,
                    unreadCount: _conversation!.unreadCount,
                    createdAt: _conversation!.createdAt,
                    updatedAt: _conversation!.updatedAt,
                  );
                }
              });
            }
          });
    }
  }

  void _startAutoRefresh() {
    _pollingTimer?.cancel();
    // Polling như backup với interval ngắn hơn (10 giây) để nhận tin nhắn nhanh hơn
    // Chỉ dùng để sync nếu socket bị disconnect
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_isLoading && _error == null) {
        // Chỉ poll nếu socket không connected
        if (_socketService == null || !_socketService!.isConnected) {
          print('🔄 Polling messages (socket disconnected)');
          _loadMessages(silent: true);
        }
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final chatService = context.read<ChatService>();

      // Load conversation và messages song song
      final results = await Future.wait([
        chatService.getConversation(widget.conversationId),
        chatService.getMessages(widget.conversationId),
      ]);

      if (mounted) {
        final messages = results[1] as List<Message>;
        setState(() {
          _conversation = results[0] as Conversation;
          _messages = messages;
          _isLoading = false;
          // Cập nhật thời gian tin nhắn mới nhất
          if (messages.isNotEmpty) {
            _lastMessageTime = messages.last.createdAt;
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      final chatService = context.read<ChatService>();
      final messages = await chatService.getMessages(widget.conversationId);

      if (mounted) {
        final hadNewMessages =
            messages.length != _messages.length ||
            (messages.isNotEmpty &&
                _messages.isNotEmpty &&
                messages.last.id != _messages.last.id);

        setState(() {
          _messages = messages;
          // Cập nhật thời gian tin nhắn mới nhất nếu có tin nhắn mới
          if (hadNewMessages && messages.isNotEmpty) {
            _lastMessageTime = messages.last.createdAt;
          }
        });

        // Chỉ scroll nếu có tin nhắn mới
        if (hadNewMessages) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      // Silent error handling
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: ${e.toString()}'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  String? _selectedProductId;

  Future<void> _showProductPicker(BuildContext context) async {
    if (_conversation == null) return;

    try {
      final productService = context.read<ProductService>();
      final products = await productService.getProducts(
        storeId: _conversation!.storeId,
      );

      if (!mounted) return;

      final selectedProduct = await showDialog<product_model.Product>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Chọn sản phẩm để gửi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Flexible(
                  child: products.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Không có sản phẩm nào'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    product.imageUrl != null &&
                                        product.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        product.imageUrl!,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                width: 50,
                                                height: 50,
                                                color: kOffWhiteColor,
                                                child: const Icon(Icons.image),
                                              );
                                            },
                                      )
                                    : Container(
                                        width: 50,
                                        height: 50,
                                        color: kOffWhiteColor,
                                        child: const Icon(Icons.image),
                                      ),
                              ),
                              title: Text(
                                product.title,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${NumberFormat('#,###').format(product.finalPrice ?? product.price)}đ',
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: () => Navigator.pop(context, product),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );

      if (selectedProduct != null && mounted) {
        _selectedProductId = selectedProduct.id;
        await _sendMessage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final hasImage = _selectedImage != null;
    final hasProduct = _selectedProductId != null;

    if (text.isEmpty && !hasImage && !hasProduct) return;
    if (_isSending || _isUploadingImage) return;

    setState(() {
      _isSending = true;
    });

    try {
      final chatService = context.read<ChatService>();
      String? imageUrl;

      // Upload ảnh nếu có
      if (_selectedImage != null) {
        setState(() {
          _isUploadingImage = true;
        });
        try {
          imageUrl = await chatService.uploadImage(_selectedImage!);
        } catch (e) {
          if (mounted) {
            setState(() {
              _isSending = false;
              _isUploadingImage = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Lỗi upload ảnh: ${e.toString().replaceAll('Exception: ', '')}',
                ),
                backgroundColor: kErrorColor,
              ),
            );
          }
          return;
        } finally {
          setState(() {
            _isUploadingImage = false;
          });
        }
      }

      // Gửi message
      final newMessage = await chatService.sendMessage(
        conversationId: widget.conversationId,
        message: text.isEmpty ? (hasImage ? '' : (hasProduct ? '' : '')) : text,
        messageType: hasImage ? 'image' : (hasProduct ? 'product' : 'text'),
        imageUrl: imageUrl,
        productId: _selectedProductId,
      );

      if (mounted) {
        _messageController.clear();
        setState(() {
          // Chỉ thêm vào list nếu socket không connected (fallback)
          // Nếu socket connected, message sẽ được emit từ server và thêm qua socket stream
          if (_socketService == null || !_socketService!.isConnected) {
            if (!_messages.any((m) => m.id == newMessage.id)) {
              _messages.add(newMessage);
              _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            }
          }
          _isSending = false;
          _selectedImage = null;
          _selectedProductId = null;
          _lastMessageTime = DateTime.now();
        });
        _scrollToBottom();
        // Reload conversation để cập nhật last_message (nếu socket không connected)
        if (_socketService == null || !_socketService!.isConnected) {
          _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatMessageTime(DateTime dateTime) {
    // Chuyển đổi UTC sang local time nếu cần
    final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final now = DateTime.now();
    final difference = now.difference(localDateTime);

    if (difference.inDays == 0) {
      return _timeFormatter.format(localDateTime);
    } else if (difference.inDays == 1) {
      return 'Hôm qua ${_timeFormatter.format(localDateTime)}';
    } else {
      return '${_dateFormatter.format(localDateTime)} ${_timeFormatter.format(localDateTime)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: _conversation != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _conversation!.otherUser.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _conversation!.storeName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              )
            : const Text('Chat'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
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
                    onPressed: _loadData,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Messages list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadMessages,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(kDefaultPadding),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message.senderId == currentUserId;

                        // Lấy tin nhắn trước và sau để xác định vị trí trong group
                        final prevMessage = index > 0
                            ? _messages[index - 1]
                            : null;
                        final nextMessage = index < _messages.length - 1
                            ? _messages[index + 1]
                            : null;

                        // Xác định vị trí trong group
                        final isFirstInGroup =
                            prevMessage == null ||
                            prevMessage.senderId != message.senderId ||
                            message.createdAt
                                    .difference(prevMessage.createdAt)
                                    .inMinutes >
                                5;

                        final isLastInGroup =
                            nextMessage == null ||
                            nextMessage.senderId != message.senderId ||
                            nextMessage.createdAt
                                    .difference(message.createdAt)
                                    .inMinutes >
                                5;

                        final isMiddleInGroup =
                            !isFirstInGroup && !isLastInGroup;

                        // Chỉ hiển thị tên cho tin nhắn đầu tiên trong group (và không phải của mình)
                        final showSenderName = isFirstInGroup && !isMe;

                        // Chỉ hiển thị timestamp cho tin nhắn cuối cùng trong group
                        final showTimestamp = isLastInGroup;

                        return _buildMessageBubble(
                          message,
                          isMe,
                          showTimestamp,
                          showSenderName: showSenderName,
                          isFirstInGroup: isFirstInGroup,
                          isLastInGroup: isLastInGroup,
                          isMiddleInGroup: isMiddleInGroup,
                        );
                      },
                    ),
                  ),
                ),

                // Selected image preview
                if (_selectedImage != null)
                  Container(
                    padding: const EdgeInsets.all(kDefaultPadding),
                    color: kOffWhiteColor,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ảnh đã chọn',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kSecondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedImage!.path.split('/').last,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: kErrorColor),
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                // Input area
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Image picker button
                        IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(
                            Icons.image_outlined,
                            color: kPrimaryColor,
                          ),
                        ),
                        // Product picker button (chỉ hiển thị cho seller)
                        if (authProvider.currentUser?.role == 'SELLER' &&
                            _conversation != null)
                          IconButton(
                            onPressed: () => _showProductPicker(context),
                            icon: const Icon(
                              Icons.shopping_bag_outlined,
                              color: kPrimaryColor,
                            ),
                            tooltip: 'Gửi sản phẩm',
                          ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: _selectedImage != null
                                  ? 'Add description (optional)...'
                                  : AppLocalizations.of(context)!.typeMessage,
                              hintStyle: const TextStyle(
                                color: kSecondaryTextColor,
                              ),
                              filled: true,
                              fillColor: kOffWhiteColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: (_isSending || _isUploadingImage)
                                ? Colors.grey
                                : kPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: (_isSending || _isUploadingImage)
                                ? null
                                : _sendMessage,
                            icon: _isUploadingImage
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : _isSending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(
    Message message,
    bool isMe,
    bool showTime, {
    bool showSenderName = false,
    bool isFirstInGroup = true,
    bool isLastInGroup = true,
    bool isMiddleInGroup = false,
  }) {
    final hasImage = message.imageUrl != null && message.imageUrl!.isNotEmpty;
    final hasProduct = message.isProduct && message.product != null;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        // Giảm margin cho tin nhắn giữa trong group
        margin: EdgeInsets.only(
          bottom: isMiddleInGroup ? 2 : 8,
          top: isFirstInGroup ? 0 : 2,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Chỉ hiển thị tên người gửi cho tin nhắn đầu tiên
            if (showSenderName)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  message.senderName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kSecondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Container(
              padding: (hasImage || hasProduct) && message.message.isEmpty
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? kPrimaryColor : Colors.grey.shade100,
                // Border radius thông minh dựa trên vị trí trong group
                borderRadius: _getBorderRadius(
                  isMe: isMe,
                  isFirstInGroup: isFirstInGroup,
                  isLastInGroup: isLastInGroup,
                  isMiddleInGroup: isMiddleInGroup,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hiển thị sản phẩm
                  if (hasProduct && message.product != null)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              productId: message.product!.id,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 250,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isMe
                                ? Colors.white.withOpacity(0.3)
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                              child: Image.network(
                                message.product!.imageUrl ?? '',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: kOffWhiteColor,
                                    child: const Icon(Icons.image, size: 30),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      message.product!.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isMe ? kTextColor : kTextColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (message.product!.price != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${NumberFormat('#,###').format(message.product!.price)}đ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isMe
                                              ? kPrimaryColor
                                              : kPrimaryColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: Stack(
                                children: [
                                  Center(
                                    child: Image.network(
                                      message.imageUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.image_not_supported,
                                              size: 100,
                                              color: Colors.white,
                                            );
                                          },
                                    ),
                                  ),
                                  Positioned(
                                    top: 40,
                                    right: 20,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Image.network(
                          message.imageUrl!,
                          width: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 200,
                              height: 150,
                              color: kOffWhiteColor,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 150,
                              color: kOffWhiteColor,
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                    ),
                  if (message.message.isNotEmpty &&
                      message.message != '📷' &&
                      message.message != '[Sản phẩm]') ...[
                    if (hasImage || hasProduct) const SizedBox(height: 8),
                    Text(
                      message.message,
                      style: TextStyle(
                        color: isMe ? Colors.white : kTextColor,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Chỉ hiển thị timestamp cho tin nhắn cuối cùng
            if (showTime)
              Padding(
                padding: EdgeInsets.only(
                  top: 4,
                  left: isMe ? 0 : 4,
                  right: isMe ? 4 : 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: isMe
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Text(
                      _formatMessageTime(message.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: kSecondaryTextColor,
                      ),
                    ),
                    // Read receipt chỉ hiển thị cho tin nhắn cuối cùng
                    if (isMe && message.isRead) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all,
                        size: 14,
                        color: Colors.blue.shade300,
                      ),
                    ] else if (isMe && !message.isRead) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.done, size: 14, color: Colors.grey.shade400),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper function để tính border radius
  BorderRadius _getBorderRadius({
    required bool isMe,
    required bool isFirstInGroup,
    required bool isLastInGroup,
    required bool isMiddleInGroup,
  }) {
    if (isMiddleInGroup) {
      // Tin nhắn giữa: chỉ bo góc trên
      return BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      );
    } else if (isFirstInGroup && isLastInGroup) {
      // Chỉ có 1 tin nhắn: bo góc đầy đủ
      return BorderRadius.circular(16);
    } else if (isFirstInGroup) {
      // Tin nhắn đầu: bo góc trên và góc dưới bên kia
      return BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: Radius.circular(isMe ? 4 : 16),
        bottomRight: Radius.circular(isMe ? 16 : 4),
      );
    } else if (isLastInGroup) {
      // Tin nhắn cuối: bo góc dưới và góc trên bên kia
      return BorderRadius.only(
        topLeft: Radius.circular(isMe ? 16 : 4),
        topRight: Radius.circular(isMe ? 4 : 16),
        bottomLeft: const Radius.circular(16),
        bottomRight: const Radius.circular(16),
      );
    } else {
      // Fallback
      return BorderRadius.circular(16);
    }
  }
}
