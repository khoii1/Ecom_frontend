import 'package:flutter/material.dart';
import 'package:ecom_frontend/screens/seller/seller_dashboard_screen.dart';
import 'package:ecom_frontend/screens/seller/my_products_store_screen.dart';
import 'package:ecom_frontend/screens/seller/store_orders_screen.dart';
import 'package:ecom_frontend/screens/chat/chat_list_screen.dart';
import 'package:ecom_frontend/screens/profile/profile_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/l10n/app_localizations.dart';

class SellerMainScreen extends StatefulWidget {
  const SellerMainScreen({super.key});

  @override
  State<SellerMainScreen> createState() => _SellerMainScreenState();
}

class _SellerMainScreenState extends State<SellerMainScreen> {
  int _selectedIndex = 0;

  List<Widget> get _widgetOptions => [
    SellerDashboardScreen(onTabSwitch: _onItemTapped), // Dashboard (index 0)
    const MyProductsStoreScreen(), // Products (index 1)
    const StoreOrdersScreen(), // Orders (index 2)
    const ChatListScreen(), // Chat (index 3)
    const ProfileScreen(hideSellerMenu: true), // Profile (index 4) - Ẩn menu seller vì đã có bottom nav
  ];

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dashboard
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: AppLocalizations.of(context)!.sellerDashboard,
                  isActive: _selectedIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),
              ),

              // Products
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  label: AppLocalizations.of(context)!.products,
                  isActive: _selectedIndex == 1,
                  onTap: () => _onItemTapped(1),
                ),
              ),

              // Orders
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.local_shipping_outlined,
                  activeIcon: Icons.local_shipping,
                  label: AppLocalizations.of(context)!.orders,
                  isActive: _selectedIndex == 2,
                  onTap: () => _onItemTapped(2),
                ),
              ),

              // Chat
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: AppLocalizations.of(context)!.chat,
                  isActive: _selectedIndex == 3,
                  onTap: () => _onItemTapped(3),
                ),
              ),

              // Profile
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: AppLocalizations.of(context)!.profile,
                  isActive: _selectedIndex == 4,
                  onTap: () => _onItemTapped(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive
                ? kPrimaryColor
                : kSecondaryTextColor.withOpacity(0.7),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive
                  ? kPrimaryColor
                  : kSecondaryTextColor.withOpacity(0.7),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

