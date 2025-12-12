import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 1)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? barcode;

  @HiveField(3)
  double price;

  @HiveField(4)
  double quantity;

  @HiveField(5)
  int threshold;

  @HiveField(6)
  String? imageUrl;

  @HiveField(7)
  String? brand;

  @HiveField(8)
  String? category;

  @HiveField(9)
  String unit;

  @HiveField(10)
  String? source; // API source: OpenFoodFacts, OpenBeautyFacts, etc.

  Product({
    required this.id,
    required this.name,
    this.barcode,
    required this.price,
    required this.quantity,
    required this.threshold,
    this.imageUrl,
    this.brand,
    this.category,
    this.unit = 'piece',
    this.source,
  });

  bool get isLowStock => quantity < threshold;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'barcode': barcode,
        'price': price,
        'quantity': quantity,
        'threshold': threshold,
        'source': source,
        'imageUrl': imageUrl,
        'brand': brand,
        'category': category,
        'unit': unit,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        barcode: json['barcode'] as String?,
        price: (json['price'] as num).toDouble(),
        quantity: (json['quantity'] as num).toDouble(),
        threshold: json['threshold'] as int,
        imageUrl: json['imageUrl'] as String?,
        brand: json['brand'] as String?,
        category: json['category'] as String?,
        source: json['source'] as String?,
        unit: json['unit'] as String? ?? 'piece',
      );

  Product copyWith({
    String? id,
    String? name,
    String? barcode,
    double? price,
    double? quantity,
    int? threshold,
    String? imageUrl,
    String? brand,
    String? category,
    String? unit,
    String? source,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      threshold: threshold ?? this.threshold,
      imageUrl: imageUrl ?? this.imageUrl,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      source: source ?? this.source,
    );
  }
}