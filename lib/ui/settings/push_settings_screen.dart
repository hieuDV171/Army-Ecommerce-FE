import 'package:army_ecommerce/blocs/settings/push_setting_bloc.dart';
import 'package:army_ecommerce/blocs/settings/push_setting_event.dart';
import 'package:army_ecommerce/blocs/settings/push_setting_state.dart';
import 'package:army_ecommerce/models/push_setting_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PushSettingsScreen extends StatefulWidget {
  const PushSettingsScreen({super.key});

  @override
  State<PushSettingsScreen> createState() => _PushSettingScreenState();
}

class _PushSettingScreenState extends State<PushSettingsScreen> {
  PushSettingModel? _currentSettings;
  PushSettingModel? _draftSettings;

  @override
  void initState() {
    super.initState();
    context.read<PushSettingBloc>().add(FetchPushSettingEvent());
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draftSettings;
    final isSaving = context.watch<PushSettingBloc>().state is PushSettingLoading;

    return PopScope(
      canPop: !isSaving && !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || isSaving || !_hasUnsavedChanges()) return;

        final shouldLeave = await _showDiscardChangesDialog() ?? false;
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cài đặt thông báo'),
          centerTitle: true,
        ),

        body: BlocConsumer<PushSettingBloc, PushSettingState>(
          builder: (context, state) {
            if (draft == null && state is PushSettingLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (draft != null) {
              final hasUnsavedChanges = _hasUnsavedChanges();
              return Stack(
                children: [
                  AbsorbPointer(
                    absorbing: isSaving,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          // // === Email Notification ===
                          // _buildSettingSection(
                          //   title: 'Email thông báo',
                          //   items: [
                          //     _buildToggleItem(
                          //       title: 'Cập nhật đơn hàng',
                          //       subtitle: 'Cập nhật về trạng thái của các đơn hàng',
                          //       value: _currentSettings.transaction == 1,
                          //       onChanged: (val) => _updateSetting(
                          //         transaction: val ? '1' : '0',
                          //       ),
                          //     ),
                          //     _buildToggleItem(
                          //       title: 'Khuyến mãi',
                          //       subtitle: 'Cập nhật về các ưu đãi và khuyến mãi sắp tới',
                          //       value: _currentSettings.announcement == 1,
                          //       onChanged: (val) => _updateSetting(
                          //         announcement: val ? '1' : '0',
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          //
                          // const SizedBox(height: 24),

                          // === Push Notification ===
                          _buildSettingSection(
                            title: 'Thông báo đẩy',
                            items: [
                              _buildToggleItem(
                                title: 'Thích (Like)',
                                subtitle: 'Thông báo khi có người thích bài viết của bạn',
                                value: draft.like == 1,
                                onChanged: (val) => _updateDraft(
                                  draft.copyWith(like: val ? 1 : 0),
                                ),
                              ),
                              _buildToggleItem(
                                title: 'Bình luận',
                                subtitle: 'Thông báo khi có người bình luận bài viết',
                                value: draft.comment == 1,
                                onChanged: (val) => _updateDraft(
                                  draft.copyWith(comment: val ? 1 : 0),
                                ),
                              ),
                              _buildToggleItem(
                                title: 'Giao dịch',
                                subtitle: 'Thông báo về các giao dịch của bạn',
                                value: draft.transaction == 1,
                                onChanged: (val) => _updateDraft(
                                  draft.copyWith(transaction: val ? 1 : 0),
                                ),
                              ),
                              _buildToggleItem(
                                title: 'Thông báo chung',
                                subtitle: 'Thông báo về các sự kiện quan trọng',
                                value: draft.announcement == 1,
                                onChanged: (val) => _updateDraft(
                                  draft.copyWith(announcement: val ? 1 : 0),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // === Sound Settings ===
                          _buildSettingSection(
                            title: 'Âm thanh',
                            items: [
                              _buildToggleItem(
                                title: 'Bật âm thanh',
                                subtitle: 'Phát âm thanh khi nhận được thông báo',
                                value: draft.soundOn == 1,
                                onChanged: (val) => _updateDraft(
                                  draft.copyWith(soundOn: val ? 1 : 0),
                                ),
                              ),
                              _buildToggleItem(
                                title: 'Âm thanh mặc định',
                                subtitle: 'Dùng âm thanh mặc định hệ thống',
                                value: draft.soundDefault == 1,
                                onChanged: (val) => _updateDraft(
                                  draft.copyWith(soundDefault: val ? 1 : 0),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isSaving || !hasUnsavedChanges ? null : _saveChangedSettings,
                              child: const Text('Lưu thay đổi'),
                            ),
                          ),
                        ],
                      ),
                      ),
                    ),
                  ),
                  if (isSaving) ...[
                    const ModalBarrier(dismissible: false, color: Colors.black38),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              );
            }

            if (state is PushSettingError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.error),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<PushSettingBloc>().add(FetchPushSettingEvent());
                      },
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: Text('Không xác định'));

          },
          listener: (context, state) {
            if (state is PushSettingSuccess) {
              setState(() {
                _currentSettings = state.data;
                _draftSettings = state.data;
              });
            }

            if (state is PushSettingSuccess && state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message!),
                backgroundColor: Colors.green,
                ),
              );
            }
            if (state is PushSettingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        ),
      ),
    );
  }

  void _updateDraft(PushSettingModel newDraft) {
    setState(() {
      _draftSettings = newDraft;
    });
  }

  void _saveChangedSettings() {
    final current = _currentSettings;
    final draft = _draftSettings;
    if (current == null || draft == null) return;

    final like = current.like != draft.like ? _toApiValue(draft.like) : null;
    final comment = current.comment != draft.comment ? _toApiValue(draft.comment) : null;
    final transaction = current.transaction != draft.transaction ? _toApiValue(draft.transaction) : null;
    final announcement = current.announcement != draft.announcement ? _toApiValue(draft.announcement) : null;
    final soundOn = current.soundOn != draft.soundOn ? _toApiValue(draft.soundOn) : null;
    final soundDefault = current.soundDefault != draft.soundDefault ? _toApiValue(draft.soundDefault) : null;

    if (like == null &&
        comment == null &&
        transaction == null &&
        announcement == null &&
        soundOn == null &&
        soundDefault == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có thay đổi để lưu')),
      );
      return;
    }

    _updateSetting(
      like: like,
      comment: comment,
      transaction: transaction,
      announcement: announcement,
      soundOn: soundOn,
      soundDefault: soundDefault,
    );
  }

  bool _hasUnsavedChanges() {
    final current = _currentSettings;
    final draft = _draftSettings;
    if (current == null || draft == null) return false;

    return current.like != draft.like ||
        current.comment != draft.comment ||
        current.transaction != draft.transaction ||
        current.announcement != draft.announcement ||
        current.soundOn != draft.soundOn ||
        current.soundDefault != draft.soundDefault;
  }

  Future<bool?> _showDiscardChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bỏ thay đổi?'),
        content: const Text('Bạn có thay đổi chưa lưu. Bạn có muốn thoát màn hình này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
  }

  String _toApiValue(int value) => value.toString();

  void _updateSetting({
    String? like,
    String? comment,
    String? transaction,
    String? announcement,
    String? soundOn,
    String? soundDefault,
  }) {
    context.read<PushSettingBloc>().add(
      UpdatePushSettingEvent(
        like: like,
        comment: comment,
        transaction: transaction,
        announcement: announcement,
        soundOn: soundOn,
        soundDefault: soundDefault,
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF999999),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.green,
            inactiveTrackColor: const Color(0xFFE0E0E0),
          ),
        ],
      ),
    );
  }
}