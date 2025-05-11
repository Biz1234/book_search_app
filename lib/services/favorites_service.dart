import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_books';

  Future<List<Book>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
    return favoritesJson
        .map((json) => Book.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> addFavorite(Book book) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    if (!favorites.any((b) => b.key == book.key)) {
      favorites.add(book);
      final favoritesJson =
          favorites.map((b) => jsonEncode(b.toJson())).toList();
      await prefs.setStringList(_favoritesKey, favoritesJson);
    }
  }

  Future<void> removeFavorite(String bookKey) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.removeWhere((b) => b.key == bookKey);
    final favoritesJson = favorites.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList(_favoritesKey, favoritesJson);
  }

  Future<bool> isFavorite(String bookKey) async {
    final favorites = await getFavorites();
    return favorites.any((b) => b.key == bookKey);
  }
}