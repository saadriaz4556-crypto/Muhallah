import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/bill_model.dart';
import '../services/notification_service.dart';

class BillController extends GetxController {
  RxList<BillModel> bills = <BillModel>[].obs;
  RxBool isLoading = false.obs;

  late Box<BillModel> billsBox;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeHive();
    await NotificationService.initializeNotifications();
    await loadBills();
  }

  Future<void> _initializeHive() async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(BillModelAdapter());
    }
    billsBox = await Hive.openBox<BillModel>('bills');
  }

  Future<void> loadBills() async {
    try {
      isLoading.value = true;
      bills.value = billsBox.values.toList();
      bills.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } catch (e) {
      print('Error loading bills: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addBill(BillModel bill) async {
    try {
      // Save to Hive
      await billsBox.put(bill.id, bill);

      // Schedule notification
      await NotificationService.scheduleNotification(bill);

      // Reload
      await loadBills();

      Get.snackbar(
        '✅ Bill Saved!',
        'Reminder set for ${_getReminderText(bill.reminderDaysBefore)} before due date',
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar('❌ Error', 'Failed to save bill', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }

  Future<bool> deleteBill(String billId) async {
    try {
      final bill = billsBox.get(billId);
      
      // Cancel notification
      await NotificationService.cancelNotification(billId);

      // Delete from Hive
      await billsBox.delete(billId);

      // Reload
      await loadBills();

      Get.snackbar('✅ Bill Deleted', '', backgroundColor: Colors.black54, colorText: Colors.white);
      return true;
    } catch (e) {
      Get.snackbar('❌ Error', 'Failed to delete bill', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }

  int get totalBills => bills.length;
  double get totalAmount => bills.fold(0.0, (sum, bill) => sum + bill.amount);

  String _getReminderText(int days) {
    if (days == 0) return '30 minutes';
    if (days == 1) return '1 day';
    return '$days days';
  }
}
