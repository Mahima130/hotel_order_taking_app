import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:hotel_order_taking_app/Utils/Constants.dart';
import 'package:hotel_order_taking_app/Widget/Common/loading_indicator.dart';
import 'package:hotel_order_taking_app/Widget/Common/empty_state.dart';
import 'package:hotel_order_taking_app/Widget/Common/background_container.dart'; // ← ADD THIS

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return time;

      int hour = int.parse(parts[0]);
      final minute = parts[1];

      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;

      return '$hour:$minute $period';
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateString = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.transparent, // ← CHANGED
      appBar: AppBar(
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'ORDER STATUS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
        backgroundColor: AppColors.drawerBackground,
        foregroundColor: AppColors.primaryGold,
        elevation: 2,
      ),
      body: BackgroundContainer(
        // ← WRAP BODY
        child: Column(
          children: [
            // Date Header (Static - No Calendar)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.spaceL),
              color: AppColors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, dd-MM-yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: AppSizes.fontL,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.spaceS),

            // Table Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.drawerBackground,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Row(
                children: const [
                  SizedBox(width: 30),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Tables',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'First Order ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'No.\nOrders',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Bill Settled At  ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Orders List from Firebase
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('order_status')
                    .where('orderDate', isEqualTo: selectedDateString)
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingIndicator();
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return EmptyState(
                      icon: Icons.receipt_long,
                      message:
                          'No orders found for ${DateFormat('dd-MM-yyyy').format(_selectedDate)}',
                    );
                  }

                  final uniqueOrders =
                      _removeDuplicateOrders(snapshot.data!.docs);

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: uniqueOrders.length,
                    itemBuilder: (context, index) {
                      final doc = uniqueOrders[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return OrderStatusCard(
                        key: ValueKey(doc.id),
                        docId: doc.id,
                        data: data,
                        formatTime: _formatTime,
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

  List<QueryDocumentSnapshot<Object?>> _removeDuplicateOrders(
      List<QueryDocumentSnapshot<Object?>> docs) {
    final Map<String, QueryDocumentSnapshot<Object?>> uniqueOrders = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final tableNumber = data['tableNumber']?.toString() ?? 'unknown';

      // Keep only the latest order for each table
      if (!uniqueOrders.containsKey(tableNumber)) {
        uniqueOrders[tableNumber] = doc;
      }
    }

    return uniqueOrders.values.toList();
  }
}

class OrderStatusCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String Function(String) formatTime;

  const OrderStatusCard({
    super.key,
    required this.docId,
    required this.data,
    required this.formatTime,
  });

  @override
  State<OrderStatusCard> createState() => _OrderStatusCardState();
}

class _OrderStatusCardState extends State<OrderStatusCard> {
  bool _isExpanded = false;
  final Map<String, bool> _expandedSubOrders = {};

  @override
  Widget build(BuildContext context) {
    final tableNumber = widget.data['tableNumber'] ?? 'N/A';
    final firstOrderTime = widget.data['firstOrderTime'] ?? 'N/A';
    final numberOfOrders = widget.data['numberOfOrders'] ?? 0;
    final billSettlementTime = widget.data['billSettlementTime'] ?? 'N/A';
    final totalAmount = (widget.data['totalAmount'] ?? 0).toDouble();
    final status = widget.data['status'] ?? 'settled';
    final isCancelled = status == 'cancelled';
    final items = List<Map<String, dynamic>>.from(widget.data['items'] ?? []);

    final groupedOrders = _groupItemsByOrderNumber(items);

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isCancelled ? Colors.red[50] : AppColors.white, // Exact red
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(
          color: isCancelled ? Colors.red : Colors.grey.shade300, // Exact red
          width: isCancelled ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    _isExpanded
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    color: isCancelled
                        ? Colors.red
                        : AppColors.buttonBackground, // Exact red
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      tableNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isCancelled
                            ? Colors.red
                            : AppColors.primaryDark, // Exact red
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      widget.formatTime(firstOrderTime),
                      style: TextStyle(
                        color: isCancelled
                            ? Colors.red
                            : Colors.grey.shade700, // Exact red
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      numberOfOrders.toString(),
                      style: TextStyle(
                        color: isCancelled
                            ? Colors.red
                            : Colors.grey.shade700, // Exact red
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      widget.formatTime(billSettlementTime),
                      style: TextStyle(
                        color: isCancelled
                            ? Colors.red
                            : Colors.grey.shade700, // Exact red
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${totalAmount.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCancelled
                            ? Colors.red
                            : AppColors.primaryDark, // Exact red
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) _buildExpandedContent(groupedOrders, isCancelled),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(
      Map<String, List<Map<String, dynamic>>> groupedOrders, bool isCancelled) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCancelled ? Colors.red[50] : Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppSizes.radiusSmall),
          bottomRight: Radius.circular(AppSizes.radiusSmall),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCancelled) _buildCancelledBanner(),
          ..._buildUnifiedOrderList(groupedOrders), // ← Changed method
        ],
      ),
    );
  }

  Widget _buildCancelledBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red, // Exact red
        borderRadius: BorderRadius.circular(AppSizes.spaceXS),
      ),
      child: const Text(
        '⚠️ ENTIRE ORDER CANCELLED',
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.drawerBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        children: const [
          Expanded(
            flex: 2,
            child: Text(
              'Order No.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'No. Items',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Amount',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Action',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUnifiedOrderList(
      Map<String, List<Map<String, dynamic>>> groupedOrders) {
    return groupedOrders.entries.map((entry) {
      final orderNumber = entry.key;
      final orderItems = entry.value;
      final subOrderKey = '${widget.docId}_order_$orderNumber';
      final isSubOrderExpanded = _expandedSubOrders[subOrderKey] ?? false;

      final orderAmount = orderItems.fold<double>(
        0,
        (sum, item) => sum + (item['amount'] as num).toDouble(),
      );

      final hasAnyCancelled = orderItems.any(
        (item) => item['status'] == 'cancelled',
      );

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: hasAnyCancelled ? Colors.red[50] : AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          border: Border.all(
            color: hasAnyCancelled ? Colors.red : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            // Order header row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      orderNumber,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasAnyCancelled
                            ? Colors.red
                            : AppColors.primaryDark,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      orderItems.length.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            hasAnyCancelled ? Colors.red : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${orderAmount.toStringAsFixed(0)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: hasAnyCancelled
                            ? Colors.red
                            : AppColors.primaryDark,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _expandedSubOrders[subOrderKey] =
                                !isSubOrderExpanded;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBackground,
                          foregroundColor: AppColors.buttonText,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSmall),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isSubOrderExpanded ? 'Hide' : 'Show',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Items list (expanded inline, no separate border)
            if (isSubOrderExpanded)
              Column(
                children: [
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Items header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppColors.drawerBackground,
                            borderRadius:
                                BorderRadius.circular(AppSizes.spaceXS),
                          ),
                          child: Row(
                            children: const [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Item',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Quantity',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Amount',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Status',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Items rows
                        ...orderItems.map((item) {
                          final itemStatus = item['status'] ?? 'delivered';
                          final isItemCancelled = itemStatus == 'cancelled';
                          final quantity = item['quantity'] ?? 0;
                          final amount = (item['amount'] ?? 0).toDouble();
                          final price = quantity > 0 ? amount / quantity : 0;

                          return Container(
                            margin: EdgeInsets.zero,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            decoration: BoxDecoration(
                              color: isItemCancelled
                                  ? Colors.red[100]
                                  : AppColors.white,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.spaceXS),
                              border: Border.all(
                                color: isItemCancelled
                                    ? Colors.red
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    item['itemName'] ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isItemCancelled
                                          ? Colors.red
                                          : AppColors.primaryDark,
                                      decoration: isItemCancelled
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${price.toStringAsFixed(0)}×$quantity',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isItemCancelled
                                          ? Colors.red
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '₹${amount.toStringAsFixed(0)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isItemCancelled
                                          ? Colors.red
                                          : AppColors.primaryDark,
                                      decoration: isItemCancelled
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isItemCancelled
                                            ? Colors.red
                                            : AppColors.success,
                                        borderRadius: BorderRadius.circular(
                                            AppSizes.spaceXS),
                                      ),
                                      child: Text(
                                        itemStatus.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildOrderItemsDetail(
      List<Map<String, dynamic>> orderItems, bool hasAnyCancelled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasAnyCancelled
            ? Colors.red[100]
            : Colors.grey.shade100, // Exact red
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(
          color:
              hasAnyCancelled ? Colors.red : Colors.grey.shade300, // Exact red
        ),
      ),
      child: Column(
        children: [
          _buildItemsHeader(),
          const SizedBox(height: AppSizes.radiusSmall),
          ..._buildItemsList(orderItems),
        ],
      ),
    );
  }

  Widget _buildItemsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.drawerBackground,
        borderRadius: BorderRadius.circular(AppSizes.spaceXS),
      ),
      child: Row(
        children: const [
          Expanded(
            flex: 3,
            child: Text(
              'Item',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Amount',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildItemsList(List<Map<String, dynamic>> orderItems) {
    return orderItems.map((item) {
      final itemStatus = item['status'] ?? 'delivered';
      final isItemCancelled = itemStatus == 'cancelled';
      final quantity = item['quantity'] ?? 0;
      final amount = (item['amount'] ?? 0).toDouble();
      final price = quantity > 0 ? amount / quantity : 0;

      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color:
              isItemCancelled ? Colors.red[100] : AppColors.white, // Exact red
          borderRadius: BorderRadius.circular(AppSizes.spaceXS),
          border: Border.all(
            color: isItemCancelled
                ? Colors.red
                : Colors.grey.shade200, // Exact red
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                item['itemName'] ?? 'N/A',
                style: TextStyle(
                  fontSize: 12,
                  color: isItemCancelled
                      ? Colors.red
                      : AppColors.primaryDark, // Exact red
                  decoration:
                      isItemCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${price.toStringAsFixed(0)}×$quantity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isItemCancelled
                      ? Colors.red
                      : Colors.grey.shade600, // Exact red
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '₹${amount.toStringAsFixed(0)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isItemCancelled
                      ? Colors.red
                      : AppColors.primaryDark, // Exact red
                  decoration:
                      isItemCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isItemCancelled
                        ? Colors.red
                        : AppColors.success, // Exact red
                    borderRadius: BorderRadius.circular(AppSizes.spaceXS),
                  ),
                  child: Text(
                    itemStatus.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> _groupItemsByOrderNumber(
      List<Map<String, dynamic>> items) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in items) {
      final orderNumber = item['orderNumber']?.toString() ?? '1';
      if (!grouped.containsKey(orderNumber)) {
        grouped[orderNumber] = [];
      }
      grouped[orderNumber]!.add(item);
    }

    return grouped;
  }
}
