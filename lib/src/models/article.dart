

class Article {
  
  int id;
  String title;
  String? description;
  String url;
  DateTime? publishDate;

  Article({
    required this.id,
    required this.title,
    this.description,
    required this.url,
    this.publishDate
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    url: json['url'],
    publishDate: json['publishDate']
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'url': url,
    'publishDate': publishDate,
  };
}