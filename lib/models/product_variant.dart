class ProductVariant {
  final String id;
  final String productId;
  final String name; // Ví dụ: "Size", "Color"
  final String value; // Ví dụ: "M", "Red"
  final double priceModifier; // Số tiền thêm/bớt so với giá gốc
  final int stockQuantity;
  final String? sku;
  final bool isActive;

  ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    required this.value,
    this.priceModifier = 0,
    this.stockQuantity = 0,
    this.sku,
    this.isActive = true,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      name: json['name'] ?? '',
      value: json['value'] ?? '',
      priceModifier: (json['price_modifier'] as num?)?.toDouble() ?? 0,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      sku: json['sku'] as String?,
      isActive: json['is_active'] ?? true,
    );
  }
}

