import 'package:army_ecommerce/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/core/services/session_manager.dart';
import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/chat/chat_bloc.dart';
import 'package:army_ecommerce/blocs/chat/chat_event.dart';
import 'package:army_ecommerce/ui/chat/chat_screen.dart';
import '../../../blocs/block/block_bloc.dart';
import '../../../blocs/block/block_event.dart';
import '../../../blocs/block/block_state.dart';
import '../../../blocs/follow/follow_bloc.dart';
import '../../../blocs/follow/follow_event.dart';
import '../../../blocs/follow/follow_state.dart';
import '../../../models/user_model.dart';
import '../../../models/api_response.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/block_repository.dart';
import '../../../repositories/follow_repository.dart';
import '../../../repositories/marketplace_repository.dart';
import '../../util/constants/app_colors.dart';
import '../../util/constants/app_radius.dart';
import '../../util/constants/app_spacing.dart';
import '../../util/theme/app_text_styles.dart';
import '../../util/widgets/app_button.dart';
import '../../util/widgets/empty_state.dart';
import '../../util/widgets/error_state.dart';
import '../../util/widgets/product_card.dart';
import '../../util/widgets/section_header.dart';
import '../../util/widgets/login_prompt.dart';
import 'package:army_ecommerce/ui/follow/followers_screen.dart';
import 'package:army_ecommerce/ui/follow/following_screen.dart';
import '../marketplace_shared.dart';
import '../product_form_page.dart';
import '../../util/theme/special_app_theme.dart';
import 'product_detail_page.dart';
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';

class SellerListingsPage extends StatefulWidget {
  final String userId;

  const SellerListingsPage({super.key, required this.userId});

  @override
  State<SellerListingsPage> createState() => _SellerListingsPageState();
}

class _SellerListingsPageState extends State<SellerListingsPage> {
  late final MarketplaceRepository _repository;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List<ProductModel> _products = [];
  int _currentIndex = 0;
  bool _hasReachedEnd = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _repository = context.read<MarketplaceRepository>();
    _scrollController.addListener(_onScroll);
    _loadProducts();
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
      _loadMore();
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _products = [];
      _currentIndex = 0;
      _hasReachedEnd = false;
    });

    try {
      final products = await _repository.getUserListings(
        userId: widget.userId,
        index: 0,
        count: 20,
      );
      if (!mounted) return;
      setState(() {
        _products = products;
        _currentIndex = 1;
        _hasReachedEnd = products.length < 20;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLikeProduct(ProductModel product) async {
    final originalIsLiked = product.isLiked;
    final originalLikeCount = product.likeCount;

    setState(() {
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        final newIsLiked = !originalIsLiked;
        final newLikeCount = newIsLiked
            ? originalLikeCount + 1
            : (originalLikeCount - 1).clamp(0, 999999).toInt();
        _products[index] = _products[index].copyWith(isLiked: newIsLiked, likeCount: newLikeCount);
      }
    });

    try {
      await _repository.likeProduct(product.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = _products[index].copyWith(isLiked: originalIsLiked, likeCount: originalLikeCount);
        }
      });
      AppSnackBar.showError(context, message: e.toString());
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _hasReachedEnd || _isLoading) return;

    setState(() => _isLoadingMore = true);
    try {
      final products = await _repository.getUserListings(
        userId: widget.userId,
        index: _currentIndex,
        count: 20,
      );
      if (!mounted) return;
      setState(() {
        _products = [..._products, ...products];
        _currentIndex += 1;
        _hasReachedEnd = products.length < 20;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.currentUser?.id ?? '';
    final isOwnListings = currentUserId.isNotEmpty && currentUserId.toString() == widget.userId.toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm người bán')),
      floatingActionButton: isOwnListings
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductFormPage(),
                  ),
                );
                if (result == true) {
                  _loadProducts();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm'),
              backgroundColor: context.specialTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _products.isEmpty
              ? ErrorState(
                  message: _error!,
                  onRetry: _loadProducts,
                )
              : _products.isEmpty
                  ? const EmptyState(title: 'Chưa có sản phẩm')
                  : RefreshIndicator(
                      onRefresh: () async => _loadProducts(),
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.lg,
                              AppSpacing.lg,
                              AppSpacing.lg,
                            ),
                            sliver: SliverGrid.builder(
                              itemCount: _products.length + (_isLoadingMore ? 1 : 0),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: AppSpacing.md,
                                crossAxisSpacing: AppSpacing.md,
                                childAspectRatio: 0.51,
                              ),
                              itemBuilder: (context, index) {
                                if (index >= _products.length) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final product = _products[index];
                                return ProductCard(
                                  product: productCardDataFromModel(product),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailPage(productId: product.id, isStock: product.isStock),
                                    ),
                                  ).then((_) => _loadProducts()),
                                  onLikeTap: () => _toggleLikeProduct(product),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class SellerInfoPage extends StatefulWidget {
  final String userId;
  final String? productId;
  final String sellerName;
  final String? avatarUrl;
  final String? sellerScore;
  final String? sellerListing;

  const SellerInfoPage({
    super.key,
    required this.userId,
    this.productId,
    required this.sellerName,
    this.avatarUrl,
    this.sellerScore,
    this.sellerListing,
  });

  @override
  State<SellerInfoPage> createState() => _SellerInfoPageState();
}

class _SellerInfoPageState extends State<SellerInfoPage> {
  bool _isLoading = true;
  String? _error;
  UserModel? _user;
  int _followersCount = 0;
  int _followingCount = 0;

  String get _sellerUserId {
    final loadedUserId = _user?.id;
    return loadedUserId != null && loadedUserId.isNotEmpty ? loadedUserId : widget.userId;
  }

  late final FollowBloc _followBloc;
  late final BlockBloc _blockBloc;
  late final ChatBloc _chatBloc;
  bool _isFollowed = false;
  bool _isBlocked = false;

  late final ScrollController _scrollController;
  List<ProductModel> _products = [];
  bool _isLoadingProducts = false;
  int _currentIndex = 0;
  bool _hasReachedEnd = false;

  @override
  void initState() {
    super.initState();
    _followBloc = FollowBloc(followRepository: context.read<FollowRepository>());
    _blockBloc = BlockBloc(blockRepository: context.read<BlockRepository>());
    _chatBloc = ChatBloc(marketplaceRepository: context.read<MarketplaceRepository>());
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadUser();
  }

  @override
  void dispose() {
    _followBloc.close();
    _blockBloc.close();
    _chatBloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 320;
    if (_scrollController.position.pixels >= threshold) {
      _loadMoreProducts();
    }
  }

  void _showZoomedAvatar(BuildContext context, String imageUrl, String name) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image(
                  image: SessionManager.getImageProvider(imageUrl),
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white, size: 80),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _products = [];
      _currentIndex = 0;
      _hasReachedEnd = false;
      _isLoadingProducts = true;
    });

    final authRepo = context.read<AuthRepository>();
    final marketRepo = context.read<MarketplaceRepository>();
    try {
      final token = await SessionManager.getToken();
      final isGuest = token == null || token.isEmpty;

      if (isGuest) {
        final productsResponse = await marketRepo.getUserListings(
          userId: _sellerUserId,
          index: 0,
          count: 20,
        );
        if (!mounted) return;
        setState(() {
          _products = productsResponse;
          _currentIndex = 1;
          _hasReachedEnd = productsResponse.length < 20;
          _isFollowed = false;
          _isBlocked = false;
          _isLoading = false;
          _isLoadingProducts = false;
        });
      } else {
        final results = await Future.wait([
          authRepo.getUserInfo(token: token, userId: _sellerUserId),
          marketRepo.getUserListings(userId: _sellerUserId, index: 0, count: 20),
        ]);

        final userResponse = results[0] as ApiResponse<UserModel>;
        final productsResponse = results[1] as List<ProductModel>;

        if (userResponse.data != null) {
          if (!mounted) return;
          setState(() {
            _user = userResponse.data;
            _products = productsResponse;
            _currentIndex = 1;
            _hasReachedEnd = productsResponse.length < 20;
            _isFollowed = userResponse.data!.followed ?? false;
            _isBlocked = userResponse.data!.isBlocked ?? false;
            _followersCount = userResponse.data!.followers ?? 0;
            _followingCount = userResponse.data!.following ?? 0;
            _isLoading = false;
            _isLoadingProducts = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            _error = userResponse.message.isNotEmpty ? userResponse.message : 'Không tìm thấy người dùng.';
            _isLoading = false;
            _isLoadingProducts = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingProducts || _hasReachedEnd || _isLoading) return;
    setState(() => _isLoadingProducts = true);
    try {
      final marketRepo = context.read<MarketplaceRepository>();
      final more = await marketRepo.getUserListings(
        userId: _sellerUserId,
        index: _currentIndex,
        count: 20,
      );
      if (!mounted) return;
      setState(() {
        _products.addAll(more);
        _currentIndex++;
        _hasReachedEnd = more.length < 20;
        _isLoadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _toggleLikeProduct(ProductModel product) async {
    final originalIsLiked = product.isLiked;
    final originalLikeCount = product.likeCount;

    setState(() {
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        final newIsLiked = !originalIsLiked;
        final newLikeCount = newIsLiked
            ? originalLikeCount + 1
            : (originalLikeCount - 1).clamp(0, 999999).toInt();
        _products[index] = _products[index].copyWith(isLiked: newIsLiked, likeCount: newLikeCount);
      }
    });

    try {
      final repo = context.read<MarketplaceRepository>();
      await repo.likeProduct(product.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = _products[index].copyWith(isLiked: originalIsLiked, likeCount: originalLikeCount);
        }
      });
      AppSnackBar.showError(context, message: e.toString());
    }
  }

  void _toggleFollow() {
    if (_isBlocked) {
      AppSnackBar.showError(context, message: 'Bạn đã chặn người dùng này, không thể thực hiện thao tác.');
      return;
    }
    final authState = context.read<AuthBloc>().state;
    final token = authState.currentUser?.token ?? '';
    if (checkLogin(context, token: token)) {
      if (_isFollowed) {
        _showUnfollowDialog();
      } else {
        setState(() {
          _isFollowed = true;
          _followersCount++;
        });
        _followBloc.add(FollowUserRequested(
          followeeId: _sellerUserId,
          username: widget.sellerName,
          action: 'follow',
        ));
      }
    }
  }

  Future<void> _showUnfollowDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Hủy theo dõi'),
        content: Text('Bỏ theo dõi "${widget.sellerName}"?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: context.specialTheme.primaryColor),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _isFollowed = false;
        _followersCount = (_followersCount - 1).clamp(0, 999999);
      });
      _followBloc.add(FollowUserRequested(
        followeeId: _sellerUserId,
        username: widget.sellerName,
        action: 'unfollow',
      ));
    }
  }

  void _toggleBlock() {
    final authState = context.read<AuthBloc>().state;
    final token = authState.currentUser?.token ?? '';
    if (checkLogin(context, token: token)) {
      if (_isBlocked) {
        _showUnblockDialog();
      } else {
        _showBlockDialog();
      }
    }
  }

  Future<void> _showBlockDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Chặn người dùng'),
        content: Text(
          'Chặn "${widget.sellerName}"? Người này sẽ không thể xem trang cá nhân hay liên hệ với bạn.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
            child: const Text('Chặn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _isBlocked = true;
        if (_isFollowed) {
          _isFollowed = false;
          _followersCount = (_followersCount - 1).clamp(0, 999999);
        }
      });
      _blockBloc.add(BlockUserRequested(
        userId: _sellerUserId,
        username: widget.sellerName,
        action: 'block',
      ));
    }
  }

  Future<void> _showUnblockDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Bỏ chặn người dùng'),
        content: Text(
          'Bỏ chặn "${widget.sellerName}"? Người này sẽ có thể xem trang và liên hệ với bạn.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: context.specialTheme.primaryColor),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _isBlocked = false);
      _blockBloc.add(BlockUserRequested(
        userId: _sellerUserId,
        username: widget.sellerName,
        action: 'unblock',
      ));
    }
  }

  void _openChat() {
    if (_isBlocked) {
      AppSnackBar.showError(context, message: 'Bạn đã chặn người dùng này, không thể thực hiện thao tác.');
      return;
    }
    final authState = context.read<AuthBloc>().state;
    final token = authState.currentUser?.token ?? '';
    if (checkLogin(context, token: token)) {
      if (_isBlocked) {
        AppSnackBar.showError(context, message: 'Bạn đã chặn người này, không thể thực hiện thao tác.');
        return;
      }
      final currentUserId = authState.currentUser?.id ?? '';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: _chatBloc,
            child: ChatScreen(
              partnerId: _sellerUserId,
              partnerUsername: _user?.username ?? widget.sellerName,
              partnerAvatar: _user?.avatar ?? widget.avatarUrl,
              currentUserId: currentUserId,
              productId: null,
            ),
          ),
        ),
      ).then((_) {
        if (mounted && token.isNotEmpty) {
          _chatBloc.add(LoadConversationsRequested());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayAvatar = _user?.avatar ?? widget.avatarUrl;
    final displayName = _user?.username ?? widget.sellerName;
    final displayListing = _user?.listing?.toString() ?? widget.sellerListing;
    final displayScore = widget.sellerScore;

    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.currentUser?.id ?? '';
    final isMe = _sellerUserId == currentUserId && currentUserId.isNotEmpty;
    final isGuest = !authState.isAuthenticated;

    final hasSellerInfo = _user != null && (
      (_user!.email ?? '').trim().isNotEmpty ||
      (_user!.phoneNumber ?? '').trim().isNotEmpty ||
      (_user!.address ?? '').trim().isNotEmpty ||
      (_user!.city ?? '').trim().isNotEmpty ||
      (_user!.status ?? '').trim().isNotEmpty ||
      (_user!.firstName ?? '').trim().isNotEmpty ||
      (_user!.lastName ?? '').trim().isNotEmpty
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _followBloc),
        BlocProvider.value(value: _blockBloc),
        BlocProvider.value(value: _chatBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<FollowBloc, FollowState>(
            listenWhen: (_, current) =>
                current is FollowActionSuccess || current is FollowFailure,
            listener: (context, state) {
              if (state is FollowActionSuccess) {
                setState(() {
                  _isFollowed = state.isFollowed;
                  // sync counters if the state returns it, or keep our optimistic values
                });
                final msg = state.isFollowed
                    ? 'Theo dõi ${state.username} thành công'
                    : 'Đã hủy theo dõi ${state.username}';
                AppSnackBar.show(context, message: msg, backgroundColor: context.specialTheme.primaryColor);
              } else if (state is FollowFailure) {
                // Revert optimistic counts
                setState(() {
                  _isFollowed = !_isFollowed;
                  if (_isFollowed) {
                    _followersCount++;
                  } else {
                    _followersCount = (_followersCount - 1).clamp(0, 999999);
                  }
                });
                AppSnackBar.showError(context, message: 'Lỗi: ${state.error}');
              }
            },
          ),
          BlocListener<BlockBloc, BlockState>(
            listenWhen: (_, current) =>
                current is BlockActionSuccess || current is BlockFailure,
            listener: (context, state) {
              if (state is BlockActionSuccess) {
                setState(() {
                  _isBlocked = state.isBlocked;
                  if (state.isBlocked) {
                    if (_isFollowed) {
                      _isFollowed = false;
                      _followersCount = (_followersCount - 1).clamp(0, 999999);
                    }
                  }
                });
                final msg = state.isBlocked
                    ? 'Đã chặn ${state.username}'
                    : 'Đã bỏ chặn ${state.username}';
                AppSnackBar.show(context, message: msg);
              } else if (state is BlockFailure) {
                setState(() {
                  _isBlocked = !_isBlocked;
                });
                _loadUser();
                AppSnackBar.showError(context, message: 'Lỗi: ${state.error}');
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBar(title: Text(displayName)),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ErrorState(
                      message: _error!,
                      onRetry: _loadUser,
                    )
                  : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (displayAvatar != null && displayAvatar.isNotEmpty) {
                                  _showZoomedAvatar(context, displayAvatar, displayName);
                                }
                              },
                              child: displayAvatar != null && displayAvatar.isNotEmpty
                                  ? CircleAvatar(radius: 36, backgroundImage: SessionManager.getImageProvider(displayAvatar))
                                  : const CircleAvatar(radius: 36, child: Icon(Icons.storefront)),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayName, style: AppTextStyles.screenTitle),
                                  const SizedBox(height: AppSpacing.xs),
                                  if (displayScore != null && displayScore.isNotEmpty) Text('Điểm: $displayScore'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem('Đơn đã bán', int.tryParse(displayListing ?? '0') ?? 0),
                              _buildStatItem(
                                'Người theo dõi',
                                _followersCount,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BlocProvider(
                                        create: (_) => FollowBloc(
                                          followRepository: context.read<FollowRepository>(),
                                        ),
                                        child: FollowersScreen(
                                          userId: _sellerUserId,
                                        ),
                                      ),
                                    ),
                                  ).then((_) {
                                    if (mounted) {
                                      _loadUser();
                                    }
                                  });
                                },
                              ),
                              _buildStatItem(
                                'Đang theo dõi',
                                _followingCount,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BlocProvider(
                                        create: (_) => FollowBloc(
                                          followRepository: context.read<FollowRepository>(),
                                        ),
                                        child: FollowingScreen(
                                          userId: _sellerUserId,
                                        ),
                                      ),
                                    ),
                                  ).then((_) {
                                    if (mounted) {
                                      _loadUser();
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (isMe) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: AppColors.primary),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Đây là trang cửa hàng của bạn. Bạn không thể tự nhắn tin, theo dõi hoặc tự chặn chính mình.',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ] else if (isGuest) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.grey),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Bạn đang ở chế độ khách. Đăng nhập để nhắn tin, theo dõi hoặc chặn người bán này.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        AppButton(
                          label: 'Chat',
                          icon: Icons.chat_bubble_outline,
                          onPressed: isMe ? null : _openChat,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _SellerActionButton(
                                label: _isFollowed ? 'Đang theo dõi' : 'Theo dõi',
                                icon: _isFollowed ? Icons.check : Icons.person_add_outlined,
                                isActive: _isFollowed,
                                activeColor: context.specialTheme.primaryColor,
                                onTap: isMe ? null : _toggleFollow,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _SellerActionButton(
                                label: _isBlocked ? 'Đã chặn' : 'Chặn',
                                icon: Icons.block,
                                isActive: _isBlocked,
                                activeColor: Colors.black87,
                                onTap: isMe ? null : _toggleBlock,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const SectionHeader(title: 'Thông tin người bán'),
                        const SizedBox(height: AppSpacing.sm),
                        if (hasSellerInfo) ...[
                          if ((_user!.email ?? '').isNotEmpty) _MetaRow(label: 'Email', value: _user!.email!),
                          if ((_user!.phoneNumber ?? '').isNotEmpty) _MetaRow(label: 'Số điện thoại', value: _user!.phoneNumber!),
                          if ((_user!.address ?? '').isNotEmpty) _MetaRow(label: 'Địa chỉ', value: _user!.address!),
                          if ((_user!.city ?? '').isNotEmpty) _MetaRow(label: 'Thành phố', value: _user!.city!),
                          if ((_user!.status ?? '').isNotEmpty) _MetaRow(label: 'Trạng thái', value: _user!.status!),
                          if ((_user!.firstName ?? '').isNotEmpty || (_user!.lastName ?? '').isNotEmpty)
                            _MetaRow(label: 'Tên', value: '${_user!.firstName ?? ''} ${_user!.lastName ?? ''}'.trim()),
                        ] else
                          const Text(
                            'Người này lười lắm, không để lại thông tin gì.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        const Divider(height: 32),
                        const SectionHeader(title: 'Sản phẩm đang bán'),
                        const SizedBox(height: AppSpacing.sm),
                        if (_products.isEmpty && !_isLoadingProducts)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                            child: Text(
                              'Chưa đăng bán sản phẩm nào.',
                              style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                            ),
                          )
                        else ...[
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _products.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppSpacing.md,
                              crossAxisSpacing: AppSpacing.md,
                              childAspectRatio: 0.51,
                            ),
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              return ProductCard(
                                product: productCardDataFromModel(product),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailPage(productId: product.id, isStock: product.isStock),
                                  ),
                                ),
                                onLikeTap: () => _toggleLikeProduct(product),
                              );
                            },
                          ),
                          if (_isLoadingProducts)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, {VoidCallback? onTap}) {
    final item = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
    if (onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: item,
      );
    }
    return item;
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SellerActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;

  const _SellerActionButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final specialTheme = context.specialTheme;
    final isThemePrimary = activeColor == AppColors.primary || activeColor == specialTheme.primaryColor;

    Gradient? bgGradient;
    Color? bgSolidColor;
    Color borderClr;

    if (isDisabled) {
      bgSolidColor = Colors.grey[200];
      borderClr = Colors.grey[300]!;
    } else if (isActive) {
      if (isThemePrimary && specialTheme.useGradient) {
        bgGradient = specialTheme.primaryGradient;
        borderClr = Colors.transparent;
      } else {
        bgSolidColor = activeColor;
        borderClr = activeColor;
      }
    } else {
      bgSolidColor = Colors.white;
      borderClr = Colors.grey[400]!;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bgSolidColor,
          gradient: bgGradient,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: borderClr == Colors.transparent
              ? null
              : Border.all(
                  color: borderClr,
                  width: 1,
                ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDisabled
                  ? Colors.grey[400]
                  : (isActive ? Colors.white : Colors.grey[700]),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDisabled
                    ? Colors.grey[400]
                    : (isActive ? Colors.white : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
