import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ecom_frontend/models/return.dart';
import 'package:ecom_frontend/services/return_service.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/utils/constants.dart';

class ReturnDetailScreen extends StatefulWidget {
  final String returnId;

  const ReturnDetailScreen({super.key, required this.returnId});

  @override
  State<ReturnDetailScreen> createState() => _ReturnDetailScreenState();
}

class _ReturnDetailScreenState extends State<ReturnDetailScreen> {
  Return? _return;
  bool _isLoading = true;
  String? _errorMessage;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadReturnDetail();
  }

  Future<void> _loadReturnDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final returnService = context.read<ReturnService>();
      final returnData = await returnService.getReturnDetail(widget.returnId);
      if (mounted) {
        setState(() {
          _return = returnData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelReturn() async {
    if (_return == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text('Bạn có chắc chắn muốn hủy yêu cầu trả hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Có', style: TextStyle(color: kErrorColor)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final returnService = context.read<ReturnService>();
      await returnService.cancelReturn(widget.returnId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy yêu cầu trả hàng'),
            backgroundColor: kSuccessColor,
          ),
        );
        _loadReturnDetail();
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

  Future<void> _approveReturn() async {
    if (_return == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận duyệt'),
        content: const Text('Bạn có chắc chắn muốn duyệt yêu cầu trả hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Duyệt', style: TextStyle(color: kSuccessColor)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final returnService = context.read<ReturnService>();
      await returnService.approveReturn(widget.returnId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã duyệt yêu cầu trả hàng'),
            backgroundColor: kSuccessColor,
          ),
        );
        _loadReturnDetail();
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

  Future<void> _showRejectDialog() async {
    if (_return == null) return;

    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối yêu cầu trả hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng nhập lý do từ chối:'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Lý do từ chối...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập lý do từ chối'),
                    backgroundColor: kErrorColor,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Từ chối', style: TextStyle(color: kErrorColor)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      noteController.dispose();
      return;
    }

    try {
      final returnService = context.read<ReturnService>();
      await returnService.rejectReturn(
        widget.returnId,
        adminNote: noteController.text.trim(),
      );
      noteController.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã từ chối yêu cầu trả hàng'),
            backgroundColor: kSuccessColor,
          ),
        );
        _loadReturnDetail();
      }
    } catch (e) {
      noteController.dispose();
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

  Future<void> _processReturn() async {
    if (_return == null) return;

    try {
      final returnService = context.read<ReturnService>();
      await returnService.processReturn(widget.returnId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chuyển sang trạng thái xử lý'),
            backgroundColor: kSuccessColor,
          ),
        );
        _loadReturnDetail();
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

  Future<void> _completeReturn() async {
    if (_return == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hoàn tất'),
        content: const Text(
          'Bạn có chắc chắn đã hoàn tất xử lý trả hàng?\n\n'
          'Hệ thống sẽ tự động trả lại stock và cập nhật trạng thái hoàn tiền.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hoàn tất', style: TextStyle(color: kSuccessColor)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final returnService = context.read<ReturnService>();
      await returnService.completeReturn(widget.returnId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hoàn tất xử lý trả hàng'),
            backgroundColor: kSuccessColor,
          ),
        );
        _loadReturnDetail();
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'processing':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          title: const Text('Chi tiết trả hàng'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: kTextColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _return == null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          title: const Text('Chi tiết trả hàng'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: kTextColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: kErrorColor),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Không tìm thấy yêu cầu trả hàng',
                style: const TextStyle(color: kErrorColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReturnDetail,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Chi tiết trả hàng'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kTextColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(kDefaultPadding),
        children: [
          // Status Card
          Container(
            padding: const EdgeInsets.all(kDefaultPadding),
            decoration: kCardDecoration,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_return!.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assignment_return,
                    color: _getStatusColor(_return!.status),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _return!.statusText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(_return!.status),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ngày tạo: ${_dateFormatter.format(_return!.createdAt)}',
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
          ),

          const SizedBox(height: kDefaultPadding),

          // Order Info
          Container(
            padding: const EdgeInsets.all(kDefaultPadding),
            decoration: kCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin đơn hàng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Mã đơn hàng', _return!.order?['code'] ?? _return!.orderId),
                if (_return!.store != null)
                  _buildInfoRow('Cửa hàng', _return!.store!['name'] ?? 'N/A'),
              ],
            ),
          ),

          const SizedBox(height: kDefaultPadding),

          // Return Items
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
                ..._return!.items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kOffWhiteColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sản phẩm ID: ${item.productId}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: kTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Số lượng: ${item.qty}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kSecondaryTextColor,
                                ),
                              ),
                              if (item.reason != null && item.reason!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Lý do: ${item.reason}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: kSecondaryTextColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          _currencyFormatter.format(item.unitPrice * item.qty),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: kDefaultPadding),

          // Reason & Description
          Container(
            padding: const EdgeInsets.all(kDefaultPadding),
            decoration: kCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lý do trả hàng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _return!.reason,
                  style: const TextStyle(
                    fontSize: 14,
                    color: kTextColor,
                  ),
                ),
                if (_return!.description != null && _return!.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Mô tả chi tiết',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _return!.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: kTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: kDefaultPadding),

          // Refund Info
          Container(
            padding: const EdgeInsets.all(kDefaultPadding),
            decoration: kCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin hoàn tiền',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Số tiền hoàn lại', _currencyFormatter.format(_return!.refundAmount)),
                _buildInfoRow('Phương thức hoàn tiền', _getRefundMethodText(_return!.refundMethod)),
                _buildInfoRow('Trạng thái hoàn tiền', _getRefundStatusText(_return!.refundStatus)),
              ],
            ),
          ),

          if (_return!.adminNote != null) ...[
            const SizedBox(height: kDefaultPadding),
            Container(
              padding: const EdgeInsets.all(kDefaultPadding),
              decoration: BoxDecoration(
                color: kInfoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(kBorderRadius),
                border: Border.all(color: kInfoColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: kInfoColor, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Ghi chú từ cửa hàng',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _return!.adminNote!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: kTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons for Customer
          Builder(
            builder: (context) {
              final currentUser = context.watch<AuthProvider>().currentUser;
              if (currentUser?.role == 'USER' && _return!.isPending) {
                return Column(
                  children: [
                    const SizedBox(height: kDefaultPadding),
                    OutlinedButton(
                      onPressed: _cancelReturn,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kErrorColor,
                        side: const BorderSide(color: kErrorColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Hủy yêu cầu trả hàng'),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Action Buttons for Seller/Admin
          Builder(
            builder: (context) {
              final currentUser = context.watch<AuthProvider>().currentUser;
              final isSellerOrAdmin = currentUser?.role == 'SELLER' || currentUser?.role == 'ADMIN';
              
              if (!isSellerOrAdmin) return const SizedBox.shrink();

              if (_return!.isPending) {
                return Column(
                  children: [
                    const SizedBox(height: kDefaultPadding),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showRejectDialog(),
                            icon: const Icon(Icons.close),
                            label: const Text('Từ chối'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kErrorColor,
                              side: const BorderSide(color: kErrorColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approveReturn(),
                            icon: const Icon(Icons.check),
                            label: const Text('Duyệt'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kSuccessColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              if (_return!.isApproved) {
                return Column(
                  children: [
                    const SizedBox(height: kDefaultPadding),
                    ElevatedButton.icon(
                      onPressed: () => _processReturn(),
                      icon: const Icon(Icons.inventory_2),
                      label: const Text('Bắt đầu xử lý'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (_return!.isProcessing) {
                return Column(
                  children: [
                    const SizedBox(height: kDefaultPadding),
                    ElevatedButton.icon(
                      onPressed: () => _completeReturn(),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Hoàn tất'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSuccessColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),

          const SizedBox(height: kDefaultPadding),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: kSecondaryTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRefundMethodText(String method) {
    switch (method) {
      case 'original':
        return 'Hoàn về phương thức thanh toán gốc';
      case 'wallet':
        return 'Hoàn vào ví điện tử';
      case 'bank_transfer':
        return 'Chuyển khoản ngân hàng';
      default:
        return method;
    }
  }

  String _getRefundStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Đã hoàn tiền';
      case 'failed':
        return 'Thất bại';
      default:
        return status;
    }
  }
}

