import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../models/user_model.dart';

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

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.currentUser.email ?? '');
    _usernameController = TextEditingController(text: widget.currentUser.username);
    _statusController = TextEditingController(text: widget.currentUser.status ?? '');
    _firstNameController = TextEditingController(text: widget.currentUser.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.currentUser.lastName ?? '');
    _addressController = TextEditingController(text: widget.currentUser.address ?? '');
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
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _pickCoverImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _coverImageFile = File(picked.path));
    }
  }

  Future<void> _pickCoverImageWeb() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _coverImageWebFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
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

    if (!hasAnyTextChange && _avatarFile == null && _coverImageFile == null && _coverImageWebFile == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Vui lòng thay đổi ít nhất một trường thông tin')),
      );
      return;
    }

    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      messenger.showSnackBar(const SnackBar(content: Text('Email không hợp lệ')));
      return;
    }

    if (password.isNotEmpty && password.length < 6) {
      messenger.showSnackBar(const SnackBar(content: Text('Mật khẩu phải có ít nhất 6 ký tự')));
      return;
    }

    Future<bool> checkFile(File? file, String label) async {
      if (file == null) return true;
      final size = await file.length();
      if (size > 2 * 1024 * 1024) {
        messenger.showSnackBar(SnackBar(content: Text('$label quá lớn. Vui lòng chọn file dưới 2MB')));
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
        avatarFile: _avatarFile,
        firstName: firstName.isEmpty ? null : firstName,
        lastName: lastName.isEmpty ? null : lastName,
        address: address.isEmpty ? null : address,
        password: password.isEmpty ? null : password,
        coverImageFile: _coverImageFile,
        coverImageWebFile: _coverImageWebFile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is SetUserInfoSuccess || current is SetUserInfoFailure,
      listener: (context, state) {
        if (state is SetUserInfoSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật hồ sơ thành công')),
          );
          Navigator.pop(context, state.user);
        } else if (state is SetUserInfoFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${state.error}')),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is SetUserInfoLoading;
        return Scaffold(
          appBar: AppBar(title: const Text('Cập nhật hồ sơ')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _avatarFile != null
                          ? FileImage(_avatarFile!)
                          : (widget.currentUser.avatar != null && widget.currentUser.avatar!.isNotEmpty
                              ? NetworkImage(widget.currentUser.avatar!)
                              : null) as ImageProvider?,
                      child: (_avatarFile == null && (widget.currentUser.avatar == null || widget.currentUser.avatar!.isEmpty))
                          ? const Icon(Icons.person, size: 52, color: Colors.grey)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(child: Text('Chạm vào avatar để thay đổi')),
                const SizedBox(height: 24),
                _buildField(_emailController, 'Email', Icons.email),
                _buildField(_usernameController, 'Username', Icons.badge),
                _buildField(_statusController, 'Status', Icons.info_outline),
                _buildField(_firstNameController, 'Firstname', Icons.person),
                _buildField(_lastNameController, 'Lastname', Icons.person_outline),
                _buildField(_addressController, 'Address', Icons.location_on),
                _buildField(_passwordController, 'Password', Icons.lock, obscureText: true),
                const SizedBox(height: 16),
                _buildFilePickerCard(
                  title: 'Cover image',
                  description: 'Ảnh bìa chính cho hồ sơ',
                  selectedFile: _coverImageFile,
                  currentUrl: widget.currentUser.coverImage,
                  onPick: _pickCoverImage,
                ),
                const SizedBox(height: 16),
                _buildFilePickerCard(
                  title: 'Cover image web',
                  description: 'Ảnh bìa dành cho web',
                  selectedFile: _coverImageWebFile,
                  currentUrl: null,
                  onPick: _pickCoverImageWeb,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('LƯU THAY ĐỔI'),
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
    required VoidCallback onPick,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(description, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            if (selectedFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(selectedFile, height: 160, width: double.infinity, fit: BoxFit.cover),
              )
            else if (currentUrl != null && currentUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(currentUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
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


