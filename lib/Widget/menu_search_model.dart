import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hotel_order_taking_app/Model/menu_item.dart';
import 'package:hotel_order_taking_app/Provider/order_provider.dart';
import 'package:hotel_order_taking_app/services/firestore_service.dart';
import 'package:hotel_order_taking_app/Screen/order_summary_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _firestoreService.getMenuCategories();
      setState(() {
        _categories = ['All', ...categories];
        _isLoadingCategories = false;
      });
      // Load all items initially
      _loadCategoryItems('All');
    } catch (e) {
      print('Error loading categories: $e');
      setState(() => _isLoadingCategories = false);
    }
  }

  // Enhanced _searchMenuItems method for menu_search_model.dart

  Future<void> _searchMenuItems(String query) async {
    print("🔄 Searching for: $query in category: $_selectedCategory");

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      // Load category items when search is cleared
      _loadCategoryItems(_selectedCategory);
      return;
    }

    setState(() => _isSearching = true);
    try {
      print("📡 Calling Firestore search...");

      // Get all search results first
      final allResults = await _firestoreService.searchMenuItems(query);
      print("✅ Total search results: ${allResults.length} items");

      // Filter results based on selected category
      List<MenuItem> filteredResults;
      if (_selectedCategory == 'All') {
        filteredResults = allResults;
      } else {
        filteredResults = allResults
            .where((item) =>
                item.category.toLowerCase() == _selectedCategory.toLowerCase())
            .toList();
        print(
            "✅ Filtered to ${filteredResults.length} items in $_selectedCategory");
      }

      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
      });
    } catch (e) {
      print("❌ Search error: $e");
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    }
  }

// Enhanced category loading to clear search when switching categories
  Future<void> _loadCategoryItems(String category) async {
    // Clear search when switching categories
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      _searchResults = [];
    }

    if (category == 'All') {
      // Load all items
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.note_add, color: Color(0xFFD4AF37)),
            SizedBox(width: 12),
            Text('Special Instructions',
                style: TextStyle(
                    color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
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
                labelText: 'Add instructions',
                hintText: 'e.g., No garlic, extra spicy',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
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
              orderProvider.addItem(item, notes: notesController.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} added with note'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFD4AF37),
              foregroundColor: Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('ADD', style: TextStyle(fontWeight: FontWeight.bold)),
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
        border:
            Border.all(color: Color(0xFFD4AF37).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFD4AF37).withOpacity(0.2),
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
                    Color(0xFFD4AF37).withOpacity(0.3),
                    Color(0xFFFFD700).withOpacity(0.2)
                  ],
                ),
                border: Border.all(color: Color(0xFFD4AF37).withOpacity(0.3)),
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
                          color: Color(0xFFB8860B),
                        ),
                      )
                    : Icon(
                        Icons.restaurant_menu,
                        size: 35,
                        color: Color(0xFFB8860B),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Code: ${item.code}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '₹${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB8860B),
                    ),
                  ),
                ],
              ),
            ),
            if (itemInOrder > 0) ...[
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFFD4AF37)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          orderProvider.decreaseQuantity(item.code.toString()),
                      icon: Icon(Icons.remove,
                          size: 18, color: Color(0xFF1A1A2E)),
                      padding: EdgeInsets.all(6),
                      constraints: BoxConstraints(),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$itemInOrder',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          orderProvider.increaseQuantity(item.code.toString()),
                      icon: Icon(Icons.add, size: 18, color: Color(0xFF1A1A2E)),
                      padding: EdgeInsets.all(6),
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Column(
                children: [
                  SizedBox(
                    width: 70,
                    height: 32,
                    child: ElevatedButton(
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
                        backgroundColor: Color(0xFFD4AF37),
                        foregroundColor: Color(0xFF1A1A2E),
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'ADD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  GestureDetector(
                    onTap: () =>
                        _showSpecialInstructionsDialog(item, orderProvider),
                    child: Text(
                      'Add note',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFFB8860B),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    if (_isLoadingCategories) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Color(0xFF1A1A2E) : Colors.grey[700],
                ),
              ),
              backgroundColor: Colors.white,
              selectedColor: Color(0xFFD4AF37),
              checkmarkColor: Color(0xFF1A1A2E),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? Color(0xFFD4AF37) : Colors.grey[300]!,
                ),
              ),
              onSelected: (selected) {
                _loadCategoryItems(category);
              },
            ),
          );
        }).toList(),
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
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
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
                  color: Color(0xFFD4AF37).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off,
                  size: 64,
                  color: Color(0xFFB8860B).withOpacity(0.5),
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

    // Category browsing view
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
                  color: Color(0xFFD4AF37).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 64,
                  color: Color(0xFFB8860B).withOpacity(0.5),
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
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF2C2C3E)],
                ),
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
                      color: Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.restaurant_menu,
                        color: Color(0xFF1A1A2E), size: 24),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Browse Menu',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Color(0xFFD4AF37)),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by name or code',
                  prefixIcon: Icon(Icons.search, color: Color(0xFFD4AF37)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _searchMenuItems('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: Color(0xFFD4AF37).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: _searchMenuItems,
              ),
            ),
            Container(
              height: 50,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildCategoryChips(),
            ),
            Expanded(
              child: _buildContent(orderProvider),
            ),
            if (orderProvider.itemCount > 0)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
                  ),
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
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '₹${orderProvider.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderSummaryScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFD4AF37),
                          foregroundColor: Color(0xFF1A1A2E),
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
