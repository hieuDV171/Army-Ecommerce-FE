import 'package:army_ecommerce/blocs/marketplace/address/address_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/address/address_event.dart';
import 'package:army_ecommerce/blocs/marketplace/address/address_state.dart';
import 'package:army_ecommerce/models/address_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../util/constants/app_colors.dart';
import '../../util/constants/app_radius.dart';
import '../../util/constants/app_spacing.dart';
import '../../util/widgets/app_button.dart';
import '../../util/widgets/app_text_field.dart';
import '../../util/widgets/loading_overlay.dart';
import '../../util/theme/special_app_theme.dart';
import '../map_picker_screen.dart';
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';
import 'package:army_ecommerce/ui/util/widgets/app_dialog.dart';

class AddressFormPage extends StatefulWidget {
  final AddressModel? address;

  const AddressFormPage({super.key, this.address});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  late final TextEditingController _receiverNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _fullAddressCtrl;
  late final TextEditingController _addressDetailCtrl;
  late final TextEditingController _latitudeCtrl;
  late final TextEditingController _longitudeCtrl;
  bool _isDefault = false;
  bool _isSubmitting = false;
  String? _selectedTag;

  ProvinceModel? _selectedProvinceModel;
  WardModel? _selectedWardModel;

  final List<Map<String, dynamic>> _presetLocations = const [
    {'name': 'Hồ Hoàn Kiếm, Hà Nội', 'lat': 21.0285, 'lng': 105.8542},
    {'name': 'Dinh Độc Lập, TP. Hồ Chí Minh', 'lat': 10.7770, 'lng': 106.6953},
    {'name': 'Cầu Rồng, Đà Nẵng', 'lat': 16.0613, 'lng': 108.2274},
    {'name': 'Chợ Bến Thành, TP. Hồ Chí Minh', 'lat': 10.7725, 'lng': 106.6980},
    {'name': 'Lăng Bác, Hà Nội', 'lat': 21.0368, 'lng': 105.8346},
  ];

  bool get _isEditMode => widget.address != null;

  @override
  void initState() {
    super.initState();
    _receiverNameCtrl = TextEditingController(
      text: widget.address?.receiverName ?? '',
    );
    _phoneCtrl = TextEditingController(text: widget.address?.phone ?? '');
    
    final initialAddress = widget.address?.address ?? '';
    if (initialAddress.isEmpty || initialAddress == widget.address?.fullAddress) {
      _selectedTag = null;
      _addressCtrl = TextEditingController(text: '');
    } else if (initialAddress == 'Nhà riêng' || initialAddress == 'Văn phòng' || initialAddress == 'Trường học') {
      _selectedTag = initialAddress;
      _addressCtrl = TextEditingController(text: initialAddress);
    } else {
      _selectedTag = 'Khác';
      _addressCtrl = TextEditingController(text: initialAddress);
    }

    _fullAddressCtrl = TextEditingController(
      text: widget.address?.fullAddress ?? '',
    );
    _addressDetailCtrl = TextEditingController(
      text: widget.address?.addressDetail ?? '',
    );
    _latitudeCtrl = TextEditingController(text: widget.address?.latitude ?? '');
    _longitudeCtrl = TextEditingController(
      text: widget.address?.longitude ?? '',
    );
    _isDefault = widget.address?.isDefault ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProvinces();
    });
  }

  @override
  void dispose() {
    _receiverNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _fullAddressCtrl.dispose();
    _addressDetailCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    super.dispose();
  }

  void _loadProvinces() {
    context.read<AddressBloc>().add(ProvincesRequested());
  }

  void _loadWards(int provinceId) {
    context.read<AddressBloc>().add(WardsRequested(provinceId));
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Chọn nhanh vị trí để lấy tọa độ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _presetLocations.length,
                  itemBuilder: (context, index) {
                    final loc = _presetLocations[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                      ),
                      title: Text(loc['name'] as String),
                      subtitle: Text(
                        'Vĩ độ: ${loc['lat']}, Kinh độ: ${loc['lng']}',
                      ),
                      onTap: () {
                        setState(() {
                          _latitudeCtrl.text = loc['lat'].toString();
                          _longitudeCtrl.text = loc['lng'].toString();
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openMapPicker(BuildContext context) async {
    final double? initialLat = double.tryParse(_latitudeCtrl.text);
    final double? initialLng = double.tryParse(_longitudeCtrl.text);

    final LatLng? result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MapPickerScreen(initialLat: initialLat, initialLng: initialLng),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitudeCtrl.text = result.latitude.toString();
        _longitudeCtrl.text = result.longitude.toString();
      });
    }
  }

  void _onSubmit() {
    final receiverName = _receiverNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final fullAddress = _fullAddressCtrl.text.trim();
    final addressDetail = _addressDetailCtrl.text.trim();
    final latitude = _latitudeCtrl.text.trim();
    final longitude = _longitudeCtrl.text.trim();

    if (receiverName.isEmpty ||
        phone.isEmpty ||
        fullAddress.isEmpty ||
        addressDetail.isEmpty) {
      AppSnackBar.show(context, message: 'Vui lòng điền đầy đủ: Tên người nhận, SĐT, Địa chỉ đầy đủ, Chi tiết thêm', backgroundColor: AppColors.danger);
      return;
    }

    if (_selectedProvinceModel == null || _selectedWardModel == null) {
      AppSnackBar.show(context, message: 'Vui lòng chọn Tỉnh/Thành phố và Phường/Xã', backgroundColor: AppColors.danger);
      return;
    }

    if (latitude.isEmpty || longitude.isEmpty) {
      AppSnackBar.show(context, message: 'Vui lòng chọn vị trí (Kinh Độ và Vĩ độ)', backgroundColor: AppColors.danger);
      return;
    }

    final bloc = context.read<AddressBloc>();

    if (_isEditMode) {
      final orig = widget.address!;
      final hasChanged = receiverName != orig.receiverName ||
          phone != orig.phone ||
          (address.isEmpty ? fullAddress : address) != orig.address ||
          fullAddress != orig.fullAddress ||
          addressDetail != (orig.addressDetail ?? '') ||
          _isDefault != orig.isDefault ||
          latitude != (orig.latitude ?? '') ||
          longitude != (orig.longitude ?? '');

      if (!hasChanged) {
        AppDialog.showError(
          context,
          title: 'Thông báo',
          message: 'Bạn chưa thay đổi thông tin nào.',
          confirmLabel: 'Đã hiểu',
        );
        return;
      }

      bloc.add(
        AddressUpdated(
          id: widget.address!.id,
          address: address.isEmpty ? fullAddress : address,
          fullAddress: fullAddress,
          receiverName: receiverName,
          phone: phone,
          isDefault: _isDefault,
          addressDetail: addressDetail,
          province: _selectedProvinceModel!.name,
          district: _selectedWardModel!.name,
          latitude: latitude,
          longitude: longitude,
          addressId: [_selectedWardModel!.id, _selectedProvinceModel!.id],
          originalAddress: orig,
        ),
      );
    } else {
      bloc.add(
        AddressAdded(
          address: address.isEmpty ? fullAddress : address,
          fullAddress: fullAddress,
          receiverName: receiverName,
          phone: phone,
          isDefault: _isDefault,
          addressDetail: addressDetail,
          province: _selectedProvinceModel!.name,
          district: _selectedWardModel!.name,
          latitude: latitude,
          longitude: longitude,
          addressId: [_selectedWardModel!.id, _selectedProvinceModel!.id],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddressBloc, AddressState>(
      listener: (context, state) {
        setState(() => _isSubmitting = state.isSubmitting);

        if (state.successMessage != null) {
          AppDialog.showSuccess(context, message: state.successMessage!).then((_) {
            if (context.mounted) {
              Navigator.pop(context, true);
            }
          });
        } else if (state.errorMessage != null) {
          AppDialog.showError(context, message: state.errorMessage!);
        }

        // Handle provinces loaded
        if (state.provinces.isNotEmpty && _selectedProvinceModel == null) {
          setState(() {
            if (_isEditMode && widget.address?.province != null) {
              final matched = state.provinces.firstWhere(
                (p) => p.name.trim().toLowerCase() == widget.address!.province!.trim().toLowerCase(),
                orElse: () => state.provinces.first,
              );
              _selectedProvinceModel = matched;
            } else {
              _selectedProvinceModel = state.provinces.first;
            }
          });
          if (_selectedProvinceModel != null) {
            _loadWards(_selectedProvinceModel!.id);
          }
        }

        // Handle wards loaded
        if (state.wards.isNotEmpty && _selectedWardModel == null) {
          setState(() {
            if (_isEditMode && widget.address?.district != null && _selectedProvinceModel != null && _selectedProvinceModel!.name.trim().toLowerCase() == widget.address!.province!.trim().toLowerCase()) {
              final matched = state.wards.firstWhere(
                (w) => w.name.trim().toLowerCase() == widget.address!.district!.trim().toLowerCase(),
                orElse: () => state.wards.first,
              );
              _selectedWardModel = matched;
            } else {
              _selectedWardModel = state.wards.first;
            }
          });
        }
      },
      child: BlocBuilder<AddressBloc, AddressState>(
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: _isSubmitting,
            child: Scaffold(
              appBar: AppBar(
                title: Text(_isEditMode ? 'Sửa địa chỉ' : 'Thêm địa chỉ mới'),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tên địa chỉ (Tùy chọn)',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: ['Nhà riêng', 'Văn phòng', 'Trường học', 'Khác'].map((tag) {
                        final isSelected = _selectedTag == tag;
                        return ChoiceChip(
                          label: Text(tag),
                          selected: isSelected,
                          selectedColor: context.specialTheme.primaryColor.withValues(alpha: 0.2),
                          checkmarkColor: context.specialTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? context.specialTheme.primaryColor : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTag = tag;
                                if (tag != 'Khác') {
                                  _addressCtrl.text = tag;
                                } else {
                                  _addressCtrl.text = '';
                                }
                              } else {
                                _selectedTag = null;
                                _addressCtrl.text = '';
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (_selectedTag == 'Khác') ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        controller: _addressCtrl,
                        label: 'Tên địa chỉ khác',
                        hint: 'VD: Nhà bạn gái, Kho hàng...',
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _receiverNameCtrl,
                      label: 'Tên người nhận *',
                      hint: 'VD: Nguyễn Văn A',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _phoneCtrl,
                      label: 'Số điện thoại *',
                      hint: 'VD: 0912345678',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Province dropdown
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: DropdownButton<ProvinceModel>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        value: state.provinces.contains(_selectedProvinceModel) ? _selectedProvinceModel : null,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        items: state.provinces.map((province) {
                          return DropdownMenuItem(
                            value: province,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: Text(province.name),
                            ),
                          );
                        }).toList(),
                        onChanged: state.isLoadingProvinces ? null : (value) {
                          if (value != null) {
                            setState(() {
                              _selectedProvinceModel = value;
                              _selectedWardModel = null;
                            });
                            _loadWards(value.id);
                          }
                        },
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Text(state.isLoadingProvinces ? 'Đang tải tỉnh/thành phố...' : 'Chọn Tỉnh/Thành phố *'),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // District dropdown (using wards)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: DropdownButton<WardModel>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        value: state.wards.contains(_selectedWardModel) ? _selectedWardModel : null,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        items: state.wards.map((ward) {
                          return DropdownMenuItem(
                            value: ward,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: Text(ward.name),
                            ),
                          );
                        }).toList(),
                        onChanged: state.isLoadingWards ? null : (value) {
                          if (value != null) {
                            setState(() => _selectedWardModel = value);
                          }
                        },
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Text(state.isLoadingWards ? 'Đang tải phường/xã...' : 'Chọn Phường/Xã *'),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _fullAddressCtrl,
                      label: 'Địa chỉ đầy đủ *',
                      hint: 'VD: 123 Đường ABC, Phường XYZ, Quận 1, TP.HCM',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _addressDetailCtrl,
                      label: 'Chi tiết thêm *',
                      hint: 'VD: Tầng 3, phòng 301',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tọa độ GPS *',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => _openMapPicker(context),
                              icon: const Icon(Icons.map, size: 16),
                              label: const Text('Chọn từ bản đồ'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: context.specialTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            TextButton.icon(
                              onPressed: () => _showLocationPicker(context),
                              icon: const Icon(Icons.list, size: 16),
                              label: const Text('Chọn nhanh'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(
                      controller: _latitudeCtrl,
                      label: 'Vĩ độ (Latitude) *',
                      hint: 'VD: 10.7769',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _longitudeCtrl,
                      label: 'Kinh độ (Longitude) *',
                      hint: 'VD: 106.7009',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (!_isEditMode) ...[
                      SwitchListTile(
                        value: _isDefault,
                        onChanged: (value) => setState(() => _isDefault = value),
                        title: const Text('Đặt làm địa chỉ mặc định'),
                        subtitle: const Text('Tự động chọn khi đặt hàng'),
                        activeThumbColor: context.specialTheme.primaryColor,
                        activeTrackColor: context.specialTheme.primaryColor.withValues(alpha: 0.5),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    AppButton(
                      label: _isEditMode ? 'Cập nhật địa chỉ' : 'Lưu địa chỉ',
                      icon: Icons.save_outlined,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _onSubmit,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
