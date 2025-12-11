import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/screens/user/user_main_screen.dart';
import 'package:ecom_frontend/screens/seller/seller_main_screen.dart';
import 'package:ecom_frontend/screens/shipper/shipper_main_screen.dart';

class RoleBasedMainScreen extends StatelessWidget {
  const RoleBasedMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final userRole = authProvider.currentUser?.role;

        // Route dựa trên role
        switch (userRole) {
          case 'SELLER':
            return const SellerMainScreen();
          case 'SHIPPER':
            return const ShipperMainScreen();
          case 'USER':
          case 'ADMIN':
          default:
            // ADMIN và USER đều dùng UserMainScreen
            // (Admin có thể có thêm quyền nhưng UI giống user)
            return const UserMainScreen();
        }
      },
    );
  }
}

