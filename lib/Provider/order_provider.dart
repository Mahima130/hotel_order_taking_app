import 'package:flutter/material.dart';
import 'package:hotel_order_taking_app/Model/menu_item.dart';
import 'package:hotel_order_taking_app/Model/order_item.dart';
import 'package:hotel_order_taking_app/Utils/Constants.dart';

class OrderProvider with ChangeNotifier {
  int? _tableNo;
  String? _tableType;
  String? _location;
  String? _phoneNo;
  String _orderType = AppStrings.regular; // ← ADD THIS
  final List<OrderItem> _orderItems = [];

  bool _isAddingToExistingOrder = false;
  String? _existingOrderId;

  // Getters
  int? get tableNo => _tableNo;
  String? get tableType => _tableType;
  String? get location => _location;
  String? get phoneNo => _phoneNo;
  String get orderType => _orderType; // ← ADD THIS
  List<OrderItem> get orderItems => _orderItems;
  int get itemCount => _orderItems.length;
  bool get isAddingToExistingOrder => _isAddingToExistingOrder;
  String? get existingOrderId => _existingOrderId;

  double get totalAmount {
    return _orderItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  void setTableInfo(int tableNo, String tableType) {
    _tableNo = tableNo;
    _tableType = tableType;
    notifyListeners();
  }

  void setLocation(String location) {
    _location = location;
    notifyListeners();
  }

  void setPhoneNo(String phoneNo) {
    _phoneNo = phoneNo;
    notifyListeners();
  }

  // ← ADD THIS METHOD
  void setOrderType(String orderType) {
    _orderType = orderType;
    notifyListeners();
  }

  void setExistingOrderContext(
      int tableNo, String tableType, String phoneNo, String orderId,
      {String? location, String? orderType}) {
    // ← ADD orderType parameter
    _tableNo = tableNo;
    _tableType = tableType;
    _location = location;
    _phoneNo = phoneNo;
    _orderType = orderType ?? AppStrings.regular; // ← ADD THIS
    _existingOrderId = orderId;
    _isAddingToExistingOrder = true;
    notifyListeners();
  }

  void clearExistingOrderContext() {
    _isAddingToExistingOrder = false;
    _existingOrderId = null;
    notifyListeners();
  }

  // Get quantity of a specific item by code (without notes consideration)
  int getItemQuantity(int itemCode) {
    int total = 0;
    for (var orderItem in _orderItems) {
      if (orderItem.code == itemCode) {
        total += orderItem.quantity;
      }
    }
    return total;
  }

  // ✅ CRITICAL FIX: Add item with proper notes handling
  void addItem(MenuItem menuItem, {String notes = ''}) {
    final trimmedNotes = notes.trim();

    print('🔍 Adding item: ${menuItem.name}, Notes: "$trimmedNotes"');

    // ✅ Find existing item with BOTH same code AND same notes
    final existingIndex = _orderItems.indexWhere(
      (item) => item.code == menuItem.code && item.notes == trimmedNotes,
    );

    if (existingIndex != -1) {
      // Item with same code AND notes exists - just increment quantity
      print('✅ Item exists, incrementing quantity');
      _orderItems[existingIndex].quantity++;
    } else {
      // Different notes = different item (even if same code)
      print('✅ Adding as new item');
      _orderItems.add(OrderItem(
        code: menuItem.code,
        name: menuItem.name,
        quantity: 1,
        price: menuItem.price,
        notes: trimmedNotes,
        category: menuItem.category ?? '',
      ));
    }

    notifyListeners();
    print('📦 Cart now has ${_orderItems.length} items');
    print(
        '🛒 Items: ${_orderItems.map((e) => '${e.name}(${e.quantity}) notes:"${e.notes}"').join(", ")}');
  }

  // ✅ Update item notes
  void updateItemNotes(int index, String notes) {
    if (index >= 0 && index < _orderItems.length) {
      _orderItems[index].notes = notes.trim();
      notifyListeners();
      print('📝 Updated notes for ${_orderItems[index].name}');
    }
  }

  // Increase quantity by item code (finds first match without notes)
  void increaseQuantity(String itemCode) {
    final intCode = int.tryParse(itemCode);
    if (intCode == null) return;

    // Find first item with this code
    final index = _orderItems.indexWhere((item) => item.code == intCode);

    if (index != -1) {
      _orderItems[index].quantity++;
      notifyListeners();
    }
  }

  // Decrease quantity by item code
  void decreaseQuantity(String itemCode) {
    final intCode = int.tryParse(itemCode);
    if (intCode == null) return;

    final index = _orderItems.indexWhere((item) => item.code == intCode);

    if (index != -1) {
      if (_orderItems[index].quantity > 1) {
        _orderItems[index].quantity--;
      } else {
        _orderItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Update quantity by index
  void updateQuantity(int index, int newQuantity) {
    if (index >= 0 && index < _orderItems.length) {
      if (newQuantity > 0) {
        _orderItems[index].quantity = newQuantity;
      } else {
        _orderItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Increment quantity by index
  void incrementQuantity(int index) {
    if (index >= 0 && index < _orderItems.length) {
      _orderItems[index].quantity++;
      notifyListeners();
    }
  }

  // Decrement quantity by index
  void decrementQuantity(int index) {
    if (index >= 0 && index < _orderItems.length) {
      if (_orderItems[index].quantity > 1) {
        _orderItems[index].quantity--;
      } else {
        _orderItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Remove item by index
  void removeItem(int index) {
    if (index >= 0 && index < _orderItems.length) {
      final removed = _orderItems.removeAt(index);
      print('🗑️ Removed: ${removed.name}');
      notifyListeners();
    }
  }

  // Clear cart
  void clearCart() {
    _orderItems.clear();
    notifyListeners();
    print('🧹 Cart cleared');
  }

  // Reset everything
  void reset() {
    _tableNo = null;
    _tableType = null;
    _location = null;
    _phoneNo = null;
    _orderType = AppStrings.regular; // ← RESET TO REGULAR
    _orderItems.clear();
    _isAddingToExistingOrder = false;
    _existingOrderId = null;
    notifyListeners();
    print('🔄 OrderProvider reset');
  }
}
