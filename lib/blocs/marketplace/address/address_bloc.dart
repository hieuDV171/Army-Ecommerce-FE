import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/marketplace_repository.dart';
import 'address_event.dart';
import 'address_state.dart';

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
        'address_id': event.addressId ?? [7, 1],
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
      };
      if (event.addressId != null) {
        data['address_id'] = event.addressId;
      }
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
