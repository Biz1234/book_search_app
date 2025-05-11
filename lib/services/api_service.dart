import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class ApiService {
  static const String _baseUrl = 'https://openlibrary.org';

  Future<List<Book>> searchBooks(String query) async {
    final response = await http.get(Uri.parse('$_baseUrl/search.json?q=$query'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> docs = data['docs'] ?? [];
      return docs.map((json) => Book.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }
}