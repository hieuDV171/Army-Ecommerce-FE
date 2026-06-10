import 'package:army_ecommerce/blocs/marketplace/notification/notification_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/notification/notification_event.dart';
import 'package:army_ecommerce/blocs/marketplace/notification/notification_state.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../util/constants/app_colors.dart';
import '../../util/constants/app_spacing.dart';
import '../../util/widgets/empty_state.dart';
import '../../util/widgets/error_state.dart';
import '../../util/widgets/loading_overlay.dart';

class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(NotificationsRequested()),
      child: const _NotificationListView(),
    );
  }
}

class _NotificationListView extends StatefulWidget {
  const _NotificationListView();

  @override
  State<_NotificationListView> createState() => _NotificationListViewState();
}

class _NotificationListViewState extends State<_NotificationListView> {
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
      context.read<NotificationBloc>().add(NotificationsLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        final message = state.errorMessage ?? state.successMessage;
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: state.isSubmitting,
          child: Scaffold(
            appBar: AppBar(title: const Text('Thong bao')),
            body: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotificationState state) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.notifications.isEmpty) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () =>
            context.read<NotificationBloc>().add(NotificationsRequested()),
      );
    }
    if (state.notifications.isEmpty) {
      return const EmptyState(title: 'Chua co thong bao');
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<NotificationBloc>().add(NotificationsRefreshed());
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          if (index >= state.notifications.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final notification = state.notifications[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: notification.read
                  ? AppColors.surface
                  : AppColors.primary.withValues(alpha: 0.12),
              child: Icon(
                notification.read
                    ? Icons.notifications_none
                    : Icons.notifications_active,
                color: notification.read
                    ? AppColors.textSecondary
                    : AppColors.primary,
              ),
            ),
            title: Text(
              notification.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: notification.read
                    ? FontWeight.w500
                    : FontWeight.w700,
              ),
            ),
            subtitle: Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: notification.read
                ? null
                : const Icon(Icons.circle, size: 10, color: AppColors.primary),
            onTap: notification.read
                ? null
                : () => context.read<NotificationBloc>().add(
                    NotificationReadRequested(notification.id),
                  ),
          );
        },
      ),
    );
  }
}
