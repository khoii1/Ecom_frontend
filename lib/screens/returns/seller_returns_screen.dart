import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ecom_frontend/models/return.dart';
import 'package:ecom_frontend/services/return_service.dart';
import 'package:ecom_frontend/screens/returns/return_detail_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';

class SellerReturnsScreen extends StatefulWidget {
  final String storeId;

  const SellerReturnsScreen({super.key, required this.storeId});

  @override
  State<SellerReturnsScreen> createState() => _SellerReturnsScreenState();
}

class _SellerReturnsScreenState extends State<SellerReturnsScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Return>> _returnsFuture;
  late TabController _tabController;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  final List<String> _tabs = ['Tất cả', 'Chờ duyệt', 'Đã duyệt', 'Đang xử lý', 'Hoàn tất'];
  final List<String?> _tabFilters = [null, 'pending', 'approved', 'processing', 'completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _returnsFuture = _fetchReturns();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Return>> _fetchReturns() async {
    final returnService = context.read<ReturnService>();
    try {
      return await returnService.getStoreReturns(widget.storeId);
    } catch (e) {
      throw Exception('Lỗi tải yêu cầu trả hàng: ${e.toString()}');
    }
  }

  Future<void> _refreshReturns() async {
    setState(() {
      _returnsFuture = _fetchReturns();
    });
  }

  List<Return> _filterReturns(List<Return> returns, String? status) {
    if (status == null) return returns;
    return returns.where((r) => r.status == status).toList();
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
        title: const Text('Quản lý trả hàng'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kTextColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          labelColor: kPrimaryColor,
          unselectedLabelColor: kSecondaryTextColor,
          indicatorColor: kPrimaryColor,
          onTap: (_) => setState(() {}),
        ),
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

            final allReturns = snapshot.data ?? [];
            final filteredReturns = _filterReturns(
              allReturns,
              _tabFilters[_tabController.index],
            );

            if (filteredReturns.isEmpty) {
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
              itemCount: filteredReturns.length,
              itemBuilder: (context, index) {
                final returnItem = filteredReturns[index];
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
              if (returnItem.user != null)
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: kSecondaryTextColor),
                    const SizedBox(width: 8),
                    Text(
                      returnItem.user!['full_name'] ?? 'Khách hàng',
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
                  'Khách hàng: ${returnItem.userId}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kTextColor,
                  ),
                ),
              const SizedBox(height: 8),
              if (returnItem.order != null)
                Text(
                  'Đơn hàng: ${returnItem.order!['code'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: kSecondaryTextColor,
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

