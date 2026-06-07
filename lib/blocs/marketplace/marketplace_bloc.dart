import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/marketplace_models.dart';
import '../../repositories/marketplace_repository.dart';
import 'marketplace_event.dart';
import 'marketplace_state.dart';

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
      final result = await marketplaceRepository.getListProducts(index: 0, count: state.count);
      emit(
        state.copyWith(
          categories: categories,
          products: _deduplicateProducts(result.products),
          isInitialLoading: false,
          hasReachedEnd: result.products.length < state.count,
          lastId: result.lastId,
          index: result.products.length,
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
      final result = await marketplaceRepository.getListProducts(index: 0, count: state.count);
      emit(
        state.copyWith(
          categories: categories,
          products: _deduplicateProducts(result.products),
          isRefreshing: false,
          hasReachedEnd: result.products.length < state.count,
          lastId: result.lastId,
          index: result.products.length,
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
      final result = await marketplaceRepository.getListProducts(
        index: state.index,
        count: state.count,
        lastId: state.lastId,
      );
      final products = result.products;
      final merged = _deduplicateProducts([...state.products, ...products]);
      emit(
        state.copyWith(
          products: merged,
          isLoadingMore: false,
          hasReachedEnd: products.length < state.count,
          lastId: result.lastId,
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

//----------------------------------------
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

//-----------------------------------
class ProductSearchBloc extends Bloc<ProductSearchEvent, ProductSearchState> {
  final MarketplaceRepository marketplaceRepository;

  ProductSearchBloc({required this.marketplaceRepository})
      : super(const ProductSearchState()) {
    on<ProductSearchRequested>(_onRequested);
    on<ProductSearchFiltered>(_onFiltered);
    on<ProductSearchRefreshed>(_onRefreshed);
    on<ProductSearchLoadMoreRequested>(_onLoadMoreRequested);
    on<ProductSearchBrandsRequested>(_onBrandsRequested);
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
        useListProductsApi: false,
        lastId: null,
        products: const [],
        index: 0,
        isInitialLoading: true,
        hasReachedEnd: false,
        clearError: true,
      ),
    );

    // Tải danh sách thương hiệu nếu có categoryId
    if (event.categoryId != null) {
      add(ProductSearchBrandsRequested(categoryId: event.categoryId));
    }

    await _loadPage(emit, index: 0, replace: true);
  }

  Future<void> _onFiltered(
    ProductSearchFiltered event,
    Emitter<ProductSearchState> emit,
  ) async {
    emit(
      state.copyWith(
        keyword: event.keyword,
        categoryId: event.categoryId,
        brandId: event.brandId,
        priceMin: event.priceMin,
        priceMax: event.priceMax,
        useListProductsApi: true,
        lastId: null,
        products: const [],
        index: 0,
        isInitialLoading: true,
        hasReachedEnd: false,
        clearError: true,
      ),
    );

    // Tải danh sách thương hiệu nếu có categoryId
    if (event.categoryId != null) {
      add(ProductSearchBrandsRequested(categoryId: event.categoryId));
    }

    await _loadPage(emit, index: 0, replace: true);
  }

  Future<void> _onRefreshed(
    ProductSearchRefreshed event,
    Emitter<ProductSearchState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, index: 0, lastId: null, clearError: true));
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

  Future<void> _onBrandsRequested(
    ProductSearchBrandsRequested event,
    Emitter<ProductSearchState> emit,
  ) async {
    emit(state.copyWith(isBrandsLoading: true));
    try {
      final brands = await marketplaceRepository.getBrands(
        categoryId: event.categoryId,
      );
      emit(state.copyWith(brands: brands, isBrandsLoading: false));
    } catch (error) {
      // Lỗi tải thương hiệu không ảnh hưởng đến tải sản phẩm
      emit(state.copyWith(isBrandsLoading: false));
    }
  }

  Future<void> _loadPage(
    Emitter<ProductSearchState> emit, {
    required int index,
    required bool replace,
  }) async {
    try {
      List<ProductModel> products;
      int? lastId;
      if (state.useListProductsApi) {
        final result = await marketplaceRepository.getListProducts(
          keyword: state.keyword,
          categoryId: state.categoryId,
          brandId: state.brandId,
          priceMin: state.priceMin,
          priceMax: state.priceMax,
          index: index,
          count: state.count,
          lastId: state.lastId,
        );
        products = result.products;
        lastId = result.lastId;
      } else {
        products = await marketplaceRepository.searchProducts(
          keyword: state.keyword,
          categoryId: state.categoryId,
          brandId: state.brandId,
          priceMin: state.priceMin,
          priceMax: state.priceMax,
          index: index,
          count: state.count,
        );
      }
      final merged = replace ? products : _deduplicate([...state.products, ...products]);
      emit(
        state.copyWith(
          products: merged,
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          lastId: lastId ?? state.lastId,
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

//---------------------------------------------
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

//----------------------------------------------
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
          history: history,
          isLoading: false,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }
}

//---------------------------------------------
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final MarketplaceRepository marketplaceRepository;

  CheckoutBloc({required this.marketplaceRepository}) : super(const CheckoutState()) {
    on<CheckoutRequested>(_onRequested);
    on<CheckoutAddressSelected>(_onAddressSelected);
    on<CheckoutShipFeeRequested>(_onShipFeeRequested);
    on<CheckoutSubmitted>(_onSubmitted);
  }

  Future<void> _onRequested(
    CheckoutRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, productId: event.productId, clearMessages: true));
    try {
      final addresses = await marketplaceRepository.getAddresses();
      final addressItems = addresses.map((address) => address.toItem()).toList();
      final defaultAddress = addressItems.isEmpty ? null : addressItems.first;

      num shipFee = 0;
      int? leatime;

      if (event.productId != null && defaultAddress != null) {
        final addressId = int.tryParse(defaultAddress.id);
        if (addressId != null) {
          try {
            final shipFeeData = await marketplaceRepository.getShipFee(
              event.productId!,
              addressId: addressId,
            );
            if (shipFeeData != null) {
              shipFee = shipFeeData.shipFee;
              leatime = shipFeeData.leatime;
            }
          } catch (_) {}
        }
      }

      emit(
        state.copyWith(
          addresses: addressItems,
          selectedAddress: defaultAddress,
          shippingFee: shipFee,
          leatime: leatime,
          isLoading: false,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onAddressSelected(
    CheckoutAddressSelected event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(selectedAddress: event.address, clearMessages: true));

    // Automatically recalculate shipping fee when address changes
    final productId = state.productId;
    final addressId = int.tryParse(event.address.id);
    if (productId != null && addressId != null) {
      emit(state.copyWith(isLoading: true));
      try {
        final shipFeeData = await marketplaceRepository.getShipFee(
          productId,
          addressId: addressId,
        );
        if (shipFeeData != null) {
          emit(
            state.copyWith(
              shippingFee: shipFeeData.shipFee,
              leatime: shipFeeData.leatime,
              isLoading: false,
            ),
          );
        } else {
          emit(state.copyWith(isLoading: false));
        }
      } catch (error) {
        emit(state.copyWith(isLoading: false, errorMessage: 'Không tính được phí ship: $error'));
      }
    }
  }

  Future<void> _onShipFeeRequested(
    CheckoutShipFeeRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));
    try {
      final shipFeeData = await marketplaceRepository.getShipFee(
        event.productId,
        addressId: event.addressId,
      );
      if (shipFeeData != null) {
        emit(
          state.copyWith(
            shippingFee: shipFeeData.shipFee,
            leatime: shipFeeData.leatime,
            isLoading: false,
          ),
        );
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Không tính được phí ship: $error'));
    }
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

    final addressId = int.tryParse(address.id);
    if (addressId == null) {
      emit(state.copyWith(errorMessage: 'Địa chỉ không hợp lệ'));
      return;
    }

    if (event.items.isEmpty) {
      emit(state.copyWith(errorMessage: 'Giỏ hàng trống'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    try {
      final itemsData = event.items.map((item) => {
        'product_id': int.parse(item.productId.split('-')[0]),
        'quantity': item.quantity,
      }).toList();

      await marketplaceRepository.createOrder({
        'items': itemsData,
        'source': 'mobile',
        'address_id': addressId,
      });

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

//------------------------------------------
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

//---------------------------------------------------
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
        'province': event.province,
        'district': event.district,
        'lat': double.tryParse(event.latitude) ?? 0.0,
        'lng': double.tryParse(event.longitude) ?? 0.0,
        'address_id': [7, 1], // Default value for now
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
        'province': event.province,
        'district': event.district,
        'lat': double.tryParse(event.latitude) ?? 0.0,
        'lng': double.tryParse(event.longitude) ?? 0.0,
        // Omitted 'address_id' on updates to avoid triggering backend validation bug (ACTION_DONE_PREVIOUSLY)
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
