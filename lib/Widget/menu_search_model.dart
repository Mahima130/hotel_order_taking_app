import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hotel_order_taking_app/Model/menu_item.dart';
import 'package:hotel_order_taking_app/Provider/order_provider.dart';
import 'package:hotel_order_taking_app/services/firestore_service.dart';
import 'package:hotel_order_taking_app/Screen/order_summary_screen.dart';
import 'package:hotel_order_taking_app/Utils/Constants.dart';

class MenuSearchModal extends StatefulWidget {
  const MenuSearchModal({Key? key}) : super(key: key);

  @override
  State<MenuSearchModal> createState() => _MenuSearchModalState();
}

class _MenuSearchModalState extends State<MenuSearchModal> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<MenuItem> _searchResults = [];
  List<MenuItem> _categoryItems = [];
  List<String> _categories = [];
  String _selectedCategory = 'All';
  bool _isSearching = false;
  bool _isLoadingCategories = true;
  Timer? _debounceTimer;

  final Map<String, String> _categoryHindiNames = {
    'All': 'सभी',
    'Breads': 'रोटी',
    'Main Course': 'मुख्य व्यंजन',
    'Starters': 'स्टार्टर',
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _firestoreService.getMenuCategories();
      setState(() {
        _categories = ['All', ...categories];
        _isLoadingCategories = false;
      });
      _loadCategoryItems('All');
    } catch (e) {
      print('Error loading categories: $e');
      setState(() => _isLoadingCategories = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      _searchMenuItems(query);
    });
  }

  Future<void> _searchMenuItems(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      _loadCategoryItems(_selectedCategory);
      return;
    }

    setState(() {
      _isSearching = true;
      _selectedCategory = 'All';
    });

    try {
      final allResults = await _firestoreService.searchMenuItems(query);
      print(
          "🔍 Search complete: Found ${allResults.length} results for '$query'");

      setState(() {
        _searchResults = allResults;
        _isSearching = false;
      });
    } catch (e) {
      print("❌ Search error: $e");
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadCategoryItems(String category) async {
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      _searchResults = [];
    }

    if (category == 'All') {
      final allItems = await _firestoreService.getMenuItems().first;
      setState(() {
        _categoryItems = allItems;
        _selectedCategory = category;
      });
    } else {
      setState(() => _isSearching = true);
      try {
        final items = await _firestoreService.getMenuItemsByCategory(category);
        setState(() {
          _categoryItems = items;
          _selectedCategory = category;
          _isSearching = false;
        });
      } catch (e) {
        print('Error loading category items: $e');
        setState(() => _isSearching = false);
      }
    }
  }

  void _showSpecialInstructionsDialog(
      MenuItem item, OrderProvider orderProvider) {
    final notesController = TextEditingController();

    // ✅ Get the existing item if it's already in the order
    final existingItemIndex = orderProvider.orderItems
        .indexWhere((orderItem) => orderItem.code == item.code);

    // ✅ If item exists, pre-fill the notes
    if (existingItemIndex != -1) {
      notesController.text = orderProvider.orderItems[existingItemIndex].notes;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.note_add, color: AppColors.buttonBackground),
            SizedBox(width: 12),
            Text(
              existingItemIndex != -1
                  ? 'Update Instructions'
                  : 'Special Instructions',
              style: TextStyle(
                  color: AppColors.drawerBackground,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.name} - ₹${item.price}',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey[800])),
            SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: existingItemIndex != -1
                    ? 'Update instructions'
                    : 'Add instructions',
                hintText: 'e.g., No garlic, extra spicy',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.buttonBackground, width: 2),
                ),
                filled: true,
                fillColor: Color(0xFFFFFDF7),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              if (existingItemIndex != -1) {
                // ✅ UPDATE existing item's notes
                orderProvider.updateItemNotes(
                    existingItemIndex, notesController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Note updated for ${item.name}'),
                    backgroundColor: Colors.blue,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                // ✅ ADD new item with notes
                orderProvider.addItem(item, notes: notesController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} added with note'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonBackground,
              foregroundColor: AppColors.buttonText,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(existingItemIndex != -1 ? 'UPDATE' : 'ADD',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item, OrderProvider orderProvider) {
    final itemInOrder = orderProvider.getItemQuantity(item.code);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.buttonBackground.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.buttonBackground.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.buttonBackground.withOpacity(0.3),
                    AppColors.buttonBackground.withOpacity(0.2)
                  ],
                ),
                border: Border.all(
                    color: AppColors.buttonBackground.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.photoUrl.isNotEmpty
                    ? Image.network(
                        item.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.restaurant,
                          size: 35,
                          color: AppColors.buttonBackground,
                        ),
                      )
                    : Icon(
                        Icons.restaurant_menu,
                        size: 35,
                        color: AppColors.buttonBackground,
                      ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Code: ${item.code}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '₹${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.drawerBackground,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 6),
            SizedBox(
              width: 90,
              child: itemInOrder > 0
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.buttonBackground.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.buttonBackground,
                              width: 1.2,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2), // 🔥 Reduced size
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Minus Button
                              InkWell(
                                onTap: () => orderProvider
                                    .decreaseQuantity(item.code.toString()),
                                child: Padding(
                                  padding:
                                      EdgeInsets.all(5), // 🔥 Smaller tap area
                                  child: Icon(Icons.remove,
                                      size: 18,
                                      color: AppColors
                                          .drawerBackground), // Smaller icon
                                ),
                              ),

                              // Quantity Number
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '$itemInOrder',
                                  style: TextStyle(
                                    fontSize: 14, // 🔥 Reduced text size
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.drawerBackground,
                                  ),
                                ),
                              ),

                              // Plus Button
                              InkWell(
                                onTap: () => orderProvider
                                    .increaseQuantity(item.code.toString()),
                                child: Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Icon(Icons.add,
                                      size: 18,
                                      color: AppColors
                                          .drawerBackground), // Smaller icon
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _showSpecialInstructionsDialog(
                              item, orderProvider),
                          child: Text(
                            'Add note',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.drawerBackground,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: () {
                        orderProvider.addItem(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.name} added'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBackground,
                        foregroundColor: AppColors.buttonText,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: Size(70, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'ADD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    if (_isLoadingCategories) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.buttonBackground),
        ),
      );
    }

    return SizedBox(
      height: 65,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          final hindiName = _categoryHindiNames[category] ?? category;

          return Padding(
            padding: EdgeInsets.only(right: 10),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.drawerBackground
                          : Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    hindiName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.drawerBackground
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              selectedColor: AppColors.buttonBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.buttonBackground
                      : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              onSelected: (selected) {
                _loadCategoryItems(category);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(OrderProvider orderProvider) {
    final bool isSearching = _isSearching;
    final bool hasSearchQuery = _searchController.text.isNotEmpty;
    final bool hasSearchResults = _searchResults.isNotEmpty;
    final bool hasCategoryItems = _categoryItems.isNotEmpty;

    if (isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.buttonBackground),
            ),
            SizedBox(height: 16),
            Text(
              'Searching...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (hasSearchQuery) {
      if (hasSearchResults) {
        return ListView.builder(
          padding: EdgeInsets.only(bottom: 100),
          itemCount: _searchResults.length,
          itemBuilder: (ctx, index) => _buildMenuItemCard(
            _searchResults[index],
            orderProvider,
          ),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.buttonBackground.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.buttonBackground.withOpacity(0.5),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'No items found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }
    }

    if (!hasSearchQuery) {
      if (hasCategoryItems) {
        return ListView.builder(
          padding: EdgeInsets.only(bottom: 100),
          itemCount: _categoryItems.length,
          itemBuilder: (ctx, index) => _buildMenuItemCard(
            _categoryItems[index],
            orderProvider,
          ),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.buttonBackground.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 64,
                  color: AppColors.buttonBackground.withOpacity(0.5),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'No items in ${_selectedCategory == 'All' ? 'menu' : _selectedCategory}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }
    }

    return Center(
      child: Text(
        'Start typing to search or select a category',
        style: TextStyle(
          color: Colors.grey[600],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Color(0xFFF8F6F0),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.drawerBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.restaurant_menu,
                        color: Colors.black, size: 24),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Browse Menu',
                    style: TextStyle(
                      color: AppColors.primaryGold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.close,
                      color: AppColors.primaryGold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or code',
                  prefixIcon:
                      Icon(Icons.search, color: AppColors.buttonBackground),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: AppColors.buttonBackground.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: AppColors.buttonBackground, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: _buildCategoryChips(),
            ),
            Expanded(
              child: _buildContent(orderProvider),
            ),
            if (orderProvider.itemCount > 0)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.drawerBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${orderProvider.itemCount} items',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '₹${orderProvider.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close menu modal

                          Future.delayed(Duration(milliseconds: 100), () {
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OrderSummaryScreen(),
                                ),
                              );
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBackground,
                          foregroundColor: AppColors.buttonText,
                          padding: EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.shopping_cart_checkout, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'VIEW ORDER',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
