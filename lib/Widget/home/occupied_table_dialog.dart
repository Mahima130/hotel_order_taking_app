// File: lib/Widget/home/occupied_table_dialog.dart
import 'package:flutter/material.dart';
import 'package:hotel_order_taking_app/Utils/Constants.dart';
import 'package:hotel_order_taking_app/Model/order.dart' as app_order;
import 'package:hotel_order_taking_app/Services/firestore_service.dart';
import 'package:provider/provider.dart';

class OccupiedTableDialog extends StatelessWidget {
  final app_order.Order order;
  final VoidCallback onAddOrder;
  final VoidCallback onViewOrder;

  const OccupiedTableDialog({
    Key? key,
    required this.order,
    required this.onAddOrder,
    required this.onViewOrder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: StreamBuilder<List<app_order.Order>>(
          stream: firestoreService.getOrdersForTableAtLocation(
            order.tableNo,
            order.location ?? 'Rooftop',
            order.tableType,
          ),
          builder: (context, snapshot) {
            // Calculate totals from ALL orders for this table
            int totalOrders = 0;
            double totalAmount = 0.0;

            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final allOrders = snapshot.data!;
              totalOrders = allOrders.length;
              totalAmount = allOrders.fold<double>(
                0.0,
                (sum, order) => sum + order.totalPrice,
              );
            } else {
              // Fallback to current order data if stream is loading
              totalOrders = order.orderCount ?? 1;
              totalAmount = order.totalPrice;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Badge with Location, Table Type and Table No
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.drawerBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppSizes.radiusLarge),
                      topRight: Radius.circular(AppSizes.radiusLarge),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Left side: Location and Table Type
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (order.location != null &&
                                order.location!.isNotEmpty)
                              //   Text(
                              //     order.location!,
                              //     style: const TextStyle(
                              //       fontSize: 16,
                              //       fontWeight: FontWeight.w600,
                              //       color: AppColors.primaryGold,
                              //     ),
                              //   ),
                              // const SizedBox(height: 2),
                              Text(
                                order.tableType,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Right side: Table Number
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        child: Text(
                          '${order.tableNo}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Area
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // First Row: No of Orders label + value + View Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // No of Orders label and value - FIXED
                          Row(
                            children: [
                              const Text(
                                'No of Orders: ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                '$totalOrders', // ✅ Shows TOTAL ORDERS, not items
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),

                          // View Button
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Future.delayed(const Duration(milliseconds: 50),
                                  () {
                                onViewOrder();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonBackground,
                              foregroundColor: AppColors.buttonText,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMedium),
                              ),
                              elevation: 2,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View Order',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.buttonText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Second Row: Amount label + value - FIXED
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '₹${totalAmount.toStringAsFixed(2)}', // ✅ Shows TOTAL AMOUNT of all orders
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Footer with Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppSizes.radiusLarge),
                      bottomRight: Radius.circular(AppSizes.radiusLarge),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: AppColors.textDark,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMedium),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            AppStrings.cancel,
                            style: TextStyle(
                              fontSize: AppSizes.fontM,
                              fontWeight: FontWeight.w600,
                              color: AppColors.buttonText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Add Order Button
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Future.delayed(const Duration(milliseconds: 50),
                                () {
                              onAddOrder();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBackground,
                            foregroundColor: AppColors.buttonText,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMedium),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_circle_outline,
                                size: 20,
                                color: AppColors.buttonText,
                              ),
                              SizedBox(width: 8),
                              Text(
                                AppStrings.addOrder,
                                style: TextStyle(
                                  fontSize: AppSizes.fontM + 1,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.buttonText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
