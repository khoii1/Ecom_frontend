import 'package:flutter/material.dart';
import 'package:ecom_frontend/screens/home/home_screen.dart';
import 'package:ecom_frontend/screens/search/search_screen.dart';
import 'package:ecom_frontend/screens/cart/cart_screen.dart';
import 'package:ecom_frontend/screens/chat/chat_list_screen.dart';
import 'package:ecom_frontend/screens/profile/profile_screen.dart';
import 'package:ecom_frontend/screens/wishlist/wishlist_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/l10n/app_localizations.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _selectedIndex = 0;

  List<Widget> get _widgetOptions => [
    HomeScreenContent(onTabSwitch: _onItemTapped), // Home (index 0) - với callback để switch tab
    const SearchScreen(), // Search (index 1)
    CartScreen(), // Cart (index 2)
    const ChatListScreen(), // Chat (index 3)
    const ProfileScreen(), // Profile (index 4)
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
              // Home
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: AppLocalizations.of(context)!.home,
                  isActive: _selectedIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),
              ),

              // Favorites
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.favorite_outline,
                  activeIcon: Icons.favorite,
                  label: AppLocalizations.of(context)!.favorites,
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WishlistScreen()),
                    );
                  },
                ),
              ),

              // Cart
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.shopping_cart_outlined,
                  activeIcon: Icons.shopping_cart,
                  label: AppLocalizations.of(context)!.cart,
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
          ),
        ],
      ),
    );
  }
}

