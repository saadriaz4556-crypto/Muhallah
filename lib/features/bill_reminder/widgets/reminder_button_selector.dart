import 'package:flutter/material.dart';

class ReminderButtonSelector extends StatelessWidget {
  final int selectedValue;
  final Function(int) onSelected;

  const ReminderButtonSelector({
    super.key,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      {'label': '30 Min', 'value': 0},
      {'label': '1 Day', 'value': 1},
      {'label': '3 Days', 'value': 3},
      {'label': '7 Days', 'value': 7},
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.0,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedValue == option['value'];
        return GestureDetector(
          onTap: () => onSelected(option['value'] as int),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFF252C42),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFF3A4154),
              ),
            ),
            child: Center(
              child: Text(
                option['label'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
