import 'package:flutter/material.dart';
import '../constants/product_units.dart';

class SearchableUnitDropdown extends StatefulWidget {
  final String? selectedUnit;
  final Function(String) onChanged;

  const SearchableUnitDropdown({
    Key? key,
    this.selectedUnit,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<SearchableUnitDropdown> createState() => _SearchableUnitDropdownState();
}

class _SearchableUnitDropdownState extends State<SearchableUnitDropdown> {
  String? _currentUnit;

  @override
  void initState() {
    super.initState();
    _currentUnit = widget.selectedUnit ?? 'piece';
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _currentUnit,
      decoration: const InputDecoration(
        labelText: 'Unit *',
        prefixIcon: Icon(Icons.scale),
        border: OutlineInputBorder(),
      ),
      isExpanded: true,
      items: ProductUnits.units.map((unit) {
        final displayName = ProductUnits.getDisplayName(unit);
        return DropdownMenuItem<String>(
          value: unit,
          child: Text(displayName),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _currentUnit = value;
          });
          widget.onChanged(value);
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a unit';
        }
        return null;
      },
    );
  }
}
