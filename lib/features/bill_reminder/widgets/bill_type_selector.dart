import 'package:flutter/material.dart';

class BillTypeSelector extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeSelected;

  const BillTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final types = ['Electricity', 'Gas', 'Water', 'Internet', 'Phone', 'Rent', 'Custom'];
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: types.map((type) {
          final isSelected = selectedType == type;
          return GestureDetector(
            onTap: () => onTypeSelected(type),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFF252C42),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFF3A4154),
                ),
              ),
              child: Center(
                child: Text(
                  type,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
