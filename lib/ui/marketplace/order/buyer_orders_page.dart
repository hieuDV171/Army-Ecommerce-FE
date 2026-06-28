import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/marketplace_repository.dart';
import 'package:army_ecommerce/blocs/marketplace/order/order_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/order/order_event.dart';
import 'package:army_ecommerce/blocs/marketplace/order/order_state.dart';
import '../../util/constants/app_spacing.dart';
import '../../util/widgets/empty_state.dart';
import '../../util/widgets/error_state.dart';
import 'widgets/order_card.dart';
import 'buyer_order_detail_page.dart';

class BuyerOrdersPage extends StatelessWidget {
  const BuyerOrdersPage({super.key});

  static const _tabs = [
    ('Tất cả', null),
    ('Chờ xử lý', 'pending'),
    ('Đã xác nhận', 'confirmed'),
    ('Đang giao', 'shipping'),
    ('Đã nhận', 'delivered'),
    ('Đã hủy', 'cancelled'),
    ('Hoàn tiền', 'refunded'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn hàng của tôi'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Tất cả'),
              Tab(text: 'Chờ xử lý'),
              Tab(text: 'Đã xác nhận'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Đã nhận'),
              Tab(text: 'Đã hủy'),
              Tab(text: 'Hoàn tiền'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final tab in _tabs) _BuyerOrderList(stateFilter: tab.$2),
          ],
        ),
      ),
    );
  }
}

class _BuyerOrderList extends StatelessWidget {
  final String? stateFilter;

  const _BuyerOrderList({required this.stateFilter});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(OrderListRequested(isSeller: false, stateFilter: stateFilter)),
      child: _BuyerOrderListView(stateFilter: stateFilter),
    );
  }
}

class _BuyerOrderListView extends StatefulWidget {
  final String? stateFilter;

  const _BuyerOrderListView({required this.stateFilter});

  @override
  State<_BuyerOrderListView> createState() => _BuyerOrderListViewState();
}

class _BuyerOrderListViewState extends State<_BuyerOrderListView> {
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
      context.read<OrderBloc>().add(
        OrderLoadMoreRequested(
          isSeller: false,
          stateFilter: widget.stateFilter,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state.isLoading && state.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errorMessage != null && state.orders.isEmpty) {
          return ErrorState(
            message: state.errorMessage!,
            onRetry: () {
              context.read<OrderBloc>().add(
                OrderListRequested(
                  isSeller: false,
                  stateFilter: widget.stateFilter,
                  isRefresh: true,
                ),
              );
            },
          );
        }

        if (state.orders.isEmpty) {
          return const EmptyState(
            title: 'Chưa có đơn hàng',
            message: 'Các đơn hàng bạn đã đặt sẽ hiển thị ở đây.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final bloc = context.read<OrderBloc>();
            bloc.add(
              OrderListRequested(
                isSeller: false,
                stateFilter: widget.stateFilter,
                isRefresh: true,
              ),
            );
            await bloc.stream.firstWhere((s) => !s.isLoading);
          },
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: state.orders.length + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index == state.orders.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final order = state.orders[index];
              return OrderCard(
                order: order,
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BuyerOrderDetailPage(
                        orderId: order.id,
                        onRefresh: () {
                          if (context.mounted) {
                            context.read<OrderBloc>().add(
                              OrderListRequested(
                                isSeller: false,
                                stateFilter: widget.stateFilter,
                                isRefresh: true,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                  if (result == true && context.mounted) {
                    context.read<OrderBloc>().add(
                      OrderListRequested(
                        isSeller: false,
                        stateFilter: widget.stateFilter,
                        isRefresh: true,
                      ),
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
