class OrderItem {
  final int code;
  final String name;
  int quantity;
  final double price;
  final String notes;
  final String category; // ✅ Added

  OrderItem({
    required this.code,
    required this.name,
    required this.quantity,
    required this.price,
    this.notes = '',
    this.category = '', // ✅ default empty if not given
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'qty': quantity,
      'price': price,
      'notes': notes,
      'category': category,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      code: map['code'] ?? 0,
      name: map['name'] ?? '',
      quantity: map['qty'] ?? 0,
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
}
