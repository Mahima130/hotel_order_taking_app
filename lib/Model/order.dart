import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_order_taking_app/Model/order_item.dart';

class Order {
  final String id;
  final int tableNo;
  final String tableType;
  final String phoneNo;
  final DateTime time;
  final double totalPrice;
  final String status;
  final List<OrderItem> items;
  final String? orderType;
  final String? location;
  final int? orderCount; // ✅ NEW - For displaying order count per table

  Order({
    required this.id,
    required this.tableNo,
    required this.tableType,
    required this.phoneNo,
    required this.time,
    required this.totalPrice,
    required this.items,
    this.status = 'active',
    this.orderType,
    this.location,
    //this.orderCount,
    this.orderCount = 1, // ✅ NEW
  });

  /// ✅ From Firestore document
  factory Order.fromFirestore(Map<String, dynamic> data, String docId) {
    return Order(
      id: docId,
      tableNo: (data['tableNo'] is int)
          ? data['tableNo'] as int
          : int.tryParse(data['tableNo'].toString()) ?? 0,
      tableType: data['tableType'] ?? '',
      phoneNo: data['phoneNo'] ?? '',
      time: (data['time'] as Timestamp).toDate(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: data['status'] ?? 'active',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      orderType: data['orderType'] ?? 'Regular',
      location: data['location'],
      orderCount: (data['orderCount'] ?? 1) as int,
    );
  }

  /// ✅ To Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'tableNo': tableNo,
      'tableType': tableType,
      'phoneNo': phoneNo,
      'time': Timestamp.fromDate(time),
      'totalPrice': totalPrice,
      'status': status,
      'items': items.map((item) => item.toMap()).toList(),
      'orderType': orderType,
      'location': location,
      // orderCount is not saved to Firestore
    };
  }

  /// ✅ Copy method
  Order copyWith({
    String? id,
    int? tableNo,
    String? tableType,
    String? phoneNo,
    DateTime? time,
    double? totalPrice,
    String? status,
    List<OrderItem>? items,
    String? orderType,
    String? location,
    int? orderCount, // ✅ NEW
  }) {
    return Order(
      id: id ?? this.id,
      tableNo: tableNo ?? this.tableNo,
      tableType: tableType ?? this.tableType,
      phoneNo: phoneNo ?? this.phoneNo,
      time: time ?? this.time,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      items: items ?? this.items,
      orderType: orderType ?? this.orderType,
      location: location ?? this.location,
      orderCount: orderCount ?? this.orderCount, // ✅ NEW
    );
  }

  /// ✅ Calculate total
  double calculateTotal() {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// ✅ Get number of unique items
  int get itemCount => items.length;

  /// ✅ Get total quantity of all items (sum of quantities)
  int get totalQuantity {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  String toString() {
    return 'Order(id: $id, tableNo: $tableNo, tableType: $tableType, phoneNo: $phoneNo, status: $status, totalPrice: $totalPrice, items: ${items.length}, orderType: $orderType, location: $location, orderCount: $orderCount)';
  }
}
