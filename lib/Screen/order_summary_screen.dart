import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hotel_order_taking_app/Model/order.dart' as app_order;
import 'package:hotel_order_taking_app/Model/order_item.dart';
import 'package:hotel_order_taking_app/Provider/order_provider.dart';
import 'package:hotel_order_taking_app/Services/firestore_service.dart';
import 'package:hotel_order_taking_app/Widget/menu_search_model.dart';
import 'package:hotel_order_taking_app/Utils/Constants.dart';
import 'package:hotel_order_taking_app/Widget/Common/background_container.dart';
import 'package:hotel_order_taking_app/Widget/Common/custom_app_bar.dart';
import 'package:hotel_order_taking_app/Widget/Common/custom_gradient_button.dart';
import 'package:hotel_order_taking_app/Widget/Common/custom_dialog.dart';
import 'package:hotel_order_taking_app/Widget/Common/loading_indicator.dart';
import 'package:hotel_order_taking_app/Widget/Common/empty_state.dart';

class OrderSummaryScreen extends StatelessWidget {
  const OrderSummaryScreen({Key? key}) : super(key: key);

  Future<void> _confirmOrder(BuildContext context) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final firestoreService = FirestoreService();

    if (orderProvider.tableNo == null ||
        orderProvider.phoneNo == null ||
        orderProvider.orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order details incomplete'),
          backgroundColor: AppColors.buttonBackground,
        ),
      );
      return;
    }

    print('🔄 Starting order confirmation...');
    print(
        '📋 Table: ${orderProvider.tableNo}, Type: ${orderProvider.tableType}');
    print('📍 Location: ${orderProvider.location}');
    print('📞 Phone: ${orderProvider.phoneNo}');
    print('🛒 Items: ${orderProvider.orderItems.length}');
    print('💰 Total: ${orderProvider.totalAmount}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const LoadingIndicator(),
    );

    try {
      // ✅ ALWAYS CREATE NEW ORDER - Don't check for existing orders
      print('🆕 Creating NEW order (separate order for table)...');

      final order = app_order.Order(
        id: '',
        tableNo: orderProvider.tableNo!,
        tableType: orderProvider.tableType!,
        phoneNo: orderProvider.phoneNo!,
        time: DateTime.now(),
        totalPrice: orderProvider.totalAmount,
        items: orderProvider.orderItems,
        status: 'active',
        orderType: orderProvider.orderType,
        location: orderProvider.location,
        orderCount: 1, // Each order is separate, so count is 1
      );

      print('📦 Order object created: ${order.toFirestore()}');

      final orderId = await firestoreService.saveOrder(order);
      Navigator.pop(context); // Close loading dialog

      print('✅ New order created with ID: $orderId');

      // ✅ CLEAR CACHE to refresh data
      firestoreService.clearOccupiedTablesCache();
      firestoreService.clearOccupiedTablesCacheForType(
          orderProvider.location!, orderProvider.tableType!);

      orderProvider.clearCart();
      orderProvider.reset();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New order created! ID: $orderId'),
          backgroundColor: AppColors.goldDark,
        ),
      );

      print('🎉 Order process completed successfully');

      // Navigate back to home screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e, stackTrace) {
      Navigator.pop(context); // Close loading dialog
      print('❌ Error in _confirmOrder: $e');
      print('📝 Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _handleBackPress(BuildContext context) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    // If no items, just go back to home
    if (orderProvider.orderItems.isEmpty) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    // Show discard dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CustomDialog(
        title: 'Discard Order?',
        content:
            'Your current order will be discarded. This action cannot be undone.',
        cancelText: AppStrings.cancel,
        confirmText: AppStrings.discard,
        confirmColor: Colors.red,
        onConfirm: () {
          Navigator.of(dialogContext).pop(true);
        },
      ),
    );

    // If user confirmed, clear and go back to home
    if (result == true && context.mounted) {
      orderProvider.clearCart();
      orderProvider.reset();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    // If no items, allow back navigation to home - navigate immediately
    if (orderProvider.orderItems.isEmpty) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return false; // Prevent default pop since we're handling navigation
    }

    // Show discard dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CustomDialog(
        title: 'Discard Order?',
        content:
            'Your current order will be discarded. This action cannot be undone.',
        cancelText: AppStrings.cancel,
        confirmText: AppStrings.discard,
        confirmColor: Colors.red,
        onConfirm: () {
          Navigator.of(dialogContext).pop(true);
        },
      ),
    );

    // If user confirmed, clear the cart and navigate to home
    if (result == true) {
      orderProvider.clearCart();
      orderProvider.reset();
      Navigator.of(context).popUntil((route) => route.isFirst);
      return false; // Prevent default pop since we're handling navigation
    }

    return false; // Prevent default pop if cancelled
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: BackgroundContainer(
          child: Column(
            children: [
              CustomAppBar(
                title: AppStrings.orderSummary,
                showBack: true,
                onBackTap: () => _handleBackPress(context),
                trailing: orderProvider.orderItems.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spaceM, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.buttonBackground,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMedium),
                        ),
                        child: Text(
                          '${orderProvider.itemCount} Items',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: AppSizes.fontS,
                          ),
                        ),
                      )
                    : null,
              ),

              // Table Info
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(AppSizes.spaceL),
                padding: const EdgeInsets.all(AppSizes.spaceL),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMedium),
                      ),
                      child: const Icon(
                        Icons.table_restaurant,
                        color: AppColors.primaryGold,
                        size: AppSizes.iconM,
                      ),
                    ),
                    SizedBox(width: AppSizes.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TABLE ${orderProvider.tableNo}',
                            style: const TextStyle(
                              fontSize: AppSizes.fontL,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          if (orderProvider.location != null &&
                              orderProvider.tableType != null)
                            Text(
                              '${orderProvider.location} - ${orderProvider.tableType}',
                              style: TextStyle(
                                fontSize: AppSizes.fontS,
                                color: Colors.grey[700],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.phone,
                            color: AppColors.primaryGold, size: AppSizes.iconS),
                        SizedBox(width: AppSizes.spaceS - 2),
                        Text(
                          orderProvider.phoneNo ?? '',
                          style: const TextStyle(
                            fontSize: AppSizes.fontM,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Items List
              Expanded(
                child: orderProvider.orderItems.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const EmptyState(
                            icon: Icons.shopping_cart_outlined,
                            message: 'No items in order',
                          ),
                          SizedBox(height: AppSizes.spaceXL),
                          SizedBox(
                            width: 200,
                            child: ElevatedButton(
                              onPressed: () => showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => const MenuSearchModal(),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonBackground,
                                foregroundColor: AppColors.buttonText,
                                minimumSize: const Size(
                                    double.infinity, AppSizes.buttonHeight),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.radiusMedium),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_shopping_cart,
                                      color: AppColors.buttonText),
                                  SizedBox(width: AppSizes.spaceS),
                                  Text(
                                    'ADD ITEMS',
                                    style: TextStyle(
                                      color: AppColors.buttonText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: AppSizes.fontL,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spaceL,
                            vertical: AppSizes.spaceS),
                        itemCount: orderProvider.orderItems.length,
                        itemBuilder: (ctx, index) {
                          final item = orderProvider.orderItems[index];
                          return _buildOrderItemCard(
                              item, orderProvider, index, context);
                        },
                      ),
              ),

              // Add More Items Button
              if (orderProvider.orderItems.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spaceL, vertical: AppSizes.spaceS),
                    child: ElevatedButton(
                      onPressed: () => showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => const MenuSearchModal(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBackground,
                        foregroundColor: AppColors.buttonText,
                        minimumSize:
                            const Size(double.infinity, AppSizes.buttonHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMedium),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: AppColors.buttonText),
                          SizedBox(width: AppSizes.spaceS),
                          Text(
                            AppStrings.addMoreItems,
                            style: TextStyle(
                              color: AppColors.buttonText,
                              fontWeight: FontWeight.w600,
                              fontSize: AppSizes.fontL,
                            ),
                          ),
                        ],
                      ),
                    )),

              // Total & Confirm
              if (orderProvider.orderItems.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(AppSizes.spaceL),
                  padding: const EdgeInsets.all(AppSizes.spaceXL),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL AMOUNT',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Text(
                            '₹${orderProvider.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.drawerBackground,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSizes.spaceL),
                      CustomGradientButton(
                        label: AppStrings.confirmOrder,
                        gradient: AppGradients.darkGradient,
                        onPressed: () => _confirmOrder(context),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItemCard(OrderItem item, OrderProvider orderProvider,
      int index, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceL),
        child: Column(
          children: [
            // Row 1: Delete Icon + Item Name
            Row(
              children: [
                InkWell(
                  onTap: () => _showDeleteConfirmation(
                      context, item.name, index, orderProvider),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200, width: 1),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.note_outlined,
                              size: 14,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.notes,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Divider
            Divider(color: Colors.grey.shade200, height: 1),

            const SizedBox(height: 12),

            // Row 2: Price + Quantity Controls + Total
            Row(
              children: [
                // Unit Price
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '₹${(item.totalPrice / item.quantity).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),

                // Quantity Controls - CENTERED
                Expanded(
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.buttonBackground.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.buttonBackground, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => orderProvider.decrementQuantity(index),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.buttonBackground,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.buttonBackground,
                                    width: 1.5),
                              ),
                              child: const Icon(
                                Icons.remove,
                                size: 16,
                                color: AppColors.buttonText,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => orderProvider.incrementQuantity(index),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.buttonBackground,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.buttonBackground,
                                    width: 1.5),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 16,
                                color: AppColors.buttonText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Total Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      '₹${item.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.drawerBackground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String itemName, int index,
      OrderProvider orderProvider) {
    showDialog(
      context: context,
      builder: (ctx) => CustomDialog(
        title: 'Remove Item',
        content: 'Remove $itemName from order?',
        cancelText: AppStrings.cancel,
        confirmText: 'REMOVE',
        confirmColor: AppColors.error,
        onConfirm: () {
          orderProvider.removeItem(index);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$itemName removed'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
