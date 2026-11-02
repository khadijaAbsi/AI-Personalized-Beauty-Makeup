import 'package:flutter/material.dart';

class FavoritesService extends ChangeNotifier {
  FavoritesService._();

  static final FavoritesService instance = FavoritesService._();

  final List<Map<String, dynamic>> products = [];

  bool isFavorite(String name) {
    return products.any((product) => product['name'] == name);
  }

  void toggleFavorite(Map<String, dynamic> product) {
    final index = products.indexWhere(
      (item) => item['name'] == product['name'],
    );

    if (index >= 0) {
      products.removeAt(index);
    } else {
      products.add(product);
    }

    notifyListeners();
  }

  void removeAt(int index) {
    if (index >= 0 && index < products.length) {
      products.removeAt(index);
      notifyListeners();
    }
  }
}
