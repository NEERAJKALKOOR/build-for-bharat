import 'package:hive/hive.dart';

part 'bill_item.g.dart';

@HiveType(typeId: 2)
class BillItem {
  @HiveField(0)
  String productId;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  String unit;

  BillItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.unit = 'piece',
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'unit': unit,
      };

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
        productId: json['productId'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] as int,
        unit: json['unit'] as String? ?? 'piece',
      );
}