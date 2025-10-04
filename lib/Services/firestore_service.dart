import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_order_taking_app/Model/order.dart' as app_order;
import 'package:hotel_order_taking_app/Model/menu_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ------------------ MENU ------------------

  // Get all menu items
  Stream<List<MenuItem>> getMenuItems() {
    return _db.collection('MenuItem').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MenuItem.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Search menu items with better debugging
  Future<List<MenuItem>> searchMenuItems(String query) async {
    try {
      print('=== SEARCH DEBUG START ===');
      print('Query: "$query"');
      print('Fetching from collection: MenuItem');

      final snapshot = await _db.collection('MenuItem').get();

      print('Total documents in collection: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        print('WARNING: MenuItem collection is empty!');
        return [];
      }

      // Debug: Show first document
      if (snapshot.docs.isNotEmpty) {
        print('Sample document:');
        print('  ID: ${snapshot.docs.first.id}');
        print('  Data: ${snapshot.docs.first.data()}');
      }

      // Parse all documents
      final allItems = <MenuItem>[];
      for (var doc in snapshot.docs) {
        try {
          final item = MenuItem.fromFirestore(doc.data(), doc.id);
          allItems.add(item);
        } catch (e) {
          print('ERROR parsing document ${doc.id}: $e');
          print('  Data: ${doc.data()}');
        }
      }

      print('Successfully parsed ${allItems.length} items');

      // Filter based on query
      final results = allItems.where((item) {
        final lowerQuery = query.toLowerCase();
        final matchesCode = item.code.toString().contains(query);
        final matchesName = item.name.toLowerCase().contains(lowerQuery);
        return matchesCode || matchesName;
      }).toList();

      print('Filtered results: ${results.length} items match "$query"');
      print('=== SEARCH DEBUG END ===');

      return results;
    } catch (e, stackTrace) {
      print('CRITICAL ERROR in searchMenuItems:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Test connection to MenuItem collection
  Future<void> testMenuItemConnection() async {
    try {
      print('\n=== TESTING MENUITEM CONNECTION ===');
      final snapshot = await _db.collection('MenuItem').limit(5).get();
      print('Connection successful!');
      print('Documents found: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        print('\nDocument ID: ${doc.id}');
        print('Data: ${doc.data()}');
      }
      print('=== TEST COMPLETE ===\n');
    } catch (e) {
      print('TEST FAILED: $e');
    }
  }

  /// ------------------ TABLES ------------------

  // Fetch table types for a specific table number
  Future<List<String>> getTableTypes(int tableNo) async {
    try {
      final querySnapshot = await _db
          .collection('TableModel')
          .where('tableNo', isEqualTo: tableNo)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('Table $tableNo not found in Firestore');
        return [];
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();

      if (!data.containsKey('type')) {
        print('No type field found for table $tableNo');
        return [];
      }

      final dynamic typeField = data['type'];
      if (typeField is List) {
        return typeField.map((e) => e.toString()).toList();
      } else if (typeField is String) {
        return [typeField];
      } else {
        print('Unexpected type field format: ${typeField.runtimeType}');
        return [];
      }
    } catch (e) {
      print('Error fetching table types: $e');
      rethrow;
    }
  }

  // Get all table numbers for a specific table category
  Future<List<int>> getTablesByType(String tableType) async {
    try {
      final snapshot = await _db.collection('TableModel').get();

      final tableNumbers = <int>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final tableNo = data['tableNo'] as int?;

        if (tableNo == null) continue;

        final dynamic typeField = data['type'];
        bool hasType = false;

        if (typeField is List) {
          hasType = typeField.any((t) => t.toString() == tableType);
        } else if (typeField is String) {
          hasType = typeField == tableType;
        }

        if (hasType) {
          tableNumbers.add(tableNo);
        }
      }

      tableNumbers.sort();
      return tableNumbers;
    } catch (e) {
      print('Error fetching tables by type: $e');
      return [];
    }
  }

  // FIXED: Get occupied table numbers for a specific type
  Future<List<int>> getOccupiedTablesByType(String tableType) async {
    try {
      print('=== DEBUG: Checking occupied tables for type: $tableType ===');

      // SIMPLIFIED QUERY: Remove complex filters to avoid index requirement
      final snapshot = await _db
          .collection('orders')
          .where('tableType', isEqualTo: tableType)
          .where('status', isNotEqualTo: 'closed')
          .get();

      final occupiedTables = <int>{};

      print('Found ${snapshot.docs.length} non-closed orders for $tableType');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final tableNo = data['tableNo'] as int?;
        final status = data['status'] as String?;

        if (tableNo != null) {
          occupiedTables.add(tableNo);
          print(' - Table $tableNo (Status: $status)');
        }
      }

      print(
          '=== DEBUG: Occupied tables for $tableType: ${occupiedTables.toList()} ===');
      return occupiedTables.toList()..sort();
    } catch (e) {
      print('Error fetching occupied tables by type: $e');
      // Fallback: Return empty list if error occurs
      return [];
    }
  }

  // NEW: Check if a specific table is occupied (real-time verification)
  Future<bool> isTableOccupied(int tableNo, String tableType) async {
    try {
      // SIMPLIFIED QUERY: Remove time filter to avoid index requirement
      final snapshot = await _db
          .collection('orders')
          .where('tableNo', isEqualTo: tableNo)
          .where('tableType', isEqualTo: tableType)
          .where('status', isNotEqualTo: 'closed')
          .limit(1)
          .get();

      final isOccupied = snapshot.docs.isNotEmpty;
      print('Table $tableNo ($tableType) occupation check: $isOccupied');
      return isOccupied;
    } catch (e) {
      print('Error checking table occupation: $e');
      return false;
    }
  }

  // Get all tables
  Future<List<Map<String, dynamic>>> getAllTables() async {
    try {
      final snapshot = await _db.collection('TableModel').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'tableNo': data['tableNo'],
          'types': data['type'] is List
              ? (data['type'] as List).map((e) => e.toString()).toList()
              : [data['type'].toString()],
        };
      }).toList();
    } catch (e) {
      print('Error fetching all tables: $e');
      rethrow;
    }
  }

  /// ------------------ ORDERS ------------------

  // Add a new order to Firestore
  Future<String> addOrder(app_order.Order order) async {
    try {
      final docRef = await _db.collection('orders').add(order.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding order: $e');
      rethrow;
    }
  }

  Future<String> saveOrder(app_order.Order order) async {
    return addOrder(order);
  }

  // Get order by ID
  Future<app_order.Order?> getOrderById(String orderId) async {
    try {
      final doc = await _db.collection('orders').doc(orderId).get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      return app_order.Order.fromFirestore(data, doc.id);
    } catch (e) {
      print('Error fetching order: $e');
      rethrow;
    }
  }

  // Delete an order
  Future<void> deleteOrder(String orderId) async {
    try {
      await _db.collection('orders').doc(orderId).delete();
    } catch (e) {
      print('Error deleting order: $e');
      rethrow;
    }
  }

  // Add items to existing order
  Future<void> addItemsToExistingOrder(String orderId,
      List<Map<String, dynamic>> newItems, double additionalAmount) async {
    try {
      final orderRef = _db.collection('orders').doc(orderId);
      final orderDoc = await orderRef.get();

      if (!orderDoc.exists) throw Exception('Order not found');

      final orderData = orderDoc.data();
      if (orderData == null) throw Exception('Order data is null');

      final existingItems = (orderData['items'] as List<dynamic>?) ?? [];
      final updatedItems = [...existingItems, ...newItems];

      final currentTotal = (orderData['totalPrice'] ?? 0).toDouble();
      final newTotal = currentTotal + additionalAmount;

      await orderRef.update({
        'items': updatedItems,
        'totalPrice': newTotal,
      });
    } catch (e) {
      print('Error adding items to existing order: $e');
      rethrow;
    }
  }

  // Get orders for a specific table and phone
  Stream<List<app_order.Order>> getOrdersByTableAndPhone(
      int tableNo, String phoneNo) {
    return _db
        .collection('orders')
        .where('tableNo', isEqualTo: tableNo)
        .where('phoneNo', isEqualTo: phoneNo)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => app_order.Order.fromFirestore(doc.data(), doc.id))
          .where((order) => order.status != 'closed')
          .toList();

      // Sort locally instead of in Firestore query
      orders.sort((a, b) => b.time.compareTo(a.time));
      return orders;
    });
  }

  // Get menu categories
  Future<List<String>> getMenuCategories() async {
    try {
      final snapshot = await _db.collection('MenuItem').get();
      final categories = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<MenuItem>> getMenuItemsByCategory(String category) async {
    try {
      final snapshot = await _db
          .collection('MenuItem')
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs
          .map((doc) => MenuItem.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching items by category: $e');
      return [];
    }
  }

  // FIXED: Get all running/active orders
  Stream<List<app_order.Order>> getRunningOrders() {
    try {
      // SIMPLIFIED QUERY: Remove complex ordering to avoid index requirement
      return _db
          .collection('orders')
          .where('status', isNotEqualTo: 'closed')
          .snapshots()
          .map((snapshot) {
        final orders = snapshot.docs
            .map((doc) => app_order.Order.fromFirestore(doc.data(), doc.id))
            .toList();

        // Sort locally instead of in Firestore query
        orders.sort((a, b) => b.time.compareTo(a.time));

        return orders;
      });
    } catch (e) {
      print('Error in getRunningOrders: $e');
      // Return empty stream if error occurs
      return Stream.value([]);
    }
  }
}
