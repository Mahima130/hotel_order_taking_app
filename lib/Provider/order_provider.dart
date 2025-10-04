// lib/providers/order_provider.dart
import 'package:flutter/material.dart';
import 'package:hotel_order_taking_app/Model/menu_item.dart';
import 'package:hotel_order_taking_app/Model/order_item.dart';

class OrderProvider with ChangeNotifier {
  int? _tableNo;
  String? _tableType;
  String? _phoneNo;
  final List<OrderItem> _orderItems = [];

  // For adding to existing orders
  bool _isAddingToExistingOrder = false;
  String? _existingOrderId;

  // Getters
  int? get tableNo => _tableNo;
  String? get tableType => _tableType;
  String? get phoneNo => _phoneNo;
  List<OrderItem> get orderItems => _orderItems;
  int get itemCount => _orderItems.length;
  bool get isAddingToExistingOrder => _isAddingToExistingOrder;
  String? get existingOrderId => _existingOrderId;

  double get totalAmount {
    return _orderItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // Setters
  void setTableInfo(int tableNo, String tableType) {
    _tableNo = tableNo;
    _tableType = tableType;
    notifyListeners();
  }

  void setPhoneNo(String phoneNo) {
    _phoneNo = phoneNo;
    notifyListeners();
  }

  // Set up for adding to existing order
  void setExistingOrderContext(
      int tableNo, String tableType, String phoneNo, String orderId) {
    _tableNo = tableNo;
    _tableType = tableType;
    _phoneNo = phoneNo;
    _existingOrderId = orderId;
    _isAddingToExistingOrder = true;
    notifyListeners();
  }

  // Clear existing order context
  void clearExistingOrderContext() {
    _isAddingToExistingOrder = false;
    _existingOrderId = null;
    notifyListeners();
  }

  // Get quantity of a specific item by ID/code
  int getItemQuantity(int itemCode) {
    for (var orderItem in _orderItems) {
      if (orderItem.code == itemCode) {
        return orderItem.quantity;
      }
    }
    return 0;
  }

  // Add item to cart
  void addItem(MenuItem menuItem, {String notes = ''}) {
    final existingIndex = _orderItems.indexWhere(
      (item) => item.code == menuItem.code,
    );

    if (existingIndex != -1) {
      _orderItems[existingIndex].quantity++;
    } else {
      _orderItems.add(OrderItem(
        code: menuItem.code,
        name: menuItem.name,
        quantity: 1,
        price: menuItem.price,
        notes: notes,
      ));
    }
    notifyListeners();
  }

  // Increase quantity by item code
  void increaseQuantity(String itemCode) {
    final intCode = int.tryParse(itemCode);
    if (intCode == null) return;

    for (int i = 0; i < _orderItems.length; i++) {
      if (_orderItems[i].code == intCode) {
        _orderItems[i].quantity++;
        notifyListeners();
        break;
      }
    }
  }

  // Decrease quantity by item code
  void decreaseQuantity(String itemCode) {
    final intCode = int.tryParse(itemCode);
    if (intCode == null) return;

    for (int i = 0; i < _orderItems.length; i++) {
      if (_orderItems[i].code == intCode) {
        if (_orderItems[i].quantity > 1) {
          _orderItems[i].quantity--;
        } else {
          _orderItems.removeAt(i);
        }
        notifyListeners();
        break;
      }
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
      _orderItems.removeAt(index);
      notifyListeners();
    }
  }

  // Clear cart (after order confirmation)
  void clearCart() {
    _orderItems.clear();
    notifyListeners();
  }

  // Reset everything
  void reset() {
    _tableNo = null;
    _tableType = null;
    _phoneNo = null;
    _orderItems.clear();
    _isAddingToExistingOrder = false;
    _existingOrderId = null;
    notifyListeners();
  }
}
