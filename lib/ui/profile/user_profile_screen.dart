import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../models/user_model.dart';
import 'set_user_info_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String? userId;
  const UserProfileScreen({super.key, this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserModel? _profile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthBloc>().add(GetUserInfoRequested(userId: widget.userId == null ? null : int.tryParse(widget.userId!)));
    });
  }

  bool get _isOwnProfile => widget.userId == null;

  void _loadProfile() {
    context.read<AuthBloc>().add(
      GetUserInfoRequested(userId: widget.userId == null ? null : int.tryParse(widget.userId!)),
    );
  }

  String _valueOf(String? value) => value == null || value.trim().isEmpty ? '-' : value;

  String _boolLabel(bool? value) {
    if (value == null) return '-';
    return value ? 'Có' : 'Không';
  }

  String _defaultAddressLabel(dynamic defaultAddress) {
    if (defaultAddress == null) return '-';
    if (defaultAddress is Map) {
      final address = defaultAddress['address']?.toString();
      final addressId = defaultAddress['address_id']?.toString();
      if ((address ?? '').isNotEmpty && (addressId ?? '').isNotEmpty) {
        return '$address (ID: $addressId)';
      }
      if ((address ?? '').isNotEmpty) return address!;
      if ((addressId ?? '').isNotEmpty) return 'ID: $addressId';
    }
    final text = defaultAddress.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  Future<void> _openEditProfile(UserModel profile) async {
    final authBloc = context.read<AuthBloc>();
    final updatedUser = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: authBloc,
          child: SetUserInfoScreen(currentUser: profile),
        ),
      ),
    );

    if (!mounted) return;

    if (updatedUser != null) {
      setState(() {
        _profile = updatedUser;
        _errorMessage = null;
      });
    }

    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is GetUserInfoSuccess ||
          current is GetUserInfoFailure ||
          current is SetUserInfoSuccess,
      listener: (context, state) {
        if (state is GetUserInfoSuccess) {
          setState(() {
            _profile = state.user;
            _errorMessage = null;
          });
        } else if (state is GetUserInfoFailure) {
          setState(() {
            _errorMessage = state.error;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi lấy hồ sơ: ${state.error}')),
          );
        } else if (state is SetUserInfoSuccess) {
          setState(() {
            _profile = state.user;
            _errorMessage = null;
          });
        }
      },
      builder: (context, state) {
        final isLoading = state is GetUserInfoLoading;
        final profile = _profile;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hồ sơ của tôi'),
            actions: [
              IconButton(
                onPressed: isLoading ? null : _loadProfile,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (isLoading && profile == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (profile == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline, size: 72, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage ?? 'Không có dữ liệu hồ sơ',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProfile,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _loadProfile(),
                child: CustomScrollView(
                  slivers: [
                    // Header với cover image
                    SliverToBoxAdapter(
                      child: LayoutBuilder(builder: (context, constraints) {
                        final double coverHeight = (constraints.maxWidth * 0.42).clamp(180.0, 280.0).toDouble();
                        const double avatarRadius = 56.0;
                        const double avatarPadding = 4.0; // padding around avatar to create white border
                        final double avatarBoxSize = avatarRadius * 2 + avatarPadding * 2; // includes padding
                        final double halfAvatarBox = avatarBoxSize / 2;
                        final double headerHeight = coverHeight + halfAvatarBox;

                        return SizedBox(
                          width: double.infinity,
                          height: headerHeight,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 0,
                                height: coverHeight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    image: profile.coverImage != null && profile.coverImage!.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(profile.coverImage!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    color: profile.coverImage == null || profile.coverImage!.isEmpty
                                        ? Colors.grey.shade300
                                        : null,
                                  ),
                                ),
                              ),

                              // Avatar + status indicator
                              Positioned(
                                left: 0,
                                right: 0,
                                top: coverHeight - halfAvatarBox,
                                child: Center(
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Avatar with white border inside a fixed-size box so we can position the dot
                                      SizedBox(
                                        width: avatarBoxSize,
                                        height: avatarBoxSize,
                                        child: Stack(
                                          children: [
                                            // Centered avatar with white circular border
                                            Center(
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: CircleAvatar(
                                                  radius: avatarRadius,
                                                  backgroundImage: profile.avatar != null && profile.avatar!.isNotEmpty
                                                      ? NetworkImage(profile.avatar!)
                                                      : null,
                                                  child: profile.avatar == null || profile.avatar!.isEmpty
                                                      ? const Icon(Icons.person, size: 56, color: Colors.grey)
                                                      : null,
                                                ),
                                              ),
                                            ),

                                            if (profile.online == true)
                                              const Positioned(
                                                right: 4,
                                                bottom: 4,
                                                child: _OnlineStatusDot(),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),

                    // Username và status
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                profile.username,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Trạng thái: ${_valueOf(profile.status)}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // Profile sections
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _SectionCard(
                              title: 'Thông tin hiển thị',
                              children: [
                                _infoRow('Username', profile.username),
                                _infoRow('Họ', profile.firstName),
                                _infoRow('Tên', profile.lastName),
                                _infoRow('Email', profile.email),
                                _infoRow('Số điện thoại', profile.phoneNumber),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _SectionCard(
                              title: 'Thông tin tài khoản',
                              children: [
                                _infoRow('ID', profile.id),
                                _infoRow('Active', profile.active.toString()),
                                _infoRow('Đang follow', _boolLabel(profile.followed)),
                                _infoRow('Bị chặn', _boolLabel(profile.isBlocked)),
                                _infoRow('Listing', profile.listing?.toString()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _SectionCard(
                              title: 'Địa chỉ',
                              children: [
                                _infoRow('Địa chỉ', profile.address),
                                _infoRow('Thành phố', profile.city),
                                _infoRow('Địa chỉ mặc định', _defaultAddressLabel(profile.defaultAddress)),
                              ],
                            ),
                            if (_isOwnProfile) ...[
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: isLoading ? null : () => _openEditProfile(profile),
                                icon: const Icon(Icons.edit),
                                label: const Text('Cập nhật hồ sơ'),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(_valueOf(value)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _OnlineStatusDot extends StatefulWidget {
  const _OnlineStatusDot();

  @override
  State<_OnlineStatusDot> createState() => _OnlineStatusDotState();
}

class _OnlineStatusDotState extends State<_OnlineStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _scale = Tween<double>(begin: 1.0, end: 2.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent.withValues(alpha: _opacity.value),
                  ),
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x6624D366),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}