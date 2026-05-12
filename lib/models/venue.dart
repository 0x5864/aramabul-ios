/// Simple venue model used by native screens.
class Venue {
  final int id;
  final String name;
  final String category;
  final String? subcategory;
  final String? city;
  final String? district;
  final String? address;
  final String? phone;
  final String? website;
  final String? mapsUrl;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? reviewCount;
  final String? imageUrl;
  final String? slug;
  final bool isFavorite;

  const Venue({
    required this.id,
    required this.name,
    required this.category,
    this.subcategory,
    this.city,
    this.district,
    this.address,
    this.phone,
    this.website,
    this.mapsUrl,
    this.latitude,
    this.longitude,
    this.rating,
    this.reviewCount,
    this.imageUrl,
    this.slug,
    this.isFavorite = false,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      subcategory: json['subcategory']?.toString(),
      city: json['city']?.toString() ?? json['il']?.toString(),
      district: json['district']?.toString() ?? json['ilce']?.toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      website: json['website']?.toString(),
      mapsUrl: json['mapsUrl']?.toString() ?? json['maps_url']?.toString(),
      latitude: _parseDouble(json['latitude'] ?? json['lat']),
      longitude: _parseDouble(json['longitude'] ?? json['lng'] ?? json['lon']),
      rating: _parseDouble(json['rating']),
      reviewCount: json['reviewCount'] is int
          ? json['reviewCount']
          : int.tryParse('${json['reviewCount'] ?? json['review_count'] ?? ''}'),
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      slug: json['slug']?.toString(),
    );
  }

  Venue copyWith({bool? isFavorite}) {
    return Venue(
      id: id,
      name: name,
      category: category,
      subcategory: subcategory,
      city: city,
      district: district,
      address: address,
      phone: phone,
      website: website,
      mapsUrl: mapsUrl,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
      reviewCount: reviewCount,
      imageUrl: imageUrl,
      slug: slug,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'subcategory': subcategory,
    'city': city,
    'district': district,
    'address': address,
    'phone': phone,
    'website': website,
    'mapsUrl': mapsUrl,
    'latitude': latitude,
    'longitude': longitude,
    'rating': rating,
    'reviewCount': reviewCount,
    'imageUrl': imageUrl,
    'slug': slug,
  };

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse('$v');
  }
}
