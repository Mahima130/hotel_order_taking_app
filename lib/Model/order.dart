import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_order_taking_app/Model/order_item.dart';

class Order {
  final String id;
  final int tableNo; // ✅ keep as int
  final String tableType;
  final String phoneNo;
  final DateTime time;
  final double totalPrice;
  final String status;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.tableNo,
    required this.tableType,
    required this.phoneNo,
    required this.time,
    required this.totalPrice,
    required this.items,
    this.status = 'active',
  });

  /// ✅ From Firestore document
  factory Order.fromFirestore(Map<String, dynamic> data, String docId) {
    return Order(
      id: docId,
      tableNo: (data['tableNo'] is int)
          ? data['tableNo'] as int
          : int.tryParse(data['tableNo'].toString()) ??
              0, // ensures int even if stored as string
      tableType: data['tableType'] ?? '',
      phoneNo: data['phoneNo'] ?? '',
      time: (data['time'] as Timestamp).toDate(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: data['status'] ?? 'active',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
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
    );
  }

  /// ✅ Calculate total
  double calculateTotal() {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get itemCount => items.length;

  @override
  String toString() {
    return 'Order(id: $id, tableNo: $tableNo, tableType: $tableType, phoneNo: $phoneNo, status: $status, totalPrice: $totalPrice, items: ${items.length})';
  }
}
