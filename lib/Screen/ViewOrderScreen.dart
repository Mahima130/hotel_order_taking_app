import 'package:flutter/material.dart';
import 'package:hotel_order_taking_app/Model/order.dart' as app_order;
import 'package:hotel_order_taking_app/Services/firestore_service.dart';
import 'package:hotel_order_taking_app/Utils/Constants.dart';
import 'package:hotel_order_taking_app/Widget/Common/loading_indicator.dart';
import 'package:hotel_order_taking_app/Widget/Common/empty_state.dart';
import 'package:hotel_order_taking_app/Widget/Common/background_container.dart';

class ViewOrderScreen extends StatefulWidget {
  final app_order.Order order;

  const ViewOrderScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<ViewOrderScreen> createState() => _ViewOrderScreenState();
}

class _ViewOrderScreenState extends State<ViewOrderScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _orderKeys = {};

  String get _detectedLocation {
    if (widget.order.location != null && widget.order.location!.isNotEmpty) {
      return widget.order.location!;
    }

    final tableNo = widget.order.tableNo;
    if (tableNo >= 101 && tableNo <= 110) return 'Rooftop';
    if (tableNo >= 201 && tableNo <= 210) return 'Lounge';
    if (tableNo >= 301 && tableNo <= 310) return 'VIP';
    return 'Rooftop';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToOrder(int index) {
    final key = _orderKeys[index];
    if (key?.currentContext != null) {
      // Add a delay to allow the expansion animation to complete
      Future.delayed(const Duration(milliseconds: 150), () {
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.1, // Keeps the expanded item near the top
            alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.drawerBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryGold),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'ORDER DETAILS',
            style: TextStyle(
              color: AppColors.primaryGold,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: AppSizes.fontXL,
            ),
          ),
        ),
      ),
      body: BackgroundContainer(
        child: Column(
          children: [
            // Table Info Section - Only Table Type and Table Number
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spaceXL, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Table Type
                  Row(
                    children: [
                      // const Icon(Icons.table_restaurant,
                      //                       //     size: 20, color: AppColors.primaryDark),
                      //                       // SizedBox(width: AppSizes.spaceS),
                      Text(
                        widget.order.tableType ?? 'Standard',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 25),
                  Row(
                    children: [
                      Text(
                        '${widget.order.tableNo}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.buttonText,
                        ),
                      ),
                    ],
                  ),

                  // Order Type Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.order.orderType == 'ENT'
                          ? AppColors.entColor
                          : AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: Text(
                      widget.order.orderType ?? AppStrings.regular,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: AppSizes.fontS,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Total Orders & Amount Badges
            StreamBuilder<List<app_order.Order>>(
              stream: _firestoreService.getOrdersForTableAtLocation(
                widget.order.tableNo,
                _detectedLocation,
                widget.order.tableType,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: const LoadingIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  print('❌ Error loading orders: ${snapshot.error}');
                  return _buildErrorBadges();
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyBadges();
                }

                final orders = snapshot.data!;
                print('📊 Found ${orders.length} orders for calculation');

                // Calculate totals
                final totalOrders = orders.length;
                final totalAmount = orders.fold<double>(
                  0.0,
                  (sum, order) => sum + order.totalPrice,
                );

                print(
                    '💰 Total Orders: $totalOrders, Total Amount: $totalAmount');

                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.drawerBackground.withOpacity(0.9),
                    border: Border(
                      top: BorderSide(
                          color: AppColors.primaryGold.withOpacity(0.3)),
                      bottom: BorderSide(
                          color: AppColors.primaryGold.withOpacity(0.3)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Total Orders Badge
                      _buildTotalBadge(
                        title: 'Total Orders',
                        value: '$totalOrders',
                        color: AppColors.buttonText,
                      ),

                      // Total Amount Badge
                      _buildTotalBadge(
                        title: 'Total Amount',
                        value: '₹${totalAmount.toStringAsFixed(0)}',
                        color: AppColors.buttonText,
                      ),
                    ],
                  ),
                );
              },
            ),

            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spaceXL, vertical: AppSizes.spaceM),
              decoration: const BoxDecoration(
                color: AppColors.drawerBackground,
              ),
              child: Row(
                children: const [
                  Expanded(
                    flex: 2,
                    child: Text('Order No.',
                        style: TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Items',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Amount',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('View',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),

            // Orders List
            Expanded(
              child: StreamBuilder<List<app_order.Order>>(
                stream: _firestoreService.getOrdersForTableAtLocation(
                  widget.order.tableNo,
                  _detectedLocation,
                  widget.order.tableType,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingIndicator();
                  }

                  if (snapshot.hasError) {
                    return const EmptyState(
                      icon: Icons.error_outline,
                      message: 'Error loading orders',
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const EmptyState(
                      icon: Icons.receipt_long,
                      message: 'No orders found',
                    );
                  }

                  final orders = snapshot.data!;

                  // Create keys for each order
                  for (int i = 0; i < orders.length; i++) {
                    _orderKeys.putIfAbsent(i, () => GlobalKey());
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final totalItems = order.items.length;
                      final totalAmount = order.items.fold<double>(
                        0,
                        (sum, item) => sum + (item.price * item.quantity),
                      );

                      return TabularOrderRow(
                        key: _orderKeys[index],
                        order: order,
                        orderNumber: index + 1,
                        totalItems: totalItems,
                        totalAmount: totalAmount,
                        onExpanded: () => _scrollToOrder(index),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Error state badges
  Widget _buildErrorBadges() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: Colors.red.withOpacity(0.3)),
          bottom: BorderSide(color: Colors.red.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTotalBadge(
            title: 'Error',
            value: 'Loading...',
            color: Colors.red,
          ),
          _buildTotalBadge(
            title: 'Error',
            value: 'Loading...',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  // Empty state badges
  Widget _buildEmptyBadges() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.drawerBackground.withOpacity(0.9),
        border: Border(
          top: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
          bottom: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTotalBadge(
            title: 'Total Orders',
            value: '0',
            color: AppColors.buttonText,
          ),
          _buildTotalBadge(
            title: 'Total Amount',
            value: '₹0',
            color: AppColors.buttonText,
          ),
        ],
      ),
    );
  }

  // Badge Widget with custom font sizes
  Widget _buildTotalBadge({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class TabularOrderRow extends StatefulWidget {
  final app_order.Order order;
  final int orderNumber;
  final int totalItems;
  final double totalAmount;
  final VoidCallback onExpanded;

  const TabularOrderRow({
    super.key,
    required this.order,
    required this.orderNumber,
    required this.totalItems,
    required this.totalAmount,
    required this.onExpanded,
  });

  @override
  State<TabularOrderRow> createState() => _TabularOrderRowState();
}

class _TabularOrderRowState extends State<TabularOrderRow> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      widget.onExpanded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceXL, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${widget.orderNumber}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800]),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${widget.totalItems}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800]),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.currency_rupee,
                          size: 14, color: AppColors.primaryDark),
                      Text(
                        widget.totalAmount.toStringAsFixed(0),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800]),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _toggleExpanded,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isExpanded
                            ? AppColors.buttonBackground
                            : AppColors.buttonBackground,
                        foregroundColor: AppColors.buttonText,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: const Size(70, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSmall),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isExpanded ? 'HIDE' : 'SHOW',
                        style: const TextStyle(
                            fontSize: AppSizes.fontS,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isExpanded)
            Container(
              width: double.infinity,
              color: Colors.grey[50],
              padding: const EdgeInsets.all(AppSizes.spaceXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ID: #${widget.order.id.substring(0, 8)}',
                    style: TextStyle(
                        fontSize: AppSizes.fontS,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: AppSizes.spaceL),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSizes.spaceS),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text('Item',
                              style: TextStyle(
                                  fontSize: AppSizes.fontS,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700])),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text('Qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: AppSizes.fontS,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700])),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Amount',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: AppSizes.fontS,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700])),
                        ),
                      ],
                    ),
                  ),
                  ...widget.order.items
                      .map((item) => _ItemDetailRow(item: item)),
                  SizedBox(height: AppSizes.spaceM),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.spaceM),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.currency_rupee,
                                size: AppSizes.fontL,
                                color: AppColors.primaryDark),
                            Text(
                              widget.totalAmount.toStringAsFixed(0),
                              style: const TextStyle(
                                  fontSize: AppSizes.fontXL,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemDetailRow extends StatelessWidget {
  final dynamic item;

  const _ItemDetailRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  item.name,
                  style: const TextStyle(
                      fontSize: AppSizes.fontM,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${item.price.toStringAsFixed(0)}×${item.quantity}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: AppSizes.fontM,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600]),
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.currency_rupee,
                        size: 14, color: AppColors.primaryDark),
                    Text(
                      (item.price * item.quantity).toStringAsFixed(0),
                      style: const TextStyle(
                          fontSize: AppSizes.fontM,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.notes != null &&
              item.notes.isNotEmpty &&
              item.notes.trim().isNotEmpty) ...[
            SizedBox(height: AppSizes.radiusSmall),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bgYellowLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.edit_note,
                      size: 14, color: AppColors.textOrange),
                  SizedBox(width: AppSizes.radiusSmall),
                  Expanded(
                    child: Text(
                      'Note: ${item.notes}',
                      style: const TextStyle(
                          fontSize: AppSizes.fontS,
                          color: AppColors.textBrown,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
