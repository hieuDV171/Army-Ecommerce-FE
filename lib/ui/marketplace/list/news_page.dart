import 'package:army_ecommerce/models/model_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/marketplace_repository.dart';
import '../../util/constants/app_colors.dart';
import '../../util/constants/app_spacing.dart';
import '../../util/widgets/error_state.dart';
import 'simple_list_page.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<MarketplaceRepository>();
    return ProductListPage(
      title: 'Tin tức',
      loader: (index, count) => repository.getNews(index: index, count: count),
      onItemTap: (context, item) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewsDetailPage(id: item.id)),
        );
      },
    );
  }
}

class NewsDetailPage extends StatelessWidget {
  final String id;

  const NewsDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<MarketplaceRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Tin tức')),
      body: FutureBuilder<MarketplaceItem?>(
        future: repository.getNewsDetail(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: () {},
            );
          }
          final item = snapshot.data;
          if (item == null) {
            return const Center(child: Text('Không tìm thấy tin tức'));
          }

          // item.title and item.subtitle (content)
          String content = item.subtitle;
          String title = item.title;
          String? trailing = item.trailing;

          String timeText = '';
          if (trailing != null && trailing.isNotEmpty) {
            final ts = int.tryParse(trailing);
            if (ts != null) {
              final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
              timeText =
                  '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            } else {
              timeText = trailing;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (timeText.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    timeText,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(content),
              ],
            ),
          );
        },
      ),
    );
  }
}
