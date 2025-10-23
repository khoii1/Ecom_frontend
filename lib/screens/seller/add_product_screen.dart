import 'dart:io';
import 'package:ecom_frontend/models/category.dart';
import 'package:ecom_frontend/providers/product_provider.dart';
import 'package:ecom_frontend/services/category_service.dart';
import 'package:ecom_frontend/services/store_service.dart';
import 'package:flutter/material.dart';
import 'package:ecom_frontend/services/product_service.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/widgets/primary_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false; // Loading cho nút đăng sản phẩm
  String? _selectedStoreId;
  bool _isLoadingStore = true; // Loading khi lấy store ID

  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoadingCategories = true; // Loading khi lấy danh mục

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchUserStore();
        _fetchCategories();
      }
    });
  }

  Future<void> _fetchCategories() async {
    // ... code giữ nguyên ...
    try {
      if (!mounted) return;
      final categoryService = context.read<CategoryService>();
      _categories = await categoryService.getCategories();
    } catch (e) {
      print("Lỗi lấy danh mục: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh mục: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  Future<void> _fetchUserStore() async {
    // ... code giữ nguyên ...
    try {
      if (!mounted) return;
      final storeService = context.read<StoreService>();
      final myStores = await storeService.getMyStores();
      if (mounted && myStores.isNotEmpty) {
        setState(() {
          _selectedStoreId = myStores.first.id;
          print("Đã tìm thấy Store ID: $_selectedStoreId");
        });
      } else if (mounted) {
        print("User không có cửa hàng nào.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn cần tạo cửa hàng trước khi đăng sản phẩm.'),
          ),
        );
      }
    } catch (e) {
      print("Lỗi lấy Store ID: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải thông tin cửa hàng: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingStore = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Copy file to app directory để tránh bị xóa
        final bytes = await pickedFile.readAsBytes();
        final tempDir = Directory.systemTemp;
        final tempFile = File(
          '${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await tempFile.writeAsBytes(bytes);

        setState(() {
          _selectedImage = tempFile;
        });
      }
    } catch (e) {
      print('Lỗi chọn ảnh: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _addProduct() async {
    // ... validation giữ nguyên ...
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh sản phẩm')),
      );
      return;
    }
    if (_isLoadingStore) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải thông tin cửa hàng...')),
      );
      return;
    }
    if (_selectedStoreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không tìm thấy ID cửa hàng. Bạn đã tạo cửa hàng chưa?',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? imageUrl;
    try {
      final productService = context.read<ProductService>();
      final productProvider = context
          .read<ProductProvider>(); // <-- LẤY PRODUCT PROVIDER

      // 1. Upload ảnh
      try {
        // Kiểm tra file tồn tại trước khi upload
        if (_selectedImage == null) {
          throw Exception("Chưa chọn ảnh sản phẩm");
        }

        if (!await _selectedImage!.exists()) {
          throw Exception("File ảnh không tồn tại hoặc đã bị xóa");
        }

        imageUrl = await productService.uploadImage(_selectedImage!);
        if (imageUrl == null) {
          throw Exception("URL ảnh trả về null sau khi upload.");
        }
      } catch (uploadError) {
        // ... xử lý lỗi upload giữ nguyên ...
        print("Lỗi upload ảnh chi tiết: $uploadError");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi upload ảnh: ${uploadError.toString()}'),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // 2. Tạo sản phẩm
      await productService.addProduct(
        storeId: _selectedStoreId!,
        title: _nameController.text,
        price: double.parse(_priceController.text),
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        discountedPrice: _discountedPriceController.text.isNotEmpty
            ? double.tryParse(_discountedPriceController.text)
            : null,
        categoryId: _selectedCategory?.id,
        imageUrl: imageUrl,
      );

      // --- THÀNH CÔNG ---
      if (mounted) {
        // Gọi refresh trên ProductProvider *TRƯỚC* khi pop
        await productProvider.refreshProducts(); // <-- GỌI REFRESH

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng sản phẩm thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // ... xử lý lỗi đăng sản phẩm giữ nguyên ...
      print("Lỗi đăng sản phẩm chi tiết: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng sản phẩm: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... Phần build UI giữ nguyên ...
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đăng sản phẩm mới"),
        backgroundColor: Colors.white,
        foregroundColor: kTextColor,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      backgroundColor: kBackgroundColor,
      body: _isLoadingStore
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(kDefaultPadding * 1.5),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImagePicker(),
                    const SizedBox(height: kDefaultPadding * 1.5),
                    _buildTextField(
                      controller: _nameController,
                      labelText: "Tên sản phẩm",
                      hintText: "Nhập tên sản phẩm",
                      prefixIcon: Icons.label_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên sản phẩm';
                        }
                        if (value.length < 2 || value.length > 200) {
                          return 'Tên sản phẩm phải từ 2-200 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: kDefaultPadding),
                    _buildTextField(
                      controller: _priceController,
                      labelText: "Giá",
                      hintText: "Nhập giá gốc (VND)",
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập giá';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Vui lòng nhập giá dương hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: kDefaultPadding),
                    _buildTextField(
                      controller: _discountedPriceController,
                      labelText: "Giá giảm giá (Nếu có)",
                      hintText: "Nhập giá sau khi giảm (VND)",
                      prefixIcon: Icons.trending_down,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final price = double.tryParse(_priceController.text);
                          final discounted = double.tryParse(value);
                          if (discounted == null || discounted < 0) {
                            return 'Giá giảm giá không hợp lệ (phải là số >= 0)';
                          }
                          if (price != null && discounted > price) {
                            return 'Giá giảm giá phải nhỏ hơn hoặc bằng giá gốc';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: kDefaultPadding),
                    _buildCategoryDropdown(),
                    const SizedBox(height: kDefaultPadding),
                    _buildTextField(
                      controller: _descriptionController,
                      labelText: "Mô tả sản phẩm",
                      hintText:
                          "Nhập mô tả chi tiết (chất liệu, kích thước,...)",
                      prefixIcon: Icons.description_outlined,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: kDefaultPadding * 2),
                    PrimaryButton(
                      text: "Đăng sản phẩm",
                      onPressed: _addProduct,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget chọn ảnh - giữ nguyên
  Widget _buildImagePicker() {
    // ... code giữ nguyên ...
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 180,
          width: MediaQuery.of(context).size.width * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            image: _selectedImage != null
                ? DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.contain,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _selectedImage == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 50,
                        color: kSecondaryTextColor,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Chọn ảnh sản phẩm",
                        style: TextStyle(
                          color: kSecondaryTextColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // Widget TextFormField chuẩn - giữ nguyên
  Widget _buildTextField({
    // ... code giữ nguyên ...
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(prefixIcon, color: kSecondaryTextColor, size: 20),
            hintText: hintText,
            hintStyle: const TextStyle(
              color: kSecondaryTextColor,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 12.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // Widget Dropdown danh mục - giữ nguyên
  Widget _buildCategoryDropdown() {
    // ... code giữ nguyên ...
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Danh mục",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _isLoadingCategories
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                ),
              )
            : _categories.isEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14.0,
                  horizontal: 12.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      color: kSecondaryTextColor,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Không có danh mục",
                      style: TextStyle(
                        color: kSecondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : DropdownButtonFormField<Category>(
                value: _selectedCategory,
                hint: const Text(
                  "Chọn danh mục sản phẩm",
                  style: TextStyle(color: kSecondaryTextColor, fontSize: 14),
                ),
                isExpanded: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.category_outlined,
                    color: kSecondaryTextColor,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14.0,
                    horizontal: 12.0,
                  ).copyWith(left: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: kPrimaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
                items: _categories.map((Category category) {
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Text(category.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (Category? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
              ),
      ],
    );
  }
}
