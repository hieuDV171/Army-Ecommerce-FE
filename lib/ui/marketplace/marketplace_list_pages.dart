import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/marketplace/marketplace_bloc.dart';
import '../../blocs/marketplace/marketplace_event.dart';
import '../../blocs/marketplace/marketplace_state.dart';
import '../../models/marketplace_models.dart';
import '../../repositories/marketplace_repository.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/price_text.dart';
import '../widgets/section_header.dart';

class ProductListPage extends StatelessWidget {
  final String title;
  final SimpleListLoader loader;

  const ProductListPage({
    super.key,
    required this.title,
    required this.loader,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SimpleListBloc(
        loader: loader,
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(SimpleListRequested()),
      child: SimpleListPage(title: title),
    );
  }
}

class SimpleListPage extends StatefulWidget {
  final String title;
  final Widget? header;
  final String emptyMessage;

  const SimpleListPage({
    super.key,
    required this.title,
    this.header,
    this.emptyMessage = 'Chưa có dữ liệu',
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
        onRetry: () => context.read<SimpleListBloc>().add(SimpleListRequested()),
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
            leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
            title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: item.trailing == null ? null : Text(item.trailing!),
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        if (state.isInitialLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.errorMessage != null && state.items.isEmpty) {
          return ErrorState(
            message: state.errorMessage!,
            onRetry: () => context.read<SimpleListBloc>().add(SimpleListRequested()),
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
                leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
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
                      onRetry: () => context.read<WalletBloc>().add(WalletRequested()),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.tactical, AppColors.primary],
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
                              PriceText(price: state.balance?.available ?? 0),
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
                        ...state.history.map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.title),
                            subtitle: Text(item.subtitle),
                            trailing: item.trailing == null ? null : Text(item.trailing!),
                          ),
                        ),
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
    if (state.isInitialLoading) return const Center(child: CircularProgressIndicator());
    if (state.errorMessage != null && state.notifications.isEmpty) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () => context.read<NotificationBloc>().add(NotificationsRequested()),
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
                color: notification.read ? AppColors.textSecondary : AppColors.primary,
              ),
            ),
            title: Text(
              notification.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: notification.read ? FontWeight.w500 : FontWeight.w700,
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
                : () => context
                .read<NotificationBloc>()
                .add(NotificationReadRequested(notification.id)),
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
          children: [
            for (final tab in _tabs) _OrderStateList(state: tab.$2),
          ],
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
        return LoadingOverlay(
          isLoading: state.isSubmitting,
          child: Scaffold(
            appBar: AppBar(title: const Text('Địa chỉ giao hàng')),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Thêm'),
              backgroundColor: AppColors.primary,
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
            const Icon(Icons.location_off_outlined, size: 72, color: AppColors.textSecondary),
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
        content: Text('Bạn có chắc muốn xóa địa chỉ của "${address.receiverName}"?'),
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
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
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
            ? const BorderSide(color: AppColors.primary, width: 1.5)
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
                  const Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
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
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Text(
                        'Mặc định',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
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
                    child: Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
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
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Xóa'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
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
  bool _isDefault = false;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.address != null;

  @override
  void initState() {
    super.initState();
    _receiverNameCtrl = TextEditingController(text: widget.address?.receiverName ?? '');
    _phoneCtrl = TextEditingController(text: widget.address?.phone ?? '');
    _addressCtrl = TextEditingController();
    _fullAddressCtrl = TextEditingController(text: widget.address?.fullAddress ?? '');
    _addressDetailCtrl = TextEditingController();
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _receiverNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _fullAddressCtrl.dispose();
    _addressDetailCtrl.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final receiverName = _receiverNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final fullAddress = _fullAddressCtrl.text.trim();
    final addressDetail = _addressDetailCtrl.text.trim();

    if (receiverName.isEmpty || phone.isEmpty || fullAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ: Tên người nhận, SĐT, Địa chỉ đầy đủ'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final bloc = context.read<AddressBloc>();

    if (_isEditMode) {
      bloc.add(AddressUpdated(
        id: widget.address!.id,
        address: address.isEmpty ? fullAddress : address,
        fullAddress: fullAddress,
        receiverName: receiverName,
        phone: phone,
        isDefault: _isDefault,
        addressDetail: addressDetail.isEmpty ? null : addressDetail,
      ));
    } else {
      bloc.add(AddressAdded(
        address: address.isEmpty ? fullAddress : address,
        fullAddress: fullAddress,
        receiverName: receiverName,
        phone: phone,
        isDefault: _isDefault,
        addressDetail: addressDetail.isEmpty ? null : addressDetail,
      ));
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
                  label: 'Chi tiết thêm (tùy chọn)',
                  hint: 'VD: Tầng 3, phòng 301',
                ),
                const SizedBox(height: AppSpacing.xl),
                SwitchListTile(
                  value: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value),
                  title: const Text('Đặt làm địa chỉ mặc định'),
                  subtitle: const Text('Tự động chọn khi đặt hàng'),
                  activeThumbColor: AppColors.primary,
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
    );
  }
}

class CheckoutPage extends StatelessWidget {
  final ProductModel product;

  const CheckoutPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CheckoutBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(CheckoutRequested()),
      child: _CheckoutView(product: product),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  final ProductModel product;

  const _CheckoutView({required this.product});

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutBloc, CheckoutState>(
      listener: (context, state) {
        final message = state.errorMessage ?? state.successMessage;
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
        if (state.successMessage != null) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: state.isSubmitting,
          child: Scaffold(
            appBar: AppBar(title: const Text('Thanh toán')),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppButton(
                  label: 'Đặt hàng',
                  icon: Icons.payment,
                  onPressed: () {
                    context.read<CheckoutBloc>().add(
                      CheckoutSubmitted(
                        productId: widget.product.id,
                        quantity: _quantity,
                      ),
                    );
                  },
                ),
              ),
            ),
            body: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CheckoutState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.addresses.isEmpty) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () => context.read<CheckoutBloc>().add(CheckoutRequested()),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SectionHeader(
          title: 'Địa chỉ nhận hàng',
          actionLabel: state.addresses.isNotEmpty ? 'Thêm' : null,
          onActionTap: state.addresses.isNotEmpty ? () => _openAddressForm(context) : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.addresses.isEmpty) ...[
          const EmptyState(
            title: 'Chưa có địa chỉ',
            message: 'Bạn cần thêm địa chỉ trước khi đặt hàng.',
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Thêm địa chỉ mới',
            icon: Icons.add_location_alt,
            onPressed: () => _openAddressForm(context),
          ),
        ] else
          ...state.addresses.map(
                (address) => ListTile(
              onTap: () {
                context.read<CheckoutBloc>().add(CheckoutAddressSelected(address));
              },
              title: Text(address.title),
              subtitle: Text(address.subtitle),
              trailing: Icon(
                state.selectedAddress?.id == address.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: state.selectedAddress?.id == address.id
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Sản phẩm'),
        const SizedBox(height: AppSpacing.sm),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
          title: Text(widget.product.title),
          subtitle: PriceText(price: widget.product.price),
          trailing: _QuantityStepper(
            value: _quantity,
            onChanged: (value) => setState(() => _quantity = value),
          ),
        ),
        const Divider(height: 32),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tổng thanh toán',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            PriceText(price: widget.product.price * _quantity),
          ],
        ),
      ],
    );
  }

  void _openAddressForm(BuildContext context) async {
    final bloc = BlocProvider.of<CheckoutBloc>(context);
    final repository = context.read<MarketplaceRepository>();
    final addressBloc = AddressBloc(marketplaceRepository: repository);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: addressBloc,
          child: const AddressFormPage(),
        ),
      ),
    );
    addressBloc.close();
    if (result == true && context.mounted) {
      bloc.add(CheckoutRequested());
    }
  }
}

class _QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Giảm',
          onPressed: value <= 1 ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value'),
        IconButton(
          tooltip: 'Tăng',
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
