import 'package:ecom_frontend/providers/category_provider.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh mục sản phẩm"),
        // Không cần nút back vì nó là một tab chính
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(context, categoryProvider),
    );
  }

  Widget _buildBody(BuildContext context, CategoryProvider categoryProvider) {
    // Hiển thị trạng thái tải hoặc lỗi
    if (categoryProvider.status == CategoryStatus.loading ||
        categoryProvider.status == CategoryStatus.initial) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
        ),
      );
    }
    if (categoryProvider.status == CategoryStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Lỗi tải danh mục: ${categoryProvider.errorMessage ?? 'Unknown error'}",
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    context.read<CategoryProvider>().fetchCategories(),
                child: const Text("Thử lại"),
              ),
            ],
          ),
        ),
      );
    }
    if (categoryProvider.categories.isEmpty) {
      return const Center(child: Text("Không có danh mục nào."));
    }

    // Hiển thị danh sách danh mục
    final categories = categoryProvider.categories;
    return ListView.separated(
      itemCount: categories.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: Colors.grey[300]), // Đường kẻ ngăn cách
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          leading: const Icon(
            Icons.category_outlined,
            color: kSecondaryTextColor,
          ), // Icon mẫu
          title: Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: kSecondaryTextColor,
          ),
          onTap: () {
            // TODO: Điều hướng đến trang hiển thị sản phẩm thuộc danh mục này
            print("Selected category: ${category.name} (ID: ${category.id})");
            // Navigator.push(context, MaterialPageRoute(builder: (_) => ProductsByCategoryScreen(categoryId: category.id)));
          },
        );
      },
    );
  }
}
