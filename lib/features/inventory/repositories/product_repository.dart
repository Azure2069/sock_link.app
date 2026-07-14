
import "../models/product.dart";

class ProductRepository {
  final List<Product> _products = [];

  List<Product> getProducts() {
    return List.unmodifiable(_products);
  }

  bool addProduct(Product product) {
    final idDuplicated = _products.any(
      (existingProduct) => existingProduct.id == product.id,
    );
    if (idDuplicated ||
        product.stock < 0 ||
        product.name.isEmpty ||
        product.costPrice < 0 ||
        product.unit.isEmpty||
        product.sellingPrice<0) {
      return false;
    }
    _products.add(product);
    return true;
  }
}
