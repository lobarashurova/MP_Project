import '../models/product_model.dart';

class MockProducts {
  static final List<ProductModel> products = [
    ProductModel(
      id: '1',
      name: 'Plov (Uzbek Pilaf)',
      category: 'Main Dishes',
      price: 12.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Plov',
      rating: 4.9,
      description: 'Traditional Uzbek rice dish with lamb, carrots, and aromatic spices',
    ),
    ProductModel(
      id: '2',
      name: 'Lagman',
      category: 'Main Dishes',
      price: 10.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Lagman',
      rating: 4.7,
      description: 'Hand-pulled noodles with meat and vegetables in savory broth',
    ),
    ProductModel(
      id: '3',
      name: 'Manti',
      category: 'Appetizers',
      price: 8.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Manti',
      rating: 4.8,
      description: 'Steamed dumplings filled with spiced meat and onions',
    ),
    ProductModel(
      id: '4',
      name: 'Samsa',
      category: 'Appetizers',
      price: 3.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Samsa',
      rating: 4.6,
      description: 'Flaky pastry filled with lamb, onions, and spices',
    ),
    ProductModel(
      id: '5',
      name: 'Shurpa',
      category: 'Soups',
      price: 7.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Shurpa',
      rating: 4.5,
      description: 'Hearty lamb soup with vegetables and herbs',
    ),
    ProductModel(
      id: '6',
      name: 'Mastava',
      category: 'Soups',
      price: 6.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Mastava',
      rating: 4.4,
      description: 'Rice soup with meat and fresh vegetables',
    ),
    ProductModel(
      id: '7',
      name: 'Chak-Chak',
      category: 'Desserts',
      price: 5.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Chak-Chak',
      rating: 4.7,
      description: 'Sweet honey pastry with crispy dough pieces',
    ),
    ProductModel(
      id: '8',
      name: 'Halva',
      category: 'Desserts',
      price: 4.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Halva',
      rating: 4.6,
      description: 'Traditional sweet made from sesame seeds and honey',
    ),
    ProductModel(
      id: '9',
      name: 'Shashlik',
      category: 'Main Dishes',
      price: 14.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Shashlik',
      rating: 4.8,
      description: 'Grilled marinated meat skewers with onions',
    ),
    ProductModel(
      id: '10',
      name: 'Achichuk Salad',
      category: 'Salads',
      price: 4.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Achichuk',
      rating: 4.3,
      description: 'Fresh tomato and onion salad with herbs',
    ),
    ProductModel(
      id: '11',
      name: 'Dimlama',
      category: 'Main Dishes',
      price: 13.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Dimlama',
      rating: 4.7,
      description: 'Slow-cooked meat stew with layers of vegetables',
    ),
    ProductModel(
      id: '12',
      name: 'Non (Flatbread)',
      category: 'Breads',
      price: 2.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Non',
      rating: 4.9,
      description: 'Traditional round flatbread baked in tandoor oven',
    ),
  ];

  static List<String> get categories {
    final categorySet = <String>{};
    for (var product in products) {
      categorySet.add(product.category);
    }
    return categorySet.toList();
  }

  static List<ProductModel> getProductsByCategory(String category) {
    return products.where((product) => product.category == category).toList();
  }
}
