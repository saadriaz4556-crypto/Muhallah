import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/bill_controller.dart';
import '../widgets/bill_card_widget.dart';
import 'add_bill_screen.dart';

class BillListScreen extends StatelessWidget {
  final BillController controller = Get.put(BillController());

  static const Color _darkBackground = Color(0xFF252A34);
  static const Color _primaryColor = Color(0xFF08D9D6);
  static const Color _darkCardColor = Color(0xFF2A303C);
  static const Color _darkTextColor = Color(0xFFEAEAEA);
  static const Color _darkSecondaryText = Colors.white70;

  BillListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      // Card 1: Total Bills
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _darkCardColor,
                            border: Border.all(color: _primaryColor, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.receipt,
                                  color: _primaryColor, size: 32),
                              const SizedBox(height: 12),
                              Text(
                                'Total Bills',
                                style: TextStyle(
                                    color: _darkSecondaryText, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Obx(() => FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${controller.totalBills}',
                                      style: TextStyle(
                                        color: _primaryColor,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Card 2: Total Amount
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _darkCardColor,
                            border: Border.all(color: _primaryColor, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.account_balance_wallet,
                                  color: _primaryColor, size: 32),
                              const SizedBox(height: 12),
                              Text(
                                'Total Amount',
                                style: TextStyle(
                                    color: _darkSecondaryText, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Obx(() => FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'PKR ${controller.totalAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: _primaryColor,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Bill List or Empty State
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (controller.bills.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.bills.length,
                      itemBuilder: (context, index) {
                        final bill = controller.bills[index];
                        return Dismissible(
                          key: Key(bill.id),
                          direction: DismissDirection.startToEnd,
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            color: _primaryColor,
                            child: Icon(Icons.delete, color: _darkBackground),
                          ),
                          onDismissed: (direction) async {
                            await controller.deleteBill(bill.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bill deleted')),
                            );
                          },
                          child: BillCardWidget(bill: bill),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton.small(
          onPressed: () => Get.to(() => const AddBillScreen()),
          backgroundColor: _primaryColor,
          foregroundColor: _darkBackground,
          child: const Icon(Icons.add, size: 24),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_darkBackground, _primaryColor.withValues(alpha: 0.2)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _darkCardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back, color: _darkTextColor),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Bill Reminders',
            style: TextStyle(
              color: _darkTextColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.credit_card, size: 80, color: _primaryColor),
          const SizedBox(height: 24),
          Text(
            'No bills added yet',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _darkTextColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your utility bills to get due-date reminders\nand never miss a payment.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _darkSecondaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
