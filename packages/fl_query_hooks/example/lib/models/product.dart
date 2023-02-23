class Product {
  int id;
  String title;
  String description;
  double price;
  double discountPercentage;
  double rating;
  double stock;
  String brand;
  String category;
  String thumbnail;
  List<String> images;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.brand,
    required this.category,
    required this.thumbnail,
    required this.images,
  });

  Product.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        description = json['description'],
        price = json['price'].toDouble(),
        discountPercentage = json['discountPercentage'].toDouble(),
        rating = json['rating'].toDouble(),
        stock = json['stock'].toDouble(),
        brand = json['brand'],
        category = json['category'],
        thumbnail = json['thumbnail'],
        images = json['images'].cast<String>();

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'discountPercentage': discountPercentage,
      'rating': rating,
      'stock': stock,
      'brand': brand,
      'category': category,
      'thumbnail': thumbnail,
      'images': images,
    };
    return data;
  }
}

class PagedProducts {
  List<Product> products;
  int total;
  int skip;
  int limit;

  PagedProducts({
    this.products = const [],
    required this.total,
    required this.skip,
    required this.limit,
  });

  PagedProducts.fromJson(Map<String, dynamic> json)
      : products = json['products']
                ?.map<Product>((v) => Product.fromJson(
                      Map.castFrom<dynamic, dynamic, String, dynamic>(v),
                    ))
                .toList() ??
            [],
        total = json['total'],
        skip = json['skip'],
        limit = json['limit'];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'products': products.map((v) => v.toJson()).toList(),
      'total': total,
      'skip': skip,
      'limit': limit,
    };
    return data;
  }
}
