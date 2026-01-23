class OrderItem {
  final int code;
  final String name;
  int quantity;
  final double price;
  String notes; // ✅ Changed from 'final' to mutable
  final String category;

  OrderItem({
    required this.code,
    required this.name,
    required this.quantity,
    required this.price,
    this.notes = '',
    this.category = '',
  });

  double get totalPrice => price * quantity;

  // ✅ FIXED: Use 'itemName' to match Firebase structure
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'itemName': name, // ✅ Changed from 'name' to 'itemName'
      'quantity': quantity, // ✅ Changed from 'qty' to 'quantity'
      'amount': totalPrice, // ✅ Changed from 'price' to 'amount'
      'price': price, // ✅ Keep individual price too
      'notes': notes,
      'category': category,
      'status': 'pending', // ✅ Added status field
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      code: map['code'] ?? 0,
      name: map['itemName'] ?? map['name'] ?? '', // ✅ Handle both field names
      quantity: map['quantity'] ?? map['qty'] ?? 0, // ✅ Handle both
      price: (map['price'] ?? 0).toDouble(),
      notes: map['notes'] ?? '',
      category: map['category'] ?? '',
    );
  }

  OrderItem copyWith({
    int? code,
    String? name,
    int? quantity,
    double? price,
    String? notes,
    String? category,
  }) {
    return OrderItem(
      code: code ?? this.code,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      category: category ?? this.category,
    );
  }

  @override
  String toString() {
    return 'OrderItem(code: $code, name: $name, qty: $quantity, price: $price, notes: "$notes")';
  }
}
