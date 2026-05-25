import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/marketplace_models.dart';
import '../../repositories/marketplace_repository.dart';

abstract class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeRequested extends HomeEvent {}

class HomeRefreshed extends HomeEvent {}

class HomeLoadMoreRequested extends HomeEvent {}

class HomeState extends Equatable {
  final List<CategoryModel> categories;
  final List<ProductModel> products;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final String? errorMessage;
  final int index;
  final int count;

  const HomeState({
    this.categories = const [],
    this.products = const [],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.errorMessage,
    this.index = 0,
    this.count = 20,
  });

  bool get isEmpty => !isInitialLoading && products.isEmpty;

  HomeState copyWith({
    List<CategoryModel>? categories,
    List<ProductModel>? products,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    String? errorMessage,
    bool clearError = false,
    int? index,
    int? count,
  }) {
    return HomeState(
      categories: categories ?? this.categories,
      products: products ?? this.products,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      index: index ?? this.index,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        products,
        isInitialLoading,
        isRefreshing,
        isLoadingMore,
        hasReachedEnd,
        errorMessage,
        index,
        count,
      ];
}

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final MarketplaceRepository marketplaceRepository;

  HomeBloc({required this.marketplaceRepository}) : super(const HomeState()) {
    on<HomeRequested>(_onRequested);
    on<HomeRefreshed>(_onRefreshed);
    on<HomeLoadMoreRequested>(_onLoadMoreRequested);
  }

  Future<void> _onRequested(HomeRequested event, Emitter<HomeState> emit) async {
    emit(state.copyWith(isInitialLoading: true, clearError: true, index: 0));
    try {
      final categories = await marketplaceRepository.getCategories(parentId: 0);
      final products = await marketplaceRepository.getProducts(index: 0, count: state.count);
      emit(
        state.copyWith(
          categories: categories,
          products: _deduplicateProducts(products),
          isInitialLoading: false,
          hasReachedEnd: products.length < state.count,
          index: products.length,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isInitialLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onRefreshed(HomeRefreshed event, Emitter<HomeState> emit) async {
    emit(state.copyWith(isRefreshing: true, clearError: true, index: 0));
    try {
      final categories = await marketplaceRepository.getCategories(parentId: 0);
      final products = await marketplaceRepository.getProducts(index: 0, count: state.count);
      emit(
        state.copyWith(
          categories: categories,
          products: _deduplicateProducts(products),
          isRefreshing: false,
          hasReachedEnd: products.length < state.count,
          index: products.length,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isRefreshing: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onLoadMoreRequested(
    HomeLoadMoreRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedEnd || state.isInitialLoading) return;

    emit(state.copyWith(isLoadingMore: true, clearError: true));
    try {
      final products = await marketplaceRepository.getProducts(
        index: state.index,
        count: state.count,
      );
      final merged = _deduplicateProducts([...state.products, ...products]);
      emit(
        state.copyWith(
          products: merged,
          isLoadingMore: false,
          hasReachedEnd: products.length < state.count,
          index: merged.length,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: error.toString()));
    }
  }

  List<ProductModel> _deduplicateProducts(List<ProductModel> products) {
    final map = <String, ProductModel>{};
    for (final product in products) {
      map[product.id] = product;
    }
    return map.values.toList();
  }
}

abstract class ProductDetailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductDetailRequested extends ProductDetailEvent {
  final String productId;

  ProductDetailRequested(this.productId);

  @override
  List<Object?> get props => [productId];
}

class ProductLikeToggled extends ProductDetailEvent {}

class ProductCommentSent extends ProductDetailEvent {
  final String content;

  ProductCommentSent(this.content);

  @override
  List<Object?> get props => [content];
}

class ProductReported extends ProductDetailEvent {
  final String subject;
  final String details;

  ProductReported({required this.subject, required this.details});

  @override
  List<Object?> get props => [subject, details];
}

class ProductDetailState extends Equatable {
  final ProductModel? product;
  final List<CommentModel> comments;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const ProductDetailState({
    this.product,
    this.comments = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  ProductDetailState copyWith({
    ProductModel? product,
    List<CommentModel>? comments,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return ProductDetailState(
      product: product ?? this.product,
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        product,
        comments,
        isLoading,
        isSubmitting,
        errorMessage,
        successMessage,
      ];
}

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final MarketplaceRepository marketplaceRepository;
  String? _productId;

  ProductDetailBloc({required this.marketplaceRepository})
      : super(const ProductDetailState()) {
    on<ProductDetailRequested>(_onRequested);
    on<ProductLikeToggled>(_onLikeToggled);
    on<ProductCommentSent>(_onCommentSent);
    on<ProductReported>(_onReported);
  }

  Future<void> _onRequested(
    ProductDetailRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    _productId = event.productId;
    emit(state.copyWith(isLoading: true, clearMessages: true));
    try {
      final product = await marketplaceRepository.getProductDetail(event.productId);
      final comments = await marketplaceRepository.getComments(event.productId);
      emit(
        state.copyWith(
          product: product,
          comments: comments,
          isLoading: false,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onLikeToggled(
    ProductLikeToggled event,
    Emitter<ProductDetailState> emit,
  ) async {
    final product = state.product;
    if (product == null) return;

    final optimistic = product.copyWith(
      isLiked: !product.isLiked,
      likeCount: product.likeCount + (product.isLiked ? -1 : 1),
    );
    emit(state.copyWith(product: optimistic, clearMessages: true));

    try {
      await marketplaceRepository.likeProduct(product.id);
    } catch (error) {
      emit(state.copyWith(product: product, errorMessage: error.toString()));
    }
  }

  Future<void> _onCommentSent(
    ProductCommentSent event,
    Emitter<ProductDetailState> emit,
  ) async {
    final productId = _productId;
    if (productId == null || event.content.trim().isEmpty) return;

    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    try {
      await marketplaceRepository.sendComment(productId, event.content.trim());
      final comments = await marketplaceRepository.getComments(productId);
      emit(
        state.copyWith(
          comments: comments,
          isSubmitting: false,
          successMessage: 'Đã gửi bình luận',
        ),
      );
    } catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onReported(
    ProductReported event,
    Emitter<ProductDetailState> emit,
  ) async {
    final productId = _productId;
    if (productId == null) return;

    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    try {
      await marketplaceRepository.reportProduct(productId, event.subject, event.details);
      emit(
        state.copyWith(
          isSubmitting: false,
          successMessage: 'Đã gửi báo cáo sản phẩm',
        ),
      );
    } catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.toString()));
    }
  }
}

abstract class ProductSearchEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductSearchRequested extends ProductSearchEvent {
  final String keyword;
  final String? categoryId;
  final String? brandId;
  final num? priceMin;
  final num? priceMax;

  ProductSearchRequested({
    this.keyword = '',
    this.categoryId,
    this.brandId,
    this.priceMin,
    this.priceMax,
  });

  @override
  List<Object?> get props => [keyword, categoryId, brandId, priceMin, priceMax];
}

class ProductSearchRefreshed extends ProductSearchEvent {}

class ProductSearchLoadMoreRequested extends ProductSearchEvent {}

class ProductSearchState extends Equatable {
  final List<ProductModel> products;
  final String keyword;
  final String? categoryId;
  final String? brandId;
  final num? priceMin;
  final num? priceMax;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final String? errorMessage;
  final int index;
  final int count;

  const ProductSearchState({
    this.products = const [],
    this.keyword = '',
    this.categoryId,
    this.brandId,
    this.priceMin,
    this.priceMax,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.errorMessage,
    this.index = 0,
    this.count = 20,
  });

  ProductSearchState copyWith({
    List<ProductModel>? products,
    String? keyword,
    String? categoryId,
    String? brandId,
    num? priceMin,
    num? priceMax,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    String? errorMessage,
    int? index,
    int? count,
    bool clearError = false,
  }) {
    return ProductSearchState(
      products: products ?? this.products,
      keyword: keyword ?? this.keyword,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      index: index ?? this.index,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props => [
        products,
        keyword,
        categoryId,
        brandId,
        priceMin,
        priceMax,
        isInitialLoading,
        isRefreshing,
        isLoadingMore,
        hasReachedEnd,
        errorMessage,
        index,
        count,
      ];
}

class ProductSearchBloc extends Bloc<ProductSearchEvent, ProductSearchState> {
  final MarketplaceRepository marketplaceRepository;

  ProductSearchBloc({required this.marketplaceRepository})
      : super(const ProductSearchState()) {
    on<ProductSearchRequested>(_onRequested);
    on<ProductSearchRefreshed>(_onRefreshed);
    on<ProductSearchLoadMoreRequested>(_onLoadMoreRequested);
  }

  Future<void> _onRequested(
    ProductSearchRequested event,
    Emitter<ProductSearchState> emit,
  ) async {
    emit(
      state.copyWith(
        keyword: event.keyword,
        categoryId: event.categoryId,
        brandId: event.brandId,
        priceMin: event.priceMin,
        priceMax: event.priceMax,
        products: const [],
        index: 0,
        isInitialLoading: true,
        hasReachedEnd: false,
        clearError: true,
      ),
    );
    await _loadPage(emit, index: 0, replace: true);
  }

  Future<void> _onRefreshed(
    ProductSearchRefreshed event,
    Emitter<ProductSearchState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, index: 0, clearError: true));
    await _loadPage(emit, index: 0, replace: true);
  }

  Future<void> _onLoadMoreRequested(
    ProductSearchLoadMoreRequested event,
    Emitter<ProductSearchState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedEnd || state.isInitialLoading) return;
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    await _loadPage(emit, index: state.index, replace: false);
  }

  Future<void> _loadPage(
    Emitter<ProductSearchState> emit, {
    required int index,
    required bool replace,
  }) async {
    try {
      final products = await marketplaceRepository.searchProducts(
        keyword: state.keyword,
        categoryId: state.categoryId,
        brandId: state.brandId,
        priceMin: state.priceMin,
        priceMax: state.priceMax,
        index: index,
        count: state.count,
      );
      final merged = replace ? products : _deduplicate([...state.products, ...products]);
      emit(
        state.copyWith(
          products: merged,
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          hasReachedEnd: products.length < state.count,
          index: merged.length,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  List<ProductModel> _deduplicate(List<ProductModel> products) {
    final map = <String, ProductModel>{};
    for (final product in products) {
      map[product.id] = product;
    }
    return map.values.toList();
  }
}

abstract class SimpleListEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SimpleListRequested extends SimpleListEvent {}

class SimpleListRefreshed extends SimpleListEvent {}

class SimpleListLoadMoreRequested extends SimpleListEvent {}

class SimpleActionRequested extends SimpleListEvent {
  final String path;
  final Map<String, dynamic> data;

  SimpleActionRequested({required this.path, required this.data});

  @override
  List<Object?> get props => [path, data];
}

class SimpleListState extends Equatable {
  final List<MarketplaceItem> items;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isSubmitting;
  final bool hasReachedEnd;
  final String? errorMessage;
  final String? successMessage;
  final int index;
  final int count;

  const SimpleListState({
    this.items = const [],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.hasReachedEnd = false,
    this.errorMessage,
    this.successMessage,
    this.index = 0,
    this.count = 20,
  });

  SimpleListState copyWith({
    List<MarketplaceItem>? items,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isSubmitting,
    bool? hasReachedEnd,
    String? errorMessage,
    String? successMessage,
    int? index,
    int? count,
    bool clearMessages = false,
  }) {
    return SimpleListState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
      index: index ?? this.index,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props => [
        items,
        isInitialLoading,
        isRefreshing,
        isLoadingMore,
        isSubmitting,
        hasReachedEnd,
        errorMessage,
        successMessage,
        index,
        count,
      ];
}

typedef SimpleListLoader = Future<List<MarketplaceItem>> Function(int index, int count);

class SimpleListBloc extends Bloc<SimpleListEvent, SimpleListState> {
  final SimpleListLoader loader;
  final MarketplaceRepository marketplaceRepository;

  SimpleListBloc({
    required this.loader,
    required this.marketplaceRepository,
  }) : super(const SimpleListState()) {
    on<SimpleListRequested>(_onRequested);
    on<SimpleListRefreshed>(_onRefreshed);
    on<SimpleListLoadMoreRequested>(_onLoadMoreRequested);
    on<SimpleActionRequested>(_onActionRequested);
  }

  Future<void> _onRequested(
    SimpleListRequested event,
    Emitter<SimpleListState> emit,
  ) async {
    emit(state.copyWith(isInitialLoading: true, index: 0, clearMessages: true));
    try {
      final items = await loader(0, state.count);
      emit(
        state.copyWith(
          items: _deduplicateItems(items),
          isInitialLoading: false,
          hasReachedEnd: items.length < state.count,
          index: items.length,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isInitialLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onRefreshed(
    SimpleListRefreshed event,
    Emitter<SimpleListState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, index: 0, clearMessages: true));
    try {
      final items = await loader(0, state.count);
      emit(
        state.copyWith(
          items: _deduplicateItems(items),
          isRefreshing: false,
          hasReachedEnd: items.length < state.count,
          index: items.length,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isRefreshing: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onLoadMoreRequested(
    SimpleListLoadMoreRequested event,
    Emitter<SimpleListState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedEnd || state.isInitialLoading) return;

    emit(state.copyWith(isLoadingMore: true, clearMessages: true));
    try {
      final items = await loader(state.index, state.count);
      final merged = _deduplicateItems([...state.items, ...items]);
      emit(
        state.copyWith(
          items: merged,
          isLoadingMore: false,
          hasReachedEnd: items.length < state.count,
          index: merged.length,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onActionRequested(
    SimpleActionRequested event,
    Emitter<SimpleListState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    try {
      await marketplaceRepository.postAction(event.path, event.data);
      emit(state.copyWith(isSubmitting: false, successMessage: 'Thao tác thành công'));
      add(SimpleListRefreshed());
    } catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.toString()));
    }
  }

  List<MarketplaceItem> _deduplicateItems(List<MarketplaceItem> items) {
    final map = <String, MarketplaceItem>{};
    for (final item in items) {
      map[item.id] = item;
    }
    return map.values.toList();
  }
}

abstract class WalletEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class WalletRequested extends WalletEvent {}

class WalletState extends Equatable {
  final WalletBalanceModel? balance;
  final List<MarketplaceItem> history;
  final bool isLoading;
  final String? errorMessage;

  const WalletState({
    this.balance,
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  WalletState copyWith({
    WalletBalanceModel? balance,
    List<MarketplaceItem>? history,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [balance, history, isLoading, errorMessage];
}

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final MarketplaceRepository marketplaceRepository;

  WalletBloc({required this.marketplaceRepository}) : super(const WalletState()) {
    on<WalletRequested>(_onRequested);
  }

  Future<void> _onRequested(WalletRequested event, Emitter<WalletState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final balance = await marketplaceRepository.getCurrentBalance();
      final history = await marketplaceRepository.getBalanceHistory(index: 0, count: 20);
      emit(
        state.copyWith(
          balance: balance,
          history: history.map((item) => item.toItem()).toList(),
          isLoading: false,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }
}

abstract class CheckoutEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckoutRequested extends CheckoutEvent {}

class CheckoutAddressSelected extends CheckoutEvent {
  final MarketplaceItem address;

  CheckoutAddressSelected(this.address);

  @override
  List<Object?> get props => [address];
}

class CheckoutSubmitted extends CheckoutEvent {
  final String productId;
  final int quantity;

  CheckoutSubmitted({
    required this.productId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productId, quantity];
}

class CheckoutState extends Equatable {
  final List<MarketplaceItem> addresses;
  final MarketplaceItem? selectedAddress;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const CheckoutState({
    this.addresses = const [],
    this.selectedAddress,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  CheckoutState copyWith({
    List<MarketplaceItem>? addresses,
    MarketplaceItem? selectedAddress,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return CheckoutState(
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        addresses,
        selectedAddress,
        isLoading,
        isSubmitting,
        errorMessage,
        successMessage,
      ];
}

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final MarketplaceRepository marketplaceRepository;

  CheckoutBloc({required this.marketplaceRepository}) : super(const CheckoutState()) {
    on<CheckoutRequested>(_onRequested);
    on<CheckoutAddressSelected>(_onAddressSelected);
    on<CheckoutSubmitted>(_onSubmitted);
  }

  Future<void> _onRequested(
    CheckoutRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));
    try {
      final addresses = await marketplaceRepository.getAddresses();
      final addressItems = addresses.map((address) => address.toItem()).toList();
      emit(
        state.copyWith(
          addresses: addressItems,
          selectedAddress: addressItems.isEmpty ? null : addressItems.first,
          isLoading: false,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  void _onAddressSelected(
    CheckoutAddressSelected event,
    Emitter<CheckoutState> emit,
  ) {
    emit(state.copyWith(selectedAddress: event.address, clearMessages: true));
  }

  Future<void> _onSubmitted(
    CheckoutSubmitted event,
    Emitter<CheckoutState> emit,
  ) async {
    final address = state.selectedAddress;
    if (address == null) {
      emit(state.copyWith(errorMessage: 'Vui lòng chọn địa chỉ giao hàng'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    try {
      await marketplaceRepository.postAction(
        '/order/create_order',
        {
          'items': [
            {'product_id': event.productId, 'quantity': event.quantity},
          ],
          'source': 'mobile',
          'address_id': address.id,
        },
      );
      emit(
        state.copyWith(
          isSubmitting: false,
          successMessage: 'Đã tạo đơn hàng',
        ),
      );
    } catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.toString()));
    }
  }
}

abstract class ConversationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ConversationsRequested extends ConversationEvent {}

class ConversationsRefreshed extends ConversationEvent {}

class ConversationsLoadMoreRequested extends ConversationEvent {}

class ConversationState extends Equatable {
  final List<ConversationModel> conversations;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final String? errorMessage;
  final int index;
  final int count;

  const ConversationState({
    this.conversations = const [],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.errorMessage,
    this.index = 0,
    this.count = 20,
  });

  ConversationState copyWith({
    List<ConversationModel>? conversations,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    String? errorMessage,
    int? index,
    int? count,
    bool clearError = false,
  }) {
    return ConversationState(
      conversations: conversations ?? this.conversations,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      index: index ?? this.index,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props => [
        conversations,
        isInitialLoading,
        isRefreshing,
        isLoadingMore,
        hasReachedEnd,
        errorMessage,
        index,
        count,
      ];
}

class ConversationListBloc extends Bloc<ConversationEvent, ConversationState> {
  final MarketplaceRepository marketplaceRepository;

  ConversationListBloc({required this.marketplaceRepository})
      : super(const ConversationState()) {
    on<ConversationsRequested>(_onRequested);
    on<ConversationsRefreshed>(_onRefreshed);
    on<ConversationsLoadMoreRequested>(_onLoadMoreRequested);
  }

  Future<void> _onRequested(
    ConversationsRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(state.copyWith(isInitialLoading: true, index: 0, clearError: true));
    await _loadPage(emit, index: 0, replace: true);
  }

  Future<void> _onRefreshed(
    ConversationsRefreshed event,
    Emitter<ConversationState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, index: 0, clearError: true));
    await _loadPage(emit, index: 0, replace: true);
  }

  Future<void> _onLoadMoreRequested(
    ConversationsLoadMoreRequested event,
    Emitter<ConversationState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedEnd || state.isInitialLoading) return;
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    await _loadPage(emit, index: state.index, replace: false);
  }

  Future<void> _loadPage(
    Emitter<ConversationState> emit, {
    required int index,
    required bool replace,
  }) async {
    try {
      final conversations = await marketplaceRepository.getConversations(
        index: index,
        count: state.count,
      );
      final merged = replace ? conversations : _deduplicateConversations(
        [...state.conversations, ...conversations],
      );
      emit(
        state.copyWith(
          conversations: merged,
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          hasReachedEnd: conversations.length < state.count,
          index: merged.length,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  List<ConversationModel> _deduplicateConversations(
    List<ConversationModel> conversations,
  ) {
    final map = <String, ConversationModel>{};
    for (final conversation in conversations) {
      map[conversation.id] = conversation;
    }
    return map.values.toList();
  }
}

abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatRequested extends ChatEvent {}

class ChatMessageSubmitted extends ChatEvent {
  final String message;

  ChatMessageSubmitted(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatState extends Equatable {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, isSending, errorMessage];
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final MarketplaceRepository marketplaceRepository;
  final ConversationModel conversation;

  ChatBloc({
    required this.marketplaceRepository,
    required this.conversation,
  }) : super(const ChatState()) {
    on<ChatRequested>(_onRequested);
    on<ChatMessageSubmitted>(_onMessageSubmitted);
  }

  Future<void> _onRequested(ChatRequested event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await marketplaceRepository.markConversationRead(conversation.partnerId);
      final messages = await marketplaceRepository.getConversation(
        partnerId: conversation.partnerId,
        conversationId: conversation.id,
      );
      emit(state.copyWith(messages: messages.reversed.toList(), isLoading: false, clearError: true));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onMessageSubmitted(
    ChatMessageSubmitted event,
    Emitter<ChatState> emit,
  ) async {
    final content = event.message.trim();
    final productId = conversation.productId;
    if (content.isEmpty) return;

    final localMessage = MessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      senderId: 'me',
      content: content,
      isLocalPending: true,
    );
    emit(state.copyWith(messages: [...state.messages, localMessage], isSending: true));

    try {
      final sent = await marketplaceRepository.sendMessage(
        toId: conversation.partnerId,
        message: content,
        productId: productId,
      );
      final messages = [...state.messages]..removeWhere((item) => item.id == localMessage.id);
      emit(
        state.copyWith(
          messages: [...messages, if (sent != null) sent.copyWith(senderId: 'me')],
          isSending: false,
          clearError: true,
        ),
      );
    } catch (error) {
      final messages = state.messages
          .map((item) => item.id == localMessage.id
              ? item.copyWith(isLocalPending: false, isFailed: true)
              : item)
          .toList();
      emit(state.copyWith(messages: messages, isSending: false, errorMessage: error.toString()));
    }
  }
}

abstract class NotificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationsRequested extends NotificationEvent {}

class NotificationsRefreshed extends NotificationEvent {}

class NotificationsLoadMoreRequested extends NotificationEvent {}

class NotificationReadRequested extends NotificationEvent {
  final String notificationId;

  NotificationReadRequested(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class NotificationState extends Equatable {
  final List<NotificationModel> notifications;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isSubmitting;
  final bool hasReachedEnd;
  final String? errorMessage;
  final String? successMessage;
  final int index;
  final int count;

  const NotificationState({
    this.notifications = const [],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.hasReachedEnd = false,
    this.errorMessage,
    this.successMessage,
    this.index = 0,
    this.count = 20,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isSubmitting,
    bool? hasReachedEnd,
    String? errorMessage,
    String? successMessage,
    int? index,
    int? count,
    bool clearMessages = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
      index: index ?? this.index,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        isInitialLoading,
        isRefreshing,
        isLoadingMore,
        isSubmitting,
        hasReachedEnd,
        errorMessage,
        successMessage,
        index,
        count,
      ];
}

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final MarketplaceRepository marketplaceRepository;

  NotificationBloc({required this.marketplaceRepository})
      : super(const NotificationState()) {
    on<NotificationsRequested>(_onRequested);
    on<NotificationsRefreshed>(_onRefreshed);
    on<NotificationsLoadMoreRequested>(_onLoadMoreRequested);
    on<NotificationReadRequested>(_onReadRequested);
  }

  Future<void> _onRequested(
    NotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(isInitialLoading: true, index: 0, clearMessages: true));
    await _loadPage(emit, index: 0, replace: true);
  }

  Future<void> _onRefreshed(
    NotificationsRefreshed event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, index: 0, clearMessages: true));
    await _loadPage(emit, index: 0, replace: true);
  }

  Future<void> _onLoadMoreRequested(
    NotificationsLoadMoreRequested event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedEnd || state.isInitialLoading) return;
    emit(state.copyWith(isLoadingMore: true, clearMessages: true));
    await _loadPage(emit, index: state.index, replace: false);
  }

  Future<void> _onReadRequested(
    NotificationReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state.notifications;
    emit(
      state.copyWith(
        isSubmitting: true,
        notifications: current
            .map((item) => item.id == event.notificationId ? item.copyWith(read: true) : item)
            .toList(),
        clearMessages: true,
      ),
    );

    try {
      await marketplaceRepository.markNotificationRead(event.notificationId);
      emit(state.copyWith(isSubmitting: false, successMessage: 'Da danh dau da doc'));
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          notifications: current,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _loadPage(
    Emitter<NotificationState> emit, {
    required int index,
    required bool replace,
  }) async {
    try {
      final notifications = await marketplaceRepository.getNotifications(
        index: index,
        count: state.count,
      );
      final merged = replace
          ? notifications
          : _deduplicate([...state.notifications, ...notifications]);
      emit(
        state.copyWith(
          notifications: merged,
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          hasReachedEnd: notifications.length < state.count,
          index: merged.length,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  List<NotificationModel> _deduplicate(List<NotificationModel> notifications) {
    final map = <String, NotificationModel>{};
    for (final notification in notifications) {
      map[notification.id] = notification;
    }
    return map.values.toList();
  }
}

abstract class AddressEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddressListRequested extends AddressEvent {}

class AddressAdded extends AddressEvent {
  final String address;
  final String fullAddress;
  final String receiverName;
  final String phone;
  final bool isDefault;
  final String? addressDetail;

  AddressAdded({
    required this.address,
    required this.fullAddress,
    required this.receiverName,
    required this.phone,
    this.isDefault = false,
    this.addressDetail,
  });

  @override
  List<Object?> get props => [address, fullAddress, receiverName, phone, isDefault, addressDetail];
}

class AddressUpdated extends AddressEvent {
  final String id;
  final String address;
  final String fullAddress;
  final String receiverName;
  final String phone;
  final bool isDefault;
  final String? addressDetail;

  AddressUpdated({
    required this.id,
    required this.address,
    required this.fullAddress,
    required this.receiverName,
    required this.phone,
    this.isDefault = false,
    this.addressDetail,
  });

  @override
  List<Object?> get props => [id, address, fullAddress, receiverName, phone, isDefault, addressDetail];
}

class AddressDeleted extends AddressEvent {
  final String id;

  AddressDeleted(this.id);

  @override
  List<Object?> get props => [id];
}

class AddressState extends Equatable {
  final List<AddressModel> addresses;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const AddressState({
    this.addresses = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  AddressState copyWith({
    List<AddressModel>? addresses,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        addresses,
        isLoading,
        isSubmitting,
        errorMessage,
        successMessage,
      ];
}

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final MarketplaceRepository marketplaceRepository;

  AddressBloc({required this.marketplaceRepository}) : super(const AddressState()) {
    on<AddressListRequested>(_onListRequested);
    on<AddressAdded>(_onAdded);
    on<AddressUpdated>(_onUpdated);
    on<AddressDeleted>(_onDeleted);
  }

  Future<void> _onListRequested(
    AddressListRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));
    try {
      final addresses = await marketplaceRepository.getAddresses();
      emit(
        state.copyWith(
          addresses: addresses,
          isLoading: false,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onAdded(
    AddressAdded event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    try {
      final data = <String, dynamic>{
        'address': event.address,
        'full_address': event.fullAddress,
        'receiver_name': event.receiverName,
        'phone': event.phone,
        'is_default': event.isDefault,
      };
      if (event.addressDetail != null && event.addressDetail!.isNotEmpty) {
        data['address_detail'] = event.addressDetail;
      }
      await marketplaceRepository.addAddress(data);
      final addresses = await marketplaceRepository.getAddresses();
      emit(
        state.copyWith(
          addresses: addresses,
          isSubmitting: false,
          successMessage: 'Đã thêm địa chỉ',
        ),
      );
    } catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onUpdated(
    AddressUpdated event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    try {
      final data = <String, dynamic>{
        'address': event.address,
        'full_address': event.fullAddress,
        'receiver_name': event.receiverName,
        'phone': event.phone,
        'is_default': event.isDefault,
      };
      if (event.addressDetail != null && event.addressDetail!.isNotEmpty) {
        data['address_detail'] = event.addressDetail;
      }
      await marketplaceRepository.updateAddress(event.id, data);
      final addresses = await marketplaceRepository.getAddresses();
      emit(
        state.copyWith(
          addresses: addresses,
          isSubmitting: false,
          successMessage: 'Đã cập nhật địa chỉ',
        ),
      );
    } catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onDeleted(
    AddressDeleted event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    try {
      await marketplaceRepository.deleteAddress(event.id);
      final addresses = await marketplaceRepository.getAddresses();
      emit(
        state.copyWith(
          addresses: addresses,
          isSubmitting: false,
          successMessage: 'Đã xóa địa chỉ',
        ),
      );
    } catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.toString()));
    }
  }
}
