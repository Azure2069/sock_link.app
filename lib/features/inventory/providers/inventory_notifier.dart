import "package:flutter_riverpod/legacy.dart";

import "../models/product.dart";
import "../repositories/product_repository.dart";

import "package:flutter_riverpod/flutter_riverpod.dart";

class InventoryNotifier extends StateNotifier<List<Product>> {
  final ProductRepository _repository;

  InventoryNotifier(this._repository) : super(_repository.getProducts());

  bool addProduct(Product product) {
    final added = _repository.addProduct(product);

    if (added) {
      state = _repository.getProducts();
    }
    return added;
  }
}
