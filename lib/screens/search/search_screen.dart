import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:ecom_frontend/models/product.dart';
import 'package:ecom_frontend/providers/product_provider.dart';
import 'package:ecom_frontend/providers/category_provider.dart';
import 'package:ecom_frontend/screens/product/product_detail_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/widgets/product_filter_widget.dart';
import 'package:ecom_frontend/services/product_service.dart';
import 'package:ecom_frontend/services/wishlist_service.dart';
import 'package:ecom_frontend/l10n/app_localizations.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // State & formatter
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  List<Product> _searchResults = [];
  bool _isLoading = false;
  String _currentQuery = "";
  ProductFilter _currentFilter = ProductFilter();

  // Wishlist state - Map<productId, isInWishlist>
  final Map<String, bool> _wishlistStatus = {};
  final Map<String, bool> _checkingWishlist = {}; // Track which products are being checked/toggled
  bool _isCheckingAllWishlist = false; // Flag to prevent multiple simultaneous checks
  final Set<String> _checkedProducts = {}; // Track products that have already been checked (to avoid re-checking)
  bool _isPostFrameCallbackPending = false; // Prevent multiple postFrameCallbacks

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu ban đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch("");
    });
    // Lắng nghe thay đổi ô tìm kiếm
    _searchController.addListener(() {
      if (_searchController.text != _currentQuery) {
        _performSearch(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Lọc kết quả theo từ khóa và bộ lọc
  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _currentQuery = query.toLowerCase();
    });

    try {
      final productService = context.read<ProductService>();
      // Chuyển categoryId từ int sang string nếu có
      final categoryIdStr = _currentFilter.categoryId != null
          ? _currentFilter.categoryId.toString()
          : null;
      final products = await productService.getProducts(
        search: query.isNotEmpty ? query : null,
        categoryIdString: categoryIdStr,
        minPrice: _currentFilter.minPrice,
        maxPrice: _currentFilter.maxPrice,
        minRating: _currentFilter.minRating,
        sort: _currentFilter.sort,
      );

      if (mounted) {
        setState(() {
          _searchResults = products;
          _isLoading = false;
        });
        // Check wishlist status for all products (only check products that haven't been checked yet)
        // Use a small delay to avoid checking during setState rebuild
        if (!_isPostFrameCallbackPending) {
          _isPostFrameCallbackPending = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _isPostFrameCallbackPending = false;
            if (mounted) {
              final productsToCheck = products.where((p) {
                return !_wishlistStatus.containsKey(p.id) && 
                       _checkingWishlist[p.id] != true &&
                       !_checkedProducts.contains(p.id);
              }).toList();
              if (productsToCheck.isNotEmpty && !_isCheckingAllWishlist) {
                _checkSearchResultsWishlist(productsToCheck);
              }
            }
          });
        }
      }
    } catch (e) {
      // Fallback: lọc từ provider nếu API lỗi
      if (mounted) {
        final allProducts = context.read<ProductProvider>().products;
        List<Product> filtered = List.from(allProducts);

        // Lọc theo từ khóa
        if (_currentQuery.isNotEmpty) {
          filtered = filtered.where((p) {
            return p.title.toLowerCase().contains(_currentQuery);
          }).toList();
        }

        // Lọc theo category
        if (_currentFilter.categoryId != null) {
          filtered = filtered.where((p) {
            return p.categoryId == _currentFilter.categoryId.toString();
          }).toList();
        }

        // Lọc theo giá
        if (_currentFilter.minPrice != null) {
          filtered = filtered.where((p) => p.price >= _currentFilter.minPrice!).toList();
        }
        if (_currentFilter.maxPrice != null) {
          filtered = filtered.where((p) => p.price <= _currentFilter.maxPrice!).toList();
        }

        // Lọc theo rating
        if (_currentFilter.minRating != null) {
          filtered = filtered.where((p) {
            return p.rating != null && p.rating! >= _currentFilter.minRating!;
          }).toList();
        }

        // Sắp xếp
        if (_currentFilter.sort != null) {
          switch (_currentFilter.sort) {
            case 'price_asc':
              filtered.sort((a, b) => a.price.compareTo(b.price));
              break;
            case 'price_desc':
              filtered.sort((a, b) => b.price.compareTo(a.price));
              break;
            case 'rating_desc':
              filtered.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
              break;
            case 'name_asc':
              filtered.sort((a, b) => a.title.compareTo(b.title));
              break;
          }
        }

        setState(() {
          _searchResults = filtered;
          _isLoading = false;
        });
        // Check wishlist status for all products (only check products that haven't been checked yet)
        // Use a small delay to avoid checking during setState rebuild
        if (!_isPostFrameCallbackPending) {
          _isPostFrameCallbackPending = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _isPostFrameCallbackPending = false;
            if (mounted) {
              final productsToCheck = filtered.where((p) {
                return !_wishlistStatus.containsKey(p.id) && 
                       _checkingWishlist[p.id] != true &&
                       !_checkedProducts.contains(p.id);
              }).toList();
              if (productsToCheck.isNotEmpty && !_isCheckingAllWishlist) {
                _checkSearchResultsWishlist(productsToCheck);
              }
            }
          });
        }
      }
    }
  }

  // Check wishlist status for search results
  Future<void> _checkSearchResultsWishlist(List<Product> products) async {
    if (!mounted || products.isEmpty || _isCheckingAllWishlist) return;
    
    // Filter out products that already have status or are being checked
    final productsToCheck = products.where((p) {
      return !_wishlistStatus.containsKey(p.id) && 
             _checkingWishlist[p.id] != true &&
             !_checkedProducts.contains(p.id);
    }).toList();
    
    if (productsToCheck.isEmpty) return; // Nothing to check
    
    _isCheckingAllWishlist = true;
    
    try {
      final wishlistService = context.read<WishlistService>();
      final Map<String, bool> newStatuses = {};
      
      // Check all products in parallel, but only once
      final futures = productsToCheck.map((product) async {
        // Double-check to avoid race conditions
        if (_wishlistStatus.containsKey(product.id) || 
            _checkingWishlist[product.id] == true ||
            _checkedProducts.contains(product.id)) {
          return;
        }
        
        try {
          final isInWishlist = await wishlistService.checkInWishlist(product.id);
          // Only add if still mounted and product hasn't been checked by another operation
          if (mounted && !_wishlistStatus.containsKey(product.id) && !_checkedProducts.contains(product.id)) {
            newStatuses[product.id] = isInWishlist;
            _checkedProducts.add(product.id); // Mark as checked
          }
        } catch (e) {
          // Silent fail - just don't set the status
          print("Error checking wishlist for ${product.id}: $e");
        }
      }).toList();
      
      await Future.wait(futures);
      
      // Update all statuses in a single setState to avoid multiple rebuilds
      if (mounted && newStatuses.isNotEmpty) {
        setState(() {
          _wishlistStatus.addAll(newStatuses);
        });
      }
    } finally {
      if (mounted) {
        _isCheckingAllWishlist = false;
      }
    }
  }

  // Toggle wishlist for a specific product
  Future<void> _toggleWishlist(String productId) async {
    if (!mounted) return;
    
    // Prevent multiple simultaneous toggles for the same product
    if (_checkingWishlist[productId] == true) return;
    
    final currentStatus = _wishlistStatus[productId] ?? false;
    
    // Mark product as checked to prevent re-checking after toggle
    _checkedProducts.add(productId);
    
    // Optimistically update UI first
    setState(() {
      _checkingWishlist[productId] = true;
      _wishlistStatus[productId] = !currentStatus; // Update immediately
    });

    try {
      final wishlistService = context.read<WishlistService>();
      if (currentStatus) {
        await wishlistService.removeFromWishlist(productId);
        // Status already updated optimistically, no need to update again
      } else {
        await wishlistService.addToWishlist(productId);
        // Status already updated optimistically, no need to update again
      }
    } catch (e) {
      print("Error toggling wishlist for $productId: $e");
      // Revert on error
      if (mounted) {
        setState(() {
          _wishlistStatus[productId] = currentStatus; // Revert to original status
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus
                  ? 'Lỗi khi xóa khỏi yêu thích'
                  : 'Lỗi khi thêm vào yêu thích',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _checkingWishlist[productId] = false;
        });
      }
    }
  }

  void _showFilterSheet() {
    final categories = context.read<CategoryProvider>().categories;
    final categoryList = categories.map((c) => {
      'id': int.tryParse(c.id) ?? 0,
      'name': c.name,
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: ProductFilterSheet(
          initialFilter: _currentFilter,
          categories: categoryList,
          onApply: (filter) {
            setState(() => _currentFilter = filter);
            _performSearch(_searchController.text);
          },
        ),
      ),
    );
  }

  // AppBar có ô tìm kiếm
  AppBar _buildSearchBar(BuildContext context) {
    return AppBar(
      backgroundColor: kPrimaryColor,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      automaticallyImplyLeading: false,
      titleSpacing: kDefaultPadding,
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchPlaceholder,
          hintStyle: TextStyle(
            color: kSecondaryTextColor.withOpacity(0.7),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: kSecondaryTextColor.withOpacity(0.9),
            size: 22,
          ),
          filled: true,
          fillColor: kOffWhiteColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(
              color: kPrimaryColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: kSecondaryTextColor.withOpacity(0.7),
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.filter_list_alt, color: Colors.white),
              onPressed: _showFilterSheet,
            ),
            if (_currentFilter.hasFilters)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: kDefaultPadding / 2),
      ],
    );
  }

  // Header kết quả
  Widget _buildResultHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  _currentQuery.isEmpty
                      ? "Hiển thị tất cả sản phẩm"
                      : 'Kết quả cho "${_searchController.text}"',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: kTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!_isLoading)
                Text(
                  "${_searchResults.length} kết quả",
                  style: const TextStyle(fontSize: 13, color: kSecondaryTextColor),
                ),
            ],
          ),
          // Hiển thị các filter đang áp dụng
          if (_currentFilter.hasFilters) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_currentFilter.categoryId != null)
                  _buildFilterChip(
                    'Danh mục',
                    () => setState(() {
                      _currentFilter = _currentFilter.copyWith(clearCategory: true);
                      _performSearch(_searchController.text);
                    }),
                  ),
                if (_currentFilter.minPrice != null || _currentFilter.maxPrice != null)
                  _buildFilterChip(
                    'Giá: ${_currency.format(_currentFilter.minPrice ?? 0)} - ${_currency.format(_currentFilter.maxPrice ?? 100000000)}',
                    () => setState(() {
                      _currentFilter = _currentFilter.copyWith(
                        clearMinPrice: true,
                        clearMaxPrice: true,
                      );
                      _performSearch(_searchController.text);
                    }),
                  ),
                if (_currentFilter.minRating != null)
                  _buildFilterChip(
                    '⭐ ${_currentFilter.minRating}+',
                    () => setState(() {
                      _currentFilter = _currentFilter.copyWith(clearMinRating: true);
                      _performSearch(_searchController.text);
                    }),
                  ),
                if (_currentFilter.sort != null)
                  _buildFilterChip(
                    _getSortLabel(_currentFilter.sort!),
                    () => setState(() {
                      _currentFilter = _currentFilter.copyWith(clearSort: true);
                      _performSearch(_searchController.text);
                    }),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: kPrimaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'price_asc':
        return 'Giá thấp → cao';
      case 'price_desc':
        return 'Giá cao → thấp';
      case 'rating_desc':
        return 'Đánh giá cao';
      case 'name_asc':
        return 'Tên A-Z';
      case 'newest':
        return 'Mới nhất';
      default:
        return sort;
    }
  }

  // Lưới kết quả
  Widget _buildSearchResultsGrid(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
        ),
      );
    }

    if (_searchResults.isEmpty && _currentQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kLargePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_outlined,
                  size: 64,
                  color: kPrimaryColor.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: kLargePadding),
              Text(
                AppLocalizations.of(context)!.noResults,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: kSmallPadding),
              Text(
                "Thử tìm kiếm với từ khóa khác",
                style: TextStyle(
                  fontSize: 14,
                  color: kSecondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (_searchResults.isEmpty && _currentQuery.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kLargePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_outlined,
                  size: 64,
                  color: kPrimaryColor.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: kLargePadding),
              const Text(
                "Tìm kiếm sản phẩm",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: kSmallPadding),
              Text(
                AppLocalizations.of(context)!.searchPlaceholder,
                style: TextStyle(
                  fontSize: 14,
                  color: kSecondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 1.5,
      ).copyWith(bottom: kDefaultPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: kDefaultPadding / 1.5,
        mainAxisSpacing: kDefaultPadding / 1.5,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) =>
          _buildProductCard(context, _searchResults[index]),
    );
  }

  // Card sản phẩm
  Widget _buildProductCard(BuildContext context, Product product) {
    final hasDiscount =
        product.discountPercentage != null && product.discountPercentage! > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kBorderRadius),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh + nút yêu thích
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color: kOffWhiteColor,
                    ),
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child:
                          product.imageUrl != null &&
                              product.imageUrl!.isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: kSecondaryTextColor,
                                    ),
                                  ),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              kPrimaryColor,
                                            ),
                                      ),
                                    );
                                  },
                            )
                          : const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: kSecondaryTextColor,
                              ),
                            ),
                    ),
                  ),
                  // Wishlist button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleWishlist(product.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _checkingWishlist[product.id] == true
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    kHeartColor,
                                  ),
                                ),
                              )
                            : Icon(
                                (_wishlistStatus[product.id] ?? false)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: (_wishlistStatus[product.id] ?? false)
                                    ? kHeartColor
                                    : kHeartColor.withOpacity(0.6),
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Thông tin sản phẩm
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: kTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Giá + badge giảm giá
                      Flexible(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                _currency.format(
                                  product.finalPrice ?? product.price,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasDiscount)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '-${product.discountPercentage!.toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Rating (nếu có)
                      if (product.rating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              product.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                color: kSecondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Layout tổng
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildSearchBar(context),
      body: RefreshIndicator(
        onRefresh: () => _performSearch(_searchController.text),
        color: kPrimaryColor,
        backgroundColor: Colors.white,
        child: Column(
          children: [
            _buildResultHeader(),
            Expanded(child: _buildSearchResultsGrid(context)),
          ],
        ),
      ),
    );
  }
}
