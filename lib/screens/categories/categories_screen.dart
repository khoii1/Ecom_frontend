import 'package:ecom_frontend/providers/category_provider.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:ecom_frontend/screens/product/products_by_category_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Danh mục sản phẩm"),
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(context, categoryProvider),
    );
  }

  Widget _buildBody(BuildContext context, CategoryProvider categoryProvider) {
    if (categoryProvider.status == CategoryStatus.loading ||
        categoryProvider.status == CategoryStatus.initial) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
        ),
      );
    }
    // ... (Phần xử lý lỗi và empty giữ nguyên) ...
    if (categoryProvider.status == CategoryStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 50),
              const SizedBox(height: 16),
              Text(
                "Lỗi tải danh mục:\n${categoryProvider.errorMessage ?? 'Không rõ nguyên nhân'}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: kSecondaryTextColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Thử lại"),
                onPressed: () =>
                    context.read<CategoryProvider>().fetchCategories(),
                style: ElevatedButton.styleFrom(
                  foregroundColor: kPrimaryColor, // Màu chữ/icon nút
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (categoryProvider.categories.isEmpty) {
      return const Center(child: Text("Không có danh mục nào."));
    }

    final categories = categoryProvider.categories;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      itemCount: categories.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey[200],
        indent: kDefaultPadding,
        endIndent: kDefaultPadding,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          // --- THAY ĐỔI: Hiển thị ảnh thay vì Icon ---
          leading: category.imageUrl != null && category.imageUrl!.isNotEmpty
              ? ClipRRect(
                  // Bo tròn ảnh
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    category.imageUrl!,
                    width: 50, // Kích thước ảnh
                    height: 50,
                    fit: BoxFit.cover,
                    // Hiển thị placeholder khi đang tải hoặc lỗi
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              kPrimaryColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                )
              : Container(
                  // Placeholder nếu không có ảnh
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(Icons.category_outlined, color: Colors.grey[400]),
                ),
          // --- KẾT THÚC THAY ĐỔI ---
          title: Text(
            category.name,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: kTextColor,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: kSecondaryTextColor,
          ),
          onTap: () {
            print("Đã chọn danh mục: ${category.name} (ID: ${category.id})");
            // Ví dụ điều hướng:
            /*
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductsByCategoryScreen(
                  categoryName: category.name,
                  categoryId: category.id,
                ),
              ),
            );
            */
          },
          splashColor: kPrimaryColor.withOpacity(0.1),
        );
      },
    );
  }
}
