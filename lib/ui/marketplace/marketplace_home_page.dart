import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/marketplace/marketplace_bloc.dart';
import '../../blocs/marketplace/marketplace_event.dart';
import '../../blocs/marketplace/marketplace_state.dart';
import '../../models/marketplace_models.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/gradient_header.dart';
import '../widgets/product_card.dart';
import '../widgets/search_pill.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_product_grid.dart';
import 'marketplace_chat_pages.dart';
import 'marketplace_list_pages.dart';
import 'marketplace_product_pages.dart';
import 'marketplace_shared.dart';

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
                  MaterialPageRoute(builder: (_) => const NotificationListPage()),
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
