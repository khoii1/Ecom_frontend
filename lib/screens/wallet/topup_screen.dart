import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ecom_frontend/services/wallet_service.dart';
import 'package:ecom_frontend/screens/payment/vnpay_webview_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';

class TopupScreen extends StatefulWidget {
  static const String routeName = '/wallet/topup';

  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  // Các mức nạp tiền nhanh
  final List<double> _quickAmounts = [50000, 100000, 200000, 500000, 1000000, 2000000];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTopup() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;

    if (amount < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền nạp tối thiểu là 10,000 VNĐ'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    if (amount > 50000000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền nạp tối đa là 50,000,000 VNĐ'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final walletService = context.read<WalletService>();

      // 1. Tạo yêu cầu nạp tiền
      final transaction = await walletService.createTopupRequest(
        amount: amount,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      // 2. Tạo VNPay URL
      final paymentUrl = await walletService.createTopupPaymentUrl(
        transactionId: transaction.id,
        amount: amount,
      );

      if (mounted) {
        // 3. Mở WebView để thanh toán
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VnpayWebViewScreen(
              paymentUrl: paymentUrl,
            ),
          ),
        );

        if (result == true && mounted) {
          // Thanh toán thành công
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nạp tiền thành công!'),
              backgroundColor: kSuccessColor,
            ),
          );
          Navigator.pop(context, true); // Return true để refresh balance
        }
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

  void _selectQuickAmount(double amount) {
    setState(() {
      _amountController.text = _currencyFormatter.format(amount).replaceAll('đ', '').trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Nạp tiền vào ví'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kTextColor,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(kDefaultPadding),
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(kDefaultPadding),
              decoration: BoxDecoration(
                color: kInfoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(kBorderRadius),
                border: Border.all(color: kInfoColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: kInfoColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Số tiền nạp tối thiểu: 10,000 VNĐ\nSố tiền nạp tối đa: 50,000,000 VNĐ',
                      style: TextStyle(
                        fontSize: 13,
                        color: kTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: kDefaultPadding * 1.5),

            // Quick Amount Buttons
            const Text(
              'Chọn số tiền nhanh',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _quickAmounts.map((amount) {
                return InkWell(
                  onTap: () => _selectQuickAmount(amount),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: kOffWhiteColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      _currencyFormatter.format(amount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: kDefaultPadding * 1.5),

            // Amount Input
            const Text(
              'Số tiền nạp *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: kInputDecoration('Nhập số tiền', prefixIcon: Icons.attach_money),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số tiền nạp';
                }
                final amount = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
                if (amount < 10000) {
                  return 'Số tiền nạp tối thiểu là 10,000 VNĐ';
                }
                if (amount > 50000000) {
                  return 'Số tiền nạp tối đa là 50,000,000 VNĐ';
                }
                return null;
              },
            ),

            const SizedBox(height: kDefaultPadding),

            // Description Input
            const Text(
              'Ghi chú (tùy chọn)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: kInputDecoration('Nhập ghi chú...', prefixIcon: Icons.note),
              maxLines: 3,
            ),

            const SizedBox(height: kDefaultPadding * 2),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitTopup,
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
                      'Nạp tiền',
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

