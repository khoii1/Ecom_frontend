class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String orderId;
  final int rating;
  final String? comment;
  final List<String> imageUrls;
  final String? sellerResponse;
  final DateTime? sellerResponseAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.orderId,
    required this.rating,
    this.comment,
    this.imageUrls = const [],
    this.sellerResponse,
    this.sellerResponseAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'].toString(),
      productId: json['product_id'].toString(),
      userId: json['user_id'].toString(),
      userName: json['user_name'] ?? 'Ẩn danh',
      orderId: json['order_id']?.toString() ?? '',
      rating: json['rating'] is int
          ? json['rating']
          : int.parse(json['rating'].toString()),
      comment: json['comment'],
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : [],
      sellerResponse: json['seller_response'],
      sellerResponseAt: json['seller_response_at'] != null
          ? DateTime.parse(json['seller_response_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class ReviewStats {
  final int totalReviews;
  final double averageRating;
  final int fiveStar;
  final int fourStar;
  final int threeStar;
  final int twoStar;
  final int oneStar;

  ReviewStats({
    required this.totalReviews,
    required this.averageRating,
    required this.fiveStar,
    required this.fourStar,
    required this.threeStar,
    required this.twoStar,
    required this.oneStar,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    return ReviewStats(
      totalReviews: json['total_reviews'] ?? 0,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      fiveStar: json['five_star'] ?? 0,
      fourStar: json['four_star'] ?? 0,
      threeStar: json['three_star'] ?? 0,
      twoStar: json['two_star'] ?? 0,
      oneStar: json['one_star'] ?? 0,
    );
  }
}
