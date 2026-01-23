import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hotel_order_taking_app/Provider/order_provider.dart';
import 'package:hotel_order_taking_app/services/firestore_service.dart';
import 'package:hotel_order_taking_app/Widget/menu_search_model.dart';
import 'package:hotel_order_taking_app/Model/order.dart' as app_order;
import 'package:hotel_order_taking_app/Screen/qr_screen.dart';
import 'package:hotel_order_taking_app/Screen/ChangePasswordScreen.dart';
import 'package:hotel_order_taking_app/Screen/OrderStatusScreen.dart';
import 'package:hotel_order_taking_app/Screen/ViewOrderScreen.dart';

import 'package:hotel_order_taking_app/Utils/Constants.dart';
import 'package:hotel_order_taking_app/Widget/Common/background_container.dart';
import 'package:hotel_order_taking_app/Widget/Common/custom_app_bar.dart';
import 'package:hotel_order_taking_app/Widget/home/order_card_v2.dart';
import 'package:hotel_order_taking_app/Widget/Common/custom_dropdown_field.dart';
import 'package:hotel_order_taking_app/Widget/Common/loading_indicator.dart';
import 'package:hotel_order_taking_app/Widget/Common/empty_state.dart';
import 'package:hotel_order_taking_app/Widget/Common/custom_dialog.dart';
import 'package:hotel_order_taking_app/Widget/home/order_card.dart';
import 'package:hotel_order_taking_app/Widget/home/occupied_table_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _addToExistingOrder(app_order.Order order) {
    // Set up the order FIRST
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.reset();
    orderProvider.setTableInfo(order.tableNo, order.tableType);
    orderProvider.setLocation(order.location ?? 'Rooftop');
    orderProvider.setPhoneNo(order.phoneNo);
    orderProvider.setOrderType(order.orderType ?? AppStrings.regular);

    // Use rootNavigator: true to ensure proper dialog context
    showDialog(
      context: context,
      builder: (ctx) => const MenuSearchModal(),
      useRootNavigator: true, // ← ADD THIS LINE
    );
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CustomDialog(
        title: 'Logout',
        content: 'Are you sure you want to logout?',
        cancelText: AppStrings.cancel,
        confirmText: 'Logout',
        confirmColor: AppColors.error,
        onConfirm: () {
          Navigator.of(dialogContext).pop(true);
        },
      ),
    );

    if (confirmed == true) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.clearCart();
      orderProvider.reset();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.65,
      child: Container(
        color: AppColors.drawerBackground,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  child: Image.network(
                    AppImages.restaurantLogo,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: AppSizes.spaceM),
                    _DrawerItem(
                      icon: Icons.add_circle_outline,
                      title: 'New Order',
                      onTap: () => Navigator.pop(context),
                    ),
                    _DrawerItem(
                      icon: Icons.list_alt,
                      title: 'Order Status',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OrderStatusScreen(),
                          ),
                        );
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(
                        color: Colors.grey, thickness: 0.5, height: 30),
                    _DrawerItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      iconColor: AppColors.primaryGold,
                      textColor: AppColors.primaryGold,
                      onTap: () {
                        Navigator.pop(context);
                        _logout();
                      },
                    ),
                    const Divider(
                        color: Colors.grey, thickness: 0.5, height: 30),
                    _buildQRSection(),
                    SizedBox(height: AppSizes.spaceXL),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          const Text(
            'Scan to Pay Bill',
            style: TextStyle(
              color: AppColors.primaryGold, // ← CHANGED FROM textDark to white
              fontSize: AppSizes.fontL,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSizes.spaceM),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(color: AppColors.primaryGold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.network(
              AppImages.qrCodePlaceholder,
              width: 170,
              height: 170,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 120,
                height: 120,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.qr_code,
                  size: 60,
                  color: AppColors.primaryGold,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSizes.spaceS),
          Text(
            'Scan QR to complete payment',
            style: TextStyle(
              color: AppColors
                  .primaryGold, // ← CHANGED to lighter grey for dark background
              fontSize: AppSizes.fontS,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      //backgroundColor: AppColors.bgLight,
      drawer: _buildDrawer(),
      drawerScrimColor: Colors.black.withOpacity(0.75),
      body: BackgroundContainer(
        child: Column(
          children: [
            CustomAppBar(
              title: AppStrings.createOrder,
              showMenu: true,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            _OrderFormWidget(
              firestoreService: _firestoreService,
              onShowSnackBar: _showSnackBar,
              onAddToExistingOrder: _addToExistingOrder, // ← ADD THIS LINE
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: const Text(
                AppStrings.runningOrders,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSizes.fontXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: _RunningOrdersSection(
                firestoreService: _firestoreService,
                onAddToOrder: _addToExistingOrder,
                onViewOrder: (order) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewOrderScreen(order: order),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.drawerBackground, // ← ADD THIS - Dark red background
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? AppColors.primaryGold,
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? AppColors.primaryGold, // ← Gold text
            fontSize: AppSizes.fontL,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _OrderFormWidget extends StatefulWidget {
  final FirestoreService firestoreService;
  final Function(String) onShowSnackBar;
  final Function(app_order.Order) onAddToExistingOrder; // ← ADD THIS

  const _OrderFormWidget({
    required this.firestoreService,
    required this.onShowSnackBar,
    required this.onAddToExistingOrder, // ← ADD THIS
  });

  @override
  State<_OrderFormWidget> createState() => _OrderFormWidgetState();
}

class _OrderFormWidgetState extends State<_OrderFormWidget> {
  String? _selectedTableType;
  int? _selectedTableNo;
  String _selectedOrderType = AppStrings.regular;
  bool _useDefaultContact = false;
  bool _isLoading = false;
  String? _selectedLocation;
  final TextEditingController _phoneController = TextEditingController();

  Map<String, List<int>> _cachedTables = {};
  Map<String, List<int>> _cachedOccupiedTables = {};

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showOrderTypeDropdown() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Order Type',
                style: TextStyle(
                  fontSize: AppSizes.fontXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: AppSizes.spaceL),
              _OrderTypeOption(
                icon: Icons.restaurant,
                label: AppStrings.regular,
                color: AppColors.primaryDark,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedOrderType = AppStrings.regular);
                },
              ),
              SizedBox(height: AppSizes.spaceS),
              _OrderTypeOption(
                icon: Icons.star,
                label: AppStrings.ent,
                color: AppColors.entColor,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedOrderType = AppStrings.ent);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationSelectionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _LocationSelectionDialog(
        onLocationSelected: (location, type) {
          setState(() {
            _selectedLocation = location;
            _selectedTableType = type;
            _selectedTableNo = null;
            _cachedTables.clear();
            _cachedOccupiedTables.clear();
          });
        },
      ),
    );
  }

  // void _showOccupiedTableWarning(int tableNo, app_order.Order order) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (dialogContext) => OccupiedTableDialog(
  //       order: order,
  //       onAddOrder: () {
  //         // Close the dialog first
  //         Navigator.of(context, rootNavigator: true).pop();
  //         // Small delay to ensure dialog closes
  //         Future.delayed(Duration(milliseconds: 50), () {
  //           widget.onAddToExistingOrder(order);
  //         });
  //       },
  //       onViewOrder: () {
  //         Navigator.of(context, rootNavigator: true).pop();
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => ViewOrderScreen(order: order),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  Future<void> _showTableNumberDialog() async {
    if (_selectedLocation == null) {
      widget.onShowSnackBar('Please select location first');
      return;
    }
    if (_selectedTableType == null) {
      widget.onShowSnackBar('Please select table type first');
      return;
    }

    final cacheKey = '$_selectedLocation-$_selectedTableType';
    List<int> tablesToShow;
    List<int> occupiedTables;
    Map<int, app_order.Order> ordersByTable = {}; // ← NEW

    if (_cachedTables.containsKey(cacheKey) &&
        _cachedOccupiedTables.containsKey(cacheKey)) {
      tablesToShow = _cachedTables[cacheKey]!;
      occupiedTables = _cachedOccupiedTables[cacheKey]!;
    } else {
      setState(() => _isLoading = true);
      try {
        final allTables =
            await widget.firestoreService.getTablesByType(_selectedLocation!);
        final occupied = await widget.firestoreService
            .getOccupiedTablesByType(_selectedLocation!, _selectedTableType!);
        tablesToShow = allTables.isEmpty
            ? List.generate(20, (index) => 101 + index)
            : allTables;
        occupiedTables = occupied;
        _cachedTables[cacheKey] = tablesToShow;
        _cachedOccupiedTables[cacheKey] = occupiedTables;
        setState(() => _isLoading = false);
      } catch (e) {
        setState(() => _isLoading = false);
        widget.onShowSnackBar('Error loading tables: $e');
        return;
      }
    }

    // ← NEW: Fetch running orders for occupied tables
    try {
      final runningOrders =
          await widget.firestoreService.getRunningOrders().first;
      for (var order in runningOrders) {
        if (order.location == _selectedLocation &&
            order.tableType == _selectedTableType) {
          ordersByTable[order.tableNo] = order;
        }
      }
    } catch (e) {
      print('Error fetching running orders: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => _TableSelectionDialog(
        location: _selectedLocation!,
        tableType: _selectedTableType!,
        tablesToShow: tablesToShow,
        occupiedTables: occupiedTables,
        ordersByTable: ordersByTable, // ← NEW
        onTableSelected: (tableNo) {
          setState(() => _selectedTableNo = tableNo);
        },
        onOccupiedTap: (tableNo, order) {
          // Close table selection dialog first
          Navigator.pop(ctx);

          // Small delay to ensure dialog closes completely
          Future.delayed(const Duration(milliseconds: 100), () {
            // Show occupied table dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => OccupiedTableDialog(
                order: order,
                onAddOrder: () {
                  widget.onAddToExistingOrder(order);
                },
                onViewOrder: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewOrderScreen(order: order),
                    ),
                  );
                },
              ),
            );
          });
        },
      ),
    );
  }

  void _startNewOrder() async {
    if (_selectedLocation == null) {
      widget.onShowSnackBar('Please select location');
      return;
    }
    if (_selectedTableType == null) {
      widget.onShowSnackBar('Please select table type');
      return;
    }
    if (_selectedTableNo == null) {
      widget.onShowSnackBar('Please select table number');
      return;
    }
    if (!_useDefaultContact && _phoneController.text.isEmpty) {
      widget.onShowSnackBar('Please enter contact number or check cash');
      return;
    }

    try {
      final occupiedTables = await widget.firestoreService
          .getOccupiedTablesByType(_selectedLocation!, _selectedTableType!);
      if (occupiedTables.contains(_selectedTableNo)) {
        widget.onShowSnackBar(
          'Table $_selectedTableNo is occupied. Use "${AppStrings.addOrder}" instead.',
        );
        return;
      }
    } catch (e) {
      print('Error checking table occupancy: $e');
    }

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.setTableInfo(_selectedTableNo!, _selectedTableType!);
    orderProvider.setLocation(_selectedLocation!);
    orderProvider.setPhoneNo(
      _useDefaultContact ? 'Default' : _phoneController.text,
    );
    orderProvider.setOrderType(_selectedOrderType); // ← ADD THIS LINE
    orderProvider.clearCart();

    showDialog(context: context, builder: (ctx) => const MenuSearchModal());
  }
  // Replace the entire _OrderFormWidget build method with this:

  @override
  Widget build(BuildContext context) {
    final isEntOrder = _selectedOrderType == AppStrings.ent;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      // REMOVE ALL PADDING FROM PARENT
      padding: EdgeInsets.zero, // ← CHANGED FROM 16 to 0
      decoration: BoxDecoration(
        color: isEntOrder
            ? AppColors.entBgLight.withOpacity(0.95)
            : AppColors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16), // ← ADD PADDING HERE INSTEAD
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Type Selector
            GestureDetector(
              onTap: _showOrderTypeDropdown,
              child: Container(
                height: AppSizes.buttonHeight,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color:
                      isEntOrder ? AppColors.entColor : AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEntOrder ? Icons.star : Icons.restaurant,
                      size: AppSizes.iconS,
                      color: AppColors.white,
                    ),
                    SizedBox(width: AppSizes.spaceS),
                    Expanded(
                      child: Text(
                        _selectedOrderType,
                        style: const TextStyle(
                          fontSize: AppSizes.fontM,
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: AppColors.white,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSizes.spaceM),
            // Location & Table Row - WHITE BACKGROUND
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomDropdownField(
                      hint: AppStrings.locationAndType,
                      value: _selectedLocation != null &&
                              _selectedTableType != null
                          ? '$_selectedLocation - $_selectedTableType'
                          : null,
                      icon: Icons.location_on,
                      onTap: _showLocationSelectionDialog,
                      backgroundColor: AppColors.white,
                    ),
                  ),
                  SizedBox(width: AppSizes.spaceS),
                  Expanded(
                    flex: 3,
                    child: CustomDropdownField(
                      hint: AppStrings.tableNo,
                      value: _selectedTableNo != null
                          ? 'Table $_selectedTableNo'
                          : null,
                      icon: Icons.table_bar,
                      onTap: _showTableNumberDialog,
                      isLoading: _isLoading,
                      backgroundColor: AppColors.white,
                    ),
                  ),
                  SizedBox(width: AppSizes.spaceS),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors
                          .buttonBackground, // ← Light Yellow background
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.buttonBackground.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QrScannerScreen(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.qr_code_scanner,
                        color: AppColors.buttonText, // ← Black icon
                        size: AppSizes.iconM,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSizes.spaceM),
            // Contact Row
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _useDefaultContact = !_useDefaultContact;
                        if (_useDefaultContact) _phoneController.clear();
                      });
                    },
                    child: Container(
                      height: AppSizes.buttonHeight,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(
                          color: _useDefaultContact
                              ? AppColors.buttonBackground
                              : Colors.grey.shade300,
                          width: _useDefaultContact ? 2 : 1,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMedium),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _useDefaultContact,
                            onChanged: (value) {
                              setState(() {
                                _useDefaultContact = value ?? false;
                                if (_useDefaultContact)
                                  _phoneController.clear();
                              });
                            },
                            activeColor: AppColors
                                .buttonBackground, // ← Light Yellow when checked
                            checkColor:
                                AppColors.buttonText, // ← Black checkmark
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const Text(
                            AppStrings.cash,
                            style: TextStyle(
                              fontSize: AppSizes.fontS + 1,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSizes.spaceS),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !_useDefaultContact,
                    decoration: InputDecoration(
                      hintText: AppStrings.contactNumber,
                      prefixIcon: const Icon(
                        Icons.phone,
                        size: AppSizes.iconS,
                        color: AppColors.primaryGold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMedium),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMedium),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMedium),
                        borderSide: const BorderSide(
                          color: AppColors.buttonBackground,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spaceM),
            ElevatedButton(
              onPressed: _startNewOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBackground, // Light Yellow
                minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, color: AppColors.buttonText), // Black icon
                  SizedBox(width: AppSizes.spaceS),
                  Text(
                    AppStrings.takeOrder,
                    style: TextStyle(
                      color: AppColors.buttonText, // Black text
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.fontL,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _OrderTypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OrderTypeOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSizes.spaceS),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 20),
            SizedBox(width: AppSizes.spaceM),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ✅ REPLACE YOUR ENTIRE OLD _RunningOrdersSection CLASS WITH THIS:

class _RunningOrdersSection extends StatefulWidget {
  final FirestoreService firestoreService;
  final Function(app_order.Order) onAddToOrder;
  final Function(app_order.Order) onViewOrder;

  const _RunningOrdersSection({
    required this.firestoreService,
    required this.onAddToOrder,
    required this.onViewOrder,
  });

  @override
  State<_RunningOrdersSection> createState() => _RunningOrdersSectionState();
}

class _RunningOrdersSectionState extends State<_RunningOrdersSection> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<app_order.Order>>(
      stream: widget.firestoreService.getRunningOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyState(
            icon: Icons.restaurant_menu,
            message: AppStrings.noRunningOrders,
          );
        }

        final orders = snapshot.data!;

        // ✅ GROUP ORDERS BY TABLE and calculate totals
        final Map<String, List<app_order.Order>> ordersByTable = {};
        for (var order in orders) {
          final key =
              '${order.location ?? 'Unknown'}-${order.tableType}-${order.tableNo}';
          ordersByTable.putIfAbsent(key, () => []).add(order);
        }

        // ✅ CREATE DISPLAY ORDERS WITH CORRECT COUNTS AND TOTALS
        final List<app_order.Order> displayOrders = [];
        ordersByTable.forEach((key, tableOrders) {
          if (tableOrders.isNotEmpty) {
            // Use the most recent order as base
            final latestOrder =
                tableOrders.reduce((a, b) => a.time.isAfter(b.time) ? a : b);

            // Calculate total items count across all orders for this table
            final totalItemsCount = tableOrders.fold<int>(
                0, (sum, order) => sum + order.items.length);

            // Calculate total price across all orders for this table
            final totalTablePrice = tableOrders.fold<double>(
                0.0, (sum, order) => sum + order.totalPrice);

            // Create display order with aggregated data
            final displayOrder = latestOrder.copyWith(
              orderCount: tableOrders.length, // Number of orders for this table
              totalPrice: totalTablePrice, // Combined total price
              // If you want to show total items instead of order count, use:
              // orderCount: totalItemsCount,
            );

            displayOrders.add(displayOrder);
          }
        });

        // ✅ Sort by table number
        displayOrders.sort((a, b) => a.tableNo.compareTo(b.tableNo));

        return GridView.builder(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.68,
            crossAxisSpacing: 12,
            mainAxisSpacing: 20,
          ),
          itemCount: displayOrders.length,
          itemBuilder: (context, index) {
            final order = displayOrders[index];
            return OrderCardV2(
              key: ValueKey('${order.id}-${order.time.millisecondsSinceEpoch}'),
              order: order,
              onAddToOrder: () => widget.onAddToOrder(order),
              onViewOrder: () => widget.onViewOrder(order),
            );
          },
        );
      },
    );
  }
}

class _LocationSelectionDialog extends StatefulWidget {
  final Function(String location, String type) onLocationSelected;

  const _LocationSelectionDialog({required this.onLocationSelected});

  @override
  State<_LocationSelectionDialog> createState() =>
      _LocationSelectionDialogState();
}

class _LocationSelectionDialogState extends State<_LocationSelectionDialog> {
  String? expandedLocation;
  String? _selectedLocation;
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: AppColors.transparent, // ← MATCH TABLE DIALOG
        child: Container(
          // ← USE CONTAINER LIKE TABLE DIALOG
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: AppColors.white, // ← PURE WHITE
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ← ADD HEADER LIKE TABLE DIALOG
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.drawerBackground, // ← Dark blue header
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.radiusLarge),
                    topRight: Radius.circular(AppSizes.radiusLarge),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Select Location & Type',
                        style: TextStyle(
                          fontSize: AppSizes.fontL,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.primaryGold,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // ← CONTENT AREA
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildLocationSection(
                          'Rooftop',
                          Icons.roofing,
                          ['Diamond', 'Silver'],
                        ),
                        SizedBox(height: AppSizes.spaceM),
                        _buildLocationSection(
                          'Lounge',
                          Icons.weekend,
                          ['Diamond', 'Silver'],
                        ),
                        SizedBox(height: AppSizes.spaceM),
                        _buildLocationSection(
                          'VIP',
                          Icons.star,
                          ['Diamond', 'Silver'],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ← FOOTER WITH BUTTONS
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppSizes.radiusLarge),
                    bottomRight: Radius.circular(AppSizes.radiusLarge),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: AppColors.textDark,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.spaceS),
                          ),
                        ),
                        child: const Text(
                          AppStrings.cancel,
                          style: TextStyle(
                            fontSize: AppSizes.fontM,
                            fontWeight: FontWeight.w600,
                            color: AppColors.buttonText, // ← ADDED
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spaceM),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _selectedLocation != null && _selectedType != null
                                ? () {
                                    widget.onLocationSelected(
                                      _selectedLocation!,
                                      _selectedType!,
                                    );
                                    Navigator.pop(context);
                                  }
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBackground,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.spaceS),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[500],
                        ),
                        child: const Text(
                          AppStrings.confirm,
                          style: TextStyle(
                            fontSize: AppSizes.fontM,
                            color: AppColors.buttonText, // ← CHANGED
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection(
    String location,
    IconData icon,
    List<String> types,
  ) {
    final isExpanded = expandedLocation == location;
    return Column(
      children: [
        InkWell(
          onTap: () =>
              setState(() => expandedLocation = isExpanded ? null : location),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.spaceS),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryGold, size: 20),
                SizedBox(width: AppSizes.spaceM),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textDark,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: types
                  .map((type) => _buildTypeOption(location, type))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTypeOption(String location, String type) {
    final isSelected = _selectedLocation == location && _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedLocation = location;
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        margin: const EdgeInsets.only(left: 20, bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.buttonBackground.withOpacity(0.2)
              : AppColors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                isSelected ? AppColors.buttonBackground : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.arrow_right,
              size: AppSizes.iconS,
              color: AppColors.buttonBackground,
            ),
            SizedBox(width: AppSizes.spaceS),
            Text(
              type,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: AppSizes.fontM,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableSelectionDialog extends StatefulWidget {
  final String location;
  final String tableType;
  final List<int> tablesToShow;
  final List<int> occupiedTables;
  final Map<int, app_order.Order> ordersByTable; // ← ADD THIS
  final Function(int) onTableSelected;
  final Function(int, app_order.Order) onOccupiedTap; // ← CHANGE THIS

  const _TableSelectionDialog({
    required this.location,
    required this.tableType,
    required this.tablesToShow,
    required this.occupiedTables,
    required this.ordersByTable, // ← ADD THIS
    required this.onTableSelected,
    required this.onOccupiedTap,
  });

  @override
  State<_TableSelectionDialog> createState() => _TableSelectionDialogState();
}

class _TableSelectionDialogState extends State<_TableSelectionDialog> {
  int? selectedTableNo;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: AppColors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.drawerBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.radiusLarge),
                    topRight: Radius.circular(AppSizes.radiusLarge),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.location} - ${widget.tableType}',
                        style: const TextStyle(
                          fontSize: AppSizes.fontL,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.primaryGold,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: widget.tablesToShow.length,
                    itemBuilder: (context, index) {
                      final tableNo = widget.tablesToShow[index];
                      final isOccupied =
                          widget.occupiedTables.contains(tableNo);
                      final isSelected = selectedTableNo == tableNo;

                      return InkWell(
                        onTap: isOccupied
                            ? () {
                                print(
                                    'Occupied table tapped: $tableNo'); // ← ADD THIS
                                final order = widget.ordersByTable[tableNo];
                                print(
                                    'Order found: ${order != null}'); // ← ADD THIS
                                if (order != null) {
                                  widget.onOccupiedTap(tableNo, order);
                                } else {
                                  print(
                                      'Order is null for table $tableNo'); // ← ADD THIS
                                }
                              }
                            : () => setState(() => selectedTableNo = tableNo),
                        borderRadius: BorderRadius.circular(AppSizes.spaceS),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isOccupied
                                ? Colors.red[100]
                                : isSelected
                                    ? AppColors.buttonBackground
                                    : AppColors.white,
                            borderRadius:
                                BorderRadius.circular(AppSizes.spaceS),
                            border: Border.all(
                              color: isOccupied
                                  ? AppColors.error
                                  : isSelected
                                      ? AppColors.buttonBackground
                                      : Colors.grey.shade300,
                              width: isOccupied || isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.table_bar,
                                color: isOccupied
                                    ? AppColors.error
                                    : isSelected
                                        ? AppColors.white
                                        : AppColors.textDark,
                                size: 20,
                              ),
                              const SizedBox(height: 2),
                              Flexible(
                                child: Text(
                                  '$tableNo',
                                  style: TextStyle(
                                    fontSize: AppSizes.fontM,
                                    fontWeight: FontWeight.bold,
                                    color: isOccupied
                                        ? AppColors.error
                                        : isSelected
                                            ? AppColors.white
                                            : AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppSizes.radiusLarge),
                    bottomRight: Radius.circular(AppSizes.radiusLarge),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: AppColors.textDark,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.spaceS),
                          ),
                        ),
                        child: const Text(
                          AppStrings.cancel,
                          style: TextStyle(
                            fontSize: AppSizes.fontM,
                            fontWeight: FontWeight.w600,
                            color: AppColors.buttonText, // ← ADDED
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spaceM),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedTableNo != null
                            ? () {
                                widget.onTableSelected(selectedTableNo!);
                                Navigator.pop(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBackground,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.spaceS),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[500],
                        ),
                        child: const Text(
                          AppStrings.confirm,
                          style: TextStyle(
                            fontSize: AppSizes.fontM,
                            fontWeight: FontWeight.w600,
                            color: AppColors.buttonText, // ← ADDED
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
