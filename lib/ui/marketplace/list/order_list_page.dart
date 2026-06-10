import 'package:army_ecommerce/blocs/marketplace/simple_list/simple_list_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/simple_list/simple_list_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../repositories/marketplace_repository.dart';
import 'simple_list_page.dart';

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
        loader: (index, count) async {
          final orders = await repository.getOrders(
            state: state,
            index: index,
            count: count,
          );
          return orders.map((order) => order.toItem()).toList();
        },
      )..add(SimpleListRequested()),
      child: const SimpleListBody(emptyMessage: 'Chưa có đơn hàng'),
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
      child: const SimpleListBody(emptyMessage: 'Chua co don hang'),
    );
  }
}
