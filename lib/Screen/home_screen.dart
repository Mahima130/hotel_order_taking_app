import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hotel_order_taking_app/Provider/order_provider.dart';
import 'package:hotel_order_taking_app/services/firestore_service.dart';
import 'package:hotel_order_taking_app/Widget/menu_search_model.dart';
import 'package:hotel_order_taking_app/Model/order.dart' as app_order;
import 'package:hotel_order_taking_app/Screen/qr_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedTableType;
  int? _selectedTableNo;
  bool _useDefaultContact = false;
  bool _isLoading = false;

  final List<String> _tableCategories = ['Rooftop', 'Standard', 'VIP'];

  void _showOccupiedTableWarning(int tableNo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Table Occupied'),
        content: Text(
            'Table $tableNo has a running order. Use "ADD ORDER" button instead.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _showTableSelectionDialog() async {
    if (_selectedTableType == null) {
      _showSnackBar('Please select table category first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final allTables =
          await _firestoreService.getTablesByType(_selectedTableType!);
      final occupiedTables =
          await _firestoreService.getOccupiedTablesByType(_selectedTableType!);

      setState(() => _isLoading = false);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_selectedTableType Tables',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: allTables.isEmpty
                      ? const Center(child: Text('No tables available'))
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: allTables.length,
                          itemBuilder: (context, index) {
                            final tableNo = allTables[index];
                            final isOccupied = occupiedTables.contains(tableNo);

                            return InkWell(
                              onTap: isOccupied
                                  ? () => _showOccupiedTableWarning(tableNo)
                                  : () {
                                      setState(
                                          () => _selectedTableNo = tableNo);
                                      Navigator.pop(ctx);
                                    },
                              child: Card(
                                elevation: 2,
                                color:
                                    isOccupied ? Colors.red[100] : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isOccupied
                                        ? Colors.red
                                        : const Color(0xFFD4AF37),
                                    width: isOccupied ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.table_restaurant,
                                      color: isOccupied
                                          ? Colors.red
                                          : const Color(0xFF1A1A2E),
                                      size: 28,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$tableNo',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isOccupied
                                            ? Colors.red
                                            : const Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    if (isOccupied)
                                      Text(
                                        'Occupied',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading tables: $e');
    }
  }

  void _navigateToQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QrScannerScreen()),
    );
  }

  void _startNewOrder() async {
    if (_selectedTableType == null) {
      _showSnackBar('Please select table category');
      return;
    }
    if (_selectedTableNo == null) {
      _showSnackBar('Please select table number');
      return;
    }
    if (!_useDefaultContact && _phoneController.text.isEmpty) {
      _showSnackBar('Please enter contact number or check default');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final occupiedTables =
          await _firestoreService.getOccupiedTablesByType(_selectedTableType!);

      if (occupiedTables.contains(_selectedTableNo)) {
        _showSnackBar(
            'Table $_selectedTableNo is occupied. Use "ADD ORDER" instead.');
        setState(() => _isLoading = false);
        return;
      }
    } catch (e) {
      print('Error checking table occupancy: $e');
    }
    setState(() => _isLoading = false);

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.setTableInfo(_selectedTableNo!, _selectedTableType!);
    orderProvider
        .setPhoneNo(_useDefaultContact ? 'Default' : _phoneController.text);
    orderProvider.clearCart();

    showDialog(context: context, builder: (ctx) => const MenuSearchModal());
  }

  void _addToExistingOrder(app_order.Order order) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.setExistingOrderContext(
      order.tableNo,
      order.tableType,
      order.phoneNo,
      order.id,
    );
    showDialog(context: context, builder: (ctx) => const MenuSearchModal());
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Add your logout logic here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showTableCategoryDropdown(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 16),
              ..._tableCategories.map((category) => InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTableType = category;
                        _selectedTableNo = null;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: _selectedTableType == category
                            ? const Color(0xFFD4AF37).withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedTableType == category
                              ? const Color(0xFFD4AF37)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.category,
                            color: const Color(0xFFD4AF37),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            category,
                            style: const TextStyle(
                              color: Color(0xFF1A1A2E),
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const NetworkImage(
                  'https://i.pinimg.com/1200x/bd/b9/ab/bdb9abb6d73a15e466c244fd8d23aeaa.jpg',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.7),
                  BlendMode.lighten,
                ),
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.15)),
          Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 4,
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1A1A2E),
                      const Color(0xFF16213E),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ROYAL RESTAURANT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: _logout,
                        tooltip: 'Logout',
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FIXED ROW: Table Category + Table Number + QR Scanner
                    Row(
                      children: [
                        // Table Category
                        Expanded(
                          flex: 3,
                          child: GestureDetector(
                            onTap: () => _showTableCategoryDropdown(context),
                            child: Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedTableType != null
                                      ? const Color(0xFFD4AF37)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.category,
                                    size: 18,
                                    color: Color(0xFFD4AF37),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedTableType ?? 'Category',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _selectedTableType != null
                                            ? const Color(0xFF1A1A2E)
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    size: 20,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Table Number
                        Expanded(
                          flex: 3,
                          child: GestureDetector(
                            onTap:
                                _isLoading ? null : _showTableSelectionDialog,
                            child: Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedTableNo != null
                                      ? const Color(0xFFD4AF37)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  _isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFFD4AF37),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.table_restaurant,
                                          size: 18,
                                          color: Color(0xFFD4AF37),
                                        ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedTableNo != null
                                          ? 'Table $_selectedTableNo'
                                          : 'Table No',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _selectedTableNo != null
                                            ? const Color(0xFF1A1A2E)
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    size: 20,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // QR Scanner Button
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1A1A2E).withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _navigateToQRScanner,
                            icon: const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                              size: 24,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Contact Number + Default Checkbox Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            enabled: !_useDefaultContact,
                            decoration: InputDecoration(
                              hintText: 'Contact Number',
                              prefixIcon: const Icon(
                                Icons.phone,
                                size: 18,
                                color: Color(0xFFD4AF37),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD4AF37),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _useDefaultContact = !_useDefaultContact;
                                if (_useDefaultContact) {
                                  _phoneController.clear();
                                }
                              });
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: _useDefaultContact
                                      ? const Color(0xFFD4AF37)
                                      : Colors.grey.shade300,
                                  width: _useDefaultContact ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Checkbox(
                                    value: _useDefaultContact,
                                    onChanged: (value) {
                                      setState(() {
                                        _useDefaultContact = value ?? false;
                                        if (_useDefaultContact) {
                                          _phoneController.clear();
                                        }
                                      });
                                    },
                                    activeColor: const Color(0xFFD4AF37),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1A1A2E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search Menu Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFC4A030)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _startNewOrder,
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text(
                          'TAKE ORDER',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Text(
                  'RUNNING ORDERS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<app_order.Order>>(
                  stream: _firestoreService.getRunningOrders(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFFD4AF37)),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Running Orders',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final orders = snapshot.data!;

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white.withOpacity(0.95),
                          child: InkWell(
                            onTap: () => _addToExistingOrder(order),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Table ${order.tableNo}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.tableType,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFD4AF37),
                                          Color(0xFFC4A030)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Text(
                                      'ADD ORDER',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
