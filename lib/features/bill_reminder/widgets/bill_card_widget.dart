import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../models/bill_model.dart';
import '../screens/add_bill_screen.dart';
import '../controllers/bill_controller.dart';
import '../../../widgets/fullscreen_image_viewer.dart';

class BillCardWidget extends StatelessWidget {
  final BillModel bill;
  final VoidCallback? onTap;

  const BillCardWidget({super.key, required this.bill, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF252C42),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A4154), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getBillTypeIcon(bill.billType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.billType == 'Custom'
                            ? (bill.customBillName ?? 'Custom Bill')
                            : bill.billType,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due: ${DateFormat('d MMM, yyyy').format(bill.dueDate)}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (bill.billImageUrl != null) ...[
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FullscreenImageViewer(imageUrl: bill.billImageUrl!),
                        ),
                      );
                    },
                    child: Hero(
                      tag: bill.billImageUrl!,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          bill.billImageUrl!.replaceFirst(
                              '/upload/', '/upload/w_100,h_100,c_fill/'),
                          height: 45,
                          width: 45,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image,
                                  color: Colors.grey, size: 24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  color: const Color(0xFF252C42),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Get.to(() => AddBillScreen(billToEdit: bill));
                    } else if (value == 'delete') {
                      // Confirm delete
                      final controller = Get.find<BillController>();
                      await controller.deleteBill(bill.id);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Color(0xFF00BCD4), size: 20),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'PKR ${bill.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getBillTypeColor(bill.billType),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A4154),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Reminder: ${_getReminderText(bill.reminderDaysBefore)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
            if (bill.dueDateAutoDetected)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 14, color: Color(0xFFFFB800)),
                    SizedBox(width: 4),
                    Text(
                      'Date auto-detected via AI',
                      style: TextStyle(fontSize: 10, color: Color(0xFFFFB800)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getReminderText(int daysBefore) {
    if (daysBefore == 0) return '30 minutes';
    if (daysBefore == 1) return '1 day';
    return '$daysBefore days';
  }

  Widget _getBillTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
      case 'electricity':
        icon = Icons.flash_on;
        color = const Color(0xFFFFB800);
        break;
      case 'gas':
        icon = Icons.local_fire_department;
        color = const Color(0xFFFF6B35);
        break;
      case 'water':
        icon = Icons.opacity;
        color = const Color(0xFF2196F3);
        break;
      case 'internet':
        icon = Icons.language;
        color = const Color(0xFF9C27B0);
        break;
      case 'phone':
        icon = Icons.phone;
        color = const Color(0xFF4CAF50);
        break;
      case 'rent':
        icon = Icons.home;
        color = const Color(0xFF009688);
        break;
      default:
        icon = Icons.description;
        color = const Color(0xFF607D8B);
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Color _getBillTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'electricity':
        return const Color(0xFFFFB800);
      case 'gas':
        return const Color(0xFFFF6B35);
      case 'water':
        return const Color(0xFF2196F3);
      case 'internet':
        return const Color(0xFF9C27B0);
      case 'phone':
        return const Color(0xFF4CAF50);
      case 'rent':
        return const Color(0xFF009688);
      default:
        return const Color(0xFF607D8B);
    }
  }
}
