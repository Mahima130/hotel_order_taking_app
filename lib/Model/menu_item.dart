class MenuItem {
  final String id;
  final int code;
  final String name;
  final double price;
  final String category;
  final String photoUrl;

  MenuItem({
    required this.id,
    required this.code,
    required this.name,
    required this.price,
    required this.category,
    required this.photoUrl,
  });

  // UPDATED: Better error handling and debugging
  factory MenuItem.fromFirestore(Map<String, dynamic> data, String id) {
    try {
      // Extract and validate each field
      final code = data['code'];
      final name = data['name'];
      final price = data['price'];
      final category = data['category'];
      final photoUrl = data['photoUrl'];

      // Debug logging
      if (code == null) print('WARNING: code is null for document $id');
      if (name == null) print('WARNING: name is null for document $id');
      if (price == null) print('WARNING: price is null for document $id');

      return MenuItem(
        id: id,
        code: code is int ? code : (int.tryParse(code?.toString() ?? '0') ?? 0),
        name: name?.toString() ?? '',
        price: price is num
            ? price.toDouble()
            : (double.tryParse(price?.toString() ?? '0') ?? 0.0),
        category: category?.toString() ?? '',
        photoUrl: photoUrl?.toString() ?? '',
      );
    } catch (e) {
      print('ERROR in MenuItem.fromFirestore for document $id: $e');
      print('Data received: $data');
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'name': name,
      'price': price,
      'category': category,
      'photoUrl': photoUrl,
    };
  }

  @override
  String toString() {
    return 'MenuItem(id: $id, code: $code, name: $name, price: $price, category: $category)';
  }
}
