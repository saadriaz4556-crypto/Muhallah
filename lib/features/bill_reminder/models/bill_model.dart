import 'package:hive/hive.dart';

part 'bill_model.g.dart';

@HiveType(typeId: 2)
class BillModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String billType; // Electricity, Gas, Water, Internet, Phone, Rent, Custom

  @HiveField(2)
  final String? customBillName; // Only if type == Custom

  @HiveField(3)
  final double amount; // PKR amount (required)

  @HiveField(4)
  final DateTime dueDate; // Due date (auto or manual)

  @HiveField(5)
  final int reminderDaysBefore; // 0=30min, 1=1day, 3=3days, 7=7days

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final String? billImageUrl; // NEW: Cloudinary URL (not local path!)

  @HiveField(8)
  final bool dueDateAutoDetected; // Flag: was date auto-detected via OCR?

  @HiveField(9)
  final bool amountAutoDetected; // Flag: was amount auto-detected via OCR?

  BillModel({
    required this.id,
    required this.billType,
    this.customBillName,
    required this.amount,
    required this.dueDate,
    required this.reminderDaysBefore,
    required this.createdAt,
    this.billImageUrl,
    this.dueDateAutoDetected = false,
    this.amountAutoDetected = false,
  });
}
