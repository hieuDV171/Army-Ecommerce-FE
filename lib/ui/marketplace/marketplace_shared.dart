import '../../models/marketplace_models.dart';
import '../util/widgets/product_card.dart';

ProductCardData productCardDataFromModel(ProductModel product) {
  final primaryImage = product.images.isNotEmpty
      ? product.images.first.url
      : (product.imageUrls.isEmpty ? null : product.imageUrls.first);
  final sellerScore = double.tryParse(product.seller?.score ?? '');
  final sellerListing = int.tryParse(product.seller?.listing ?? '');

  return ProductCardData(
    id: product.id,
    title: product.title,
    price: product.price,
    imageUrl: (primaryImage != null && primaryImage.isNotEmpty) ? primaryImage : null,
    rating: product.rating ?? sellerScore,
    soldCount: product.soldCount ?? sellerListing,
    sellerLocation: product.sellerLocation ?? product.shipsFrom,
    isLiked: product.isLiked,
  );
}
