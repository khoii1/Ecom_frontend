import 'package:flutter/material.dart';
import 'package:ecom_frontend/utils/constants.dart';

// Model cho tin nhắn chat
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// Chatbot Button - Nút nổi để mở chatbot
class ChatbotFloatingButton extends StatelessWidget {
  const ChatbotFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const ChatbotSheet(),
        );
      },
      backgroundColor: kPrimaryColor,
      child: const Icon(Icons.chat, color: Colors.white),
    );
  }
}

// Chatbot Sheet - Bottom sheet chứa giao diện chat
class ChatbotSheet extends StatefulWidget {
  const ChatbotSheet({super.key});

  @override
  State<ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends State<ChatbotSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // Các câu hỏi thường gặp
  final List<Map<String, String>> _quickQuestions = [
    {'q': 'Làm sao để đặt hàng?', 'a': 'Để đặt hàng, bạn hãy:\n1. Chọn sản phẩm bạn muốn mua\n2. Nhấn "Thêm vào giỏ hàng"\n3. Vào giỏ hàng và nhấn "Thanh toán"\n4. Điền thông tin giao hàng\n5. Chọn phương thức thanh toán và hoàn tất đơn hàng'},
    {'q': 'Phương thức thanh toán?', 'a': 'Chúng tôi hỗ trợ các phương thức thanh toán:\n• Thanh toán qua VNPay (ATM, Visa, Mastercard)\n• Thanh toán khi nhận hàng (COD)\n• Chuyển khoản ngân hàng'},
    {'q': 'Chính sách đổi trả?', 'a': 'Chính sách đổi trả của chúng tôi:\n• Đổi trả trong vòng 7 ngày kể từ ngày nhận hàng\n• Sản phẩm còn nguyên tem, nhãn mác\n• Không áp dụng cho sản phẩm đã qua sử dụng\n• Miễn phí đổi trả nếu lỗi từ nhà sản xuất'},
    {'q': 'Thời gian giao hàng?', 'a': 'Thời gian giao hàng dự kiến:\n• Nội thành: 1-2 ngày làm việc\n• Ngoại thành: 2-3 ngày làm việc\n• Tỉnh khác: 3-5 ngày làm việc\n\nBạn có thể theo dõi đơn hàng trong mục "Đơn hàng của tôi"'},
    {'q': 'Liên hệ hỗ trợ', 'a': 'Bạn có thể liên hệ với chúng tôi qua:\n• Email: support@ecommerce.vn\n• Hotline: 1900 1234\n• Fanpage: facebook.com/ecommerce\n\nThời gian làm việc: 8h-22h hàng ngày'},
  ];

  @override
  void initState() {
    super.initState();
    // Tin nhắn chào mừng
    _messages.add(ChatMessage(
      text: 'Xin chào! 👋 Tôi là trợ lý ảo của cửa hàng. Tôi có thể giúp gì cho bạn?',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Xử lý phản hồi từ bot
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      
      final response = _getBotResponse(text);
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  String _getBotResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    // Kiểm tra các từ khóa phổ biến
    if (lowerMessage.contains('đặt hàng') || lowerMessage.contains('mua hàng') || lowerMessage.contains('order')) {
      return _quickQuestions[0]['a']!;
    }
    if (lowerMessage.contains('thanh toán') || lowerMessage.contains('trả tiền') || lowerMessage.contains('payment')) {
      return _quickQuestions[1]['a']!;
    }
    if (lowerMessage.contains('đổi') || lowerMessage.contains('trả') || lowerMessage.contains('hoàn')) {
      return _quickQuestions[2]['a']!;
    }
    if (lowerMessage.contains('giao hàng') || lowerMessage.contains('ship') || lowerMessage.contains('delivery')) {
      return _quickQuestions[3]['a']!;
    }
    if (lowerMessage.contains('liên hệ') || lowerMessage.contains('hỗ trợ') || lowerMessage.contains('contact')) {
      return _quickQuestions[4]['a']!;
    }
    if (lowerMessage.contains('xin chào') || lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return 'Xin chào! Rất vui được hỗ trợ bạn. Bạn cần giúp đỡ gì ạ?';
    }
    if (lowerMessage.contains('cảm ơn') || lowerMessage.contains('thank')) {
      return 'Không có gì ạ! Nếu cần hỗ trợ thêm, đừng ngần ngại hỏi nhé! 😊';
    }
    if (lowerMessage.contains('giá') || lowerMessage.contains('bao nhiêu')) {
      return 'Bạn có thể xem giá sản phẩm trực tiếp trên trang chi tiết sản phẩm. Nếu cần tư vấn sản phẩm cụ thể, hãy cho tôi biết tên sản phẩm nhé!';
    }
    if (lowerMessage.contains('khuyến mãi') || lowerMessage.contains('giảm giá') || lowerMessage.contains('voucher')) {
      return 'Bạn có thể xem các mã giảm giá hiện có trong giỏ hàng khi thanh toán. Nhập mã vào ô "Mã giảm giá" để được giảm giá nhé!';
    }

    // Phản hồi mặc định
    return 'Cảm ơn bạn đã liên hệ! Tôi chưa hiểu rõ câu hỏi của bạn. Bạn có thể:\n\n• Chọn một câu hỏi bên dưới\n• Liên hệ hotline: 1900 1234\n• Email: support@ecommerce.vn';
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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trợ lý ảo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Trực tuyến',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Quick questions
          if (_messages.length < 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Câu hỏi thường gặp:',
                    style: TextStyle(
                      fontSize: 12,
                      color: kSecondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickQuestions.map((q) {
                      return GestureDetector(
                        onTap: () => _sendMessage(q['q']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            q['q']!,
                            style: const TextStyle(
                              color: kPrimaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + bottomPadding,
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      hintStyle: const TextStyle(color: kSecondaryTextColor),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => _sendMessage(_messageController.text),
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? kPrimaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : kTextColor,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (index * 100)),
              builder: (context, value, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: kSecondaryTextColor.withOpacity(0.5 + (value * 0.5)),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

