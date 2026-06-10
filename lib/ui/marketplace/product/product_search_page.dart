import 'package:army_ecommerce/blocs/marketplace/product_search/product_search_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/product_search/product_search_event.dart';
import 'package:army_ecommerce/blocs/marketplace/product_search/product_search_state.dart';
import 'package:army_ecommerce/models/brand_model.dart';
import 'package:army_ecommerce/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../repositories/marketplace_repository.dart';
import '../../util/constants/app_colors.dart';
import '../../util/constants/app_radius.dart';
import '../../util/constants/app_spacing.dart';
import '../../util/widgets/app_bottom_sheet.dart';
import '../../util/widgets/app_text_field.dart';
import '../../util/widgets/app_button.dart';
import '../../util/widgets/empty_state.dart';
import '../../util/widgets/error_state.dart';
import '../../util/widgets/product_card.dart';
import '../../util/widgets/shimmer_product_grid.dart';
import '../marketplace_shared.dart';
import 'product_detail_page.dart';
import '../../util/theme/special_app_theme.dart';

class SearchPage extends StatelessWidget {
  final String? categoryId;

  const SearchPage({super.key, this.categoryId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductSearchBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(ProductSearchRequested(categoryId: categoryId)),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _keywordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 320;
    if (_scrollController.position.pixels >= threshold) {
      context.read<ProductSearchBloc>().add(ProductSearchLoadMoreRequested());
    }
  }

  Future<void> _openFilterSheet(BuildContext context, ProductSearchState state) async {
    final searchBloc = context.read<ProductSearchBloc>();
    await AppBottomSheet.show<void>(
      context: context,
      child: BlocProvider.value(
        value: searchBloc,
        child: _ProductSearchFilterSheet(state: state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductSearchBloc, ProductSearchState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Tìm kiếm')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _keywordController,
                        label: 'Từ khóa',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filled(
                      tooltip: 'Tìm kiếm',
                      onPressed: () {
                        context.read<ProductSearchBloc>().add(
                              ProductSearchRequested(
                                keyword: _keywordController.text.trim(),
                                categoryId: state.categoryId,
                              ),
                            );
                      },
                      icon: const Icon(Icons.search),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      tooltip: 'Lọc kết quả',
                      onPressed: () => _openFilterSheet(context, state),
                      icon: const Icon(Icons.tune),
                    ),
                  ],
                ),
              ),
              // Hiển thị danh sách thương hiệu nếu có categoryId
              if (state.categoryId != null)
                _BrandsList(
                  brands: state.brands,
                  isLoading: state.isBrandsLoading,
                  selectedBrandId: state.brandId,
                  onBrandSelected: (brandId) {
                    context.read<ProductSearchBloc>().add(
                          ProductSearchFiltered(
                            keyword: state.keyword,
                            categoryId: state.categoryId,
                            brandId: brandId,
                            priceMin: state.priceMin,
                            priceMax: state.priceMax,
                          ),
                        );
                  },
                ),
              Expanded(child: _buildResult(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResult(BuildContext context, ProductSearchState state) {
    if (state.isInitialLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: ShimmerProductGrid(),
      );
    }
    if (state.errorMessage != null && state.products.isEmpty) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () => context.read<ProductSearchBloc>().add(
              state.useListProductsApi
                  ? ProductSearchFiltered(
                      keyword: state.keyword,
                      categoryId: state.categoryId,
                      brandId: state.brandId,
                      priceMin: state.priceMin,
                      priceMax: state.priceMax,
                    )
                  : ProductSearchRequested(
                      keyword: state.keyword,
                      categoryId: state.categoryId,
                      brandId: state.brandId,
                      priceMin: state.priceMin,
                      priceMax: state.priceMax,
                    ),
            ),
      );
    }
    if (state.products.isEmpty) {
      return const EmptyState(
        title: 'Không tìm thấy sản phẩm',
        message: 'Hãy thử từ khóa hoặc bộ lọc khác.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProductSearchBloc>().add(
              state.useListProductsApi
                  ? ProductSearchFiltered(
                      keyword: state.keyword,
                      categoryId: state.categoryId,
                      brandId: state.brandId,
                      priceMin: state.priceMin,
                      priceMax: state.priceMax,
                    )
                  : ProductSearchRequested(
                      keyword: state.keyword,
                      categoryId: state.categoryId,
                      brandId: state.brandId,
                      priceMin: state.priceMin,
                      priceMax: state.priceMax,
                    ),
            );
      },
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.products.length + (state.isLoadingMore ? 2 : 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.66,
        ),
        itemBuilder: (context, index) {
          if (index >= state.products.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = state.products[index];
          return ProductCard(
            product: productCardDataFromModel(product),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductDetailPage(productId: product.id)),
            ),
          );
        },
      ),
    );
  }
}

class _ProductSearchFilterSheet extends StatefulWidget {
  final ProductSearchState state;

  const _ProductSearchFilterSheet({required this.state});

  @override
  State<_ProductSearchFilterSheet> createState() => _ProductSearchFilterSheetState();
}

class _ProductSearchFilterSheetState extends State<_ProductSearchFilterSheet> {
  late List<ProductBrandInfo> _availableBrands;
  String? _selectedBrandId;
  late double _currentMinPrice;
  late double _currentMaxPrice;
  late double _minPriceBound;
  late double _maxPriceBound;

  @override
  void initState() {
    super.initState();
    _selectedBrandId = widget.state.brandId;

    // Collect brands from products
    final Map<String, ProductBrandInfo> brandMap = {};
    for (final product in widget.state.products) {
      final brand = product.brand;
      if (brand != null && brand.id.isNotEmpty) {
        brandMap[brand.id] = brand;
      }
    }
    // Also include currently selected brand if not already in the map
    if (widget.state.brandId != null && !brandMap.containsKey(widget.state.brandId)) {
      brandMap[widget.state.brandId!] = ProductBrandInfo(
        id: widget.state.brandId!,
        name: 'ID: ${widget.state.brandId}',
      );
    }
    _availableBrands = brandMap.values.toList();

    // Determine price range bounds
    final products = widget.state.products;
    if (products.isNotEmpty) {
      _minPriceBound = products.map((p) => p.price.toDouble()).reduce((a, b) => a < b ? a : b);
      _maxPriceBound = products.map((p) => p.price.toDouble()).reduce((a, b) => a > b ? a : b);
    } else {
      _minPriceBound = 0;
      _maxPriceBound = 10000000;
    }

    if (_minPriceBound == _maxPriceBound) {
      _maxPriceBound = _minPriceBound + 100000;
    }

    _currentMinPrice = (widget.state.priceMin?.toDouble() ?? _minPriceBound).clamp(_minPriceBound, _maxPriceBound);
    _currentMaxPrice = (widget.state.priceMax?.toDouble() ?? _maxPriceBound).clamp(_minPriceBound, _maxPriceBound);
    if (_currentMinPrice > _currentMaxPrice) {
      _currentMinPrice = _minPriceBound;
      _currentMaxPrice = _maxPriceBound;
    }
  }

  String _formatPrice(num value) {
    try {
      return '${NumberFormat.decimalPattern('vi_VN').format(value)} xu';
    } catch (_) {
      return '${value.toStringAsFixed(0)} xu';
    }
  }

  void _applyFilter() {
    context.read<ProductSearchBloc>().add(
          ProductSearchFiltered(
            keyword: widget.state.keyword,
            categoryId: widget.state.categoryId,
            brandId: _selectedBrandId,
            priceMin: _currentMinPrice.round(),
            priceMax: _currentMaxPrice.round(),
          ),
        );
    Navigator.of(context).pop();
  }

  void _clearFilter() {
    context.read<ProductSearchBloc>().add(
          ProductSearchRequested(
            keyword: widget.state.keyword,
            categoryId: widget.state.categoryId,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final specialTheme = context.specialTheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bộ lọc tìm kiếm',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Thương hiệu',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (_availableBrands.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'Không có thương hiệu nào từ các sản phẩm tìm thấy',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: _availableBrands.map((brand) {
                  final isSelected = _selectedBrandId == brand.id;
                  final displayName = brand.name.isNotEmpty && brand.name != 'Thương hiệu'
                      ? brand.name
                      : 'ID: ${brand.id}';
                  return ChoiceChip(
                    label: Text(displayName),
                    selected: isSelected,
                    selectedColor: specialTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: specialTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? specialTheme.primaryColor : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedBrandId = selected ? brand.id : null;
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Khoảng giá',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${_formatPrice(_currentMinPrice)} - ${_formatPrice(_currentMaxPrice)}',
                  style: TextStyle(
                    color: specialTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            RangeSlider(
              values: RangeValues(_currentMinPrice, _currentMaxPrice),
              min: _minPriceBound,
              max: _maxPriceBound,
              activeColor: specialTheme.primaryColor,
              inactiveColor: AppColors.border,
              labels: RangeLabels(
                _formatPrice(_currentMinPrice),
                _formatPrice(_currentMaxPrice),
              ),
              onChanged: (values) {
                setState(() {
                  _currentMinPrice = values.start;
                  _currentMaxPrice = values.end;
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilter,
                    child: const Text('Xóa lọc'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Áp dụng',
                    onPressed: _applyFilter,
                    icon: Icons.filter_alt,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandsList extends StatelessWidget {
  final List<BrandModel> brands;
  final bool isLoading;
  final String? selectedBrandId;
  final Function(String?) onBrandSelected;

  const _BrandsList({
    required this.brands,
    required this.isLoading,
    required this.selectedBrandId,
    required this.onBrandSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty && !isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thương hiệu',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 40,
            child: isLoading
                ? const Center(child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: brands.length + 1,
                    separatorBuilder: (_, i) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Nút "Tất cả" để xóa filter thương hiệu
                        return _BrandChip(
                          label: 'Tất cả',
                          isSelected: selectedBrandId == null,
                          onTap: () => onBrandSelected(null),
                        );
                      }
                      final brand = brands[index - 1];
                      return _BrandChip(
                        label: brand.name,
                        isSelected: selectedBrandId == brand.id,
                        onTap: () => onBrandSelected(brand.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrandChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
