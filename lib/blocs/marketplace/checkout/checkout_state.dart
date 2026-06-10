import 'package:army_ecommerce/models/model_helpers.dart';
import 'package:equatable/equatable.dart';

class CheckoutState extends Equatable {
  final List<MarketplaceItem> addresses;
  final MarketplaceItem? selectedAddress;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final num shippingFee;
  final int? leatime;
  final int? productId;

  const CheckoutState({
    this.addresses = const [],
    this.selectedAddress,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.shippingFee = 0,
    this.leatime,
    this.productId,
  });

  CheckoutState copyWith({
    List<MarketplaceItem>? addresses,
    MarketplaceItem? selectedAddress,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    num? shippingFee,
    int? leatime,
    int? productId,
    bool clearMessages = false,
  }) {
    return CheckoutState(
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
      shippingFee: shippingFee ?? this.shippingFee,
      leatime: leatime ?? this.leatime,
      productId: productId ?? this.productId,
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
    shippingFee,
    leatime,
    productId,
  ];
}
