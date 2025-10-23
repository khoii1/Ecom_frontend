class Category {
  final String id;
  final String name;
  final String? parentId;

  Category({required this.id, required this.name, this.parentId});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      parentId: json['parent_id'],
    );
  }
}
