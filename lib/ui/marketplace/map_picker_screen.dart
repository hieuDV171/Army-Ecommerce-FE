import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../util/constants/app_colors.dart';
import '../util/constants/app_radius.dart';
import '../util/constants/app_spacing.dart';
import '../util/widgets/app_button.dart';
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  late LatLng _currentCenter;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    // Default coordinates (Hanoi center) if no initial coords are provided
    final double lat = widget.initialLat ?? 21.0285;
    final double lng = widget.initialLng ?? 105.8542;
    _currentCenter = LatLng(lat, lng);

    // If no initial coordinates are passed, try to fetch current GPS location
    if (widget.initialLat == null || widget.initialLng == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _determinePosition();
      });
    }
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          AppSnackBar.show(context, message: 'Dịch vụ định vị GPS chưa được bật.');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            AppSnackBar.show(context, message: 'Quyền định vị GPS bị từ chối.');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          AppSnackBar.show(context, message: 'Quyền định vị bị từ chối vĩnh viễn. Vui lòng bật trong cài đặt.');
        }
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final newLatLng = LatLng(position.latitude, position.longitude);
      _mapController.move(newLatLng, 15.0);
      setState(() {
        _currentCenter = newLatLng;
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, message: 'Lỗi khi lấy vị trí: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn tọa độ giao hàng'),
        actions: [
          if (_isLoadingLocation)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Flutter Map Widget
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
              maxZoom: 18.0,
              minZoom: 5.0,
              onPositionChanged: (position, hasGesture) {
                setState(() {
                  _currentCenter = position.center;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.army_ecommerce',
              ),
            ],
          ),

          // Central Pin indicator (Visual indicator of picked position)
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 35), // Offset icon size to match point
              child: const Icon(
                Icons.location_on,
                size: 44,
                color: AppColors.primary,
              ),
            ),
          ),

          // Floating Action Button to Geolocate User
          Positioned(
            right: AppSpacing.lg,
            bottom: 160,
            child: FloatingActionButton(
              onPressed: _isLoadingLocation ? null : _determinePosition,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              child: const Icon(Icons.my_location),
            ),
          ),

          // Bottom Action Panel
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tọa độ được chọn',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(Icons.pin_drop_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Vĩ độ (Lat): ${_currentCenter.latitude.toStringAsFixed(6)}\nKinh độ (Lng): ${_currentCenter.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Xác nhận vị trí',
                      icon: Icons.check,
                      onPressed: () {
                        Navigator.pop(context, _currentCenter);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
