import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ecom_frontend/models/review.dart';
import 'package:ecom_frontend/models/order.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/services/review_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

// Widget hiển thị sao đánh giá
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, size: size, color: color ?? Colors.amber);
        } else if (index < rating) {
          return Icon(
            Icons.star_half,
            size: size,
            color: color ?? Colors.amber,
          );
        } else {
          return Icon(
            Icons.star_border,
            size: size,
            color: color ?? Colors.amber,
          );
        }
      }),
    );
  }
}

// Widget cho phép chọn sao để đánh giá
class RatingSelector extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final double size;

  const RatingSelector({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: () => onRatingChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starValue <= rating ? Icons.star : Icons.star_border,
              size: size,
              color: Colors.amber,
            ),
          ),
        );
      }),
    );
  }
}

// Widget hiển thị thống kê đánh giá
class ReviewStatsWidget extends StatelessWidget {
  final ReviewStats stats;

  const ReviewStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Điểm trung bình
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                stats.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              RatingStars(rating: stats.averageRating, size: 20),
              const SizedBox(height: 4),
              Text(
                '${stats.totalReviews} đánh giá',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Phân bổ sao
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRatingBar(5, stats.fiveStar, stats.totalReviews),
                _buildRatingBar(4, stats.fourStar, stats.totalReviews),
                _buildRatingBar(3, stats.threeStar, stats.totalReviews),
                _buildRatingBar(2, stats.twoStar, stats.totalReviews),
                _buildRatingBar(1, stats.oneStar, stats.totalReviews),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int star, int count, int total) {
    final percentage = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$star', style: const TextStyle(fontSize: 12)),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation(Colors.amber),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget hiển thị một review
class ReviewCard extends StatelessWidget {
  final Review review;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReviewCard({
    super.key,
    required this.review,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: kPrimaryColor.withOpacity(0.1),
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        RatingStars(rating: review.rating.toDouble(), size: 14),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(review.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOwner)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Sửa'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: review.imageUrls.map((imageUrl) {
                return GestureDetector(
                  onTap: () {
                    _showFullscreenImage(context, imageUrl, review.imageUrls);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image),
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // Show fullscreen image viewer
  void _showFullscreenImage(BuildContext context, String imageUrl, List<String> allImages) {
    final initialIndex = allImages.indexOf(imageUrl);
    
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Image viewer with PageView for multiple images
            PageView.builder(
              controller: PageController(initialPage: initialIndex >= 0 ? initialIndex : 0),
              itemCount: allImages.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      allImages[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 100,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // Image counter (nếu có nhiều ảnh)
            if (allImages.length > 1)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${initialIndex + 1} / ${allImages.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Dialog để viết/sửa đánh giá
class WriteReviewDialog extends StatefulWidget {
  final String productName;
  final String productId;
  final List<Order>? availableOrders; // Danh sách orders đã mua sản phẩm này
  final int? initialRating;
  final String? initialComment;
  final List<String>? initialImageUrls;
  final Future<void> Function(
    String orderId,
    int rating,
    String? comment,
    List<String>? imageUrls,
  )
  onSubmit;

  const WriteReviewDialog({
    super.key,
    required this.productName,
    required this.productId,
    this.availableOrders,
    this.initialRating,
    this.initialComment,
    this.initialImageUrls,
    required this.onSubmit,
  });

  @override
  State<WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<WriteReviewDialog> {
  late int _rating;
  late TextEditingController _commentController;
  String? _selectedOrderId;
  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  bool _isLoading = false;
  bool _isUploadingImages = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 5;
    _commentController = TextEditingController(
      text: widget.initialComment ?? '',
    );
    _uploadedImageUrls = widget.initialImageUrls ?? [];
    // Nếu chỉ có 1 order, tự động chọn
    if (widget.availableOrders != null && widget.availableOrders!.length == 1) {
      _selectedOrderId = widget.availableOrders!.first.id;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage();

      if (pickedFiles.isEmpty) return;

      setState(() {
        _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      if (index < _selectedImages.length) {
        _selectedImages.removeAt(index);
      } else {
        int urlIndex = index - _selectedImages.length;
        if (urlIndex < _uploadedImageUrls.length) {
          _uploadedImageUrls.removeAt(urlIndex);
        }
      }
    });
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn số sao đánh giá')),
      );
      return;
    }

    // Chỉ yêu cầu orderId khi tạo review mới (không phải edit)
    if (widget.initialRating == null && _selectedOrderId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn đơn hàng')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> allImageUrls = List.from(_uploadedImageUrls);

      // Upload ảnh mới nếu có
      if (_selectedImages.isNotEmpty) {
        setState(() => _isUploadingImages = true);
        try {
          final reviewService = context.read<ReviewService>();
          final uploadedUrls = await reviewService.uploadReviewImages(
            _selectedImages,
          );
          allImageUrls.addAll(uploadedUrls);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi upload ảnh: ${e.toString()}')),
            );
          }
          setState(() => _isLoading = false);
          setState(() => _isUploadingImages = false);
          return;
        } finally {
          setState(() => _isUploadingImages = false);
        }
      }

      await widget.onSubmit(
        _selectedOrderId ?? '', // Có thể là empty string khi edit
        _rating,
        _commentController.text.trim(),
        allImageUrls.isNotEmpty ? allImageUrls : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allImages = [
      ..._selectedImages,
      ..._uploadedImageUrls.map((url) => null), // Placeholder cho URLs
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.initialRating != null ? 'Sửa đánh giá' : 'Viết đánh giá',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.productName,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              // Chọn đơn hàng (chỉ khi tạo mới và có nhiều orders)
              if (widget.initialRating == null &&
                  widget.availableOrders != null &&
                  widget.availableOrders!.length > 1) ...[
                DropdownButtonFormField<String>(
                  value: _selectedOrderId,
                  decoration: InputDecoration(
                    labelText: 'Chọn đơn hàng',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: widget.availableOrders!.map((order) {
                    return DropdownMenuItem<String>(
                      value: order.id,
                      child: Text(
                        'Đơn ${order.code} - ${_formatOrderDate(order.createdAt)}',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedOrderId = value);
                  },
                ),
                const SizedBox(height: 16),
              ],

              RatingSelector(
                rating: _rating,
                onRatingChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: 8),
              Text(
                _getRatingText(_rating),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: 'Chia sẻ trải nghiệm của bạn về sản phẩm...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),

              // Upload ảnh
              OutlinedButton.icon(
                onPressed: _isLoading || _isUploadingImages
                    ? null
                    : _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Thêm ảnh (tối đa 5)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              // Hiển thị ảnh đã chọn
              if (allImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: allImages.length,
                    itemBuilder: (context, index) {
                      final isFile = index < _selectedImages.length;
                      final file = isFile ? _selectedImages[index] : null;
                      final url = !isFile
                          ? _uploadedImageUrls[index - _selectedImages.length]
                          : null;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: file != null
                                  ? Image.file(
                                      file,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      url!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 100,
                                              height: 100,
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.broken_image,
                                              ),
                                            );
                                          },
                                    ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              if (_isUploadingImages) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 8),
                const Text(
                  'Đang upload ảnh...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading || _isUploadingImages
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading || _isUploadingImages
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Gửi đánh giá'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatOrderDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Rất tệ';
      case 2:
        return 'Tệ';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Tốt';
      case 5:
        return 'Tuyệt vời';
      default:
        return '';
    }
  }
}
