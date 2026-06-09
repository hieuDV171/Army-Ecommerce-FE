import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'map_picker_screen.dart';
import '../../blocs/marketplace/marketplace_bloc.dart';
import '../../blocs/marketplace/marketplace_event.dart';
import '../../blocs/marketplace/marketplace_state.dart';
import '../../models/marketplace_models.dart';
import '../../repositories/marketplace_repository.dart';
import '../util/constants/app_colors.dart';
import '../util/constants/app_radius.dart';
import '../util/constants/app_spacing.dart';
import '../util/widgets/app_button.dart';
import '../util/widgets/app_text_field.dart';
import '../util/widgets/empty_state.dart';
import '../util/widgets/error_state.dart';
import '../util/widgets/loading_overlay.dart';
import '../util/widgets/price_text.dart';
import '../util/widgets/section_header.dart';
import '../util/theme/special_app_theme.dart';

class ProductListPage extends StatelessWidget {
  final String title;
  final SimpleListLoader loader;
  final void Function(BuildContext context, MarketplaceItem item)? onItemTap;

  const ProductListPage({
    super.key,
    required this.title,
    required this.loader,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SimpleListBloc(
        loader: loader,
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(SimpleListRequested()),
      child: SimpleListPage(title: title, onItemTap: onItemTap),
    );
  }
}

class SimpleListPage extends StatefulWidget {
  final String title;
  final Widget? header;
  final String emptyMessage;
  final void Function(BuildContext context, MarketplaceItem item)? onItemTap;

  const SimpleListPage({
    super.key,
    required this.title,
    this.header,
    this.emptyMessage = 'Chưa có dữ liệu',
    this.onItemTap,
  });

  @override
  State<SimpleListPage> createState() => _SimpleListPageState();
}

class _SimpleListPageState extends State<SimpleListPage> {
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SimpleListBloc, SimpleListState>(
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
            appBar: AppBar(title: Text(widget.title)),
            body: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SimpleListState state) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () =>
            context.read<SimpleListBloc>().add(SimpleListRequested()),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(title: widget.emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SimpleListBloc>().add(SimpleListRefreshed());
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = state.items[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              child: Icon(Icons.inventory_2_outlined),
            ),
            title: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              item.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: item.trailing == null ? null : Text(item.trailing!),
            onTap: widget.onItemTap != null
                ? () => widget.onItemTap!(context, item)
                : null,
          );
        },
      ),
    );
  }
}

class _SimpleListBody extends StatefulWidget {
  final String emptyMessage;

  const _SimpleListBody({required this.emptyMessage});

  @override
  State<_SimpleListBody> createState() => _SimpleListBodyState();
}

class _SimpleListBodyState extends State<_SimpleListBody> {
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SimpleListBloc, SimpleListState>(
      listener: (context, state) {
        final message = state.errorMessage ?? state.successMessage;
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        if (state.isInitialLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.errorMessage != null && state.items.isEmpty) {
          return ErrorState(
            message: state.errorMessage!,
            onRetry: () =>
                context.read<SimpleListBloc>().add(SimpleListRequested()),
          );
        }
        if (state.items.isEmpty) {
          return EmptyState(title: widget.emptyMessage);
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<SimpleListBloc>().add(SimpleListRefreshed());
          },
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(height: AppSpacing.lg),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return const Center(child: CircularProgressIndicator());
              }
              final item = state.items[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.receipt_long_outlined),
                ),
                title: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: item.trailing == null ? null : Text(item.trailing!),
              );
            },
          ),
        );
      },
    );
  }
}

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WalletBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(WalletRequested()),
      child: const _WalletView(),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView();

  void _showTransactionDetails(BuildContext context, WalletHistoryModel item) {
    final isPositive = item.type == 'income' || item.balance >= 0;
    final absBalance = item.balance.abs();
    final formattedBalance = NumberFormat.decimalPattern(
      'vi_VN',
    ).format(absBalance);
    final balanceText = '${isPositive ? "+" : "-"}$formattedBalance xu';
    final balanceColor = isPositive ? AppColors.success : AppColors.danger;

    String displayDate = item.date;
    try {
      final dt = DateTime.parse(item.date);
      displayDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(dt.toLocal());
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Center(
                    child: Text(
                      'Chi tiết giao dịch',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Text(
                      balanceText,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: balanceColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  _buildDetailRow('Mã giao dịch (ID)', '#${item.historyId}'),
                  _buildDetailRow(
                    'Mã đối tượng',
                    item.objectId.isNotEmpty ? item.objectId : 'Không có',
                  ),
                  _buildDetailRow(
                    'Nội dung chi tiết',
                    item.detail.isNotEmpty ? item.detail : 'Không có chi tiết',
                  ),
                  _buildDetailRow(
                    'Loại giao dịch',
                    item.type == 'income'
                        ? 'Cộng xu (Income)'
                        : 'Trừ xu (Expense)',
                  ),
                  _buildDetailRow('Thời gian', displayDate),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: context.specialTheme.useGradient
                          ? context.specialTheme.primaryGradient
                          : null,
                      color: context.specialTheme.useGradient
                          ? null
                          : context.specialTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Ví quân nhu')),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.errorMessage != null
              ? ErrorState(
                  message: state.errorMessage!,
                  onRetry: () =>
                      context.read<WalletBloc>().add(WalletRequested()),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: context.specialTheme.useGradient
                            ? context.specialTheme.primaryGradient
                            : LinearGradient(
                                colors: [
                                  AppColors.tactical,
                                  context.specialTheme.primaryColor
                                ],
                              ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Số dư khả dụng',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          PriceText(
                            price: state.balance?.available ?? 0,
                            color: Colors.white,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Đang chờ: ${state.balance?.pending ?? 0}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader(title: 'Lịch sử số dư'),
                    ...state.history.map((item) {
                      final isPositive =
                          item.type == 'income' || item.balance >= 0;
                      final absBalance = item.balance.abs();
                      final formattedBalance = NumberFormat.decimalPattern(
                        'vi_VN',
                      ).format(absBalance);
                      final balanceText =
                          '${isPositive ? "+" : "-"}$formattedBalance xu';
                      final balanceColor = isPositive
                          ? AppColors.success
                          : AppColors.danger;

                      String displayDate = item.date;
                      try {
                        final dt = DateTime.parse(item.date);
                        displayDate = DateFormat(
                          'dd/MM/yyyy HH:mm:ss',
                        ).format(dt.toLocal());
                      } catch (_) {}

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.title),
                        subtitle: Text(displayDate),
                        trailing: Text(
                          balanceText,
                          style: TextStyle(
                            color: balanceColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        onTap: () => _showTransactionDetails(context, item),
                      );
                    }),
                  ],
                ),
        );
      },
    );
  }
}

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

class OrderListPage extends StatelessWidget {
  const OrderListPage({super.key});

  static const _tabs = [
    ('Chờ xử lý', 'pending'),
    ('Đã xác nhận', 'confirmed'),
    ('Đang giao', 'shipping'),
    ('Hoàn tất', 'delivered'),
    ('Đã hủy', 'cancelled'),
    ('Hoàn tiền', 'refunded'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn hàng'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Chờ xử lý'),
              Tab(text: 'Đã xác nhận'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Hoàn tất'),
              Tab(text: 'Đã hủy'),
              Tab(text: 'Hoàn tiền'),
            ],
          ),
        ),
        body: TabBarView(
          children: [for (final tab in _tabs) _OrderStateList(state: tab.$2)],
        ),
      ),
    );
  }
}

class _OrderStateList extends StatelessWidget {
  final String state;

  const _OrderStateList({required this.state});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<MarketplaceRepository>();
    return BlocProvider(
      create: (context) => SimpleListBloc(
        marketplaceRepository: repository,
        loader: (index, count) => repository.getGenericList(
          '/order/get_list_purchases',
          data: {'state': state},
          index: index,
          count: count,
        ),
      )..add(SimpleListRequested()),
      child: const _SimpleListBody(emptyMessage: 'Chưa có đơn hàng'),
    );
  }
}

class OrderHubPage extends StatelessWidget {
  const OrderHubPage({super.key});

  static const _tabs = [
    ('Chờ xử lý', 'pending'),
    ('Đã chấp nhận', 'accepted'),
    ('Đang giao', 'shipped'),
    ('Đã nhận', 'received'),
    ('Đã hủy', 'cancelled'),
    ('Hoàn tiền', 'refunded'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Don hang'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Chờ xử lý'),
              Tab(text: 'Đã chấp nhận'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Đã nhận'),
              Tab(text: 'Đã hủy'),
              Tab(text: 'Hoàn tiền'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final tab in _tabs) _TypedOrderStateList(state: tab.$2),
          ],
        ),
      ),
    );
  }
}

class _TypedOrderStateList extends StatelessWidget {
  final String state;

  const _TypedOrderStateList({required this.state});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<MarketplaceRepository>();
    return BlocProvider(
      create: (context) => SimpleListBloc(
        marketplaceRepository: repository,
        loader: (index, count) async {
          final orders = await repository.getOrders(
            state: state,
            index: index,
            count: count,
          );
          return orders.map((order) => order.toItem()).toList();
        },
      )..add(SimpleListRequested()),
      child: const _SimpleListBody(emptyMessage: 'Chua co don hang'),
    );
  }
}

class AddressListPage extends StatelessWidget {
  const AddressListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddressBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(AddressListRequested()),
      child: const _AddressListView(),
    );
  }
}

class _AddressListView extends StatelessWidget {
  const _AddressListView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddressBloc, AddressState>(
      listener: (context, state) {
        final message = state.successMessage ?? state.errorMessage;
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: state.successMessage != null
                  ? AppColors.success
                  : AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        final specialTheme = context.specialTheme;
        return LoadingOverlay(
          isLoading: state.isSubmitting,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: specialTheme.useGradient ? Colors.transparent : specialTheme.primaryDarkColor,
              flexibleSpace: specialTheme.useGradient
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: specialTheme.primaryGradient,
                      ),
                    )
                  : null,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text('Địa chỉ giao hàng', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Thêm'),
              backgroundColor: specialTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            body: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AddressState state) {
    if (state.isLoading && state.addresses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 72,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Chưa có địa chỉ nào',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Thêm địa chỉ giao hàng để đặt hàng nhanh hơn',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Thêm địa chỉ mới',
              icon: Icons.add_location_alt,
              onPressed: () => _openForm(context),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AddressBloc>().add(AddressListRequested());
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.addresses.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final address = state.addresses[index];
          return _AddressCard(
            address: address,
            onEdit: () => _openForm(context, address: address),
            onDelete: () => _confirmDelete(context, address),
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {AddressModel? address}) async {
    final bloc = context.read<AddressBloc>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: AddressFormPage(address: address),
        ),
      ),
    );
    if (result == true && context.mounted) {
      bloc.add(AddressListRequested());
    }
  }

  void _confirmDelete(BuildContext context, AddressModel address) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa địa chỉ'),
        content: Text(
          'Bạn có chắc muốn xóa địa chỉ của "${address.receiverName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AddressBloc>().add(AddressDeleted(address.id));
            },
            style: TextButton.styleFrom(foregroundColor: context.specialTheme.primaryColor),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: address.isDefault
            ? BorderSide(color: context.specialTheme.primaryColor, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      address.receiverName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (address.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: context.specialTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        'Mặc định',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.specialTheme.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    address.phone,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      address.fullAddress,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Sửa'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.specialTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Xóa'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.specialTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddressFormPage extends StatefulWidget {
  final AddressModel? address;

  const AddressFormPage({super.key, this.address});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  late final TextEditingController _receiverNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _fullAddressCtrl;
  late final TextEditingController _addressDetailCtrl;
  late final TextEditingController _latitudeCtrl;
  late final TextEditingController _longitudeCtrl;
  bool _isDefault = false;
  bool _isSubmitting = false;
  String? _selectedProvince;
  String? _selectedDistrict;

  // Mock data for provinces and districts (user can extend with real API later)
  final Map<String, List<String>> _provincesDistricts = {
    'TP. Hồ Chí Minh': [
      'Quận 1',
      'Quận 2',
      'Quận 3',
      'Quận 4',
      'Quận 5',
      'Quận 6',
      'Quận 7',
      'Quận 8',
      'Quận 9',
      'Quận 10',
      'Quận 11',
      'Quận 12',
      'Quận Bình Tân',
      'Quận Bình Thạnh',
      'Quận Gò Vấp',
      'Quận Phú Nhuận',
      'Quận Tân Bình',
      'Quận Tân Phú',
      'Quận Thủ Đức',
      'Huyện Bình Chánh',
      'Huyện Cần Giờ',
      'Huyện Củ Chi',
      'Huyện Hóc Môn',
      'Huyện Nhà Bè',
    ],
    'Hà Nội': [
      'Quận Ba Đình',
      'Quận Hoàn Kiếm',
      'Quận Tây Hồ',
      'Quận Long Biên',
      'Quận Đống Đa',
      'Quận Hai Bà Trưng',
      'Quận Hoàng Mai',
      'Quận Thanh Xuân',
      'Huyện Sóc Sơn',
      'Huyện Đông Anh',
      'Huyện Gia Lâm',
      'Huyện thanh trì',
    ],
    'Đà Nẵng': [
      'Quận Hải Châu',
      'Quận Cẩm Lệ',
      'Quận Thanh Khê',
      'Quận Sơn Trà',
      'Quận Ngũ Hành Sơn',
      'Huyện Hoàng Sa',
    ],
  };

  final List<Map<String, dynamic>> _presetLocations = const [
    {'name': 'Hồ Hoàn Kiếm, Hà Nội', 'lat': 21.0285, 'lng': 105.8542},
    {'name': 'Dinh Độc Lập, TP. Hồ Chí Minh', 'lat': 10.7770, 'lng': 106.6953},
    {'name': 'Cầu Rồng, Đà Nẵng', 'lat': 16.0613, 'lng': 108.2274},
    {'name': 'Chợ Bến Thành, TP. Hồ Chí Minh', 'lat': 10.7725, 'lng': 106.6980},
    {'name': 'Lăng Bác, Hà Nội', 'lat': 21.0368, 'lng': 105.8346},
  ];

  bool get _isEditMode => widget.address != null;

  @override
  void initState() {
    super.initState();
    _receiverNameCtrl = TextEditingController(
      text: widget.address?.receiverName ?? '',
    );
    _phoneCtrl = TextEditingController(text: widget.address?.phone ?? '');
    _addressCtrl = TextEditingController(text: widget.address?.address ?? '');
    _fullAddressCtrl = TextEditingController(
      text: widget.address?.fullAddress ?? '',
    );
    _addressDetailCtrl = TextEditingController(
      text: widget.address?.addressDetail ?? '',
    );
    _latitudeCtrl = TextEditingController(text: widget.address?.latitude ?? '');
    _longitudeCtrl = TextEditingController(
      text: widget.address?.longitude ?? '',
    );
    _isDefault = widget.address?.isDefault ?? false;
    // Set default province if needed
    if (_provincesDistricts.isNotEmpty && _selectedProvince == null) {
      _selectedProvince = _provincesDistricts.keys.first;
      _selectedDistrict = _provincesDistricts[_selectedProvince]?.first;
    }
  }

  @override
  void dispose() {
    _receiverNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _fullAddressCtrl.dispose();
    _addressDetailCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    super.dispose();
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Chọn nhanh vị trí để lấy tọa độ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _presetLocations.length,
                  itemBuilder: (context, index) {
                    final loc = _presetLocations[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                      ),
                      title: Text(loc['name'] as String),
                      subtitle: Text(
                        'Vĩ độ: ${loc['lat']}, Kinh độ: ${loc['lng']}',
                      ),
                      onTap: () {
                        setState(() {
                          _latitudeCtrl.text = loc['lat'].toString();
                          _longitudeCtrl.text = loc['lng'].toString();
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openMapPicker(BuildContext context) async {
    final double? initialLat = double.tryParse(_latitudeCtrl.text);
    final double? initialLng = double.tryParse(_longitudeCtrl.text);

    final LatLng? result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MapPickerScreen(initialLat: initialLat, initialLng: initialLng),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitudeCtrl.text = result.latitude.toString();
        _longitudeCtrl.text = result.longitude.toString();
      });
    }
  }

  void _onSubmit() {
    final receiverName = _receiverNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final fullAddress = _fullAddressCtrl.text.trim();
    final addressDetail = _addressDetailCtrl.text.trim();
    final latitude = _latitudeCtrl.text.trim();
    final longitude = _longitudeCtrl.text.trim();

    if (receiverName.isEmpty ||
        phone.isEmpty ||
        fullAddress.isEmpty ||
        addressDetail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng điền đầy đủ: Tên người nhận, SĐT, Địa chỉ đầy đủ, Chi tiết thêm',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_selectedProvince == null || _selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn Tỉnh/Thành phố và Quận/Huyện'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (latitude.isEmpty || longitude.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập Độ rộng (Lat) và Độ dài (Lng)'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final bloc = context.read<AddressBloc>();

    if (_isEditMode) {
      bloc.add(
        AddressUpdated(
          id: widget.address!.id,
          address: address.isEmpty ? fullAddress : address,
          fullAddress: fullAddress,
          receiverName: receiverName,
          phone: phone,
          isDefault: _isDefault,
          addressDetail: addressDetail,
          province: _selectedProvince!,
          district: _selectedDistrict!,
          latitude: latitude,
          longitude: longitude,
        ),
      );
    } else {
      bloc.add(
        AddressAdded(
          address: address.isEmpty ? fullAddress : address,
          fullAddress: fullAddress,
          receiverName: receiverName,
          phone: phone,
          isDefault: _isDefault,
          addressDetail: addressDetail,
          province: _selectedProvince!,
          district: _selectedDistrict!,
          latitude: latitude,
          longitude: longitude,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddressBloc, AddressState>(
      listener: (context, state) {
        setState(() => _isSubmitting = state.isSubmitting);

        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: LoadingOverlay(
        isLoading: _isSubmitting,
        child: Scaffold(
          appBar: AppBar(
            title: Text(_isEditMode ? 'Sửa địa chỉ' : 'Thêm địa chỉ mới'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _receiverNameCtrl,
                  label: 'Tên người nhận *',
                  hint: 'VD: Nguyễn Văn A',
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _phoneCtrl,
                  label: 'Số điện thoại *',
                  hint: 'VD: 0912345678',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Province dropdown
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: SizedBox(),
                    value: _selectedProvince,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    items: _provincesDistricts.keys.map((province) {
                      return DropdownMenuItem(
                        value: province,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(province),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedProvince = value;
                          _selectedDistrict = _provincesDistricts[value]?.first;
                        });
                      }
                    },
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text('Chọn Tỉnh/Thành phố *'),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // District dropdown
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: SizedBox(),
                    value: _selectedDistrict,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    items: (_provincesDistricts[_selectedProvince] ?? []).map((
                      district,
                    ) {
                      return DropdownMenuItem(
                        value: district,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(district),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedDistrict = value);
                      }
                    },
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text('Chọn Quận/Huyện *'),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _fullAddressCtrl,
                  label: 'Địa chỉ đầy đủ *',
                  hint: 'VD: 123 Đường ABC, Phường XYZ, Quận 1, TP.HCM',
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _addressCtrl,
                  label: 'Tên địa chỉ (tùy chọn)',
                  hint: 'VD: Nhà riêng, Văn phòng',
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _addressDetailCtrl,
                  label: 'Chi tiết thêm *',
                  hint: 'VD: Tầng 3, phòng 301',
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tọa độ GPS *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _openMapPicker(context),
                          icon: const Icon(Icons.map, size: 16),
                          label: const Text('Chọn từ bản đồ'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: context.specialTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        TextButton.icon(
                          onPressed: () => _showLocationPicker(context),
                          icon: const Icon(Icons.list, size: 16),
                          label: const Text('Chọn nhanh'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                // Latitude input
                AppTextField(
                  controller: _latitudeCtrl,
                  label: 'Vĩ độ (Latitude) *',
                  hint: 'VD: 10.7769',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Longitude input
                AppTextField(
                  controller: _longitudeCtrl,
                  label: 'Kinh độ (Longitude) *',
                  hint: 'VD: 106.7009',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.xl),
                SwitchListTile(
                  value: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value),
                  title: const Text('Đặt làm địa chỉ mặc định'),
                  subtitle: const Text('Tự động chọn khi đặt hàng'),
                  activeThumbColor: context.specialTheme.primaryColor,
                  activeTrackColor: context.specialTheme.primaryColor.withValues(alpha: 0.5),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: _isEditMode ? 'Cập nhật địa chỉ' : 'Lưu địa chỉ',
                  icon: Icons.save_outlined,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _onSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
