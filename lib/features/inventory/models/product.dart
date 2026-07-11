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
}
