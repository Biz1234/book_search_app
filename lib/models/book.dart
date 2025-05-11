class Book {
  final String key;
  final String title;
  final List<String>? authors;
  final String? coverUrl;

  Book({
    required this.key,
    required this.title,
    this.authors,
    this.coverUrl,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    String? coverUrl;
    if (json['cover_i'] != null) {
      coverUrl = 'https://covers.openlibrary.org/b/id/${json['cover_i']}-M.jpg';
    }

    return Book(
      key: json['key'] ?? json['title'],
      title: json['title'] ?? 'Unknown Title',
      authors: json['author_name'] != null
          ? List<String>.from(json['author_name'])
          : null,
      coverUrl: coverUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'author_name': authors,
      'cover_i': coverUrl != null ? coverUrl!.split('/id/')[1].split('-M.jpg')[0] : null,
    };
  }
}