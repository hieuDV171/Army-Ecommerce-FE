import 'package:army_ecommerce/core/utils/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/models/address_model.dart';
import '../../../repositories/marketplace_repository.dart';
import 'address_event.dart';
import 'address_state.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final MarketplaceRepository marketplaceRepository;

  AddressBloc({required this.marketplaceRepository})
    : super(const AddressState()) {
    on<AddressListRequested>(_onListRequested);
    on<AddressAdded>(_onAdded);
    on<AddressUpdated>(_onUpdated);
    on<AddressDeleted>(_onDeleted);
    on<AddressSetDefault>(_onSetDefault);
    on<ProvincesRequested>(_onProvincesRequested);
    on<WardsRequested>(_onWardsRequested);
    on<AddressClearMessages>(
      (event, emit) => emit(state.copyWith(clearMessages: true)),
    );
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

  Future<void> _onAdded(AddressAdded event, Emitter<AddressState> emit) async {
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
      final data = <String, dynamic>{};
      final orig = event.originalAddress;

      if (orig == null) {
        data.addAll({
          'address': event.address,
          'full_address': event.fullAddress,
          'receiver_name': event.receiverName,
          'phone': event.phone,
          'is_default': event.isDefault,
          'province': event.province,
          'district': event.district,
          'lat': double.tryParse(event.latitude) ?? 0.0,
          'lng': double.tryParse(event.longitude) ?? 0.0,
        });
        if (event.addressId != null) {
          data['address_id'] = event.addressId;
        }
        if (event.addressDetail != null && event.addressDetail!.isNotEmpty) {
          data['address_detail'] = event.addressDetail;
        }
      } else {
        if (event.receiverName != orig.receiverName) {
          data['receiver_name'] = event.receiverName;
        }
        if (event.phone != orig.phone) {
          data['phone'] = event.phone;
        }
        if (event.address != orig.address) {
          data['address'] = event.address;
        }
        if (event.fullAddress != orig.fullAddress) {
          data['full_address'] = event.fullAddress;
        }
        if (event.addressDetail != orig.addressDetail) {
          data['address_detail'] = event.addressDetail ?? '';
        }
        if (orig.isDefault) {
          data['is_default'] = true;
        } else if (event.isDefault != orig.isDefault) {
          data['is_default'] = event.isDefault;
        }

        final doubleNewLat = double.tryParse(event.latitude) ?? 0.0;
        final doubleOrigLat = double.tryParse(orig.latitude ?? '') ?? 0.0;
        if (doubleNewLat != doubleOrigLat) {
          data['lat'] = doubleNewLat;
        }
        final doubleNewLng = double.tryParse(event.longitude) ?? 0.0;
        final doubleOrigLng = double.tryParse(orig.longitude ?? '') ?? 0.0;
        if (doubleNewLng != doubleOrigLng) {
          data['lng'] = doubleNewLng;
        }
      }

      logger.d('AddressBloc _onUpdated payload data: $data');
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
      // TIP-06: bỏ tiền tố "Exception: " để hiện message của BE gọn gàng
      var msg = error.toString();
      if (msg.startsWith('Exception: ')) {
        msg = msg.substring('Exception: '.length);
      }
      emit(state.copyWith(isSubmitting: false, errorMessage: msg));
    }
  }

  Future<void> _onSetDefault(
    AddressSetDefault event,
    Emitter<AddressState> emit,
  ) async {
    if (event.address.isDefault) return; // đã là mặc định rồi
    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    try {
      // Đặt địa chỉ này làm mặc định
      await _patchDefault(event.address, true);
      // // Bỏ mặc định ở các địa chỉ khác (phòng khi BE không tự bỏ)
      // for (final a in state.addresses) {
      //   if (a.id != event.address.id && a.isDefault) {
      //     await _patchDefault(a, false);
      //   }
      // }
      final addresses = await marketplaceRepository.getAddresses();
      emit(
        state.copyWith(
          addresses: addresses,
          isSubmitting: false,
          successMessage: 'Đã đặt làm địa chỉ mặc định',
        ),
      );
    } catch (error) {
      var msg = error.toString();
      if (msg.startsWith('Exception: ')) {
        msg = msg.substring('Exception: '.length);
      }
      emit(state.copyWith(isSubmitting: false, errorMessage: msg));
    }
  }

  Future<void> _patchDefault(AddressModel a, bool isDefault) async {
    final data = <String, dynamic>{
      'address': (a.address != null && a.address!.isNotEmpty)
          ? a.address
          : a.fullAddress,
      'full_address': a.fullAddress,
      'receiver_name': a.receiverName,
      'phone': a.phone,
      'is_default': isDefault,
      'province': a.province ?? '',
      'district': a.district ?? '',
      'lat': double.tryParse(a.latitude ?? '') ?? 0.0,
      'lng': double.tryParse(a.longitude ?? '') ?? 0.0,
    };
    if (a.addressDetail != null && a.addressDetail!.isNotEmpty) {
      data['address_detail'] = a.addressDetail;
    }
    await marketplaceRepository.updateAddress(a.id, data);
  }

  Future<void> _onProvincesRequested(
    ProvincesRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(isLoadingProvinces: true, clearMessages: true));
    try {
      final provinces = await marketplaceRepository.getProvinces();
      emit(state.copyWith(provinces: provinces, isLoadingProvinces: false));
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingProvinces: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onWardsRequested(
    WardsRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(isLoadingWards: true, clearMessages: true));
    try {
      final wards = await marketplaceRepository.getWards(event.provinceId);
      emit(state.copyWith(wards: wards, isLoadingWards: false));
    } catch (error) {
      emit(
        state.copyWith(isLoadingWards: false, errorMessage: error.toString()),
      );
    }
  }
}
