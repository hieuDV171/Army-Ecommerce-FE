import 'package:army_ecommerce/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductModel.fromJson', () {
    test('filters video URLs out of images and moves them to videos', () {
      final json = {
        'id': '123',
        'title': 'Test Product',
        'price': 100000,
        'described': 'Test description',
        'image': [
          {'id': 'img1', 'url': 'https://example.com/image.jpg'},
          {'id': 'img2', 'url': 'https://example.com/video.mp4'},
        ],
        'video': [
          {'url': 'https://example.com/original_video.mp4'},
        ],
      };

      final product = ProductModel.fromJson(json);

      // Verify that the video.mp4 URL was filtered out of images/imageUrls
      expect(product.images.length, 1);
      expect(product.images.first.url, 'https://example.com/image.jpg');
      expect(product.imageUrls.length, 1);
      expect(product.imageUrls.first, 'https://example.com/image.jpg');

      // Verify that video.mp4 was added to the videos list alongside original_video.mp4
      expect(product.videos.length, 2);
      expect(product.videos[0].url, 'https://example.com/original_video.mp4');
      expect(product.videos[1].url, 'https://example.com/video.mp4');
    });

    test('handles fallback image URLs with videos correctly', () {
      final json = {
        'id': '124',
        'title': 'Test Product 2',
        'price': 50000,
        'described': 'Test description 2',
        'image_url': 'https://example.com/video.mp4',
      };

      final product = ProductModel.fromJson(json);

      expect(product.images.isEmpty, isTrue);
      expect(product.imageUrls.isEmpty, isTrue);
      expect(product.videos.length, 1);
      expect(product.videos.first.url, 'https://example.com/video.mp4');
    });
  });
}
