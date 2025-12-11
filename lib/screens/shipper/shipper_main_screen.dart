import 'package:flutter/material.dart';
import 'package:ecom_frontend/screens/shipper/shipper_orders_screen.dart';
import 'package:ecom_frontend/screens/profile/profile_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';

class ShipperMainScreen extends StatefulWidget {
  const ShipperMainScreen({super.key});

  @override
  State<ShipperMainScreen> createState() => _ShipperMainScreenState();
}

class _ShipperMainScreenState extends State<ShipperMainScreen> {
  int _selectedIndex = 0;

  List<Widget> get _widgetOptions => [
    const ShipperOrdersScreen(), // Orders (index 0)
    const ProfileScreen(), // Profile (index 1)
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Orders
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.local_shipping_outlined,
                  activeIcon: Icons.local_shipping,
                  label: 'Đơn hàng',
                  isActive: _selectedIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),
              ),

              // Profile
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isActive: _selectedIndex == 1,
                  onTap: () => _onItemTapped(1),
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
          ),
        ],
      ),
    );
  }
}

