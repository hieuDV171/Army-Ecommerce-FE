import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/checkout_model.dart';
import '../../repositories/marketplace_repository.dart';
import '../util/widgets/app_snackbar.dart';

import '../util/constants/app_colors.dart';
import '../util/constants/app_spacing.dart';
import '../util/constants/app_radius.dart';
import '../util/widgets/app_button.dart';
import '../util/widgets/app_text_field.dart';

/// Màn hình Quy đổi điểm thưởng (Tuần 8)
/// - Tab 1: Upload video (upload_video API) ✅
/// - Tab 2: Khiếu nại (create_reward_appeal API) ✅
/// - Tab 3: Xem lịch sử quy đổi (get_reward_history API) ⏳ BE chưa sẵn sàng
class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _appealRewardIdCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _appealRewardIdCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _appealRewardIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm thưởng'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.cloud_upload_outlined), text: 'Gửi chiến tích'),
            Tab(icon: Icon(Icons.feedback_outlined), text: 'Khiếu nại'),
            Tab(icon: Icon(Icons.history), text: 'Lịch sử'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UploadVideoTab(picker: _picker),
          _RewardAppealTab(rewardIdCtrl: _appealRewardIdCtrl),
          _RewardHistoryTab(
            tabController: _tabController,
            appealRewardIdCtrl: _appealRewardIdCtrl,
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Upload video ───────────────────────────────────────────────────

class _UploadVideoTab extends StatefulWidget {
  final ImagePicker picker;

  const _UploadVideoTab({required this.picker});

  @override
  State<_UploadVideoTab> createState() => _UploadVideoTabState();
}

class _UploadVideoTabState extends State<_UploadVideoTab> {
  XFile? _mediaFile;
  bool _isImage = false;
  bool _isLoading = false;
  final TextEditingController _descriptionCtrl = TextEditingController();

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await widget.picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() {
        _mediaFile = picked;
        _isImage = true;
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final picked = await widget.picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 5),
    );
    if (picked != null && mounted) {
      setState(() {
        _mediaFile = picked;
        _isImage = false;
      });
    }
  }

  Future<void> _submitProof() async {
    final description = _descriptionCtrl.text.trim();
    if (description.isEmpty) {
      AppSnackBar.showError(context, message: 'Vui lòng nhập mô tả chiến công');
      return;
    }
    if (_mediaFile == null) {
      AppSnackBar.showError(context, message: 'Vui lòng chọn hình ảnh hoặc video minh chứng');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = context.read<MarketplaceRepository>();

      // 1. Upload file
      final uploadedUrl = await repo.uploadFile(File(_mediaFile!.path));
      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        throw Exception('Không thể tải tệp tin lên máy chủ');
      }

      // 2. Add reward proof
      final result = await repo.addRewardProof(
        description: description,
        imageUrl: _isImage ? uploadedUrl : null,
        videoUrl: !_isImage ? uploadedUrl : null,
      );

      if (!mounted) return;

      setState(() {
        _descriptionCtrl.clear();
        _mediaFile = null;
      });

      if (result != null && result.containsKey('proof')) {
        final proof = result['proof'] as Map<String, dynamic>?;
        if (proof != null) {
          final aiScore = proof['ai_score'] as num? ?? -1;
          final rewardCoin = proof['reward_coin'] as num? ?? 0;
          _showRewardResultDialog(context, aiScore, rewardCoin);
        } else {
          AppSnackBar.showSuccess(context, message: 'Gửi minh chứng chiến tích thành công');
        }
      } else {
        AppSnackBar.showSuccess(context, message: 'Gửi minh chứng chiến tích thành công');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, message: 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRewardResultDialog(BuildContext context, num aiScore, num rewardCoin) {
    final success = aiScore > 0;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final formatter = NumberFormat.decimalPattern('vi_VN');
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: success ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    success ? Icons.check_circle_outline : Icons.error_outline,
                    size: 64,
                    color: success ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  success ? 'Thẩm Định Thành Công!' : 'Thẩm Định Thất Bại',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: success ? Colors.green : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  success
                      ? 'AI xác nhận chiến tích của bạn trùng khớp với mô tả.'
                      : 'AI xác nhận nội dung không khớp với mô tả chiến tích đã nhập.',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                if (success && rewardCoin > 0) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '+${formatter.format(rewardCoin)} xu',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: success ? Colors.green : Colors.grey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = _mediaFile != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner thông tin
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.infoBlue.withValues(alpha: 0.12),
                  AppColors.infoBlueDark.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.infoBlue.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.infoBlue, size: 20),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Gửi minh chứng chiến tích (hình ảnh hoặc video) để nhận điểm thưởng quy đổi thành xu nội bộ.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.infoBlue,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Tên/Mã điểm thưởng
          AppTextField(
            controller: _descriptionCtrl,
            label: 'Mô tả chiến công *',
            hint: 'Ví dụ: 1 người lính bị thương, 1 xe tăng bị phá hủy...',
          ),
          const SizedBox(height: AppSpacing.lg),

          // Khu vực chọn minh chứng
          const Text(
            'Hình ảnh / Video minh chứng *',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),

          GestureDetector(
            onTap: _showMediaSourceSheet,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 180,
              decoration: BoxDecoration(
                color: hasMedia ? Colors.black : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: hasMedia ? AppColors.primary : AppColors.border,
                  width: hasMedia ? 2 : 1,
                ),
              ),
              child: hasMedia
                  ? (_isImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.lg - 2),
                          child: Image.file(
                            File(_mediaFile!.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : _VideoPreview(file: File(_mediaFile!.path)))
                  : const _MediaPlaceholder(),
            ),
          ),

          if (hasMedia) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _mediaFile!.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _mediaFile = null),
                  child: const Text(
                    'Xóa',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Nút gửi
          AppButton(
            label: 'Gửi minh chứng',
            icon: Icons.cloud_upload_outlined,
            isLoading: _isLoading,
            onPressed: _submitProof,
          ),
        ],
      ),
    );
  }

  void _showMediaSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Chọn nguồn minh chứng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Chọn ảnh từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.video_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Chọn video từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.videocam_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Quay video mới'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab 2: Khiếu nại ────────────────────────────────────────────────────────

class _RewardAppealTab extends StatefulWidget {
  final TextEditingController rewardIdCtrl;

  const _RewardAppealTab({required this.rewardIdCtrl});

  @override
  State<_RewardAppealTab> createState() => _RewardAppealTabState();
}

class _RewardAppealTabState extends State<_RewardAppealTab> {
  final TextEditingController _reasonCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAppeal() async {
    final rewardId = widget.rewardIdCtrl.text.trim();
    final reason = _reasonCtrl.text.trim();

    if (rewardId.isEmpty) {
      AppSnackBar.showError(context, message: 'Vui lòng nhập mã điểm thưởng (Reward ID)');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = context.read<MarketplaceRepository>();
      final appeal = await repo.createRewardAppeal(
        rewardId: rewardId,
        reason: reason.isNotEmpty ? reason : null,
      );

      if (!mounted) return;
      final apId = appeal.appealId ?? '';
      final rwId = appeal.rewardId ?? rewardId;
      AppSnackBar.showSuccess(
        context,
        message: 'Đã gửi khiếu nại thành công cho minh chứng #$rwId! Mã khiếu nại của bạn là #$apId.',
      );
      setState(() {
        widget.rewardIdCtrl.clear();
        _reasonCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, message: 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner thông tin
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warning.withValues(alpha: 0.12),
                  AppColors.warning.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Gửi khiếu nại nếu bạn chưa nhận đúng số xu hoặc gặp lỗi khi hệ thống duyệt video chiến tích.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.warning,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Thông tin khiếu nại
          AppTextField(
            controller: widget.rewardIdCtrl,
            label: 'Mã điểm thưởng (Reward ID) *',
            hint: 'Nhập reward_id cần khiếu nại',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _reasonCtrl,
            label: 'Lý do khiếu nại (tùy chọn)',
            hint: 'Mô tả lý do bạn muốn khiếu nại...',
          ),
          const SizedBox(height: AppSpacing.xl),

          // Nút gửi khiếu nại
          AppButton(
            label: 'Gửi khiếu nại',
            icon: Icons.send_outlined,
            isLoading: _isLoading,
            onPressed: _submitAppeal,
          ),
        ],
      ),
    );
  }
}

// ─── Tab 3: Lịch sử điểm thưởng ─────────────────────────────────────────────

class _RewardHistoryTab extends StatefulWidget {
  final TabController tabController;
  final TextEditingController appealRewardIdCtrl;

  const _RewardHistoryTab({
    required this.tabController,
    required this.appealRewardIdCtrl,
  });

  @override
  State<_RewardHistoryTab> createState() => _RewardHistoryTabState();
}

class _RewardHistoryTabState extends State<_RewardHistoryTab> {
  final ScrollController _scrollController = ScrollController();
  List<RewardHistoryModel> _history = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 240;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _history = [];
      _currentPage = 1;
      _hasReachedEnd = false;
    });
    try {
      final repository = context.read<MarketplaceRepository>();
      final list = await repository.getRewardHistory(
        index: 1,
        count: 20,
      );
      if (!mounted) return;
      setState(() {
        _history = list;
        _currentPage = 2;
        _hasReachedEnd = list.length < 20;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _hasReachedEnd || _isLoading) return;
    if (!mounted) return;
    setState(() => _isLoadingMore = true);
    try {
      final repository = context.read<MarketplaceRepository>();
      final list = await repository.getRewardHistory(
        index: _currentPage,
        count: 20,
      );
      if (!mounted) return;
      setState(() {
        _history = [..._history, ...list];
        _currentPage++;
        _hasReachedEnd = list.length < 20;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _load();
  }

  Future<void> _showDetail(RewardHistoryModel item) async {
    if (item.rewardId == null) {
      AppSnackBar.showError(context, message: 'Không tìm thấy mã điểm thưởng');
      return;
    }

    // Hiển thị loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repository = context.read<MarketplaceRepository>();
      final proof = await repository.getRewardProof(item.rewardId!);
      if (!mounted) return;
      Navigator.pop(context); // Đóng loading

      _showProofDetailBottomSheet(proof);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Đóng loading
      AppSnackBar.showError(context, message: 'Không thể tải chi tiết: $e');
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null) {
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && mounted) {
          AppSnackBar.showError(context, message: 'Không thể mở liên kết video');
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(
            context,
            message: 'Không thể mở liên kết: Vui lòng đóng ứng dụng và chạy lại từ đầu (Cold Boot) nếu bạn vừa cài đặt gói.',
          );
        }
      }
    } else {
      if (mounted) {
        AppSnackBar.showError(context, message: 'Đường dẫn video không hợp lệ');
      }
    }
  }

  void _showProofDetailBottomSheet(Map<String, dynamic> proof) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final formatter = NumberFormat.decimalPattern('vi_VN');
        final id = proof['id']?.toString() ?? 'N/A';
        final description = proof['description']?.toString() ?? 'Không có mô tả';
        final rawCoin = proof['reward_coin'];
        final rewardCoin = rawCoin is num ? rawCoin : (num.tryParse(rawCoin?.toString() ?? '') ?? 0);
        final rawScore = proof['ai_score'];
        final aiScore = rawScore is num ? rawScore : (num.tryParse(rawScore?.toString() ?? '') ?? 0);
        final status = proof['status']?.toString() ?? (aiScore > 0 ? 'approved' : 'rejected');
        final createdAt = proof['created_at']?.toString() ?? '';
        final videoUrl = proof['video_url']?.toString() ?? '';
        final imageUrl = proof['image_url']?.toString() ?? '';

        final parsedDate = DateTime.tryParse(createdAt);
        final dateStr = parsedDate != null ? DateFormat('HH:mm dd/MM/yyyy').format(parsedDate.toLocal()) : createdAt;

        final isApproved = status == 'approved' || aiScore > 0;
        final isRejected = status == 'rejected' || aiScore == 0;

        Color statusColor = AppColors.warning;
        String statusLabel = 'Đang chờ duyệt';
        IconData statusIcon = Icons.pending_outlined;

        if (isApproved) {
          statusColor = AppColors.success;
          statusLabel = 'Đã duyệt';
          statusIcon = Icons.check_circle_outlined;
        } else if (isRejected) {
          statusColor = AppColors.danger;
          statusLabel = 'Từ chối';
          statusIcon = Icons.cancel_outlined;
        }

        final appealsList = proof['appeals'] as List?;

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              ),
              child: Column(
                children: [
                  // Thanh kéo ở đầu
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Chi tiết minh chứng',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, color: statusColor, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Mã minh chứng: #$id',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Thời gian: $dateStr',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                        const Divider(height: AppSpacing.xl),

                        // Mô tả chiến công
                        const Text(
                          'Mô tả chiến công',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Điểm AI & Coin nhận
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('AI Đánh Giá', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(aiScore).toStringAsFixed(1)} / 1.0',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: aiScore > 0 ? AppColors.success : AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Thưởng Xu', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '+${formatter.format(rewardCoin)} xu',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Phương tiện minh chứng
                        if (imageUrl.isNotEmpty) ...[
                          const Text(
                            'Hình ảnh minh chứng',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 120,
                                color: AppColors.surface,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image_outlined, size: 40, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ] else if (videoUrl.isNotEmpty) ...[
                          const Text(
                            'Video minh chứng (Nhấn để xem)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          InkWell(
                            onTap: () => _launchUrl(videoUrl),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_circle_outline, color: Colors.white, size: 44),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      videoUrl.split('/').last,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Nhấn để phát video',
                                    style: TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // Danh sách khiếu nại
                        if (appealsList != null && appealsList.isNotEmpty) ...[
                          const Divider(height: AppSpacing.xl),
                          const Text(
                            'Lịch sử khiếu nại',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...appealsList.map((appealMap) {
                            final appeal = Map<String, dynamic>.from(appealMap);
                            final apReason = appeal['reason']?.toString() ?? 'Không có lý do';
                            final apStatus = appeal['status']?.toString() ?? 'pending';

                            Color apColor = AppColors.warning;
                            String apLabel = 'Đang chờ xử lý';
                            if (apStatus == 'approved') {
                              apColor = AppColors.success;
                              apLabel = 'Chấp nhận';
                            } else if (apStatus == 'rejected') {
                              apColor = AppColors.danger;
                              apLabel = 'Từ chối';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Khiếu nại #${appeal['id'] ?? ''}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                      Text(
                                        apLabel,
                                        style: TextStyle(color: apColor, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    apReason,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],

                        // Nút khiếu nại nếu bị từ chối/ai_score = 0
                        if (isRejected && (appealsList == null || appealsList.isEmpty)) ...[
                          const SizedBox(height: AppSpacing.xl),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                widget.appealRewardIdCtrl.text = id;
                                widget.tabController.animateTo(1);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.feedback_outlined),
                              label: const Text('Gửi khiếu nại'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.danger,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _history.isEmpty) {
      final errStr = _error!;
      if (errStr.contains('502')) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Lỗi: $errStr', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 72,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Lịch sử sẽ hiển thị ở đây',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _history.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, index) => const Divider(),
        itemBuilder: (context, index) {
          if (index == _history.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final item = _history[index];
          return ListTile(
            onTap: () => _showDetail(item),
            leading: CircleAvatar(
              backgroundColor: AppColors.success.withValues(alpha: 0.12),
              child: const Icon(Icons.monetization_on, color: AppColors.success),
            ),
            title: Text('Mã điểm thưởng: #${item.rewardId ?? "N/A"}'),
            subtitle: Text('Số dư khả dụng: ${item.availableBalance} xu'),
            trailing: Text(
              '+${item.receivedCoin} xu',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

/// Placeholder khi chưa chọn hình ảnh/video
class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 40,
          color: AppColors.textSecondary.withValues(alpha: 0.6),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Nhấn để chọn hình ảnh hoặc video minh chứng',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Hỗ trợ: JPG, PNG, MP4, MOV • Tối đa 5 phút',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

/// Preview thông tin file video đã chọn
class _VideoPreview extends StatelessWidget {
  final File file;

  const _VideoPreview({required this.file});

  @override
  Widget build(BuildContext context) {
    final size = file.lengthSync();
    final sizeText = size > 1024 * 1024
        ? '${(size / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(size / 1024).toStringAsFixed(0)} KB';

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54),
              ),
              child: const Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              file.path.split(Platform.pathSeparator).last,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              sizeText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
        Positioned(
          top: AppSpacing.sm,
          right: AppSpacing.sm,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Đã chọn',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
