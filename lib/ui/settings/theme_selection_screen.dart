import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/blocs/theme_cubit.dart';
import 'package:army_ecommerce/ui/util/theme/special_app_theme.dart';
import 'package:army_ecommerce/ui/util/constants/app_colors.dart';
import 'package:army_ecommerce/ui/util/constants/app_radius.dart';
import 'package:army_ecommerce/ui/util/constants/app_spacing.dart';

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  // Pre-curated premium colors
  final List<Map<String, dynamic>> _primaryColorOptions = [
    {'name': 'Ngụy trang quân đội', 'color': const Color(0xFF4B5320)},
    {'name': 'Cam truyền thống', 'color': const Color(0xFFFF5A1F)},
    {'name': 'Xanh đại dương', 'color': const Color(0xFF0F4C81)},
    {'name': 'Xanh ngọc lục bảo', 'color': const Color(0xFF0D5C3A)},
    {'name': 'Đỏ thẫm tactical', 'color': const Color(0xFF9E1B1B)},
    {'name': 'Tím hoàng gia', 'color': const Color(0xFF5E35B1)},
    {'name': 'Hồng đậm cá tính', 'color': const Color(0xFFD81B60)},
    {'name': 'Cam hoàng hôn', 'color': const Color(0xFFE65100)},
    {'name': 'Xanh mòng két', 'color': const Color(0xFF00695C)},
    {'name': 'Xám đá phiến', 'color': const Color(0xFF37474F)},
  ];

  final List<Map<String, dynamic>> _darkColorOptions = [
    {'name': 'Xanh rêu tactical', 'color': const Color(0xFF2E3B34)},
    {'name': 'Cam sẫm', 'color': const Color(0xFFE83A14)},
    {'name': 'Xanh hải quân', 'color': const Color(0xFF0A2E5C)},
    {'name': 'Xanh lá thông', 'color': const Color(0xFF083D26)},
    {'name': 'Đỏ rượu vang', 'color': const Color(0xFF6B0E0E)},
    {'name': 'Tím thẫm', 'color': const Color(0xFF311B92)},
    {'name': 'Hồng san hô đậm', 'color': const Color(0xFF880E4F)},
    {'name': 'Đỏ đô sẫm', 'color': const Color(0xFFB71C1C)},
    {'name': 'Xanh mòng két đậm', 'color': const Color(0xFF004D40)},
    {'name': 'Đen than củi', 'color': const Color(0xFF212121)},
  ];

  late Color _selectedPrimary;
  late Color _selectedDark;
  late bool _useGradient;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();
    final themeState = themeCubit.state;

    if (!_initialized) {
      _selectedPrimary = themeState.customPrimaryColor;
      _selectedDark = themeState.customDarkColor;
      _useGradient = themeState.customUseGradient;
      _initialized = true;
    }

    final activeTheme = themeState.themeMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chọn Giao Diện',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Presets
            _buildSectionTitle('GIAO DIỆN SẴN CÓ', Icons.style_outlined),
            const SizedBox(height: AppSpacing.md),
            _buildPresetGrid(themeCubit, activeTheme),
            const SizedBox(height: AppSpacing.xl),

            // Section 2: Custom Theme Sandbox
            _buildSectionTitle('TỰ TẠO MÀU SẮC CÁ NHÂN', Icons.palette_outlined),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Tự do sáng tạo giao diện độc bản của riêng đồng chí. Live preview bên dưới sẽ thay đổi ngay lập tức.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Sandbox Preview
            ThemePreviewCard(
              primary: _selectedPrimary,
              dark: _selectedDark,
              useGradient: _useGradient,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Gradient toggle
            _buildGradientToggle(),
            const SizedBox(height: AppSpacing.lg),

            // Primary color selection
            _buildColorHeader('Màu chủ đạo (Primary Color)', _selectedPrimary),
            const SizedBox(height: AppSpacing.sm),
            _buildColorPicker(
              options: _primaryColorOptions,
              selectedColor: _selectedPrimary,
              onColorSelected: (color) {
                setState(() {
                  _selectedPrimary = color;
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Secondary/Dark color selection
            _buildColorHeader('Màu phụ / Màu tối (Secondary Color)', _selectedDark),
            const SizedBox(height: AppSpacing.sm),
            _buildColorPicker(
              options: _darkColorOptions,
              selectedColor: _selectedDark,
              onColorSelected: (color) {
                setState(() {
                  _selectedDark = color;
                });
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Apply Button
            _buildApplyButton(themeCubit),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).primaryColor),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.8,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildColorHeader(String label, Color activeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: activeColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPresetGrid(ThemeCubit cubit, AppThemeMode activeTheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.5,
      children: [
        _buildPresetCard(
          title: 'Cam nguyên bản',
          mode: AppThemeMode.orange,
          activeTheme: activeTheme,
          gradient: null,
          color: AppColors.primary,
          onTap: () => cubit.setTheme(AppThemeMode.orange),
        ),
        _buildPresetCard(
          title: 'Hologram ảo ảnh',
          mode: AppThemeMode.hologram,
          activeTheme: activeTheme,
          gradient: AppColors.hologramGradient,
          color: const Color(0xFF8EC5FC),
          onTap: () => cubit.setTheme(AppThemeMode.hologram),
        ),
        _buildPresetCard(
          title: 'Cầu vồng rực rỡ',
          mode: AppThemeMode.rainbow,
          activeTheme: activeTheme,
          gradient: AppColors.rainbowGradient,
          color: Colors.blue,
          onTap: () => cubit.setTheme(AppThemeMode.rainbow),
        ),
        _buildPresetCard(
          title: 'Quân đội anh hùng',
          mode: AppThemeMode.army,
          activeTheme: activeTheme,
          gradient: const LinearGradient(
            colors: [Color(0xFF4B5320), Color(0xFF2E3B34), Color(0xFF3F4E3E)],
          ),
          color: const Color(0xFF4B5320),
          onTap: () => cubit.setTheme(AppThemeMode.army),
        ),
      ],
    );
  }

  Widget _buildPresetCard({
    required String title,
    required AppThemeMode mode,
    required AppThemeMode activeTheme,
    required Gradient? gradient,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSelected = activeTheme == mode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          gradient: gradient,
          color: gradient == null ? color : null,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.3 : 0.05),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md - 2),
            color: Colors.black.withValues(alpha: 0.2),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          alignment: Alignment.bottomLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 4,
                        offset: Offset(1, 1),
                      )
                    ],
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hiệu ứng Gradient',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 2),
              Text(
                'Trộn màu sắc tạo sự mềm mại',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          Switch.adaptive(
            value: _useGradient,
            activeThumbColor: _selectedPrimary,
            activeTrackColor: _selectedPrimary.withValues(alpha: 0.5),
            onChanged: (val) {
              setState(() {
                _useGradient = val;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker({
    required List<Map<String, dynamic>> options,
    required Color selectedColor,
    required ValueChanged<Color> onColorSelected,
  }) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final color = option['color'] as Color;
          final isSelected = color == selectedColor;

          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Tooltip(
              message: option['name'] as String,
              child: Container(
                margin: const EdgeInsets.only(right: AppSpacing.md),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isSelected ? 0.35 : 0.1),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplyButton(ThemeCubit cubit) {
    final isCustomActive = cubit.state.themeMode == AppThemeMode.custom &&
        cubit.state.customPrimaryColor == _selectedPrimary &&
        cubit.state.customDarkColor == _selectedDark &&
        cubit.state.customUseGradient == _useGradient;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        onPressed: isCustomActive
            ? null
            : () {
                cubit.setCustomTheme(
                  primary: _selectedPrimary,
                  dark: _selectedDark,
                  useGradient: _useGradient,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã áp dụng giao diện tùy biến của đồng chí!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
        child: Text(
          isCustomActive ? 'Đang áp dụng giao diện này' : 'Áp Dụng Giao Diện Tùy Biến',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class ThemePreviewCard extends StatelessWidget {
  final Color primary;
  final Color dark;
  final bool useGradient;

  const ThemePreviewCard({
    super.key,
    required this.primary,
    required this.dark,
    required this.useGradient,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = useGradient
        ? LinearGradient(
            colors: [primary, dark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simulated App Bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: gradient,
              color: gradient == null ? primary : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md - 1),
                topRight: Radius.circular(AppRadius.md - 1),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.menu, color: Colors.white, size: 20),
                Text(
                  "Binh Trạm Mua Sắm",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Icon(Icons.shopping_cart, color: Colors.white, size: 20),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product details simulation
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(Icons.military_tech, color: primary, size: 30),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Ba Lô Chiến Thuật Tactical 45L",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Price
                          Text(
                            "950.000 xu",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Button and badge simulation
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          color: gradient == null ? primary : null,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Thêm Vào Giỏ Quân Nhu",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        "Đang theo dõi",
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
