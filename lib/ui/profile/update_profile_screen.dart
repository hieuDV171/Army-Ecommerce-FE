import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/services/session_manager.dart';

class UpdateProfileScreen extends StatefulWidget {
  final String currentUsername;
  const UpdateProfileScreen({super.key, required this.currentUsername});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  late TextEditingController _nameController;
  File? _selectedImage;
  String? _currentAvatarUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUsername);
    _loadAvatarFromStorage();
  }

  Future<void> _loadAvatarFromStorage() async {
    final avatar = await SessionManager.getAvatar();
    if (mounted) {
      setState(() {
        _currentAvatarUrl = avatar;
      });
    }
  }

  // Hàm mở thư viện ảnh
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      // imageQuality: 70
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _onSubmit() async {
    final messenger = ScaffoldMessenger.of(context);
    final authBloc = context.read<AuthBloc>();

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Tên không được bỏ trống')));
      return;
    }

    if (_selectedImage != null) {
      // Chặn ảnh quá lớn để tránh upload thất bại trên mạng yếu.
      final fileSize = await _selectedImage!.length();
      if (!mounted) return;

      if (fileSize > 2097152) { // (2 * 1024 * 1024 bytes)
        messenger.showSnackBar(
          const SnackBar(content: Text('Dung lượng ảnh quá lớn. Vui lòng chọn ảnh dưới 2MB')),
        );
        return;
      }
    }

    // Upload ảnh sẽ được xử lý trong repository
    authBloc.add(
      ChangeInfoRequested(username: name, avatarFile: _selectedImage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ChangeInfoSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật hồ sơ thành công!')));
          Navigator.pop(context, state.updatedUser); // Trả user mới về màn hình trước
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${state.error}')));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Cập nhật hồ sơ')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // --- VÙNG CHỌN ẢNH ĐẠI DIỆN ---
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty
                              ? NetworkImage(_currentAvatarUrl!)
                              : null),
                      child: (_selectedImage == null && (_currentAvatarUrl == null || _currentAvatarUrl!.isEmpty))
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- VÙNG ĐỔI TÊN ---
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị (Username)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 40),

              // --- NÚT XÁC NHẬN ---
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state is AuthLoading ? null : _onSubmit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blue,
                    ),
                    child: state is AuthLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('LƯU THÔNG TIN', style: TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}