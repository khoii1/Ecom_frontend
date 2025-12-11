class Category {
  final String id;
  final String name;
  final String? parentId;
  final String? imageUrl;

  Category({
    required this.id,
    required this.name,
    this.parentId,
    this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      parentId: json['parent_id']?.toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }
}
