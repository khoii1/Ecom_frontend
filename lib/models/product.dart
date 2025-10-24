class Product {
  final String id;
  final String storeId;
  final String title;
  final String? categoryId;
  final double price; // Giá gốc
  final double? discountPercentage; // Phần trăm giảm giá
  final double? finalPrice; // Giá sau khi giảm (thường được tính toán)
  final double? rating;
  final String? imageUrl;
  final String status;
  // --- SỬA: BẮT ĐẦU THÊM MỚI ---
  final String? description; // Mô tả sản phẩm
  // --- SỬA: KẾT THÚC THÊM MỚI ---

  Product({
    required this.id,
    required this.storeId,
    required this.title,
    this.categoryId,
    required this.price,
    this.discountPercentage,
    this.finalPrice,
    this.rating,
    this.imageUrl,
    required this.status,
    // --- SỬA: BẮT ĐẦU THÊM MỚI ---
    this.description, // Thêm vào constructor
    // --- SỬA: KẾT THÚC THÊM MỚI ---
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      // Chuyển đổi ID và các ID liên quan thành String một cách an toàn
      id: json['id']?.toString() ?? '', // Đảm bảo id không bao giờ null
      storeId:
          json['store_id']?.toString() ??
          '', // Đảm bảo store_id không bao giờ null
      title: json['title'] ?? '', // Đảm bảo title không bao giờ null
      categoryId: json['category_id']?.toString(), // category_id có thể null
      // Phân tích cú pháp các giá trị số một cách an toàn
      price: _parseDouble(json['price']) ?? 0.0, // Giá gốc không nên null
      discountPercentage: _parseDouble(json['discount_percentage']),
      finalPrice: _parseDouble(
        json['final_price'],
      ), // Giá cuối cùng có thể null
      rating: _parseDouble(json['rating']),

      imageUrl: json['image_url'] as String?, // imageUrl có thể null
      status:
          json['status'] ??
          'inactive', // Cung cấp giá trị mặc định nếu status null
      // --- SỬA: BẮT ĐẦU THÊM MỚI ---
      description: json['description'] as String?, // Đọc description từ JSON
      // --- SỬA: KẾT THÚC THÊM MỚI ---
    );
  }

  // Helper function để parse double một cách an toàn từ dynamic (String, int, double)
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null; // Trả về null nếu không thể parse
  }
}
