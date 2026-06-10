import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/marketplace_repository.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';

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

    if (event.items.isNotEmpty) {
      final firstSellerId = event.items.first.sellerId;
      final isSameSeller = event.items.every((item) => item.sellerId == firstSellerId);
      if (!isSameSeller) {
        emit(state.copyWith(errorMessage: 'Các sản phẩm trong đơn hàng phải thuộc cùng một người bán'));
        return;
      }
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
