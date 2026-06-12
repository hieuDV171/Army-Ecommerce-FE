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
  final ScrollController _scrollController = ScrollController();
  List<OrderModel> _orders = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
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
      _loadMore();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _orders = [];
      _currentIndex = 0;
      _hasReachedEnd = false;
    });
    try {
      final repository = context.read<MarketplaceRepository>();
      final list = await repository.getOrders(
        state: widget.stateFilter,
        index: 0,
        count: 20,
      );
      if (!mounted) return;
      setState(() {
        _orders = list;
        _currentIndex = list.length;
        _hasReachedEnd = list.length < 20;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _hasReachedEnd || _isLoading) return;
    if (!mounted) return;
    setState(() => _isLoadingMore = true);
    try {
      final repository = context.read<MarketplaceRepository>();
      final list = await repository.getOrders(
        state: widget.stateFilter,
        index: _currentIndex,
        count: 20,
      );
      if (!mounted) return;
      setState(() {
        _orders = [..._orders, ...list];
        _currentIndex += list.length;
        _hasReachedEnd = list.length < 20;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _orders.isEmpty) {
      return ErrorState(
        message: _error!,
        onRetry: _refresh,
      );
    }

    if (_orders.isEmpty) {
      return const EmptyState(
        title: 'Chưa có đơn hàng',
        message: 'Các đơn hàng bạn đã đặt sẽ hiển thị ở đây.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index == _orders.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final order = _orders[index];
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
  }
}
