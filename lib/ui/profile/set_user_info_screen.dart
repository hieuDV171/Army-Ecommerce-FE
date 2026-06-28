import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/session_manager.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../models/user_model.dart';
import '../util/widgets/image_crop_screen.dart';
import '../util/widgets/avatar_with_frame.dart';
import '../util/widgets/app_button.dart';
import '../util/theme/special_app_theme.dart';
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';

class SetUserInfoScreen extends StatefulWidget {
  final UserModel currentUser;

  const SetUserInfoScreen({super.key, required this.currentUser});

  @override
  State<SetUserInfoScreen> createState() => _SetUserInfoScreenState();
}

class _SetUserInfoScreenState extends State<SetUserInfoScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _usernameController;
  late final TextEditingController _statusController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _passwordController;

  final ImagePicker _picker = ImagePicker();
  File? _avatarFile;
  File? _coverImageFile;
  File? _coverImageWebFile;

  bool _removeAvatar = false;
  bool _removeCoverImage = false;
  bool _removeCoverImageWeb = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.currentUser.email ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.currentUser.username,
    );
    _statusController = TextEditingController(
      text: widget.currentUser.status ?? '',
    );
    _firstNameController = TextEditingController(
      text: widget.currentUser.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.currentUser.lastName ?? '',
    );
    _addressController = TextEditingController(
      text: widget.currentUser.address ?? '',
    );
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _statusController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      final croppedFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (_) => ImageCropScreen(
            imageFile: File(picked.path),
            isCircle: true,
            title: 'Cắt ảnh đại diện',
          ),
        ),
      );
      if (croppedFile != null && mounted) {
        setState(() {
          _avatarFile = croppedFile;
          _removeAvatar = false;
        });
      }
    }
  }

  Future<void> _pickCoverImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      final croppedFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (_) => ImageCropScreen(
            imageFile: File(picked.path),
            isCircle: false,
            aspectRatio: 2.0,
            title: 'Cắt ảnh bìa hồ sơ',
          ),
        ),
      );
      if (croppedFile != null && mounted) {
        setState(() {
          _coverImageFile = croppedFile;
          _removeCoverImage = false;
        });
      }
    }
  }

  Future<void> _pickCoverImageWeb() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      final croppedFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (_) => ImageCropScreen(
            imageFile: File(picked.path),
            isCircle: false,
            aspectRatio: 1.0,
            title: 'Cắt ảnh khung đại diện',
          ),
        ),
      );
      if (croppedFile != null && mounted) {
        setState(() {
          _coverImageWebFile = croppedFile;
          _removeCoverImageWeb = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final authBloc = context.read<AuthBloc>();

    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final status = _statusController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final address = _addressController.text.trim();
    final password = _passwordController.text.trim();

    final hasAnyTextChange = [
      email,
      username,
      status,
      firstName,
      lastName,
      address,
      password,
    ].any((value) => value.isNotEmpty);

    if (!hasAnyTextChange &&
        _avatarFile == null &&
        _coverImageFile == null &&
        _coverImageWebFile == null &&
        !_removeAvatar &&
        !_removeCoverImage &&
        !_removeCoverImageWeb) {
      AppSnackBar.show(
        context,
        message: 'Vui lòng thay đổi ít nhất một trường thông tin',
      );
      return;
    }

    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      AppSnackBar.showError(context, message: 'Email không hợp lệ');
      return;
    }

    if (password.isNotEmpty && password.length < 6) {
      AppSnackBar.show(context, message: 'Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    Future<bool> checkFile(File? file, String label) async {
      if (file == null) return true;
      final size = await file.length();
      if (size > 2 * 1024 * 1024) {
        if (!mounted) return false;
        AppSnackBar.showError(
          context,
          message: '$label quá lớn. Vui lòng chọn file dưới 2MB',
        );
        return false;
      }
      return true;
    }

    if (!await checkFile(_avatarFile, 'Avatar')) return;
    if (!await checkFile(_coverImageFile, 'Cover image')) return;
    if (!await checkFile(_coverImageWebFile, 'Cover image web')) return;

    if (!mounted) return;

    authBloc.add(
      SetUserInfoRequested(
        currentUser: widget.currentUser,
        email: email.isEmpty ? null : email,
        username: username.isEmpty ? null : username,
        status: status.isEmpty ? null : status,
        avatarFile: _removeAvatar ? null : _avatarFile,
        firstName: firstName.isEmpty ? null : firstName,
        lastName: lastName.isEmpty ? null : lastName,
        address: address.isEmpty ? null : address,
        password: password.isEmpty ? null : password,
        coverImageFile: _removeCoverImage ? null : _coverImageFile,
        coverImageWebFile: _removeCoverImageWeb ? null : _coverImageWebFile,
        removeAvatar: _removeAvatar,
        removeCoverImage: _removeCoverImage,
        removeCoverImageWeb: _removeCoverImageWeb,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is SetUserInfoSuccess || current is SetUserInfoFailure,
      listener: (context, state) {
        if (state is SetUserInfoSuccess) {
          AppSnackBar.showSuccess(
            context,
            message: 'Cập nhật hồ sơ thành công',
          );
          SessionManager.updateAvatarCacheBustKey();
          Navigator.pop(context, state.user);
        } else if (state is SetUserInfoFailure) {
          AppSnackBar.showError(context, message: 'Lỗi: ${state.error}');
        }
      },
      builder: (context, state) {
        final isLoading = state is SetUserInfoLoading;
        final specialTheme = context.specialTheme;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: specialTheme.useGradient
                ? Colors.transparent
                : specialTheme.primaryDarkColor,
            flexibleSpace: specialTheme.useGradient
                ? Container(
                    decoration: BoxDecoration(
                      gradient: specialTheme.primaryGradient,
                    ),
                  )
                : null,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Cập nhật hồ sơ',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      AvatarWithFrame(
                        radius: 52,
                        avatarImage: _avatarFile != null
                            ? FileImage(_avatarFile!)
                            : (!_removeAvatar &&
                                      widget.currentUser.avatar != null &&
                                      widget.currentUser.avatar!.isNotEmpty
                                  ? SessionManager.getImageProvider(
                                      widget.currentUser.avatar!,
                                    )
                                  : null),
                        frameFile: _removeCoverImageWeb
                            ? null
                            : _coverImageWebFile,
                        frameUrl: _removeCoverImageWeb
                            ? null
                            : widget.currentUser.coverImageWeb,
                        fallbackChild:
                            (_avatarFile == null &&
                                (widget.currentUser.avatar == null ||
                                    widget.currentUser.avatar!.isEmpty ||
                                    _removeAvatar))
                            ? const Icon(
                                Icons.person,
                                size: 52,
                                color: Colors.grey,
                              )
                            : null,
                        onTap: _pickAvatar,
                      ),
                      if (_avatarFile != null ||
                          (!_removeAvatar &&
                              widget.currentUser.avatar != null &&
                              widget.currentUser.avatar!.isNotEmpty))
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _avatarFile = null;
                                _removeAvatar = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Center(child: Text('Chạm vào avatar để thay đổi')),
                const SizedBox(height: 24),
                _buildField(_emailController, 'Email', Icons.email),
                _buildField(_usernameController, 'Username', Icons.badge),
                _buildField(_statusController, 'Status', Icons.info_outline),
                _buildField(_firstNameController, 'Firstname', Icons.person),
                _buildField(
                  _lastNameController,
                  'Lastname',
                  Icons.person_outline,
                ),
                _buildField(_addressController, 'Address', Icons.location_on),
                _buildField(
                  _passwordController,
                  'Password',
                  Icons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _buildFilePickerCard(
                  title: 'Cover image',
                  description: 'Ảnh bìa chính cho hồ sơ',
                  selectedFile: _coverImageFile,
                  currentUrl: widget.currentUser.coverImage,
                  isRemoved: _removeCoverImage,
                  onPick: _pickCoverImage,
                  onRemove: () {
                    setState(() {
                      _coverImageFile = null;
                      _removeCoverImage = true;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildFilePickerCard(
                  title: 'Avatar Frame',
                  description:
                      'Khung viền bao quanh ảnh đại diện (nên là ảnh vuông PNG trong suốt)',
                  selectedFile: _coverImageWebFile,
                  currentUrl: widget.currentUser.coverImageWeb,
                  isRemoved: _removeCoverImageWeb,
                  onPick: _pickCoverImageWeb,
                  isFrame: true,
                  onRemove: () {
                    setState(() {
                      _coverImageWebFile = null;
                      _removeCoverImageWeb = true;
                    });
                  },
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'LƯU THAY ĐỔI',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  Widget _buildFilePickerCard({
    required String title,
    required String description,
    required File? selectedFile,
    required String? currentUrl,
    required bool isRemoved,
    required VoidCallback onPick,
    required VoidCallback onRemove,
    bool isFrame = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (selectedFile != null ||
                    (!isRemoved && currentUrl != null && currentUrl.isNotEmpty))
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: onRemove,
                    tooltip: 'Xóa ảnh',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(description, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            if (isFrame)
              Center(
                child: AvatarWithFrame(
                  radius: 64,
                  avatarImage: _avatarFile != null
                      ? FileImage(_avatarFile!)
                      : (!_removeAvatar &&
                                widget.currentUser.avatar != null &&
                                widget.currentUser.avatar!.isNotEmpty
                            ? SessionManager.getImageProvider(
                                widget.currentUser.avatar!,
                              )
                            : null),
                  frameFile: isRemoved ? null : selectedFile,
                  frameUrl: isRemoved ? null : currentUrl,
                  fallbackChild:
                      (_avatarFile == null &&
                          (widget.currentUser.avatar == null ||
                              widget.currentUser.avatar!.isEmpty ||
                              _removeAvatar))
                      ? const Icon(Icons.person, size: 64, color: Colors.grey)
                      : null,
                ),
              )
            else if (selectedFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  selectedFile,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else if (!isRemoved && currentUrl != null && currentUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  currentUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 160,
                width: double.infinity,
                alignment: Alignment.center,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 48, color: Colors.grey),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Chọn ảnh'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
