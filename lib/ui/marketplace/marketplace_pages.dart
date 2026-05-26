import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/marketplace/marketplace_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/gradient_header.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../core/widgets/price_text.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/rating_stars.dart';
import '../../core/widgets/search_pill.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/shimmer_product_grid.dart';
import '../../models/marketplace_models.dart';
import '../../repositories/marketplace_repository.dart';

ProductCardData productCardDataFromModel(ProductModel product) {
  return ProductCardData(
    id: product.id,
    title: product.title,
    price: product.price,
    imageUrl: product.imageUrls.isEmpty ? null : product.imageUrls.first,
    rating: product.rating,
    soldCount: product.soldCount,
    sellerLocation: product.sellerLocation,
    isLiked: product.isLiked,
  );
}

class MarketplaceHomeBody extends StatefulWidget {
  final String username;
  final String? avatarUrl;

  const MarketplaceHomeBody({
    super.key,
    required this.username,
    this.avatarUrl,
  });

  @override
  State<MarketplaceHomeBody> createState() => _MarketplaceHomeBodyState();
}

class _MarketplaceHomeBodyState extends State<MarketplaceHomeBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 360;
    if (_scrollController.position.pixels >= threshold) {
      context.read<HomeBloc>().add(HomeLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state.errorMessage != null && !state.isInitialLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.isInitialLoading) {
          return const SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: ShimmerProductGrid(),
          );
        }

        if (state.errorMessage != null && state.products.isEmpty) {
          return ErrorState(
            message: state.errorMessage!,
            onRetry: () => context.read<HomeBloc>().add(HomeRequested()),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<HomeBloc>().add(HomeRefreshed());
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: _HomeHeader(username: widget.username),
              ),
              SliverToBoxAdapter(
                child: _HomeCategories(categories: state.categories),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Gợi ý hôm nay',
                    actionLabel: 'Lọc',
                    onActionTap: () => _openSearch(context),
                  ),
                ),
              ),
              if (state.products.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    title: 'Chưa có sản phẩm nào',
                    message:
                        'Hệ thống chưa có dữ liệu sản phẩm.\nKéo xuống để thử tải lại.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  sliver: SliverGrid.builder(
                    itemCount: state.products.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.66,
                    ),
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return ProductCard(
                        product: productCardDataFromModel(product),
                        onTap: () => _openProduct(context, product.id),
                      );
                    },
                  ),
                ),
              if (state.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
  }

  void _openProduct(BuildContext context, String productId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailPage(productId: productId)),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String username;

  const _HomeHeader({required this.username});

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Xin chào, $username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Thông báo',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationPage()),
                ),
                icon: const Icon(Icons.notifications_none, color: Colors.white),
              ),
              IconButton(
                tooltip: 'Chat',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConversationPage()),
                ),
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SearchPill(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletPage()),
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Ví quân nhu', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCategories extends StatelessWidget {
  final List<CategoryModel> categories;

  const _HomeCategories({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Danh mục tác chiến'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final category = categories[index];
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchPage(categoryId: category.id),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: SizedBox(
                    width: 82,
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: const Icon(Icons.category_outlined, color: AppColors.primary),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          category.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductDetailBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(ProductDetailRequested(productId)),
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductDetailBloc, ProductDetailState>(
      listener: (context, state) {
        final message = state.errorMessage ?? state.successMessage;
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        final product = state.product;
        return LoadingOverlay(
          isLoading: state.isSubmitting,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Chi tiết sản phẩm'),
              actions: [
                IconButton(
                  tooltip: 'Báo cáo',
                  onPressed: product == null ? null : () => _showReportSheet(context),
                  icon: const Icon(Icons.flag_outlined),
                ),
              ],
            ),
            bottomNavigationBar: product == null
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Chat'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppButton(
                              label: 'Mua ngay',
                              icon: Icons.flash_on,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CheckoutPage(product: product),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            body: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProductDetailState state) {
    final product = state.product;
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && product == null) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () {
          final bloc = context.read<ProductDetailBloc>();
          final id = (bloc.state.product?.id).toString();
          if (id.isNotEmpty) bloc.add(ProductDetailRequested(id));
        },
      );
    }
    if (product == null) {
      return const EmptyState(title: 'Không tìm thấy sản phẩm');
    }

    final imageUrl = product.imageUrls.isEmpty ? null : product.imageUrls.first;
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Hero(
            tag: 'product-image-${product.id}',
            child: imageUrl == null
                ? const ColoredBox(
                    color: AppColors.border,
                    child: Icon(Icons.image_outlined, size: 56),
                  )
                : Image.network(imageUrl, fit: BoxFit.cover),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.title, style: AppTextStyles.screenTitle),
              const SizedBox(height: AppSpacing.sm),
              PriceText(price: product.price),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (product.rating != null) RatingStars(rating: product.rating!),
                  const Spacer(),
                  IconButton(
                    tooltip: product.isLiked ? 'Bỏ thích' : 'Thích',
                    onPressed: () => context.read<ProductDetailBloc>().add(ProductLikeToggled()),
                    icon: Icon(
                      product.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: product.isLiked ? AppColors.danger : AppColors.textSecondary,
                    ),
                  ),
                  Text('${product.likeCount}'),
                ],
              ),
              const Divider(height: 32),
              const SectionHeader(title: 'Mô tả'),
              const SizedBox(height: AppSpacing.sm),
              Text(product.description.isEmpty ? 'Chưa có mô tả.' : product.description),
              const Divider(height: 32),
              const SectionHeader(title: 'Người bán'),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.storefront)),
                title: Text(product.sellerName ?? 'Người bán'),
                subtitle: Text(product.sellerLocation ?? 'Chưa có vị trí'),
              ),
              const Divider(height: 32),
              SectionHeader(
                title: 'Bình luận',
                actionLabel: 'Viết',
                onActionTap: () => _showCommentSheet(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.comments.isEmpty)
                const Text('Chưa có bình luận.')
              else
                ...state.comments.map(
                  (comment) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(comment.author),
                    subtitle: Text(comment.content),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCommentSheet(BuildContext context) {
    final controller = TextEditingController();
    AppBottomSheet.show<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(controller: controller, label: 'Bình luận'),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Gửi bình luận',
            onPressed: () {
              context.read<ProductDetailBloc>().add(ProductCommentSent(controller.text));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    final subjectController = TextEditingController(text: 'Sản phẩm không phù hợp');
    final detailController = TextEditingController();
    AppBottomSheet.show<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(controller: subjectController, label: 'Lý do'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: detailController, label: 'Chi tiết'),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Gửi báo cáo',
            onPressed: () {
              context.read<ProductDetailBloc>().add(
                    ProductReported(
                      subject: subjectController.text,
                      details: detailController.text,
                    ),
                  );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

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
                  ],
                ),
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
              ProductSearchRequested(
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
        context.read<ProductSearchBloc>().add(ProductSearchRefreshed());
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

class ProductListPage extends StatelessWidget {
  final String title;
  final SimpleListLoader loader;

  const ProductListPage({
    super.key,
    required this.title,
    required this.loader,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SimpleListBloc(
        loader: loader,
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(SimpleListRequested()),
      child: SimpleListPage(title: title),
    );
  }
}

class SimpleListPage extends StatefulWidget {
  final String title;
  final Widget? header;
  final String emptyMessage;

  const SimpleListPage({
    super.key,
    required this.title,
    this.header,
    this.emptyMessage = 'Chưa có dữ liệu',
  });

  @override
  State<SimpleListPage> createState() => _SimpleListPageState();
}

class _SimpleListPageState extends State<SimpleListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 240;
    if (_scrollController.position.pixels >= threshold) {
      context.read<SimpleListBloc>().add(SimpleListLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SimpleListBloc, SimpleListState>(
      listener: (context, state) {
        final message = state.errorMessage ?? state.successMessage;
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: state.isSubmitting,
          child: Scaffold(
            appBar: AppBar(title: Text(widget.title)),
            body: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SimpleListState state) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () => context.read<SimpleListBloc>().add(SimpleListRequested()),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(title: widget.emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SimpleListBloc>().add(SimpleListRefreshed());
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = state.items[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
            title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: item.trailing == null ? null : Text(item.trailing!),
          );
        },
      ),
    );
  }
}

class _SimpleListBody extends StatefulWidget {
  final String emptyMessage;

  const _SimpleListBody({required this.emptyMessage});

  @override
  State<_SimpleListBody> createState() => _SimpleListBodyState();
}

class _SimpleListBodyState extends State<_SimpleListBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 240;
    if (_scrollController.position.pixels >= threshold) {
      context.read<SimpleListBloc>().add(SimpleListLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SimpleListBloc, SimpleListState>(
      listener: (context, state) {
        final message = state.errorMessage ?? state.successMessage;
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        if (state.isInitialLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.errorMessage != null && state.items.isEmpty) {
          return ErrorState(
            message: state.errorMessage!,
            onRetry: () => context.read<SimpleListBloc>().add(SimpleListRequested()),
          );
        }
        if (state.items.isEmpty) {
          return EmptyState(title: widget.emptyMessage);
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<SimpleListBloc>().add(SimpleListRefreshed());
          },
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(height: AppSpacing.lg),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return const Center(child: CircularProgressIndicator());
              }
              final item = state.items[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: item.trailing == null ? null : Text(item.trailing!),
              );
            },
          ),
        );
      },
    );
  }
}

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WalletBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(WalletRequested()),
      child: const _WalletView(),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Ví quân nhu')),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.errorMessage != null
                  ? ErrorState(
                      message: state.errorMessage!,
                      onRetry: () => context.read<WalletBloc>().add(WalletRequested()),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.tactical, AppColors.primary],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Số dư khả dụng',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              PriceText(price: state.balance?.available ?? 0),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Đang chờ: ${state.balance?.pending ?? 0}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const SectionHeader(title: 'Lịch sử số dư'),
                        ...state.history.map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.title),
                            subtitle: Text(item.subtitle),
                            trailing: item.trailing == null ? null : Text(item.trailing!),
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<MarketplaceRepository>();
    return ProductListPage(
      title: 'Thông báo',
      loader: (index, count) => repository.getGenericList(
        '/notification/get_notification',
        data: {'group': 0},
        index: index,
        count: count,
      ),
    );
  }
}

class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ConversationListBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(ConversationsRequested()),
      child: const _ConversationListView(),
    );
  }
}

class _ConversationListView extends StatefulWidget {
  const _ConversationListView();

  @override
  State<_ConversationListView> createState() => _ConversationListViewState();
}

class _ConversationListViewState extends State<_ConversationListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 240;
    if (_scrollController.position.pixels >= threshold) {
      context.read<ConversationListBloc>().add(ConversationsLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationListBloc, ConversationState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Tin nhắn')),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ConversationState state) {
    if (state.isInitialLoading) return const Center(child: CircularProgressIndicator());
    if (state.errorMessage != null && state.conversations.isEmpty) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () => context.read<ConversationListBloc>().add(ConversationsRequested()),
      );
    }
    if (state.conversations.isEmpty) {
      return const EmptyState(title: 'Chưa có cuộc trò chuyện');
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ConversationListBloc>().add(ConversationsRefreshed());
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.conversations.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          if (index >= state.conversations.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final conversation = state.conversations[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              child: Icon(conversation.unread ? Icons.mark_chat_unread : Icons.chat_outlined),
            ),
            title: Text(conversation.partnerName),
            subtitle: Text(conversation.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: conversation.unread
                ? const Icon(Icons.circle, size: 10, color: AppColors.primary)
                : null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailPage(conversation: conversation),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  final ConversationModel conversation;

  const ChatDetailPage({super.key, required this.conversation});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
        conversation: widget.conversation,
      )..add(ChatRequested()),
      child: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.conversation.partnerName)),
            body: Column(
              children: [
                if (widget.conversation.productId != null)
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: const Text('Sản phẩm liên quan'),
                    subtitle: Text('Mã sản phẩm: ${widget.conversation.productId}'),
                  ),
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final message = state.messages[index];
                            final isMine = message.senderId == 'me';
                            return Align(
                              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: isMine ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.content,
                                      style: TextStyle(
                                        color: isMine ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (message.isLocalPending || message.isFailed)
                                      Text(
                                        message.isFailed ? 'Gửi lỗi' : 'Đang gửi',
                                        style: TextStyle(
                                          color: isMine ? Colors.white70 : AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _messageController,
                            label: 'Tin nhắn',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton.filled(
                          tooltip: 'Gửi',
                          onPressed: state.isSending
                              ? null
                              : () {
                                  context
                                      .read<ChatBloc>()
                                      .add(ChatMessageSubmitted(_messageController.text));
                                  _messageController.clear();
                                },
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OrderListPage extends StatelessWidget {
  const OrderListPage({super.key});

  static const _tabs = [
    ('Chờ xử lý', 'pending'),
    ('Đã xác nhận', 'confirmed'),
    ('Đang giao', 'shipping'),
    ('Hoàn tất', 'delivered'),
    ('Đã hủy', 'cancelled'),
    ('Hoàn tiền', 'refunded'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn hàng'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Chờ xử lý'),
              Tab(text: 'Đã xác nhận'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Hoàn tất'),
              Tab(text: 'Đã hủy'),
              Tab(text: 'Hoàn tiền'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final tab in _tabs) _OrderStateList(state: tab.$2),
          ],
        ),
      ),
    );
  }
}

class _OrderStateList extends StatelessWidget {
  final String state;

  const _OrderStateList({required this.state});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<MarketplaceRepository>();
    return BlocProvider(
      create: (context) => SimpleListBloc(
        marketplaceRepository: repository,
        loader: (index, count) => repository.getGenericList(
          '/order/get_list_purchases',
          data: {'state': state},
          index: index,
          count: count,
        ),
      )..add(SimpleListRequested()),
      child: const _SimpleListBody(emptyMessage: 'Chưa có đơn hàng'),
    );
  }
}

class AddressListPage extends StatelessWidget {
  const AddressListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddressBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(AddressListRequested()),
      child: const _AddressListView(),
    );
  }
}

class _AddressListView extends StatelessWidget {
  const _AddressListView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddressBloc, AddressState>(
      listener: (context, state) {
        final message = state.successMessage ?? state.errorMessage;
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: state.successMessage != null
                  ? AppColors.success
                  : AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: state.isSubmitting,
          child: Scaffold(
            appBar: AppBar(title: const Text('Địa chỉ giao hàng')),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Thêm'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AddressState state) {
    if (state.isLoading && state.addresses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_outlined, size: 72, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Chưa có địa chỉ nào',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Thêm địa chỉ giao hàng để đặt hàng nhanh hơn',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Thêm địa chỉ mới',
              icon: Icons.add_location_alt,
              onPressed: () => _openForm(context),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AddressBloc>().add(AddressListRequested());
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.addresses.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final address = state.addresses[index];
          return _AddressCard(
            address: address,
            onEdit: () => _openForm(context, address: address),
            onDelete: () => _confirmDelete(context, address),
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {AddressModel? address}) async {
    final bloc = context.read<AddressBloc>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: AddressFormPage(address: address),
        ),
      ),
    );
    if (result == true && context.mounted) {
      bloc.add(AddressListRequested());
    }
  }

  void _confirmDelete(BuildContext context, AddressModel address) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa địa chỉ'),
        content: Text('Bạn có chắc muốn xóa địa chỉ của "${address.receiverName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AddressBloc>().add(AddressDeleted(address.id));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: address.isDefault
            ? const BorderSide(color: AppColors.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      address.receiverName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (address.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Text(
                        'Mặc định',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    address.phone,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      address.fullAddress,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Sửa'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Xóa'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
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
}

class AddressFormPage extends StatefulWidget {
  final AddressModel? address;

  const AddressFormPage({super.key, this.address});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  late final TextEditingController _receiverNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _fullAddressCtrl;
  late final TextEditingController _addressDetailCtrl;
  bool _isDefault = false;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.address != null;

  @override
  void initState() {
    super.initState();
    _receiverNameCtrl = TextEditingController(text: widget.address?.receiverName ?? '');
    _phoneCtrl = TextEditingController(text: widget.address?.phone ?? '');
    _addressCtrl = TextEditingController();
    _fullAddressCtrl = TextEditingController(text: widget.address?.fullAddress ?? '');
    _addressDetailCtrl = TextEditingController();
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _receiverNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _fullAddressCtrl.dispose();
    _addressDetailCtrl.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final receiverName = _receiverNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final fullAddress = _fullAddressCtrl.text.trim();
    final addressDetail = _addressDetailCtrl.text.trim();

    if (receiverName.isEmpty || phone.isEmpty || fullAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ: Tên người nhận, SĐT, Địa chỉ đầy đủ'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final bloc = context.read<AddressBloc>();

    if (_isEditMode) {
      bloc.add(AddressUpdated(
        id: widget.address!.id,
        address: address.isEmpty ? fullAddress : address,
        fullAddress: fullAddress,
        receiverName: receiverName,
        phone: phone,
        isDefault: _isDefault,
        addressDetail: addressDetail.isEmpty ? null : addressDetail,
      ));
    } else {
      bloc.add(AddressAdded(
        address: address.isEmpty ? fullAddress : address,
        fullAddress: fullAddress,
        receiverName: receiverName,
        phone: phone,
        isDefault: _isDefault,
        addressDetail: addressDetail.isEmpty ? null : addressDetail,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddressBloc, AddressState>(
      listener: (context, state) {
        setState(() => _isSubmitting = state.isSubmitting);

        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: LoadingOverlay(
        isLoading: _isSubmitting,
        child: Scaffold(
          appBar: AppBar(
            title: Text(_isEditMode ? 'Sửa địa chỉ' : 'Thêm địa chỉ mới'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _receiverNameCtrl,
                  label: 'Tên người nhận *',
                  hint: 'VD: Nguyễn Văn A',
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _phoneCtrl,
                  label: 'Số điện thoại *',
                  hint: 'VD: 0912345678',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _fullAddressCtrl,
                  label: 'Địa chỉ đầy đủ *',
                  hint: 'VD: 123 Đường ABC, Phường XYZ, Quận 1, TP.HCM',
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _addressCtrl,
                  label: 'Tên địa chỉ (tùy chọn)',
                  hint: 'VD: Nhà riêng, Văn phòng',
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _addressDetailCtrl,
                  label: 'Chi tiết thêm (tùy chọn)',
                  hint: 'VD: Tầng 3, phòng 301',
                ),
                const SizedBox(height: AppSpacing.xl),
                SwitchListTile(
                  value: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value),
                  title: const Text('Đặt làm địa chỉ mặc định'),
                  subtitle: const Text('Tự động chọn khi đặt hàng'),
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: _isEditMode ? 'Cập nhật địa chỉ' : 'Lưu địa chỉ',
                  icon: Icons.save_outlined,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _onSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<MarketplaceRepository>();
    return ProductListPage(
      title: 'Tin tức',
      loader: (index, count) => repository.getNews(index: index, count: count),
    );
  }
}

class SellerListingsPage extends StatelessWidget {
  final String userId;

  const SellerListingsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<MarketplaceRepository>();
    return ProductListPage(
      title: 'Sản phẩm người bán',
      loader: (index, count) => repository.getUserListings(
        userId: userId,
        index: index,
        count: count,
      ),
    );
  }
}

class CheckoutPage extends StatelessWidget {
  final ProductModel product;

  const CheckoutPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CheckoutBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(CheckoutRequested()),
      child: _CheckoutView(product: product),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  final ProductModel product;

  const _CheckoutView({required this.product});

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutBloc, CheckoutState>(
      listener: (context, state) {
        final message = state.errorMessage ?? state.successMessage;
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
        if (state.successMessage != null) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: state.isSubmitting,
          child: Scaffold(
            appBar: AppBar(title: const Text('Thanh toán')),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppButton(
                  label: 'Đặt hàng',
                  icon: Icons.payment,
                  onPressed: () {
                    context.read<CheckoutBloc>().add(
                          CheckoutSubmitted(
                            productId: widget.product.id,
                            quantity: _quantity,
                          ),
                        );
                  },
                ),
              ),
            ),
            body: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CheckoutState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.addresses.isEmpty) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () => context.read<CheckoutBloc>().add(CheckoutRequested()),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SectionHeader(
          title: 'Địa chỉ nhận hàng',
          actionLabel: state.addresses.isNotEmpty ? 'Thêm' : null,
          onActionTap: state.addresses.isNotEmpty ? () => _openAddressForm(context) : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.addresses.isEmpty) ...[
          const EmptyState(
            title: 'Chưa có địa chỉ',
            message: 'Bạn cần thêm địa chỉ trước khi đặt hàng.',
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Thêm địa chỉ mới',
            icon: Icons.add_location_alt,
            onPressed: () => _openAddressForm(context),
          ),
        ] else
          ...state.addresses.map(
            (address) => ListTile(
              onTap: () {
                context.read<CheckoutBloc>().add(CheckoutAddressSelected(address));
              },
              title: Text(address.title),
              subtitle: Text(address.subtitle),
              trailing: Icon(
                state.selectedAddress?.id == address.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: state.selectedAddress?.id == address.id
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Sản phẩm'),
        const SizedBox(height: AppSpacing.sm),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
          title: Text(widget.product.title),
          subtitle: PriceText(price: widget.product.price),
          trailing: _QuantityStepper(
            value: _quantity,
            onChanged: (value) => setState(() => _quantity = value),
          ),
        ),
        const Divider(height: 32),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tổng thanh toán',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            PriceText(price: widget.product.price * _quantity),
          ],
        ),
      ],
    );
  }

  void _openAddressForm(BuildContext context) async {
    final bloc = BlocProvider.of<CheckoutBloc>(context);
    final repository = context.read<MarketplaceRepository>();
    final addressBloc = AddressBloc(marketplaceRepository: repository);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: addressBloc,
          child: const AddressFormPage(),
        ),
      ),
    );
    addressBloc.close();
    if (result == true && context.mounted) {
      bloc.add(CheckoutRequested());
    }
  }
}

class _QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Giảm',
          onPressed: value <= 1 ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value'),
        IconButton(
          tooltip: 'Tăng',
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
