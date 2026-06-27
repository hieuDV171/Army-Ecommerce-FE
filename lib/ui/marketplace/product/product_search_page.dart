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
  final bool autofocus;

  const SearchPage({
    super.key,
    this.categoryId,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductSearchBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(ProductSearchRequested(categoryId: categoryId))
       ..add(ProductSearchSavedSearchesRequested()),
      child: _SearchView(autofocus: autofocus),
    );
  }
}

class _SearchView extends StatefulWidget {
  final bool autofocus;
  const _SearchView({required this.autofocus});

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _keywordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  String _sortBy = 'default';
  late bool _shouldAutofocus;

  @override
  void initState() {
    super.initState();
    _shouldAutofocus = widget.autofocus;
    _scrollController.addListener(_onScroll);
    _keywordController.addListener(_onKeywordChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  void _onKeywordChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildSortRow() {
    final specialTheme = context.specialTheme;
    final options = [
      ('Mặc định', 'default'),
      ('Tên A-Z', 'name_asc'),
      ('Tên Z-A', 'name_desc'),
      ('Giá tăng', 'price_asc'),
      ('Giá giảm', 'price_desc'),
    ];
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, idx) {
          final opt = options[idx];
          final isSelected = _sortBy == opt.$2;
          return ChoiceChip(
            label: Text(opt.$1),
            selected: isSelected,
            selectedColor: specialTheme.primaryColor.withValues(alpha: 0.2),
            checkmarkColor: specialTheme.primaryColor,
            labelStyle: TextStyle(
              color: isSelected ? specialTheme.primaryColor : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
            onSelected: (selected) {
              if (selected) {
                setState(() => _sortBy = opt.$2);
              }
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _keywordController.removeListener(_onKeywordChanged);
    _keywordController.dispose();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
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
    final scrollController = ScrollController();
    await AppBottomSheet.show<void>(
      context: context,
      scrollController: scrollController,
      child: BlocProvider.value(
        value: searchBloc,
        child: _ProductSearchFilterSheet(
          state: state,
          currentKeyword: _keywordController.text.trim(),
        ),
      ),
    );
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final autofocus = _shouldAutofocus;
    _shouldAutofocus = false;
    return BlocBuilder<ProductSearchBloc, ProductSearchState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Scaffold(
            appBar: AppBar(title: const Text('Tìm kiếm')),
            body: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _keywordController,
                              focusNode: _searchFocusNode,
                              label: 'Từ khóa',
                              autofocus: autofocus,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (value) {
                                final kw = value.trim();
                                _searchFocusNode.unfocus();
                                context.read<ProductSearchBloc>().add(
                                      ProductSearchRequested(
                                        keyword: kw,
                                        categoryId: state.categoryId,
                                      ),
                                    );
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          IconButton.filled(
                            tooltip: 'Tìm kiếm',
                            onPressed: () {
                              final kw = _keywordController.text.trim();
                              _searchFocusNode.unfocus();
                              context.read<ProductSearchBloc>().add(
                                    ProductSearchRequested(
                                      keyword: kw,
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
                    _buildSortRow(),
                    Expanded(child: _buildResult(context, state)),
                  ],
                ),
                _buildDropdownOverlay(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResult(BuildContext context, ProductSearchState state) {
    final showHistory = _keywordController.text.trim().isEmpty &&
        (state.categoryId == null || state.categoryId!.isEmpty || state.categoryId == '0') &&
        (state.brandId == null || state.brandId!.isEmpty) &&
        state.priceMin == null &&
        state.priceMax == null;

    if (showHistory) {
      return const EmptyState(
        title: 'Tìm kiếm sản phẩm',
        message: 'Vui lòng nhập từ khóa hoặc chọn bộ lọc để tìm kiếm.',
      );
    }

    if (state.isInitialLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: ShimmerProductGrid(),
      );
    }
    if (state.errorMessage != null && state.products.isEmpty) {
      final hasCondition = state.keyword.trim().isNotEmpty ||
          (state.categoryId != null && state.categoryId!.isNotEmpty && state.categoryId != '0') ||
          (state.brandId != null && state.brandId!.isNotEmpty) ||
          state.priceMin != null ||
          state.priceMax != null;

      if (!hasCondition) {
        return const EmptyState(
          title: 'Tìm kiếm sản phẩm',
          message: 'Vui lòng nhập từ khóa hoặc chọn bộ lọc để tìm kiếm.',
        );
      }
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

    final sortedProducts = List<ProductModel>.from(state.products);
    if (_sortBy == 'name_asc') {
      sortedProducts.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_sortBy == 'name_desc') {
      sortedProducts.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
    } else if (_sortBy == 'price_asc') {
      sortedProducts.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'price_desc') {
      sortedProducts.sort((a, b) => b.price.compareTo(a.price));
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
        itemCount: sortedProducts.length + (state.isLoadingMore ? 2 : 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.51,
        ),
        itemBuilder: (context, index) {
          if (index >= sortedProducts.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = sortedProducts[index];
          return ProductCard(
            product: productCardDataFromModel(product),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductDetailPage(productId: product.id, isStock: product.isStock)),
            ),
            onLikeTap: () {
              context.read<ProductSearchBloc>().add(ProductSearchProductLikeToggled(product.id));
            },
          );
        },
      ),
    );
  }

  Widget _buildDropdownOverlay(BuildContext context, ProductSearchState state) {
    final query = _keywordController.text.trim().toLowerCase();
    
    final suggestions = state.savedSearches.where((item) {
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query);
    }).toList();

    if (!_searchFocusNode.hasFocus || suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 72.0,
      left: 16.0,
      right: 16.0,
      child: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: Theme.of(context).cardColor,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          constraints: const BoxConstraints(maxHeight: 250.0),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: suggestions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = suggestions[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.history, size: 18, color: AppColors.textSecondary),
                title: Text(
                  item.title,
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: Colors.red),
                  onPressed: () {
                    context.read<ProductSearchBloc>().add(
                          ProductSearchDelSavedSearchRequested(
                            searchId: item.id,
                          ),
                        );
                  },
                ),
                onTap: () {
                  _keywordController.text = item.title;
                  _keywordController.selection = TextSelection.fromPosition(
                    TextPosition(offset: item.title.length),
                  );
                  _searchFocusNode.unfocus();
                  context.read<ProductSearchBloc>().add(
                        ProductSearchRequested(
                          keyword: item.title,
                          categoryId: state.categoryId,
                        ),
                      );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProductSearchFilterSheet extends StatefulWidget {
  final ProductSearchState state;
  final String currentKeyword;

  const _ProductSearchFilterSheet({
    required this.state,
    required this.currentKeyword,
  });

  @override
  State<_ProductSearchFilterSheet> createState() => _ProductSearchFilterSheetState();
}

class _ProductSearchFilterSheetState extends State<_ProductSearchFilterSheet> {
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.state.categoryId;

    _minPriceController.text = widget.state.priceMin != null ? widget.state.priceMin!.toInt().toString() : '';
    _maxPriceController.text = widget.state.priceMax != null ? widget.state.priceMax!.toInt().toString() : '';

    final searchBloc = context.read<ProductSearchBloc>();
    if (searchBloc.state.categories.isEmpty) {
      searchBloc.add(ProductSearchCategoriesRequested());
    }
  }

  void _loadMoreCategories() {
    context.read<ProductSearchBloc>().add(ProductSearchCategoriesLoadMoreRequested());
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _increaseMinPrice() {
    final text = _minPriceController.text.trim();
    final current = double.tryParse(text) ?? 0.0;
    final newValue = current + 100000;
    setState(() {
      _minPriceController.text = newValue.toInt().toString();
    });
  }

  void _decreaseMinPrice() {
    final text = _minPriceController.text.trim();
    final current = double.tryParse(text) ?? 0.0;
    final newValue = (current - 100000).clamp(0.0, double.infinity);
    setState(() {
      _minPriceController.text = newValue.toInt().toString();
    });
  }

  void _increaseMaxPrice() {
    final text = _maxPriceController.text.trim();
    final current = double.tryParse(text) ?? 0.0;
    final newValue = current + 100000;
    setState(() {
      _maxPriceController.text = newValue.toInt().toString();
    });
  }

  void _decreaseMaxPrice() {
    final text = _maxPriceController.text.trim();
    final current = double.tryParse(text) ?? 0.0;
    final newValue = (current - 100000).clamp(0.0, double.infinity);
    setState(() {
      _maxPriceController.text = newValue.toInt().toString();
    });
  }

  String _formatPriceText(String text) {
    if (text.isEmpty) return '0 xu';
    final val = double.tryParse(text);
    if (val == null) return '0 xu';
    try {
      return '${NumberFormat.decimalPattern('vi_VN').format(val)} xu';
    } catch (_) {
      return '${val.toStringAsFixed(0)} xu';
    }
  }

  void _applyFilter() {
    final minPriceVal = double.tryParse(_minPriceController.text.trim())?.round();
    final maxPriceVal = double.tryParse(_maxPriceController.text.trim())?.round();

    context.read<ProductSearchBloc>().add(
          ProductSearchFiltered(
            keyword: widget.currentKeyword,
            categoryId: _selectedCategoryId,
            brandId: widget.state.brandId,
            priceMin: minPriceVal,
            priceMax: maxPriceVal,
          ),
        );
    Navigator.of(context).pop();
  }

  void _clearFilter() {
    context.read<ProductSearchBloc>().add(
          ProductSearchRequested(
            keyword: widget.currentKeyword,
            categoryId: null,
          ),
        );
    Navigator.of(context).pop();
  }

  Widget _buildPriceSpinnerField({
    required TextEditingController controller,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    final specialTheme = context.specialTheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(() {}),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                iconSize: 18,
                icon: const Icon(Icons.keyboard_arrow_up),
                onPressed: onIncrement,
                color: specialTheme.primaryColor,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                iconSize: 18,
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: onDecrement,
                color: specialTheme.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final specialTheme = context.specialTheme;
    return BlocBuilder<ProductSearchBloc, ProductSearchState>(
      builder: (context, state) {
        return Column(
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
              'Danh mục',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (state.isCategoriesLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (state.categories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'Không có danh mục nào',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              )
            else ...[
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: state.categories.map((category) {
                  final isSelected = _selectedCategoryId == category.id;
                  return ChoiceChip(
                    label: Text(category.name),
                    selected: isSelected,
                    selectedColor: specialTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: specialTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? specialTheme.primaryColor : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = selected ? category.id : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (!state.hasReachedEndCategories)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    icon: state.isCategoriesLoadingMore
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.expand_more, size: 16),
                    label: Text(
                      state.isCategoriesLoadingMore ? 'Đang tải...' : 'Tải thêm',
                      style: const TextStyle(fontSize: 13),
                    ),
                    onPressed: state.isCategoriesLoadingMore ? null : _loadMoreCategories,
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              'Khoảng giá',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Giá tối thiểu',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _buildPriceSpinnerField(
                        controller: _minPriceController,
                        onIncrement: _increaseMinPrice,
                        onDecrement: _decreaseMinPrice,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatPriceText(_minPriceController.text),
                        style: TextStyle(
                          fontSize: 12,
                          color: specialTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Giá tối đa',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _buildPriceSpinnerField(
                        controller: _maxPriceController,
                        onIncrement: _increaseMaxPrice,
                        onDecrement: _decreaseMaxPrice,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatPriceText(_maxPriceController.text),
                        style: TextStyle(
                          fontSize: 12,
                          color: specialTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
        );
      },
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
