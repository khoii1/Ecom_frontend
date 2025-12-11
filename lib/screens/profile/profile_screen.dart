import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/providers/locale_provider.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecom_frontend/l10n/app_localizations.dart';

import 'package:ecom_frontend/screens/orders/my_orders_screen.dart';
import 'package:ecom_frontend/screens/discount/discount_vouchers_screen.dart';
import 'package:ecom_frontend/screens/wishlist/wishlist_screen.dart';
import 'package:ecom_frontend/screens/address/address_list_screen.dart';
import 'package:ecom_frontend/screens/notifications/notifications_screen.dart';
import 'package:ecom_frontend/screens/returns/my_returns_screen.dart';
import 'package:ecom_frontend/screens/wallet/wallet_screen.dart';
import 'package:ecom_frontend/services/notification_service.dart';
import 'package:ecom_frontend/services/order_service.dart';
import 'package:ecom_frontend/services/wishlist_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool hideSellerMenu;
  
  const ProfileScreen({super.key, this.hideSellerMenu = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _orderCount = 0;
  int _wishlistCount = 0;
  int _deliveringCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final orderService = context.read<OrderService>();
      final wishlistService = context.read<WishlistService>();

      final orders = await orderService.getMyOrders();
      final wishlistItems = await wishlistService.getMyWishlist();

      if (mounted) {
        setState(() {
          _orderCount = orders.length;
          _wishlistCount = wishlistItems.length;
          _deliveringCount = orders.where((o) => 
            o.status == 'shipped' || o.status == 'delivering'
          ).length;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  String _getRoleName(BuildContext context, String? role) {
    final l10n = AppLocalizations.of(context)!;
    switch (role) {
      case 'USER':
        return l10n.customer;
      case 'SELLER':
        return l10n.seller;
      case 'ADMIN':
        return l10n.admin;
      case 'SHIPPER':
        return l10n.shipper;
      default:
        return 'Unknown';
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'SELLER':
        return Icons.storefront;
      case 'ADMIN':
        return Icons.admin_panel_settings;
      case 'SHIPPER':
        return Icons.local_shipping;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: user == null
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : CustomScrollView(
              slivers: [
                // Custom App Bar with gradient
                SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: kPrimaryColor,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: kPrimaryGradient,
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10),
                              // Avatar
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.8),
                                      Colors.white.withOpacity(0.4),
                                    ],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    user.fullName.isNotEmpty
                                        ? user.fullName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Name
                              Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName
                                    : '(Chưa có tên)',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Email
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              // Role Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getRoleIcon(user.role),
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child:                                     Text(
                                      _getRoleName(context, user.role),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Menu Items
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Row
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: kCardShadow,
                          ),
                          child: Row(
                            children: [
                              _buildStatItem(
                                icon: Icons.shopping_bag_outlined,
                                label: AppLocalizations.of(context)!.orders,
                                value: _isLoadingStats ? '-' : _orderCount.toString(),
                                color: kPrimaryColor,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MyOrdersScreen(),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: kOffWhiteColor,
                              ),
                              _buildStatItem(
                                icon: Icons.favorite_outline,
                                label: AppLocalizations.of(context)!.favorites,
                                value: _isLoadingStats ? '-' : _wishlistCount.toString(),
                                color: kHeartColor,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const WishlistScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Section: Đơn hàng
                        _buildSectionTitle(AppLocalizations.of(context)!.myOrders),
                        const SizedBox(height: 12),
                        _buildMenuCard([
                          _buildMenuItem(
                            icon: Icons.receipt_long_outlined,
                            title: AppLocalizations.of(context)!.allOrders,
                            subtitle: AppLocalizations.of(context)!.viewOrderHistory,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyOrdersScreen(),
                              ),
                            ),
                          ),
                          _buildMenuItem(
                            icon: Icons.local_shipping_outlined,
                            title: AppLocalizations.of(context)!.delivering,
                            subtitle: AppLocalizations.of(context)!.trackOrder,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyOrdersScreen(),
                                ),
                              );
                            },
                            badgeText: _deliveringCount > 0 ? _deliveringCount.toString() : null,
                          ),
                          _buildMenuItem(
                            icon: Icons.replay_outlined,
                            title: AppLocalizations.of(context)!.returnRequest,
                            subtitle: AppLocalizations.of(context)!.viewManageReturns,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyReturnsScreen(),
                              ),
                            ),
                            showDivider: false,
                          ),
                        ]),

                        // Section: Dịch vụ
                        const SizedBox(height: 24),
                        _buildSectionTitle(AppLocalizations.of(context)!.services),
                        const SizedBox(height: 12),
                        _buildMenuCard([
                          _buildMenuItem(
                            icon: Icons.account_balance_wallet_outlined,
                            title: AppLocalizations.of(context)!.wallet,
                            subtitle: AppLocalizations.of(context)!.walletDesc,
                            iconColor: kPrimaryColor,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WalletScreen(),
                              ),
                            ),
                          ),
                          _buildMenuItem(
                            icon: Icons.card_giftcard_outlined,
                            title: AppLocalizations.of(context)!.promoCode,
                            subtitle: AppLocalizations.of(context)!.promoCodeDesc,
                            iconColor: kHeartColor,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DiscountVouchersScreen(),
                              ),
                            ),
                            showDivider: false,
                          ),
                        ]),

                        // Section: Cài đặt
                        const SizedBox(height: 24),
                        _buildSectionTitle(AppLocalizations.of(context)!.settings),
                        const SizedBox(height: 12),
                        _buildMenuCard([
                          _buildMenuItem(
                            icon: Icons.notifications_outlined,
                            title: AppLocalizations.of(context)!.notifications,
                            subtitle: AppLocalizations.of(context)!.notificationsDesc,
                            iconColor: Colors.orange,
                            badge: _buildNotificationBadge(context),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            ),
                          ),
                          _buildMenuItem(
                            icon: Icons.location_on_outlined,
                            title: AppLocalizations.of(context)!.deliveryAddress,
                            subtitle: AppLocalizations.of(context)!.deliveryAddressDesc,
                            iconColor: Colors.blue,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddressListScreen(),
                              ),
                            ),
                          ),
                          _buildMenuItem(
                            icon: Icons.person_outline,
                            title: AppLocalizations.of(context)!.personalInfo,
                            subtitle: AppLocalizations.of(context)!.personalInfoDesc,
                            onTap: () {
                              // TODO: Navigate to edit profile screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)!.featureDeveloping),
                                ),
                              );
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.security_outlined,
                            title: AppLocalizations.of(context)!.security,
                            subtitle: AppLocalizations.of(context)!.securityDesc,
                            onTap: () {
                              // TODO: Navigate to change password screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)!.featureDeveloping),
                                ),
                              );
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.language_outlined,
                            title: AppLocalizations.of(context)!.language,
                            subtitle: AppLocalizations.of(context)!.languageDesc,
                            onTap: () => _showLanguageDialog(context),
                            showDivider: false,
                          ),
                        ]),

                        // Logout Button
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: kHeartColor.withOpacity(0.3),
                            ),
                          ),
                          child: TextButton.icon(
                            onPressed: () => _confirmLogout(context),
                            icon: const Icon(Icons.logout, color: kHeartColor),
                            label: Text(
                              AppLocalizations.of(context)!.logout,
                              style: const TextStyle(
                                color: kHeartColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // App Version
                        Center(
                          child: Text(
                            AppLocalizations.of(context)!.appVersion,
                            style: TextStyle(
                              color: kSecondaryTextColor.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNotificationBadge(BuildContext context) {
    return FutureBuilder<int>(
      future: context.read<NotificationService>().getUnreadCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: kHeartColor,
            borderRadius: BorderRadius.circular(10),
          ),
          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
          child: Text(
            count > 99 ? '99+' : count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    final widget = Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: kSecondaryTextColor),
        ),
      ],
    );

    if (onTap != null) {
      return Expanded(
        child: InkWell(onTap: onTap, child: widget),
      );
    }

    return Expanded(child: widget);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: kTextColor,
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardShadow,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Widget? badge,
    String? badgeText,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? kPrimaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor ?? kPrimaryColor, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: kTextColor,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: kSecondaryTextColor),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge != null) badge,
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kHeartColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (badge != null || badgeText != null) const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: kSecondaryTextColor.withOpacity(0.5),
              ),
            ],
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(height: 1, indent: 70, endIndent: 20, color: kOffWhiteColor),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kHeartColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout, color: kHeartColor),
              ),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.logoutTitle),
            ],
          ),
          content: Text(AppLocalizations.of(context)!.logoutConfirm),
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kHeartColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(AppLocalizations.of(context)!.logout),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthProvider>().logout();
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.language, color: kPrimaryColor),
                  ),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context)!.language),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...AppLocale.values.map((locale) {
                    return RadioListTile<AppLocale>(
                      title: Text(
                        locale == AppLocale.vi 
                            ? AppLocalizations.of(context)!.vietnamese 
                            : AppLocalizations.of(context)!.english,
                      ),
                      value: locale,
                      groupValue: localeProvider.locale,
                      onChanged: (value) {
                        if (value != null) {
                          localeProvider.setLocale(value);
                          setState(() {});
                        }
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(
                  child: Text(AppLocalizations.of(context)!.close),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
