class ProductUnits {
  static const Map<String, String> unitsMap = {
    'kg': 'kilogram',
    'g': 'gram',
    'mg': 'milligram',
    'L': 'liter',
    'ml': 'milliliter',
    'piece': 'piece',
    'dozen': 'dozen',
    'pack': 'pack',
    'box': 'box',
    'set': 'set',
    'pair': 'pair',
    'unit': 'unit',
    'bottle': 'bottle',
    'jar': 'jar',
    'tin': 'tin',
    'can': 'can',
    'pouch': 'pouch',
    'bag': 'bag',
    'sack': 'sack',
    'bundle': 'bundle',
    'roll': 'roll',
    'sheet': 'sheet',
    'strip': 'strip',
    'tube': 'tube',
    'vial': 'vial',
    'sachet': 'sachet',
    'bunch': 'bunch',
    'meter': 'meter',
    'loaf': 'loaf',
    'slice': 'slice',
  };

  static List<String> get units => unitsMap.keys.toList();

  static String getDisplayName(String unit) {
    final fullForm = unitsMap[unit];
    if (fullForm == null || fullForm == unit) return unit;
    return '$unit ($fullForm)';
  }

  static String getShortName(String displayName) {
    // Extract short name from "kg (kilogram)" format
    if (displayName.contains('(')) {
      return displayName.split(' ').first;
    }
    return displayName;
  }

  static List<String> searchUnits(String query) {
    if (query.isEmpty) return units;
    return units
        .where((unit) =>
            unit.toLowerCase().startsWith(query.toLowerCase()) ||
            unitsMap[unit]!.toLowerCase().startsWith(query.toLowerCase()))
        .toList();
  }
}
