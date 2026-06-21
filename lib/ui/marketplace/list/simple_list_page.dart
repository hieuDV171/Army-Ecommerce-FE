import 'package:army_ecommerce/blocs/marketplace/simple_list/simple_list_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/simple_list/simple_list_event.dart';
import 'package:army_ecommerce/blocs/marketplace/simple_list/simple_list_state.dart';
import 'package:army_ecommerce/models/model_helpers.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../util/constants/app_spacing.dart';
import '../../util/widgets/empty_state.dart';
import '../../util/widgets/error_state.dart';
import '../../util/widgets/loading_overlay.dart';
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';

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
          AppSnackBar.show(context, message: message);
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

class SimpleListBody extends StatefulWidget {
  final String emptyMessage;

  const SimpleListBody({super.key, required this.emptyMessage});

  @override
  State<SimpleListBody> createState() => _SimpleListBodyState();
}

class _SimpleListBodyState extends State<SimpleListBody> {
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
          AppSnackBar.show(context, message: message);
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
