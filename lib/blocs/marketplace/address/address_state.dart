import 'package:army_ecommerce/models/address_model.dart';
import 'package:equatable/equatable.dart';

class AddressState extends Equatable {
  final List<AddressModel> addresses;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final List<ProvinceModel> provinces;
  final List<WardModel> wards;
  final bool isLoadingProvinces;
  final bool isLoadingWards;

  const AddressState({
    this.addresses = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.provinces = const [],
    this.wards = const [],
    this.isLoadingProvinces = false,
    this.isLoadingWards = false,
  });

  AddressState copyWith({
    List<AddressModel>? addresses,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    List<ProvinceModel>? provinces,
    List<WardModel>? wards,
    bool? isLoadingProvinces,
    bool? isLoadingWards,
    bool clearMessages = false,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
      provinces: provinces ?? this.provinces,
      wards: wards ?? this.wards,
      isLoadingProvinces: isLoadingProvinces ?? this.isLoadingProvinces,
      isLoadingWards: isLoadingWards ?? this.isLoadingWards,
    );
  }

  @override
  List<Object?> get props => [
        addresses,
        isLoading,
        isSubmitting,
        errorMessage,
        successMessage,
        provinces,
        wards,
        isLoadingProvinces,
        isLoadingWards,
      ];
}
