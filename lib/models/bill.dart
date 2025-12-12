import 'package:hive/hive.dart';
import 'bill_item.dart';

part 'bill.g.dart';

@HiveType(typeId: 3)
class Bill extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  List<BillItem> items;

  @HiveField(2)
  double total;

  @HiveField(3)
  DateTime timestamp;

  Bill({
    required this.id,
    required this.items,
    required this.total,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((item) => item.toJson()).toList(),
        'total': total,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: json['id'] as String,
        items: (json['items'] as List)
            .map((item) => BillItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}