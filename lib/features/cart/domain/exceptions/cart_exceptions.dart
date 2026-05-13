/// Exception thrown when there's insufficient stock for a product
class InsufficientStockException implements Exception {
  InsufficientStockException(this.message);
  final String message;

  @override
  String toString() => message;
}
