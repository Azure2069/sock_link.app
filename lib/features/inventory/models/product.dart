class Product {
  final int id;
  final String name;
  final double costPrice;
  final double sellingPrice;
  final int stock;
  final String unit;

  const Product({
    required this.name,
    required this.id,
    required this.costPrice,
    required this.sellingPrice,
    required this.stock,
    required this.unit,
  });

  Product copyWith({
    String? name,
    int? id,
    double? costPrice,
    double? sellingPrice,
    int? stock,
    String? unit,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
    );
  }
}
