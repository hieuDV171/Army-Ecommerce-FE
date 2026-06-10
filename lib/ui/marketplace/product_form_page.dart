import 'dart:io';
import 'package:army_ecommerce/models/address_model.dart';
import 'package:army_ecommerce/models/brand_model.dart';
import 'package:army_ecommerce/models/category_model.dart';
import 'package:army_ecommerce/models/product_model.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../util/constants/app_colors.dart';
import '../util/constants/app_radius.dart';
import '../util/constants/app_spacing.dart';
import '../util/widgets/app_button.dart';
import '../util/widgets/loading_overlay.dart';
import '../util/theme/special_app_theme.dart';

class ProductFormPage extends StatefulWidget {
  final ProductModel? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final MarketplaceRepository _repository;

  bool _isLoading = false;
  bool _isInitializing = true;
  String? _initError;

  // Form Fields
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _videoUrlController = TextEditingController();

  // Dropdown Lists
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  List<AddressModel> _warehouses = [];

  // Selected Values
  CategoryModel? _selectedCategory;
  BrandModel? _selectedBrand;
  AddressModel? _selectedWarehouse;

  // Images and Videos lists
  final List<String> _existingImages = [];
  final List<String> _deletedImages = [];
  final List<File> _newImageFiles = [];
  final List<String> _newUploadedImageUrls = [];

  // Product Variants
  final List<ProductSizeModel> _variants = [];

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    _repository = context.read<MarketplaceRepository>();
    _loadFormData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoading = true;
      _initError = null;
    });

    try {
      // Fetch categories, brands, and addresses (warehouses) concurrently
      final results = await Future.wait([
        _repository.getCategories(),
        _repository.getBrands(),
        _repository.getAddresses(),
      ]);

      if (!mounted) return;

      _categories = results[0] as List<CategoryModel>;
      _brands = results[1] as List<BrandModel>;
      _warehouses = results[2] as List<AddressModel>;

      // Populate details if edit mode
      if (_isEditMode) {
        final prod = widget.product!;
        _titleController.text = prod.title;
        _priceController.text = prod.price.toInt().toString();
        _descController.text = prod.described;
        
        if (prod.videos.isNotEmpty) {
          _videoUrlController.text = prod.videos.first.url;
        }

        _existingImages.addAll(prod.imageUrls);

        // Find Category
        if (prod.category != null) {
          _selectedCategory = _categories.firstWhere(
            (c) => c.id.toString() == prod.category!.id.toString(),
            orElse: () => _categories.isNotEmpty ? _categories.first : const CategoryModel(id: '0', name: ''),
          );
        }

        // Find Brand
        if (prod.brand != null) {
          _selectedBrand = _brands.firstWhere(
            (b) => b.id.toString() == prod.brand!.id.toString(),
            orElse: () => _brands.isNotEmpty ? _brands.first : const BrandModel(id: '', name: ''),
          );
        }

        // Find Warehouse
        if (prod.shipsFromId != null) {
          _selectedWarehouse = _warehouses.firstWhere(
            (w) => w.id.toString() == prod.shipsFromId.toString(),
            orElse: () => _warehouses.isNotEmpty ? _warehouses.first : const AddressModel(id: '', receiverName: '', phone: '', fullAddress: '', address: ''),
          );
        }

        // Populate Variants
        for (final size in prod.sizes) {
          _variants.add(size);
        }
      }

      setState(() {
        _isInitializing = false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = 'Lỗi tải thông tin ban đầu: $e';
        _isInitializing = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    if (_existingImages.length - _deletedImages.length + _newImageFiles.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ được chọn tối đa 4 hình ảnh')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (image == null) return;

    setState(() {
      _newImageFiles.add(File(image.path));
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
    });
  }

  void _removeExistingImage(String url) {
    setState(() {
      _deletedImages.add(url);
    });
  }

  void _undoRemoveExistingImage(String url) {
    setState(() {
      _deletedImages.remove(url);
    });
  }

  void _showAddVariantDialog({ProductSizeModel? variantToEdit, int? editIndex}) {
    final sizeController = TextEditingController(text: variantToEdit?.name ?? '');
    final colorController = TextEditingController(text: variantToEdit?.color ?? '');
    final stockController = TextEditingController(text: variantToEdit?.stock?.toString() ?? '');
    final weightController = TextEditingController(text: variantToEdit?.weight?.toString() ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(variantToEdit == null ? 'Thêm phân loại' : 'Sửa phân loại'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sizeController,
                decoration: const InputDecoration(
                  labelText: 'Kích cỡ (Size) *',
                  hintText: 'VD: M, L, XL, 40, 41...',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(
                  labelText: 'Màu sắc (Color) *',
                  hintText: 'VD: Đen, Rằn ri, Xanh lá...',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số lượng tồn kho *',
                  hintText: 'VD: 50, 100...',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Khối lượng (kg) *',
                  hintText: 'VD: 0.5, 1.2...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final size = sizeController.text.trim();
              final color = colorController.text.trim();
              final stock = int.tryParse(stockController.text.trim());
              final weight = double.tryParse(weightController.text.trim());

              if (size.isEmpty || color.isEmpty || stock == null || stock < 0 || weight == null || weight < 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin hợp lệ')),
                );
                return;
              }

              setState(() {
                final newVariant = ProductSizeModel(
                  id: variantToEdit?.id ?? '', // empty for new variant
                  name: size,
                  color: color,
                  stock: stock,
                  weight: weight,
                );

                if (editIndex != null) {
                  _variants[editIndex] = newVariant;
                } else {
                  _variants.add(newVariant);
                }
              });

              Navigator.pop(dialogContext);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWarehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Kho hàng (Địa chỉ gửi)')),
      );
      return;
    }

    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sản phẩm cần có ít nhất 1 phân loại hàng (kích cỡ/màu sắc...)')),
      );
      return;
    }

    final remainingImagesCount = _existingImages.length - _deletedImages.length + _newImageFiles.length;
    if (remainingImagesCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 hình ảnh sản phẩm')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload new files if any
      _newUploadedImageUrls.clear();
      for (final file in _newImageFiles) {
        final url = await _repository.uploadFile(file);
        if (url != null) {
          _newUploadedImageUrls.add(url);
        }
      }

      // 2. Prepare payload
      final title = _titleController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final description = _descController.text.trim();
      final shipFromId = int.parse(_selectedWarehouse!.id);
      
      final categoryId = _selectedCategory?.id != null ? int.tryParse(_selectedCategory!.id) : null;
      final brandId = _selectedBrand?.id != null ? int.tryParse(_selectedBrand!.id) : null;

      final variantsJson = _variants.map((v) {
        final map = <String, dynamic>{
          'size': v.name,
          'color': v.color,
          'stock': v.stock,
          'weight': v.weight,
        };
        if (_isEditMode && v.id.isNotEmpty) {
          map['id'] = int.tryParse(v.id) ?? v.id;
        }
        return map;
      }).toList();

      final videoUrl = _videoUrlController.text.trim();
      final List<Map<String, dynamic>> videos = [];
      if (videoUrl.isNotEmpty) {
        videos.add({'url': videoUrl});
      }

      if (_isEditMode) {
        final payload = <String, dynamic>{
          'title': title,
          'price': price,
          'description': description,
          'ship_from_id': shipFromId,
          'variants': variantsJson,
          'category_id': ?categoryId,
          'brand_id': ?brandId,
          'image_urls': _newUploadedImageUrls,
          'image_urls_del': _deletedImages,
          'videos': videos,
        };

        await _repository.updateProduct(widget.product!.id, payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật sản phẩm thành công')),
        );
      } else {
        final payload = <String, dynamic>{
          'title': title,
          'price': price,
          'description': description,
          'ship_from_id': shipFromId,
          'variants': variantsJson,
          'category_id': ?categoryId,
          'brand_id': ?brandId,
          'image_urls': _newUploadedImageUrls,
          'videos': videos,
        };

        await _repository.addProduct(payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm sản phẩm thành công')),
        );
      }

      Navigator.pop(context, true); // Pop back to listing and trigger refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final specialTheme = context.specialTheme;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: specialTheme.useGradient ? Colors.transparent : specialTheme.primaryDarkColor,
          flexibleSpace: specialTheme.useGradient
              ? Container(
                  decoration: BoxDecoration(
                    gradient: specialTheme.primaryGradient,
                  ),
                )
              : null,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            _isEditMode ? 'Chỉnh sửa sản phẩm' : 'Đăng bán sản phẩm',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        body: _isInitializing
            ? const Center(child: CircularProgressIndicator())
            : _initError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_initError!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton(onPressed: _loadFormData, child: const Text('Tải lại')),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Section 1: Images
                          _buildImageSection(),
                          const SizedBox(height: AppSpacing.lg),

                          // Section 2: Info
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Thông tin chung', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormField(
                                    controller: _titleController,
                                    decoration: const InputDecoration(labelText: 'Tên sản phẩm *'),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'Vui lòng nhập tên sản phẩm';
                                      if (val.trim().length > 255) return 'Tên sản phẩm tối đa 255 ký tự';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormField(
                                    controller: _priceController,
                                    decoration: const InputDecoration(labelText: 'Giá bán (xu) *'),
                                    keyboardType: TextInputType.number,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'Vui lòng nhập giá bán';
                                      final price = double.tryParse(val.trim());
                                      if (price == null || price < 0) return 'Giá bán phải là số hợp lệ >= 0';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormField(
                                    controller: _descController,
                                    decoration: const InputDecoration(labelText: 'Mô tả chi tiết *'),
                                    maxLines: 4,
                                    keyboardType: TextInputType.multiline,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'Vui lòng nhập mô tả';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormField(
                                    controller: _videoUrlController,
                                    decoration: const InputDecoration(
                                      labelText: 'Đường dẫn Video (Tùy chọn)',
                                      hintText: 'VD: https://youtube.com/...',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Section 3: Dropdowns
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Phân loại & Xuất xứ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: AppSpacing.md),

                                  // Category Dropdown
                                  DropdownButtonFormField<CategoryModel>(
                                    decoration: const InputDecoration(labelText: 'Danh mục'),
                                    initialValue: _selectedCategory,
                                    items: _categories
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                                        .toList(),
                                    onChanged: (val) => setState(() => _selectedCategory = val),
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // Brand Dropdown
                                  DropdownButtonFormField<BrandModel>(
                                    decoration: const InputDecoration(labelText: 'Thương hiệu'),
                                    initialValue: _selectedBrand,
                                    items: _brands
                                        .map((b) => DropdownMenuItem(value: b, child: Text(b.name)))
                                        .toList(),
                                    onChanged: (val) => setState(() => _selectedBrand = val),
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // Warehouse (Address) Dropdown
                                  DropdownButtonFormField<AddressModel>(
                                    decoration: const InputDecoration(labelText: 'Kho hàng gửi (Địa chỉ của bạn) *'),
                                    initialValue: _selectedWarehouse,
                                    items: _warehouses
                                        .map((w) => DropdownMenuItem(value: w, child: Text(w.address ?? w.fullAddress)))
                                        .toList(),
                                    onChanged: (val) => setState(() => _selectedWarehouse = val),
                                    validator: (val) => val == null ? 'Vui lòng chọn kho hàng gửi đi' : null,
                                  ),
                                  if (_warehouses.isEmpty) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    const Text(
                                      'Bạn chưa đăng ký địa chỉ kho hàng nào. Hãy thêm địa chỉ của bạn trước khi bán sản phẩm.',
                                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Section 4: Variants
                          _buildVariantsSection(),
                          const SizedBox(height: AppSpacing.xl),

                          // Submit Button
                          AppButton(
                            label: _isEditMode ? 'CẬP NHẬT SẢN PHẨM' : 'ĐĂNG BÁN NGAY',
                            icon: _isEditMode ? Icons.check : Icons.rocket_launch,
                            onPressed: _warehouses.isEmpty ? null : _submitForm,
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildImageSection() {
    final activeImagesCount = _existingImages.length - _deletedImages.length + _newImageFiles.length;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hình ảnh sản phẩm *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '$activeImagesCount / 4',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Chọn tối thiểu 1 và tối đa 4 hình ảnh mô tả rõ sản phẩm của bạn',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Image grid/list
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Pick Image Slot
                  if (activeImagesCount < 4)
                    InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppColors.textSecondary),
                            SizedBox(height: 4),
                            Text('Chọn ảnh', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: AppSpacing.sm),

                  // Existing image items
                  ..._existingImages.map((url) {
                    final isDeleted = _deletedImages.contains(url);
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Stack(
                        children: [
                          Opacity(
                            opacity: isDeleted ? 0.3 : 1.0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: Image.network(
                                url,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (!isDeleted)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _removeExistingImage(url),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            )
                          else
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _undoRemoveExistingImage(url),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.undo, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

                  // New selected file items
                  ..._newImageFiles.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final file = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Image.file(
                              file,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => _removeNewImage(idx),
                              child: Container(
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantsSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Phân loại sản phẩm *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                TextButton.icon(
                  onPressed: () => _showAddVariantDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm phân loại', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const Text(
              'Thêm kích cỡ, màu sắc, số lượng tồn kho và trọng lượng cho mỗi phân loại',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_variants.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 36, color: Colors.grey),
                    SizedBox(height: AppSpacing.sm),
                    Text('Chưa có phân loại nào', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _variants.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final variant = _variants[index];
                  final displayStock = variant.stock?.toString() ?? '0';
                  final displayWeight = variant.weight?.toString() ?? '0';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Size: ${variant.name} | Màu: ${variant.color ?? "Mặc định"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Kho: $displayStock sản phẩm | Nặng: ${displayWeight}kg',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showAddVariantDialog(variantToEdit: variant, editIndex: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            setState(() {
                              _variants.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
