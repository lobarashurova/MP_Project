import '../models/meal_model.dart';

class MockProducts {
  static final List<MealModel> products = [
    // ----------------- MAIN DISHES -----------------
    MealModel(
      id: '1',
      name: 'Plov (Uzbek Pilaf)',
      category: 'Main Dishes',
      price: 12.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Plov',
      rating: 4.9,
      description: 'Traditional Uzbek rice dish with lamb, carrots, and aromatic spices',
    ),
    MealModel(
      id: '2',
      name: 'Lagman',
      category: 'Main Dishes',
      price: 10.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Lagman',
      rating: 4.7,
      description: 'Hand-pulled noodles with meat and vegetables in savory broth',
    ),
    MealModel(
      id: '3',
      name: 'Shashlik',
      category: 'Main Dishes',
      price: 14.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Shashlik',
      rating: 4.8,
      description: 'Grilled marinated meat skewers served with onions',
    ),
    MealModel(
      id: '4',
      name: 'Dimlama',
      category: 'Main Dishes',
      price: 13.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Dimlama',
      rating: 4.7,
      description: 'Slow-cooked stew of meat and layered vegetables',
    ),
    MealModel(
      id: '5',
      name: 'Kazan Kabob',
      category: 'Main Dishes',
      price: 15.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Kazan+Kabob',
      rating: 4.8,
      description: 'Crispy fried meat and potatoes cooked in a cauldron',
    ),
    MealModel(
      id: '6',
      name: 'Norin',
      category: 'Main Dishes',
      price: 9.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Norin',
      rating: 4.5,
      description: 'Cold noodle dish with finely chopped horse meat',
    ),

    // ----------------- APPETIZERS -----------------
    MealModel(
      id: '7',
      name: 'Manti',
      category: 'Appetizers',
      price: 8.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Manti',
      rating: 4.8,
      description: 'Steamed dumplings filled with spiced meat and onions',
    ),
    MealModel(
      id: '8',
      name: 'Samsa',
      category: 'Appetizers',
      price: 3.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Samsa',
      rating: 4.6,
      description: 'Flaky pastry stuffed with lamb and onion mixture',
    ),
    MealModel(
      id: '9',
      name: 'Chuchvara',
      category: 'Appetizers',
      price: 6.49,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Chuchvara',
      rating: 4.7,
      description: 'Small dumplings served with broth or sour cream',
    ),
    MealModel(
      id: '10',
      name: 'Kazi',
      category: 'Appetizers',
      price: 11.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Kazi',
      rating: 4.6,
      description: 'Traditional horse meat sausage served cold',
    ),

    // ----------------- SOUPS -----------------
    MealModel(
      id: '11',
      name: 'Shurpa',
      category: 'Soups',
      price: 7.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Shurpa',
      rating: 4.5,
      description: 'Aromatic lamb soup with fresh vegetables',
    ),
    MealModel(
      id: '12',
      name: 'Mastava',
      category: 'Soups',
      price: 6.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Mastava',
      rating: 4.4,
      description: 'Rice soup with meat, vegetables, and herbs',
    ),
    MealModel(
      id: '13',
      name: 'Ugro Supi',
      category: 'Soups',
      price: 6.49,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Ugro+Soup',
      rating: 4.3,
      description: 'Noodle soup with vegetables and beef pieces',
    ),

    // ----------------- SALADS -----------------
    MealModel(
      id: '14',
      name: 'Achichuk Salad',
      category: 'Salads',
      price: 4.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Achichuk',
      rating: 4.3,
      description: 'Fresh tomato and onion salad with herbs',
    ),
    MealModel(
      id: '15',
      name: 'Baqlajon Salati',
      category: 'Salads',
      price: 5.49,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Baqlajon',
      rating: 4.6,
      description: 'Grilled eggplant salad with tomatoes and garlic',
    ),
    MealModel(
      id: '16',
      name: 'Tashkent Salad',
      category: 'Salads',
      price: 7.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Tashkent',
      rating: 4.7,
      description: 'Beef, radish, and greens with creamy dressing',
    ),

    // ----------------- BREADS -----------------
    MealModel(
      id: '17',
      name: 'Non (Flatbread)',
      category: 'Breads',
      price: 2.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Non',
      rating: 4.9,
      description: 'Traditional round flatbread baked in tandoor',
    ),
    MealModel(
      id: '18',
      name: 'Katlama',
      category: 'Breads',
      price: 3.49,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Katlama',
      rating: 4.6,
      description: 'Layered crispy bread fried in oil',
    ),

    // ----------------- DESSERTS -----------------
    MealModel(
      id: '19',
      name: 'Chak-Chak',
      category: 'Desserts',
      price: 5.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Chak+Chak',
      rating: 4.7,
      description: 'Honey-soaked fried dough pieces',
    ),
    MealModel(
      id: '20',
      name: 'Halva',
      category: 'Desserts',
      price: 4.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Halva',
      rating: 4.6,
      description: 'Sweet sesame paste dessert',
    ),
    MealModel(
      id: '21',
      name: 'Nisholda',
      category: 'Desserts',
      price: 3.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Nisholda',
      rating: 4.5,
      description: 'Foamy whipped sugar dessert with herbs',
    ),
    MealModel(
      id: '22',
      name: 'Sumalak',
      category: 'Desserts',
      price: 6.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Sumalak',
      rating: 4.9,
      description: 'Traditional wheat sprout dessert cooked for hours',
    ),

    // ----------------- DRINKS -----------------
    MealModel(
      id: '23',
      name: 'Kefir',
      category: 'Drinks',
      price: 2.49,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Kefir',
      rating: 4.4,
      description: 'Fermented milk drink served chilled',
    ),
    MealModel(
      id: '24',
      name: 'Ayran',
      category: 'Drinks',
      price: 2.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Ayran',
      rating: 4.5,
      description: 'Refreshing yogurt-based drink with salt',
    ),
    MealModel(
      id: '25',
      name: 'Uzbek Tea',
      category: 'Drinks',
      price: 1.99,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Tea',
      rating: 5.0,
      description: 'Green tea served in a traditional piala cup',
    ),
    MealModel(
      id: '26',
      name: 'Kompot',
      category: 'Drinks',
      price: 2.49,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Kompot',
      rating: 4.6,
      description: 'Sweet drink made from dried fruits',
    ),
    MealModel(
      id: '27',
      name: 'Coca Cola',
      category: 'Drinks',
      price: 2.49,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=CocaCola',
      rating: 4.6,
      description: 'Popular soda',
    ),
    MealModel(
      id: '28',
      name: 'Fanta',
      category: 'Drinks',
      price: 2.49,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Fanta',
      rating: 4.6,
      description: 'Popular soda',
    ),
    MealModel(
      id: '29',
      name: 'Sprite',
      category: 'Drinks',
      price: 2.49,
      imageUrl: 'https://via.placeholder.com/300x300/E65E07/FFFFFF?text=Sprite',
      rating: 4.6,
      description: 'Popular soda',
    ),
  ];

  static List<String> get categories {
    final categorySet = <String>{};
    for (var product in products) {
      categorySet.add(product.category);
    }
    return categorySet.toList();
  }

  static List<MealModel> getProductsByCategory(String category) {
    return products.where((product) => product.category == category).toList();
  }
}
