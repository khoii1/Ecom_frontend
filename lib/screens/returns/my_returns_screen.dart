import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ecom_frontend/models/return.dart';
import 'package:ecom_frontend/services/return_service.dart';
import 'package:ecom_frontend/screens/returns/return_detail_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';

class MyReturnsScreen extends StatefulWidget {
  static const String routeName = '/my-returns';

  const MyReturnsScreen({super.key});

  @override
  State<MyReturnsScreen> createState() => _MyReturnsScreenState();
}

class _MyReturnsScreenState extends State<MyReturnsScreen> {
  late Future<List<Return>> _returnsFuture;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _returnsFuture = _fetchReturns();
  }

  Future<List<Return>> _fetchReturns() async {
    final returnService = context.read<ReturnService>();
    try {
      return await returnService.getMyReturns();
    } catch (e) {
      throw Exception('Lỗi tải yêu cầu trả hàng: ${e.toString()}');
    }
  }

  Future<void> _refreshReturns() async {
    setState(() {
      _returnsFuture = _fetchReturns();
    });
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
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Yêu cầu trả hàng'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kTextColor,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReturns,
        child: FutureBuilder<List<Return>>(
          future: _returnsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: kErrorColor),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi: ${snapshot.error}',
                      style: const TextStyle(color: kErrorColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshReturns,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            final returns = snapshot.data ?? [];

            if (returns.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_return, size: 64, color: kLightTextColor),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có yêu cầu trả hàng nào',
                      style: TextStyle(color: kSecondaryTextColor),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(kDefaultPadding),
              itemCount: returns.length,
              itemBuilder: (context, index) {
                final returnItem = returns[index];
                return _buildReturnCard(returnItem);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildReturnCard(Return returnItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: kCardDecoration,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReturnDetailScreen(returnId: returnItem.id),
            ),
          ).then((_) => _refreshReturns());
        },
        borderRadius: BorderRadius.circular(kBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(returnItem.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      returnItem.statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(returnItem.status),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _dateFormatter.format(returnItem.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: kSecondaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (returnItem.order != null)
                Row(
                  children: [
                    Icon(Icons.receipt_long, size: 16, color: kSecondaryTextColor),
                    const SizedBox(width: 8),
                    Text(
                      'Đơn hàng: ${returnItem.order!['code'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: kTextColor,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Đơn hàng: ${returnItem.orderId}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kTextColor,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Lý do: ${returnItem.reason}',
                style: const TextStyle(
                  fontSize: 13,
                  color: kSecondaryTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Số tiền hoàn lại',
                        style: TextStyle(
                          fontSize: 12,
                          color: kSecondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currencyFormatter.format(returnItem.refundAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: kSecondaryTextColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

