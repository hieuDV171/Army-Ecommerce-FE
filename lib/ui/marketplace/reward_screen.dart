import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_radius.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            Tab(icon: Icon(Icons.video_library_outlined), text: 'Upload video'),
            Tab(icon: Icon(Icons.feedback_outlined), text: 'Khiếu nại'),
            Tab(icon: Icon(Icons.history), text: 'Lịch sử'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UploadVideoTab(picker: _picker),
          const _RewardAppealTab(),
          const _RewardHistoryTab(),
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
  XFile? _videoFile;

  Future<void> _pickVideo() async {
    final picked = await widget.picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (picked != null && mounted) {
      setState(() => _videoFile = picked);
    }
  }

  Future<void> _pickVideoFromCamera() async {
    final picked = await widget.picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 5),
    );
    if (picked != null && mounted) {
      setState(() => _videoFile = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = _videoFile != null;

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
                  const Color(0xFF1565C0).withValues(alpha: 0.12),
                  const Color(0xFF0D47A1).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: const Color(0xFF1565C0).withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 20),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Upload video chiến tích để nhận điểm thưởng quy đổi thành xu nội bộ.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1565C0),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Khu vực chọn video
          const Text(
            'Video chiến tích *',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),

          GestureDetector(
            onTap: _showVideoSourceSheet,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 180,
              decoration: BoxDecoration(
                color: hasVideo ? Colors.black : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: hasVideo ? AppColors.primary : AppColors.border,
                  width: hasVideo ? 2 : 1,
                ),
              ),
              child: hasVideo
                  ? _VideoPreview(file: File(_videoFile!.path))
                  : const _VideoPlaceholder(),
            ),
          ),

          if (hasVideo) ...[
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
                    _videoFile!.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _videoFile = null),
                  child: const Text(
                    'Xóa',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Nút gửi — DISABLED vì API chưa có BE
          _StubSubmitButton(
            label: 'Tải video lên',
            icon: Icons.cloud_upload_outlined,
          ),
        ],
      ),
    );
  }

  void _showVideoSourceSheet() {
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
                  'Chọn video',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.video_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
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
                  _pickVideoFromCamera();
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
  const _RewardAppealTab();

  @override
  State<_RewardAppealTab> createState() => _RewardAppealTabState();
}

class _RewardAppealTabState extends State<_RewardAppealTab> {
  final TextEditingController _rewardIdCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _rewardIdCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
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
            controller: _rewardIdCtrl,
            label: 'Mã điểm thưởng (Reward ID) *',
            hint: 'Nhập reward_id cần khiếu nại',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _reasonCtrl,
            label: 'Lý do khiếu nại (tùy chọn)',
            hint: 'Mô tả lý do bạn muốn khiếu nại...',
          ),
          const SizedBox(height: AppSpacing.xl),

          // Nút gửi khiếu nại — DISABLED vì API chưa có BE
          _StubSubmitButton(
            label: 'Gửi khiếu nại',
            icon: Icons.send_outlined,
          ),
        ],
      ),
    );
  }
}

// ─── Tab 3: Lịch sử điểm thưởng ─────────────────────────────────────────────

class _RewardHistoryTab extends StatefulWidget {
  const _RewardHistoryTab();

  @override
  State<_RewardHistoryTab> createState() => _RewardHistoryTabState();
}

class _RewardHistoryTabState extends State<_RewardHistoryTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          // Banner cảnh báo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.construction, color: AppColors.warning, size: 20),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API chưa được cài đặt',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Chức năng "Lịch sử điểm thưởng" đang chờ Backend hoàn thiện API get_reward_history.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Skeleton / empty illustration
          Expanded(
            child: Center(
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
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Khi API get_reward_history được triển khai,\ndanh sách sẽ tự động cập nhật.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Hiển thị schema mô tả để developer tham khảo
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '// Kết quả mong đợi từ get_reward_history:',
                          style: TextStyle(
                            color: Color(0xFF6A9955),
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '{\n'
                          '  "user_id": "string",\n'
                          '  "reward_id": "string",\n'
                          '  "received_coin": 150,\n'
                          '  "available_balance": 500\n'
                          '}',
                          style: TextStyle(
                            color: Color(0xFFCE9178),
                            fontSize: 11,
                            fontFamily: 'monospace',
                            height: 1.6,
                          ),
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
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

/// Placeholder khi chưa chọn video
class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_circle_outline,
          size: 40,
          color: AppColors.textSecondary.withValues(alpha: 0.6),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Nhấn để chọn hoặc quay video',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Định dạng MP4, MOV • Tối đa 5 phút',
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

/// Nút gửi bị vô hiệu hóa vì API chưa có BE
class _StubSubmitButton extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StubSubmitButton({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AbsorbPointer(
          child: AppButton(
            label: label,
            icon: icon,
            onPressed: null,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'API chưa được cài đặt',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
