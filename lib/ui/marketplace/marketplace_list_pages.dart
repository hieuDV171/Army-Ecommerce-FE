import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/marketplace/marketplace_bloc.dart';
import '../../blocs/marketplace/marketplace_event.dart';
import '../../blocs/marketplace/marketplace_state.dart';
import '../../repositories/marketplace_repository.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
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

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<MarketplaceRepository>();
    return ProductListPage(
      title: 'Thông báo',
      loader: (index, count) => repository.getGenericList(
        '/notification/get_notification',
        data: {'group': 0},
        index: index,
        count: count,
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

class AddressListPage extends StatelessWidget {
  const AddressListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<MarketplaceRepository>();
    return ProductListPage(
      title: 'Địa chỉ giao hàng',
      loader: (index, count) => repository.getGenericList(
        '/order/get_list_order_address',
        index: index,
        count: count,
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
