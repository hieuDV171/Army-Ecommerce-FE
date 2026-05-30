import 'package:equatable/equatable.dart';

import '../../models/marketplace_models.dart';

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
  final int? lastId;

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
    this.lastId,
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
    int? lastId,
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
      lastId: lastId ?? this.lastId,
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
    lastId,
  ];
}

//------------------------------------------
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

//-------------------------------------
class ProductSearchState extends Equatable {
  final List<ProductModel> products;
  final List<BrandModel> brands;
  final String keyword;
  final String? categoryId;
  final String? brandId;
  final num? priceMin;
  final num? priceMax;
  final bool useListProductsApi;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final bool isBrandsLoading;
  final String? errorMessage;
  final int index;
  final int count;
  final int? lastId;

  const ProductSearchState({
    this.products = const [],
    this.brands = const [],
    this.keyword = '',
    this.categoryId,
    this.brandId,
    this.priceMin,
    this.priceMax,
    this.useListProductsApi = false,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.isBrandsLoading = false,
    this.errorMessage,
    this.index = 0,
    this.count = 20,
    this.lastId,
  });

  ProductSearchState copyWith({
    List<ProductModel>? products,
    List<BrandModel>? brands,
    String? keyword,
    String? categoryId,
    String? brandId,
    num? priceMin,
    num? priceMax,
    bool? useListProductsApi,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    bool? isBrandsLoading,
    String? errorMessage,
    int? index,
    int? count,
    int? lastId,
    bool clearError = false,
  }) {
    return ProductSearchState(
      products: products ?? this.products,
      brands: brands ?? this.brands,
      keyword: keyword ?? this.keyword,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      useListProductsApi: useListProductsApi ?? this.useListProductsApi,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isBrandsLoading: isBrandsLoading ?? this.isBrandsLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      index: index ?? this.index,
      count: count ?? this.count,
      lastId: lastId ?? this.lastId,
    );
  }

  @override
  List<Object?> get props => [
    products,
    brands,
    keyword,
    categoryId,
    brandId,
    priceMin,
    priceMax,
    useListProductsApi,
    isInitialLoading,
    isRefreshing,
    isLoadingMore,
    hasReachedEnd,
    isBrandsLoading,
    errorMessage,
    index,
    count,
    lastId,
  ];
}

//----------------------------
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

//--------------------------------------
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

//----------------------------
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

//---------------------------------------
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

//---------------------------------
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
