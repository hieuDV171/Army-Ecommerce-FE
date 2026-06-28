import 'package:army_ecommerce/blocs/marketplace/simple_list/simple_list_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/simple_list/simple_list_event.dart';
import 'package:army_ecommerce/blocs/marketplace/simple_list/simple_list_state.dart';
import 'package:army_ecommerce/models/model_helpers.dart';
import 'package:army_ecommerce/ui/util/theme/special_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../util/constants/app_colors.dart';
import 'news_page.dart';

/// Tab "Tin tức" — hiển thị 2 tin mới nhất dạng card có ảnh,
/// các tin còn lại hiển thị dạng danh sách thu gọn.
class NewsTabBody extends StatelessWidget {
  const NewsTabBody({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng Bloc được cung cấp từ HomeScreen để giữ trạng thái
    return const _NewsTabView();
  }
}

class _NewsTabView extends StatefulWidget {
  const _NewsTabView();

  @override
  State<_NewsTabView> createState() => _NewsTabViewState();
}

class _NewsTabViewState extends State<_NewsTabView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      context.read<SimpleListBloc>().add(SimpleListLoadMoreRequested());
    }
  }

  void _openDetail(BuildContext context, MarketplaceItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewsDetailPage(id: item.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SimpleListBloc, SimpleListState>(
      builder: (context, state) {
        // Chỉ hiện loading xoay nếu danh sách đang trống hoàn toàn (lần đầu vào app)
        if (state.isInitialLoading && state.items.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: context.specialTheme.primaryColor,
            ),
          );
        }

        if (state.errorMessage != null && state.items.isEmpty) {
          return _buildError(context, state.errorMessage!);
        }

        if (state.items.isEmpty && !state.isInitialLoading) {
          return _buildEmpty(context);
        }

        return RefreshIndicator(
          color: context.specialTheme.primaryColor,
          onRefresh: () async {
            context.read<SimpleListBloc>().add(SimpleListRequested());
            // Đợi một chút để người dùng thấy hiệu ứng refresh
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── 2 tin đầu dạng card lớn có ảnh ──────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = state.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NewsCardLarge(
                          item: item,
                          onTap: () => _openDetail(context, item),
                        ),
                      );
                    },
                    childCount: state.items.length < 2 ? state.items.length : 2,
                  ),
                ),
              ),

              // ── Header "Tin khác" (chỉ hiện khi có > 2 tin) ─────────────
              if (state.items.length > 2)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Tin khác',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[600],
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),

              // ── Danh sách các tin còn lại ─────────────────────────────────
              if (state.items.length > 2)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = state.items[index + 2];
                        return _NewsListTile(
                          item: item,
                          onTap: () => _openDetail(context, item),
                        );
                      },
                      childCount:
                          state.items.length -
                          2 +
                          (state.isLoadingMore ? 1 : 0),
                    ),
                  ),
                ),

              // ── Loading more indicator ─────────────────────────────────────
              if (state.isLoadingMore && state.items.length <= 2)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                context.read<SimpleListBloc>().add(SimpleListRequested()),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return RefreshIndicator(
      color: context.specialTheme.primaryColor,
      onRefresh: () async {
        context.read<SimpleListBloc>().add(SimpleListRequested());
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 72, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'Chưa có tin tức',
                  style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card lớn cho 2 tin đầu ──────────────────────────────────────────────────
class _NewsCardLarge extends StatelessWidget {
  final MarketplaceItem item;
  final VoidCallback onTap;

  const _NewsCardLarge({required this.item, required this.onTap});

  String _formatTime(String? trailing) {
    if (trailing == null || trailing.isEmpty) return '';
    final ts = int.tryParse(trailing);
    if (ts != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
    return trailing;
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _formatTime(item.trailing);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh bìa
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, e, st) =>
                              _buildImageFallback(context),
                        )
                      : _buildImageFallback(context),
                ),
              ),
              // Nội dung
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    if (item.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (timeText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 13,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeText,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageFallback(BuildContext context) {
    return Container(
      color: AppColors.greyBackground,
      child: Center(
        child: Icon(Icons.article_outlined, size: 48, color: Colors.grey[300]),
      ),
    );
  }
}

// ── List tile cho các tin còn lại ───────────────────────────────────────────
class _NewsListTile extends StatelessWidget {
  final MarketplaceItem item;
  final VoidCallback onTap;

  const _NewsListTile({required this.item, required this.onTap});

  String _formatTime(String? trailing) {
    if (trailing == null || trailing.isEmpty) return '';
    final ts = int.tryParse(trailing);
    if (ts != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
    return trailing;
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _formatTime(item.trailing);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          color: Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail nhỏ hoặc icon
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 64,
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, e, st) => _buildSmallFallback(),
                      )
                    : _buildSmallFallback(),
              ),
            ),
            const SizedBox(width: 12),
            // Tiêu đề + mô tả + thời gian
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                  if (timeText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeText,
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallFallback() {
    return Container(
      color: AppColors.greyBackground,
      child: Icon(Icons.article_outlined, size: 28, color: Colors.grey[300]),
    );
  }
}
