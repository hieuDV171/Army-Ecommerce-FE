import 'package:army_ecommerce/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/marketplace_repository.dart';
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

class _BuyerOrderList extends StatefulWidget {
  final String? stateFilter;

  const _BuyerOrderList({required this.stateFilter});

  @override
  State<_BuyerOrderList> createState() => _BuyerOrderListState();
}

class _BuyerOrderListState extends State<_BuyerOrderList> {
  Future<List<OrderModel>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<OrderModel>> _load() {
    return context.read<MarketplaceRepository>().getOrders(
          state: widget.stateFilter,
          index: 0,
          count: 20,
        );
  }

  Future<void> _refresh() async {
    final newFuture = _load();
    setState(() {
      _future = newFuture;
    });
    await newFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrderModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return ErrorState(
            message: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }

        final orders = snapshot.data ?? const <OrderModel>[];
        if (orders.isEmpty) {
          return const EmptyState(
            title: 'Chưa có đơn hàng',
            message: 'Các đơn hàng bạn đã đặt sẽ hiển thị ở đây.',
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderCard(
                order: order,
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BuyerOrderDetailPage(orderId: order.id),
                    ),
                  );
                  if (result == true) {
                    _refresh();
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
