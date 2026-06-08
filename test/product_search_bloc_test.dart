import 'package:flutter_test/flutter_test.dart';
import 'package:army_ecommerce/blocs/marketplace/marketplace_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/marketplace_event.dart';
import 'package:army_ecommerce/blocs/marketplace/marketplace_state.dart';
import 'package:army_ecommerce/models/marketplace_models.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';

class MockMarketplaceRepository implements MarketplaceRepository {
  bool getListProductsCalled = false;
  bool searchProductsCalled = false;

  @override
  Future<ProductListResult> getListProducts({
    int index = 0,
    int count = 20,
    String? keyword,
    String? categoryId,
    String? brandId,
    int? productSizeId,
    num? priceMin,
    num? priceMax,
    String? order,
    int? latitude,
    int? longitude,
    int? lastId,
  }) async {
    getListProductsCalled = true;
    return ProductListResult(products: const [], lastId: null);
  }

  @override
  Future<List<ProductModel>> searchProducts({
    String? keyword,
    String? categoryId,
    String? brandId,
    num? priceMin,
    num? priceMax,
    String? condition,
    int index = 0,
    int count = 20,
  }) async {
    searchProductsCalled = true;
    return const [];
  }

  @override
  Future<List<BrandModel>> getBrands({String? categoryId, int index = 0, int count = 20}) async {
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Method not mocked: ${invocation.memberName}');
  }
}

void main() {
  late MockMarketplaceRepository repository;
  late ProductSearchBloc bloc;

  setUp(() {
    repository = MockMarketplaceRepository();
    bloc = ProductSearchBloc(marketplaceRepository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  test('when search is requested without conditions, it calls getListProducts', () async {
    bloc.add(ProductSearchRequested());
    await expectLater(
      bloc.stream,
      emitsThrough(isA<ProductSearchState>()),
    );
    expect(repository.getListProductsCalled, isTrue);
    expect(repository.searchProductsCalled, isFalse);
    expect(bloc.state.useListProductsApi, isTrue);
  });

  test('when search is requested with keyword condition, it calls searchProducts', () async {
    bloc.add(ProductSearchRequested(keyword: 'áo'));
    await expectLater(
      bloc.stream,
      emitsThrough(isA<ProductSearchState>()),
    );
    expect(repository.getListProductsCalled, isFalse);
    expect(repository.searchProductsCalled, isTrue);
    expect(bloc.state.useListProductsApi, isFalse);
  });
}
