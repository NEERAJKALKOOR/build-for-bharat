import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';

class BillingService {
  static const String _boxName = 'bills';
  Box<Bill>? _box;
  final _uuid = const Uuid();

  Future<void> init() async {
    _box = await Hive.openBox<Bill>(_boxName);
  }

  Future<String> saveBill(List<BillItem> items) async {
    final total = items.fold<double>(0, (sum, item) => sum + item.total);
    final bill = Bill(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      items: items,
      total: total,
    );
    await _box?.put(bill.id, bill);
    return bill.id;
  }

  List<Bill> getAllBills() {
    return _box?.values.toList() ?? [];
  }

  Bill? getBill(String id) {
    return _box?.get(id);
  }

  List<Bill> getBillsForToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _box?.values.where((bill) {
      final billDate = DateTime(
        bill.timestamp.year,
        bill.timestamp.month,
        bill.timestamp.day,
      );
      return billDate == today;
    }).toList() ?? [];
  }

  List<Bill> getBillsForLastNDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _box?.values.where((bill) => bill.timestamp.isAfter(cutoff)).toList() ?? [];
  }

  List<Map<String, dynamic>> exportToJson() {
    return getAllBills().map((b) => b.toJson()).toList();
  }

  Future<void> importFromJson(List<dynamic> jsonList) async {
    for (var json in jsonList) {
      final bill = Bill.fromJson(json);
      await _box?.put(bill.id, bill);
    }
  }
}