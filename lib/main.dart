import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/favorites_service.dart';
import 'models/book.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(const BookSearchApp());
}

class BookSearchApp extends StatelessWidget {
  const BookSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Book Search',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const BookSearchScreen(),
    const FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}

class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({super.key});

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final ApiService _apiService = ApiService();
  final FavoritesService _favoritesService = FavoritesService();
  final TextEditingController _controller = TextEditingController();
  List<Book> _books = [];
  bool _isLoading = false;
  String? _error;

  void _searchBooks(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final books = await _apiService.searchBooks(query);
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load books. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _toggleFavorite(Book book) async {
    final isFavorite = await _favoritesService.isFavorite(book.key);
    if (isFavorite) {
      await _favoritesService.removeFavorite(book.key);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${book.title} removed from favorites')),
      );
    } else {
      await _favoritesService.addFavorite(book);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${book.title} added to favorites')),
      );
    }
    setState(() {}); // Refresh UI to update heart icon
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search for books...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchBooks(_controller.text),
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: _searchBooks,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _books.isEmpty
                          ? const Center(child: Text('Search for a book!'))
                          : ListView.builder(
                              itemCount: _books.length,
                              itemBuilder: (context, index) {
                                final book = _books[index];
                                return Card(
                                  child: ListTile(
                                    leading: book.coverUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: book.coverUrl!,
                                            width: 50,
                                            height: 50,
                                            placeholder: (context, url) =>
                                                const CircularProgressIndicator(),
                                            errorWidget: (context, url, error) =>
                                                const Icon(Icons.error),
                                          )
                                        : const Icon(Icons.book, size: 50),
                                    title: Text(book.title),
                                    subtitle: book.authors != null
                                        ? Text(book.authors!.join(', '))
                                        : const Text('Unknown Author'),
                                    trailing: FutureBuilder<bool>(
                                      future:
                                          _favoritesService.isFavorite(book.key),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const CircularProgressIndicator();
                                        }
                                        final isFavorite = snapshot.data ?? false;
                                        return IconButton(
                                          icon: Icon(
                                            isFavorite
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color:
                                                isFavorite ? Colors.red : null,
                                          ),
                                          onPressed: () => _toggleFavorite(book),
                                        );
                                      },
                                    ),
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

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();

  void _removeFavorite(Book book) async {
    await _favoritesService.removeFavorite(book.key);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${book.title} removed from favorites')),
    );
    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: FutureBuilder<List<Book>>(
        future: _favoritesService.getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading favorites'));
          }
          final favorites = snapshot.data ?? [];
          if (favorites.isEmpty) {
            return const Center(child: Text('No favorite books yet!'));
          }
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final book = favorites[index];
              return Card(
                child: ListTile(
                  leading: book.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: book.coverUrl!,
                          width: 50,
                          height: 50,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        )
                      : const Icon(Icons.book, size: 50),
                  title: Text(book.title),
                  subtitle: book.authors != null
                      ? Text(book.authors!.join(', '))
                      : const Text('Unknown Author'),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () => _removeFavorite(book),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}