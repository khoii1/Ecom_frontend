import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/screens/seller/add_product_screen.dart';
import 'package:ecom_frontend/screens/seller/my_products_store_screen.dart';
import 'package:ecom_frontend/screens/seller/store_orders_screen.dart';
import 'package:ecom_frontend/screens/seller/seller_reviews_screen.dart';
import 'package:ecom_frontend/screens/profile/profile_screen.dart';
import 'package:ecom_frontend/screens/chat/chat_list_screen.dart';
import 'package:ecom_frontend/screens/analytics/analytics_screen.dart';
import 'package:ecom_frontend/screens/returns/seller_returns_screen.dart';
import 'package:ecom_frontend/services/store_service.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SellerDashboardScreen extends StatelessWidget {
  final Function(int)? onTabSwitch;
  
  const SellerDashboardScreen({super.key, this.onTabSwitch});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Kênh người bán',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với thông tin nhanh
              _buildQuickStats(context),
              const SizedBox(height: kDefaultPadding * 1.5),
              
              // Grid menu
              _buildGridMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        gradient: kPrimaryGradient,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.fullName ?? 'Người bán',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.storefront,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Người bán',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridMenu(BuildContext context) {
    final menuItems = [
      _MenuItem(
        icon: Icons.add_shopping_cart,
        title: 'Thêm sản phẩm',
        color: kPrimaryColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.inventory_2,
        title: 'Sản phẩm',
        color: kInfoColor,
        onTap: () {
          if (onTabSwitch != null) {
            onTabSwitch!(1); // Switch to Products tab
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyProductsStoreScreen()),
            );
          }
        },
      ),
      _MenuItem(
        icon: Icons.local_shipping,
        title: 'Đơn hàng',
        color: kAccentColor,
        onTap: () {
          if (onTabSwitch != null) {
            onTabSwitch!(2); // Switch to Orders tab
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StoreOrdersScreen()),
            );
          }
        },
      ),
      _MenuItem(
        icon: Icons.rate_review,
        title: 'Đánh giá',
        color: kStarColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SellerReviewsScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.chat_bubble,
        title: 'Tin nhắn',
        color: kInfoColor,
        onTap: () {
          if (onTabSwitch != null) {
            onTabSwitch!(3); // Switch to Chat tab
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatListScreen()),
            );
          }
        },
      ),
      _MenuItem(
        icon: Icons.analytics,
        title: 'Phân tích',
        color: kSuccessColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.warning_amber,
        title: 'Vấn đề giao hàng',
        color: kWarningColor,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tính năng đang phát triển'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
      _MenuItem(
        icon: Icons.assignment_return,
        title: 'Trả hàng',
        color: kErrorColor,
        onTap: () async {
          // Lấy storeId của seller
          final storeService = context.read<StoreService>();
          try {
            final stores = await storeService.getMyStores();
            if (stores.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bạn chưa có cửa hàng nào'),
                  backgroundColor: kErrorColor,
                ),
              );
              return;
            }
            // Lấy store đầu tiên (hoặc có thể cho user chọn nếu có nhiều stores)
            final storeId = stores.first.id;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SellerReturnsScreen(storeId: storeId),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${e.toString()}'),
                backgroundColor: kErrorColor,
              ),
            );
          }
        },
      ),
      _MenuItem(
        icon: Icons.account_balance_wallet,
        title: 'Ví',
        color: kPrimaryDark,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tính năng đang phát triển'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
      _MenuItem(
        icon: Icons.person,
        title: 'Hồ sơ',
        color: kSecondaryTextColor,
        onTap: () {
          if (onTabSwitch != null) {
            onTabSwitch!(4); // Switch to Profile tab
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
      ),
      _MenuItem(
        icon: Icons.headset_mic,
        title: 'Dịch vụ',
        color: kInfoColor,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tính năng đang phát triển'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return _buildMenuItemCard(context, item);
      },
    );
  }

  Widget _buildMenuItemCard(BuildContext context, _MenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(kBorderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kBorderRadius),
            boxShadow: kCardShadow,
            border: Border.all(
              color: kOffWhiteColor,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}

