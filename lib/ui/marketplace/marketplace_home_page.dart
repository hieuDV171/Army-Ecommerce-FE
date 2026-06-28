import 'package:army_ecommerce/blocs/chat/chat_bloc.dart';
import 'package:army_ecommerce/blocs/chat/chat_event.dart';
import 'package:army_ecommerce/blocs/chat/chat_state.dart';
import 'package:army_ecommerce/blocs/marketplace/home/home_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/home/home_event.dart';
import 'package:army_ecommerce/blocs/marketplace/home/home_state.dart';
import 'package:army_ecommerce/models/category_model.dart';
import 'package:army_ecommerce/models/product_model.dart';
import 'package:army_ecommerce/ui/chat/conversation_list_screen.dart';
import 'package:army_ecommerce/ui/util/widgets/login_prompt.dart';
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../util/constants/app_radius.dart';
import '../util/constants/app_spacing.dart';
import '../util/theme/special_app_theme.dart';
import '../util/widgets/empty_state.dart';
import '../util/widgets/error_state.dart';
import '../util/widgets/gradient_header.dart';
import '../util/widgets/product_card.dart';
import '../util/widgets/search_pill.dart';
import '../util/widgets/section_header.dart';
import '../util/widgets/shimmer_product_grid.dart';
import 'list/wallet_page.dart';
import 'product/product_detail_page.dart';
import 'product/product_search_page.dart';
import 'marketplace_shared.dart';

class MarketplaceHomeBody extends StatefulWidget {
  final String username;
  final String? avatarUrl;
  final String userId;
  final String token;

  const MarketplaceHomeBody({
    super.key,
    required this.username,
    this.avatarUrl,
    required this.userId,
    required this.token,
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
          AppSnackBar.showError(context, message: state.errorMessage!);
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
                child: _HomeHeader(
                  username: widget.username,
                  userId: widget.userId,
                  token: widget.token,
                ),
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
                  child: SectionHeader(title: 'Gợi ý hôm nay'),
                ),
              ),
              if (state.products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      child: EmptyState(
                        title: 'Chưa có sản phẩm nào',
                        message:
                            'Hệ thống chưa có dữ liệu sản phẩm.\nKéo xuống để thử tải lại.',
                      ),
                    ),
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.51,
                        ),
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return ProductCard(
                        product: productCardDataFromModel(product),
                        onTap: () => _openProduct(context, product),
                        onLikeTap: () {
                          context.read<HomeBloc>().add(
                            HomeProductLikeToggled(product.id),
                          );
                        },
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

  void _openProduct(BuildContext context, ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailPage(productId: product.id, isStock: product.isStock),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String username;
  final String userId;
  final String token;

  const _HomeHeader({
    required this.username,
    required this.userId,
    required this.token,
  });

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

              // Icon chat với badge số tin nhắn chưa đọc
              BlocBuilder<ChatBloc, ChatState>(
                builder: (ctx, chatState) {
                  final unread = ctx.read<ChatBloc>().numNewMessage;
                  return IconButton(
                    tooltip: 'Tin nhắn',
                    onPressed: () {
                      if (checkLogin(ctx, token: token)) {
                        final chatBloc = ctx.read<ChatBloc>();
                        Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: chatBloc,
                              child: ConversationListScreen(
                                currentUserId: userId,
                              ),
                            ),
                          ),
                        ).then((_) {
                          // Làm mới badge khi quay lại từ màn hình chat
                          if (ctx.mounted && token.isNotEmpty) {
                            chatBloc.add(
                              LoadConversationsRequested(isSilent: true),
                            );
                          }
                        });
                      }
                    },
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white,
                        ),
                        if (unread > 0)
                          Positioned(
                            right: -6,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 255, 0, 0),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                              constraints: const BoxConstraints(minWidth: 16),
                              child: Text(
                                unread > 99 ? '99+' : '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SearchPill(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SearchPage(autofocus: true),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: () {
              if (checkLogin(context, token: token)) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletPage()),
                );
              }
            },
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
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
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

class _HomeCategories extends StatefulWidget {
  final List<CategoryModel> categories;

  const _HomeCategories({required this.categories});

  @override
  State<_HomeCategories> createState() => _HomeCategoriesState();
}

class _HomeCategoriesState extends State<_HomeCategories> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent * 0.8;
    if (_scrollController.position.pixels >= threshold) {
      context.read<HomeBloc>().add(HomeLoadMoreCategoriesRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Danh mục tác chiến'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 96,
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                return ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      widget.categories.length +
                      (state.isLoadingMoreCategories ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index >= widget.categories.length) {
                      return const SizedBox(
                        width: 50,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final category = widget.categories[index];
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
                            (() {
                              final specialTheme = context.specialTheme;
                              final iconWidget = Icon(
                                Icons.category_outlined,
                                color: specialTheme.useGradient
                                    ? Colors.white
                                    : specialTheme.primaryColor,
                              );
                              return Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: specialTheme.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                ),
                                child: Center(
                                  child: specialTheme.useGradient
                                      ? ShaderMask(
                                          shaderCallback: (bounds) =>
                                              specialTheme.primaryGradient!
                                                  .createShader(bounds),
                                          child: iconWidget,
                                        )
                                      : iconWidget,
                                ),
                              );
                            }()),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
