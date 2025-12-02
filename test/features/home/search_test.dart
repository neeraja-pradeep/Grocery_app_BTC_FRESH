import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/features/home/domain/entities/product.dart';
import 'package:grocery_app/features/home/domain/entities/product_media.dart';
import 'package:grocery_app/features/home/domain/entities/product_variant.dart';

void main() {
  group('Product Search Tests', () {
    test('Product.fromJson should parse API response correctly', () {
      final json = {
        'id': 42,
        'name': 'Milk',
        'description': 'Milk',
        'category_name': 'Dairy & Breakfast',
        'category_id': 2,
        'slug': null,
        'description_plaintext': 'qqqqqqqqqqqqqq',
        'search_document': 'samplesearchdoc',
        'created_at': '2025-11-21T09:47:09.221374Z',
        'updated_at': '2025-11-24T11:46:12.099484Z',
        'weight': null,
        'default_variant_id': null,
        'rating': '1.0',
        'tax_class_id': 1,
        'media': [
          {
            'id': 45,
            'file_path': 'products/media/f566204d2fbb4412b37f1e30a7ea0c03.webp',
            'image':
                'grocery-application.b-cdn.net/products/media/f566204d2fbb4412b37f1e30a7ea0c03.webp',
            'alt': 'Product image',
            'external_url': null,
            'oembed_data': null,
            'to_remove': false,
            'product_id': 42,
            'created_at': '2025-11-22T16:51:25.689118Z',
            'updated_at': '2025-11-22T16:51:25.702181Z',
          },
        ],
        'variants': [
          {
            'id': 19,
            'sku': 'Milk',
            'name': 'Milk',
            'product_id': 42,
            'track_inventory': true,
            'price': '90.00',
            'discounted_price': '100.00',
            'is_selected': true,
            'is_preorder': false,
            'preorder_end_date': null,
            'preorder_global_threshold': null,
            'quantity_limit_per_customer': null,
            'created_at': '2025-11-21T09:47:10.612770Z',
            'updated_at': '2025-11-24T11:45:49.452496Z',
            'weight': '12.00',
            'status': false,
            'tags': null,
            'bar_code': null,
            'media': [],
            'current_quantity': 2,
            'current_stock_unit': 'units',
            'prod_description': 'Milk',
            'product_rating': '1.0',
            'warehouse_name': 'warehose1',
            'warehouse_id': 1,
          },
        ],
        'status': true,
        'tags': null,
      };

      final product = Product.fromJson(json);

      expect(product.id, 42);
      expect(product.name, 'Milk');
      expect(product.categoryName, 'Dairy & Breakfast');
      expect(product.categoryId, 2);
      expect(product.rating, '1.0');
      expect(product.status, true);
      expect(product.media.length, 1);
      expect(product.variants.length, 1);
      expect(product.hasVariants, true);
    });

    test('Product should handle display image correctly', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        categoryName: 'Test Category',
        categoryId: 1,
        rating: '4.0',
        taxClassId: 1,
        media: [
          ProductMedia(
            id: 1,
            imageUrl: 'https://example.com/image.jpg',
            productId: 1,
            createdAt: DateTime.now(),
          ),
        ],
        variants: [],
        status: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(product.displayImage, 'https://example.com/image.jpg');
    });

    test('Product should calculate display price correctly', () {
      final variant = ProductVariant(
        id: 1,
        name: 'Test Variant',
        productId: 1,
        sku: 'TEST',
        price: 100.0,
        discountedPrice: 80.0,
        currentQuantity: '10',
        status: true,
        media: [],
        isPreorder: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final product = Product(
        id: 1,
        name: 'Test Product',
        categoryName: 'Test Category',
        categoryId: 1,
        rating: '4.0',
        taxClassId: 1,
        media: [],
        variants: [variant],
        status: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(product.displayPrice, 80.0);
      expect(product.hasDiscount, true);
    });
  });
}
