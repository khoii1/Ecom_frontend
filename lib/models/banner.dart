class Banner {
  final String id;
  final String title;
  final String? description;
  final String imageUrl;
  final String linkType; // 'product', 'category', 'store', 'none'
  final String? linkTargetId;
  final String position; // 'home_top', 'home_middle', 'home_bottom', 'category_top', 'sidebar'
  final int displayOrder;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final int clickCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Banner({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    this.linkType = 'none',
    this.linkTargetId,
    this.position = 'home_top',
    this.displayOrder = 0,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.clickCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] ?? '',
      linkType: json['link_type'] ?? 'none',
      linkTargetId: json['link_target_id'] as String?,
      position: json['position'] ?? 'home_top',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
      clickCount: (json['click_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Kiểm tra banner có đang hiệu lực không
  bool get isValid {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }
}

