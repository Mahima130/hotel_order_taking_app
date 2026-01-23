import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_order_taking_app/Model/order.dart' as app_order;
import 'package:hotel_order_taking_app/Model/menu_item.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ CACHE OCCUPIED TABLES IN MEMORY FOR 60 SECONDS
  static final Map<String, _CachedData<List<int>>> _occupiedTablesCache = {};
  static final Map<String, _CachedData<List<int>>> _allTablesCache = {};

  /// ✅ SUPER FAST: Get occupied table numbers by LOCATION (not tableType!)
  /// ✅ SUPER FAST: Get occupied table numbers by LOCATION AND TABLE TYPE
  Future<List<int>> getOccupiedTablesByType(
      String location, String tableType) async {
    try {
      print(
          '🔄 Checking occupied tables for location: $location, type: $tableType');

      // ✅ CHECK CACHE FIRST (60 second TTL for better performance)
      final cacheKey = 'occupied_${location}_$tableType';
      if (_occupiedTablesCache.containsKey(cacheKey)) {
        final cached = _occupiedTablesCache[cacheKey]!;
        if (!cached.isExpired(const Duration(seconds: 60))) {
          print(
              '⚡ CACHE HIT! Using cached data (${cached.data.length} tables)');
          return cached.data;
        } else {
          _occupiedTablesCache.remove(cacheKey);
        }
      }

      final stopwatch = Stopwatch()..start();

      // ✅ CORRECT QUERY: Query by BOTH location AND tableType!
      final snapshot = await _db
          .collection('orders')
          .where('location', isEqualTo: location)
          .where('tableType', isEqualTo: tableType) // ✅ ADD THIS LINE
          .where('status', whereIn: ['active', 'pending'])
          .limit(200)
          .get();

      stopwatch.stop();
      print('⚡ Query completed in ${stopwatch.elapsedMilliseconds}ms');

      final occupiedTables = <int>{};

      for (var doc in snapshot.docs) {
        final tableNo = doc.data()['tableNo'] as int?;
        if (tableNo != null) {
          occupiedTables.add(tableNo);
        }
      }

      final sortedTables = occupiedTables.toList()..sort();

      // ✅ CACHE THE RESULT
      _occupiedTablesCache[cacheKey] = _CachedData(sortedTables);

      print('✅ Found ${sortedTables.length} occupied tables: $sortedTables');
      return sortedTables;
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }

  /// ✅ SUPER FAST: Get all tables by LOCATION
  Future<List<int>> getTablesByType(String location) async {
    try {
      print('🔄 Fetching tables for location: $location');

      // ✅ CHECK CACHE FIRST
      final cacheKey = 'tables_$location';
      if (_allTablesCache.containsKey(cacheKey)) {
        final cached = _allTablesCache[cacheKey]!;
        if (!cached.isExpired(const Duration(minutes: 5))) {
          print(
              '⚡ CACHE HIT! Using cached tables (${cached.data.length} tables)');
          return cached.data;
        } else {
          _allTablesCache.remove(cacheKey);
        }
      }

      final stopwatch = Stopwatch()..start();

      // ✅ CORRECT QUERY: Query by LOCATION
      final snapshot = await _db
          .collection('TableModel')
          .where('location', isEqualTo: location)
          .get();

      stopwatch.stop();
      print('⚡ Query completed in ${stopwatch.elapsedMilliseconds}ms');

      if (snapshot.docs.isNotEmpty) {
        final tableNumbers = <int>[];
        for (var doc in snapshot.docs) {
          final tableNo = doc.data()['tableNo'] as int?;
          if (tableNo != null) {
            tableNumbers.add(tableNo);
          }
        }
        tableNumbers.sort();

        // ✅ CACHE THE RESULT
        _allTablesCache[cacheKey] = _CachedData(tableNumbers);

        print('✅ Found ${tableNumbers.length} tables from Firestore');
        return tableNumbers;
      }

      // ✅ FAST FALLBACK: Hardcoded defaults
      print('⚠️ No tables in Firestore, using defaults');
      final defaults = _getDefaultTables(location);

      if (defaults.isNotEmpty) {
        _allTablesCache[cacheKey] = _CachedData(defaults);
      }

      return defaults;
    } catch (e) {
      print('❌ Error: $e');
      return _getDefaultTables(location);
    }
  }

  /// ✅ INSTANT: Get default tables (no Firestore query needed)
  List<int> _getDefaultTables(String location) {
    const defaults = {
      'Rooftop': [101, 102, 103, 104, 105, 106, 107, 108, 109, 110],
      'Lounge': [201, 202, 203, 204, 205, 206, 207, 208, 209, 210],
      'VIP': [301, 302, 303, 304, 305, 306, 307, 308, 309, 310],
    };
    return defaults[location] ?? [101, 102, 103, 104, 105];
  }

  /// ✅ CLEAR CACHE (call after order created/updated)
  void clearOccupiedTablesCache() {
    _occupiedTablesCache.clear();
    print('🧹 Cleared cache');
  }

  void clearOccupiedTablesCacheForType(String location, String tableType) {
    _occupiedTablesCache.remove('occupied_${location}_$tableType');
    _allTablesCache.remove('tables_$location');
    print('🧹 Cleared cache for: $location - $tableType');
  }
  // ============ MENU ITEMS ============

  Stream<List<MenuItem>> getMenuItems() {
    return _db.collection('MenuItem').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MenuItem.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<List<MenuItem>> searchMenuItems(String query) async {
    try {
      if (query.isEmpty) return [];

      print('🔍 Global search for: "$query"');
      final stopwatch = Stopwatch()..start();

      final lowerQuery = query.toLowerCase();
      final snapshot = await _db
          .collection('MenuItem')
          .get(const GetOptions(source: Source.serverAndCache));

      stopwatch.stop();
      print('📥 Fetched all items in ${stopwatch.elapsedMilliseconds}ms');

      if (snapshot.docs.isEmpty) {
        print('⚠️ MenuItem collection is empty!');
        return [];
      }

      final allItems = <MenuItem>[];
      for (var doc in snapshot.docs) {
        try {
          final item = MenuItem.fromFirestore(doc.data(), doc.id);
          allItems.add(item);
        } catch (e) {
          print('⚠️ Error parsing item: $e');
        }
      }

      print('✅ Parsed ${allItems.length} items');

      final searchStart = Stopwatch()..start();

      final results = allItems.where((item) {
        final matchesCode = item.code.toString().contains(query);
        final matchesName = item.name.toLowerCase().contains(lowerQuery);
        return matchesCode || matchesName;
      }).toList();

      searchStart.stop();
      print(
          '✅ Found ${results.length} items matching "$query" in ${searchStart.elapsedMilliseconds}ms');

      return results;
    } catch (e, stackTrace) {
      print('❌ Error in searchMenuItems: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<String>> getMenuCategories() async {
    try {
      final snapshot = await _db
          .collection('MenuItem')
          .get(const GetOptions(source: Source.serverAndCache));

      final categories = <String>{};

      for (var doc in snapshot.docs) {
        final category = doc.data()['category'] as String?;
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
      print('📂 Fetching items for category: $category');
      final stopwatch = Stopwatch()..start();

      final snapshot = await _db
          .collection('MenuItem')
          .where('category', isEqualTo: category)
          .get(const GetOptions(source: Source.serverAndCache));

      stopwatch.stop();
      print(
          '✅ Fetched ${snapshot.docs.length} items in ${stopwatch.elapsedMilliseconds}ms');

      return snapshot.docs
          .map((doc) => MenuItem.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching items by category: $e');
      return [];
    }
  }

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

  Future<int> getOrderCountForTable(
      String location, String tableType, int tableNo) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('location', isEqualTo: location)
          .where('tableType', isEqualTo: tableType)
          .where('tableNo', isEqualTo: tableNo)
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error counting orders: $e');
      return 0;
    }
  }

  // ============ TABLE OPERATIONS ============

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

  Future<bool> isTableOccupied(
      int tableNo, String location, String tableType) async {
    try {
      // ✅ FIXED: Now passing BOTH location AND tableType
      final occupiedTables = await getOccupiedTablesByType(location, tableType);
      return occupiedTables.contains(tableNo);
    } catch (e) {
      print('Error checking table occupation: $e');
      return false;
    }
  }

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

  Stream<List<app_order.Order>> getOrdersForTable(
      int tableNo, String location) {
    try {
      print('🔍 Fetching orders for Table $tableNo in $location');

      return _db
          .collection('orders')
          .where('tableNo', isEqualTo: tableNo)
          .where('location', isEqualTo: location)
          // ✅ REMOVED 'isNotEqualTo' to avoid needing composite index
          .snapshots()
          .map((snapshot) {
        print('📦 Found ${snapshot.docs.length} orders');

        final orders = snapshot.docs
            .map((doc) {
              try {
                return app_order.Order.fromFirestore(doc.data(), doc.id);
              } catch (e) {
                print('⚠️ Error parsing order ${doc.id}: $e');
                return null;
              }
            })
            .whereType<app_order.Order>() // Filter out nulls
            .where((order) =>
                order.status != 'closed') // ✅ Filter in memory instead
            .toList();

        // Sort by time - newest first
        orders.sort((a, b) => b.time.compareTo(a.time));

        print('✅ Returning ${orders.length} valid orders');
        return orders;
      });
    } catch (e) {
      print('❌ Error in getOrdersForTable: $e');
      return Stream.value([]);
    }
  }
  // ============ ORDER OPERATIONS ============

  Future<String> addOrder(app_order.Order order) async {
    try {
      final docRef = await _db.collection('orders').add(order.toFirestore());

      // ✅ CLEAR CACHE AFTER NEW ORDER
      clearOccupiedTablesCache();

      return docRef.id;
    } catch (e) {
      print('Error adding order: $e');
      rethrow;
    }
  }

  Future<String> saveOrder(app_order.Order order) async {
    return addOrder(order);
  }

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

  Future<void> deleteOrder(String orderId) async {
    try {
      await _db.collection('orders').doc(orderId).delete();

      // ✅ CLEAR CACHE AFTER DELETE
      clearOccupiedTablesCache();
    } catch (e) {
      print('Error deleting order: $e');
      rethrow;
    }
  }

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

      orders.sort((a, b) => b.time.compareTo(a.time));
      return orders;
    });
  }

  Stream<List<app_order.Order>> getRunningOrders() {
    try {
      return _db
          .collection('orders')
          .where('status', whereIn: [
            'active',
            'pending'
          ]) // ✅ Check this matches your status
          .limit(100)
          .snapshots()
          .map((snapshot) {
            final orders = snapshot.docs
                .map((doc) {
                  try {
                    return app_order.Order.fromFirestore(doc.data(), doc.id);
                  } catch (e) {
                    print('⚠️ Error parsing order ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<app_order.Order>()
                .toList();

            // Sort by time (newest first)
            orders.sort((a, b) => b.time.compareTo(a.time));

            print('✅ Returning ${orders.length} running orders');
            return orders;
          });
    } catch (e) {
      print('❌ Error in getRunningOrders: $e');
      return Stream.value([]);
    }
  }

  /// ✅ Get ALL orders for a specific table at a specific location
  Stream<List<app_order.Order>> getOrdersForTableAtLocation(
    int tableNo,
    String location,
    String tableType,
  ) {
    try {
      print(
          '🔍 Fetching ALL orders for Table $tableNo at $location ($tableType)');

      return _db
          .collection('orders')
          .where('tableNo', isEqualTo: tableNo)
          .where('location', isEqualTo: location)
          .where('tableType', isEqualTo: tableType)
          .where('status', whereIn: ['active', 'pending'])
          .snapshots()
          .map((snapshot) {
            final orders = snapshot.docs
                .map((doc) {
                  try {
                    return app_order.Order.fromFirestore(doc.data(), doc.id);
                  } catch (e) {
                    print('⚠️ Error parsing order ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<app_order.Order>()
                .toList();

            // Sort by time - newest first
            orders.sort((a, b) => b.time.compareTo(a.time));

            print('✅ Found ${orders.length} orders for this table');
            return orders;
          });
    } catch (e) {
      print('❌ Error in getOrdersForTableAtLocation: $e');
      return Stream.value([]);
    }
  }

  /// ✅ Check if table has an active order
  Future<app_order.Order?> getActiveOrderForTable(
    int tableNo,
    String location,
    String tableType,
  ) async {
    try {
      print(
          '🔍 Checking for active order: Table $tableNo at $location ($tableType)');

      final snapshot = await _db
          .collection('orders')
          .where('tableNo', isEqualTo: tableNo)
          .where('location', isEqualTo: location)
          .where('tableType', isEqualTo: tableType)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print('✅ No active order found - will create new');
        return null;
      }

      final doc = snapshot.docs.first;
      print('✅ Found existing order: ${doc.id}');
      return app_order.Order.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      print('❌ Error checking active order: $e');
      return null;
    }
  }

  /// ✅ Update existing order by adding new items
  Future<void> updateOrderWithNewItems(
    String orderId,
    List<Map<String, dynamic>> newItems,
    double newTotalPrice,
    int newOrderCount, // Add this parameter
  ) async {
    try {
      print('📝 Updating order $orderId with ${newItems.length} new items');

      final orderRef = _db.collection('orders').doc(orderId);
      final orderDoc = await orderRef.get();

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data()!;
      final existingItems = (orderData['items'] as List<dynamic>?) ?? [];

      // ✅ Merge existing items with new items
      final allItems = [...existingItems, ...newItems];

      await orderRef.update({
        'items': allItems,
        'totalPrice': newTotalPrice,
        'orderCount': newOrderCount, // Update order count
        'time': Timestamp.now(), // ✅ Update timestamp
      });

      print('✅ Order updated successfully');

      // ✅ Clear cache after update
      clearOccupiedTablesCache();
    } catch (e) {
      print('❌ Error updating order: $e');
      rethrow;
    }
  }

  Future<void> seedOrderStatusData() async {
    try {
      print('🌱 Starting to seed order status data...');

      // ✅ CLEAR OLD DATA FIRST
      final existingDocs = await _db.collection('order_status').get();
      for (var doc in existingDocs.docs) {
        await doc.reference.delete();
      }
      print('🧹 Cleared ${existingDocs.docs.length} existing records');

      // ✅ DYNAMIC DATES - Will always be relative to TODAY
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final yesterday = DateFormat('yyyy-MM-dd')
          .format(now.subtract(const Duration(days: 1)));
      final twoDaysAgo = DateFormat('yyyy-MM-dd')
          .format(now.subtract(const Duration(days: 2)));

      final fakeOrders = [
        // ✅ TODAY'S ORDERS - Will always show on current day
        {
          'tableNumber': '101-VIP',
          'firstOrderTime': '10:00',
          'numberOfOrders': 2,
          'billSettlementTime': '11:00',
          'totalAmount': 800,
          'status': 'settled',
          'orderDate': today, // ✅ Always today's date
          'createdAt': Timestamp.now(),
          'items': [
            {
              'orderNumber': '1',
              'itemName': 'Dahi Kebab',
              'quantity': 2,
              'amount': 200,
              'status': 'delivered'
            },
            {
              'orderNumber': '1',
              'itemName': 'Dal Makhni',
              'quantity': 1,
              'amount': 200,
              'status': 'delivered'
            },
            {
              'orderNumber': '2',
              'itemName': 'Paneer Tikka',
              'quantity': 3,
              'amount': 400,
              'status': 'delivered'
            },
            {
              'orderNumber': '2',
              'itemName': 'Butter Naan',
              'quantity': 2,
              'amount': 150,
              'status': 'cancelled'
            },
          ],
        },
        {
          'tableNumber': '102-Silver',
          'firstOrderTime': '11:00',
          'numberOfOrders': 3,
          'billSettlementTime': '12:00',
          'totalAmount': 1500,
          'status': 'settled',
          'orderDate': today, // ✅ Always today's date
          'createdAt': Timestamp.now(),
          'items': [
            {
              'orderNumber': '1',
              'itemName': 'Butter Chicken',
              'quantity': 2,
              'amount': 600,
              'status': 'delivered'
            },
            {
              'orderNumber': '1',
              'itemName': 'Naan',
              'quantity': 4,
              'amount': 160,
              'status': 'delivered'
            },
            {
              'orderNumber': '2',
              'itemName': 'Biryani',
              'quantity': 2,
              'amount': 500,
              'status': 'delivered'
            },
            {
              'orderNumber': '3',
              'itemName': 'Raita',
              'quantity': 2,
              'amount': 240,
              'status': 'delivered'
            },
          ],
        },
        {
          'tableNumber': '103-Diamond',
          'firstOrderTime': '11:30',
          'numberOfOrders': 1,
          'billSettlementTime': '12:30',
          'totalAmount': 0,
          'status': 'cancelled',
          'orderDate': today, // ✅ Always today's date
          'createdAt': Timestamp.now(),
          'items': [
            {
              'orderNumber': '1',
              'itemName': 'Veg Momos',
              'quantity': 1,
              'amount': 150,
              'status': 'cancelled'
            },
            {
              'orderNumber': '1',
              'itemName': 'Cold Coffee',
              'quantity': 2,
              'amount': 300,
              'status': 'cancelled'
            },
          ],
        },
        {
          'tableNumber': '104-VIP',
          'firstOrderTime': '12:00',
          'numberOfOrders': 3,
          'billSettlementTime': '13:15',
          'totalAmount': 1950,
          'status': 'settled',
          'orderDate': today, // ✅ Always today's date
          'createdAt': Timestamp.now(),
          'items': [
            {
              'orderNumber': '1',
              'itemName': 'Tandoori Chicken',
              'quantity': 2,
              'amount': 800,
              'status': 'delivered'
            },
            {
              'orderNumber': '1',
              'itemName': 'Garlic Naan',
              'quantity': 4,
              'amount': 200,
              'status': 'delivered'
            },
            {
              'orderNumber': '2',
              'itemName': 'Dal Tadka',
              'quantity': 1,
              'amount': 250,
              'status': 'delivered'
            },
            {
              'orderNumber': '2',
              'itemName': 'Jeera Rice',
              'quantity': 2,
              'amount': 300,
              'status': 'delivered'
            },
            {
              'orderNumber': '3',
              'itemName': 'Gulab Jamun',
              'quantity': 4,
              'amount': 400,
              'status': 'delivered'
            },
            {
              'orderNumber': '3',
              'itemName': 'Ice Cream',
              'quantity': 2,
              'amount': 250,
              'status': 'cancelled'
            },
          ],
        },
        {
          'tableNumber': '105-Silver',
          'firstOrderTime': '14:30',
          'numberOfOrders': 2,
          'billSettlementTime': '15:45',
          'totalAmount': 950,
          'status': 'settled',
          'orderDate': today, // ✅ Always today's date
          'createdAt': Timestamp.now(),
          'items': [
            {
              'orderNumber': '1',
              'itemName': 'Chicken Biryani',
              'quantity': 2,
              'amount': 700,
              'status': 'delivered'
            },
            {
              'orderNumber': '2',
              'itemName': 'Lassi',
              'quantity': 2,
              'amount': 250,
              'status': 'delivered'
            },
          ],
        },

        // ✅ YESTERDAY'S ORDERS (optional - for history)
        {
          'tableNumber': '201-Diamond',
          'firstOrderTime': '14:00',
          'numberOfOrders': 2,
          'billSettlementTime': '15:00',
          'totalAmount': 1200,
          'status': 'settled',
          'orderDate': yesterday,
          'createdAt': Timestamp.now(),
          'items': [
            {
              'orderNumber': '1',
              'itemName': 'Chicken Curry',
              'quantity': 2,
              'amount': 700,
              'status': 'delivered'
            },
            {
              'orderNumber': '2',
              'itemName': 'Roti',
              'quantity': 5,
              'amount': 500,
              'status': 'delivered'
            },
          ],
        },

        // ✅ TWO DAYS AGO (optional - for history)
        {
          'tableNumber': '301-Silver',
          'firstOrderTime': '18:00',
          'numberOfOrders': 1,
          'billSettlementTime': '19:00',
          'totalAmount': 600,
          'status': 'settled',
          'orderDate': twoDaysAgo,
          'createdAt': Timestamp.now(),
          'items': [
            {
              'orderNumber': '1',
              'itemName': 'Pizza',
              'quantity': 2,
              'amount': 600,
              'status': 'delivered'
            },
          ],
        },
      ];

      int totalAdded = 0;

      for (var order in fakeOrders) {
        await _db.collection('order_status').add(order);
        print(
            '✅ Added order for ${order['tableNumber']} on ${order['orderDate']}');
        totalAdded++;
      }

      print('🎉 Successfully added $totalAdded order status records!');
      print('📅 Today: $today');
      print('📅 Yesterday: $yesterday');
      print('📅 Two days ago: $twoDaysAgo');
      print(
          '\n⚠️ NOTE: Run this function daily or on app launch to keep data fresh!');
    } catch (e) {
      print('❌ Error seeding order status data: $e');
      rethrow;
    }
  }

  Future<void> ensureTodayDataExists() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Check if data exists for today
      final todayData = await _db
          .collection('order_status')
          .where('orderDate', isEqualTo: today)
          .limit(1)
          .get();

      if (todayData.docs.isEmpty) {
        print('📅 No data for today, seeding...');
        await seedOrderStatusData();
      } else {
        print('✅ Data already exists for today');
      }
    } catch (e) {
      print('❌ Error checking today\'s data: $e');
    }
  }
  // ============ SEED DATA ============

  Future<void> seedTableData() async {
    try {
      print('🌱 Starting to seed table data...');

      final data = {
        'Rooftop': {
          'Diamond': [101, 102, 103, 104, 105],
          'Silver': [106, 107, 108, 109, 110],
        },
        'Lounge': {
          'Diamond': [201, 202, 203, 204, 205],
          'Silver': [206, 207, 208, 209, 210],
        },
        'VIP': {
          'Diamond': [301, 302, 303, 304, 305],
          'Silver': [306, 307, 308, 309, 310],
        },
      };

      int totalAdded = 0;

      for (String location in data.keys) {
        final tableTypes = data[location]!;

        for (String tableType in tableTypes.keys) {
          final tableNumbers = tableTypes[tableType]!;

          for (int tableNo in tableNumbers) {
            final docId =
                '${location.toLowerCase()}_${tableType.toLowerCase()}_$tableNo';

            await _db.collection('TableModel').doc(docId).set({
              'location': location,
              'tableType': tableType,
              'tableNo': tableNo,
              'status': 'available',
            });

            print('✅ Added: $location - $tableType - Table $tableNo');
            totalAdded++;
          }
        }
      }

      print('🎉 Successfully added $totalAdded tables to Firebase!');
    } catch (e) {
      print('❌ Error seeding data: $e');
      rethrow;
    }
  }
}

/// Cache wrapper with timestamp
class _CachedData<T> {
  final T data;
  final DateTime timestamp;

  _CachedData(this.data) : timestamp = DateTime.now();

  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(timestamp) > maxAge;
  }
}
