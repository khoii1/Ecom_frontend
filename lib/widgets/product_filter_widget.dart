import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ecom_frontend/utils/constants.dart';

class ProductFilter {
  final int? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final String? sort;

  ProductFilter({
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.sort,
  });

  ProductFilter copyWith({
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sort,
    bool clearCategory = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMinRating = false,
    bool clearSort = false,
  }) {
    return ProductFilter(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      sort: clearSort ? null : (sort ?? this.sort),
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (categoryId != null) params['category_id'] = categoryId;
    if (minPrice != null) params['min_price'] = minPrice;
    if (maxPrice != null) params['max_price'] = maxPrice;
    if (minRating != null) params['min_rating'] = minRating;
    if (sort != null) params['sort'] = sort;
    return params;
  }

  bool get hasFilters =>
      categoryId != null ||
      minPrice != null ||
      maxPrice != null ||
      minRating != null ||
      sort != null;
}

class ProductFilterSheet extends StatefulWidget {
  final ProductFilter initialFilter;
  final List<Map<String, dynamic>> categories;
  final ValueChanged<ProductFilter> onApply;

  const ProductFilterSheet({
    super.key,
    required this.initialFilter,
    required this.categories,
    required this.onApply,
  });

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late int? _selectedCategory;
  late RangeValues _priceRange;
  late double _minRating;
  late String? _selectedSort;

  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static const double _maxPrice = 100000000; // 100 triệu

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'newest', 'label': 'Mới nhất'},
    {'value': 'price_asc', 'label': 'Giá thấp đến cao'},
    {'value': 'price_desc', 'label': 'Giá cao đến thấp'},
    {'value': 'rating_desc', 'label': 'Đánh giá cao nhất'},
    {'value': 'name_asc', 'label': 'Tên A-Z'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialFilter.categoryId;
    _priceRange = RangeValues(
      widget.initialFilter.minPrice ?? 0,
      widget.initialFilter.maxPrice ?? _maxPrice,
    );
    _minRating = widget.initialFilter.minRating ?? 0;
    _selectedSort = widget.initialFilter.sort;
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _priceRange = const RangeValues(0, _maxPrice);
      _minRating = 0;
      _selectedSort = null;
    });
  }

  void _applyFilters() {
    final filter = ProductFilter(
      categoryId: _selectedCategory,
      minPrice: _priceRange.start > 0 ? _priceRange.start : null,
      maxPrice: _priceRange.end < _maxPrice ? _priceRange.end : null,
      minRating: _minRating > 0 ? _minRating : null,
      sort: _selectedSort,
    );
    widget.onApply(filter);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Đặt lại'),
                ),
                const Text(
                  'Bộ lọc',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Danh mục
                  const Text(
                    'Danh mục',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Tất cả'),
                        selected: _selectedCategory == null,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = null);
                        },
                        selectedColor: kPrimaryColor.withOpacity(0.2),
                        checkmarkColor: kPrimaryColor,
                      ),
                      ...widget.categories.map((cat) => FilterChip(
                            label: Text(cat['name'] ?? ''),
                            selected: _selectedCategory == cat['id'],
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? cat['id'] : null;
                              });
                            },
                            selectedColor: kPrimaryColor.withOpacity(0.2),
                            checkmarkColor: kPrimaryColor,
                          )),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Khoảng giá
                  const Text(
                    'Khoảng giá',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _currencyFormat.format(_priceRange.start),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _currencyFormat.format(_priceRange.end),
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: _maxPrice,
                    divisions: 100,
                    activeColor: kPrimaryColor,
                    onChanged: (values) {
                      setState(() => _priceRange = values);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Đánh giá tối thiểu
                  const Text(
                    'Đánh giá tối thiểu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [0.0, 3.0, 3.5, 4.0, 4.5].map((rating) {
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (rating > 0) ...[
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text('${rating.toString()}+'),
                            ] else
                              const Text('Tất cả'),
                          ],
                        ),
                        selected: _minRating == rating,
                        onSelected: (selected) {
                          setState(() => _minRating = selected ? rating : 0);
                        },
                        selectedColor: kPrimaryColor.withOpacity(0.2),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Sắp xếp
                  const Text(
                    'Sắp xếp theo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sortOptions.map((option) {
                      return ChoiceChip(
                        label: Text(option['label']),
                        selected: _selectedSort == option['value'],
                        onSelected: (selected) {
                          setState(() {
                            _selectedSort = selected ? option['value'] : null;
                          });
                        },
                        selectedColor: kPrimaryColor.withOpacity(0.2),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Apply button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Áp dụng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

