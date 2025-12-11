import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ecom_frontend/services/wallet_service.dart';
import 'package:ecom_frontend/screens/wallet/topup_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';

class WalletScreen extends StatefulWidget {
  static const String routeName = '/wallet';

  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _balanceFuture;
  late TabController _tabController;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  final List<String> _tabs = ['Tất cả', 'Nạp tiền', 'Thanh toán', 'Hoàn tiền'];
  final List<String?> _tabFilters = [null, 'topup', 'payment', 'refund'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _balanceFuture = _fetchBalance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchBalance() async {
    final walletService = context.read<WalletService>();
    try {
      return await walletService.getBalance();
    } catch (e) {
      throw Exception('Lỗi tải số dư ví: ${e.toString()}');
    }
  }

  Future<void> _refreshBalance() async {
    setState(() {
      _balanceFuture = _fetchBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Ví điện tử'),
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
      body: Column(
        children: [
          // Balance Card
          FutureBuilder<Map<String, dynamic>>(
            future: _balanceFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 180,
                  padding: const EdgeInsets.all(kDefaultPadding),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  height: 180,
                  padding: const EdgeInsets.all(kDefaultPadding),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: kErrorColor),
                        const SizedBox(height: 8),
                        Text(
                          'Lỗi: ${snapshot.error}',
                          style: const TextStyle(color: kErrorColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _refreshBalance,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final balanceData = snapshot.data ?? {};
              final balance = (balanceData['balance'] as num?)?.toDouble() ?? 0.0;

              return Container(
                margin: const EdgeInsets.all(kDefaultPadding),
                padding: const EdgeInsets.all(kDefaultPadding * 1.5),
                decoration: BoxDecoration(
                  gradient: kPrimaryGradient,
                  borderRadius: BorderRadius.circular(kBorderRadius),
                  boxShadow: kCardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Số dư ví',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _refreshBalance,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currencyFormatter.format(balance),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TopupScreen(),
                            ),
                          ).then((_) => _refreshBalance());
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text(
                          'Nạp tiền',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: kPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Transactions List
          Expanded(
            child: _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final walletService = context.read<WalletService>();
    final filter = _tabFilters[_tabController.index];

    return FutureBuilder(
      future: walletService.getTransactions(
        type: filter,
        limit: 50,
        offset: 0,
      ),
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
                  onPressed: () => setState(() {}),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final response = snapshot.data;
        final transactions = response?.transactions ?? [];

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: kLightTextColor),
                const SizedBox(height: 16),
                Text(
                  'Chưa có giao dịch nào',
                  style: TextStyle(color: kSecondaryTextColor),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(kDefaultPadding),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionCard(transaction);
            },
          ),
        );
      },
    );
  }

  Widget _buildTransactionCard(transaction) {
    final isPositive = transaction.type == 'topup' || transaction.type == 'refund';
    final isNegative = transaction.type == 'payment';
    final amountColor = isPositive ? kSuccessColor : (isNegative ? kErrorColor : kTextColor);
    final icon = isPositive
        ? Icons.add_circle
        : (isNegative ? Icons.remove_circle : Icons.info);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: kCardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: amountColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                if (transaction.description != null)
                  Text(
                    transaction.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: kSecondaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(transaction.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transaction.statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(transaction.status),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: kLightTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? "+" : (isNegative ? "-" : "")}${_currencyFormatter.format(transaction.amount)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return kSuccessColor;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return kErrorColor;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

