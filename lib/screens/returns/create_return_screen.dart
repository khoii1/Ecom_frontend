import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ecom_frontend/models/order.dart';
import 'package:ecom_frontend/services/return_service.dart';
import 'package:ecom_frontend/utils/constants.dart';

class CreateReturnScreen extends StatefulWidget {
  final Order order;

  const CreateReturnScreen({super.key, required this.order});

  @override
  State<CreateReturnScreen> createState() => _CreateReturnScreenState();
}

class _CreateReturnScreenState extends State<CreateReturnScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _returnType = 'refund';
  final Map<String, Map<String, dynamic>> _selectedItems = {};
  bool _isSubmitting = false;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Pre-select all items
    if (widget.order.items != null) {
      for (var item in widget.order.items!) {
        _selectedItems[item.id] = {
          'item': item,
          'qty': item.qty,
          'reason': '',
        };
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReturn() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một sản phẩm để trả hàng')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final returnService = context.read<ReturnService>();
      
      final items = _selectedItems.entries.map((entry) {
        final data = entry.value;
        final item = data['item'] as OrderItem;
        return {
          'order_item_id': item.id,
          'product_id': item.productId,
          'qty': data['qty'] as int,
          if ((data['reason'] as String).isNotEmpty) 'reason': data['reason'],
        };
      }).toList();

      await returnService.createReturn(
        orderId: widget.order.id,
        returnType: _returnType,
        reason: _reasonController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        items: items,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yêu cầu trả hàng đã được gửi thành công'),
            backgroundColor: kSuccessColor,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Yêu cầu trả hàng'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kTextColor,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(kDefaultPadding),
          children: [
            // Order Info Card
            Container(
              padding: const EdgeInsets.all(kDefaultPadding),
              decoration: kCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: kPrimaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Đơn hàng ${widget.order.code}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tổng tiền: ${_currencyFormatter.format(widget.order.total)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: kSecondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: kDefaultPadding),

            // Return Type
            Container(
              padding: const EdgeInsets.all(kDefaultPadding),
              decoration: kCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Loại yêu cầu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    value: 'refund',
                    groupValue: _returnType,
                    onChanged: (value) => setState(() => _returnType = value!),
                    title: const Text('Hoàn tiền'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: kPrimaryColor,
                  ),
                  RadioListTile<String>(
                    value: 'exchange',
                    groupValue: _returnType,
                    onChanged: (value) => setState(() => _returnType = value!),
                    title: const Text('Đổi hàng'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: kPrimaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: kDefaultPadding),

            // Selected Items
            Container(
              padding: const EdgeInsets.all(kDefaultPadding),
              decoration: kCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sản phẩm trả hàng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.order.items?.map((item) {
                    final itemData = _selectedItems[item.id];
                    if (itemData == null) return const SizedBox.shrink();
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kOffWhiteColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (item.productImageUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.productImageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: kLightTextColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.image, color: kLightTextColor),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productTitle,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: kTextColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_currencyFormatter.format(item.unitPrice)} x ${item.qty}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: kSecondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                'Số lượng trả: ',
                                style: TextStyle(fontSize: 12, color: kSecondaryTextColor),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${itemData['qty']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: kPrimaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: TextEditingController(text: itemData['reason'] as String),
                            onChanged: (value) {
                              _selectedItems[item.id]!['reason'] = value;
                            },
                            decoration: InputDecoration(
                              hintText: 'Lý do trả hàng (tùy chọn)',
                              hintStyle: const TextStyle(fontSize: 12),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            maxLines: 2,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }).toList() ?? [],
                ],
              ),
            ),

            const SizedBox(height: kDefaultPadding),

            // Reason
            Container(
              padding: const EdgeInsets.all(kDefaultPadding),
              decoration: kCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lý do trả hàng *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reasonController,
                    decoration: kInputDecoration('Nhập lý do trả hàng', prefixIcon: Icons.info_outline),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập lý do trả hàng';
                      }
                      if (value.trim().length < 5) {
                        return 'Lý do phải có ít nhất 5 ký tự';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: kDefaultPadding),

            // Description
            Container(
              padding: const EdgeInsets.all(kDefaultPadding),
              decoration: kCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mô tả chi tiết (tùy chọn)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: kInputDecoration('Mô tả thêm về tình trạng sản phẩm...', prefixIcon: Icons.description),
                    maxLines: 4,
                  ),
                ],
              ),
            ),

            const SizedBox(height: kDefaultPadding * 2),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReturn,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Gửi yêu cầu trả hàng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),

            const SizedBox(height: kDefaultPadding),
          ],
        ),
      ),
    );
  }
}

