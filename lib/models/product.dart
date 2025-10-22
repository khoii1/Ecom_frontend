class Product {
  final String id;
  final String storeId;
  final String title;
  final String? categoryId;
  final double price;
  final double? discountedPrice;
  final double? rating;
  final String? imageUrl;
  final String status;

  Product({
    required this.id,
    required this.storeId,
    required this.title,
    this.categoryId,
    required this.price,
    this.discountedPrice,
    this.rating,
    this.imageUrl,
    required this.status,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      storeId: json['store_id'],
      title: json['title'],
      categoryId: json['category_id'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      discountedPrice: json['discounted_price'] != null
          ? double.tryParse(json['discounted_price'].toString())
          : null,
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString())
          : null,
      imageUrl: json['image_url'],
      status: json['status'],
    );
  }
}
