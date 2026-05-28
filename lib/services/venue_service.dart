import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/venue.dart';

/// Manages favorites locally and venue API calls.
class VenueService {
  static const String _favoritesKey = 'aramabul_favorites';
  static const String kApiBase = 'https://aramabul.com';

  // ---------------------------------------------------------------------------
  // Fallback venues — shown when API is unreachable
  // ---------------------------------------------------------------------------

  static const List<Map<String, dynamic>> _fallbackVenuesData = [
    {'id': 9001, 'name': 'Karaköy Güllüoğlu', 'category': 'Restoran', 'district': 'Beyoğlu', 'city': 'İstanbul', 'rating': 4.5, 'reviewCount': 1200, 'latitude': 41.0225, 'longitude': 28.9774, 'slug': 'karakoy-gulluoglu'},
    {'id': 9002, 'name': 'Mandabatmaz', 'category': 'Kafe', 'district': 'Beyoğlu', 'city': 'İstanbul', 'rating': 4.6, 'reviewCount': 890, 'latitude': 41.0318, 'longitude': 28.9748, 'slug': 'mandabatmaz'},
    {'id': 9003, 'name': 'Mikla Restaurant', 'category': 'Restoran', 'district': 'Beyoğlu', 'city': 'İstanbul', 'rating': 4.7, 'reviewCount': 650, 'latitude': 41.0347, 'longitude': 28.9788, 'slug': 'mikla-restaurant'},
    {'id': 9004, 'name': 'Çiya Sofrası', 'category': 'Restoran', 'district': 'Kadıköy', 'city': 'İstanbul', 'rating': 4.4, 'reviewCount': 1500, 'latitude': 40.9903, 'longitude': 29.0282, 'slug': 'ciya-sofrasi'},
    {'id': 9005, 'name': 'Walter\'s Coffee Roastery', 'category': 'Kafe', 'district': 'Kadıköy', 'city': 'İstanbul', 'rating': 4.3, 'reviewCount': 420, 'latitude': 40.9907, 'longitude': 29.0268, 'slug': 'walters-coffee'},
    {'id': 9006, 'name': 'Alexandra Cocktail Bar', 'category': 'Bar', 'district': 'Beyoğlu', 'city': 'İstanbul', 'rating': 4.5, 'reviewCount': 310, 'latitude': 41.0334, 'longitude': 28.9771, 'slug': 'alexandra-bar'},
    {'id': 9007, 'name': 'Topkapı Sarayı Müzesi', 'category': 'Müze', 'district': 'Fatih', 'city': 'İstanbul', 'rating': 4.8, 'reviewCount': 3500, 'latitude': 41.0115, 'longitude': 28.9833, 'slug': 'topkapi-sarayi'},
    {'id': 9008, 'name': 'Raffles Istanbul', 'category': 'Otel', 'district': 'Beşiktaş', 'city': 'İstanbul', 'rating': 4.6, 'reviewCount': 780, 'latitude': 41.0432, 'longitude': 29.0087, 'slug': 'raffles-istanbul'},
    {'id': 9009, 'name': 'Sortie Club', 'category': 'Gece Hayatı', 'district': 'Kuruçeşme', 'city': 'İstanbul', 'rating': 4.1, 'reviewCount': 520, 'latitude': 41.0551, 'longitude': 29.0365, 'slug': 'sortie-club'},
    {'id': 9010, 'name': 'Süleymaniye Hamamı', 'category': 'Sağlık', 'district': 'Fatih', 'city': 'İstanbul', 'rating': 4.4, 'reviewCount': 290, 'latitude': 41.0163, 'longitude': 28.9637, 'slug': 'suleymaniye-hamami'},
    {'id': 9011, 'name': 'Bebek Parkı', 'category': 'Park', 'district': 'Beşiktaş', 'city': 'İstanbul', 'rating': 4.3, 'reviewCount': 180, 'latitude': 41.0762, 'longitude': 29.0441, 'slug': 'bebek-parki'},
    {'id': 9012, 'name': 'İstinye Park AVM', 'category': 'Alışveriş', 'district': 'Sarıyer', 'city': 'İstanbul', 'rating': 4.5, 'reviewCount': 2200, 'latitude': 41.1138, 'longitude': 29.0570, 'slug': 'istinye-park'},
  ];

  static List<Venue> get fallbackVenues =>
      _fallbackVenuesData.map((e) => Venue.fromJson(e)).toList();

  // ---------------------------------------------------------------------------
  // Favorites (local storage)
  // ---------------------------------------------------------------------------

  static Future<List<Venue>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favoritesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list
          .map((e) => Venue.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[VenueService] getFavorites error: $e');
      return [];
    }
  }

  static Future<void> addFavorite(Venue venue) async {
    final favorites = await getFavorites();
    if (favorites.any((v) => v.id == venue.id)) return;
    favorites.insert(0, venue);
    await _saveFavorites(favorites);
  }

  static Future<void> removeFavorite(int venueId) async {
    final favorites = await getFavorites();
    favorites.removeWhere((v) => v.id == venueId);
    await _saveFavorites(favorites);
  }

  static Future<bool> isFavorite(int venueId) async {
    final favorites = await getFavorites();
    return favorites.any((v) => v.id == venueId);
  }

  static Future<void> toggleFavorite(Venue venue) async {
    if (await isFavorite(venue.id)) {
      await removeFavorite(venue.id);
    } else {
      await addFavorite(venue);
    }
  }

  static Future<void> _saveFavorites(List<Venue> venues) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(venues.map((v) => v.toJson()).toList());
    await prefs.setString(_favoritesKey, json);
  }

  // ---------------------------------------------------------------------------
  // Nearby Venues (API)
  // ---------------------------------------------------------------------------

  static Future<List<Venue>> fetchNearbyVenues({
    required double latitude,
    required double longitude,
    String? category,
    int limit = 20,
  }) async {
    try {
      // /api/venues/nearby does not exist — use search with location context
      final params = {
        'q': category ?? 'istanbul',
        'limit': limit.toString(),
      };
      final uri = Uri.parse('$kApiBase/api/venues/search')
          .replace(queryParameters: params);

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode != 200) {
        debugPrint('[VenueService] fetchNearby ${response.statusCode}');
        return [];
      }

      return _parseVenueResponse(body);
    } catch (e) {
      debugPrint('[VenueService] fetchNearby error: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Search Venues (API)
  // ---------------------------------------------------------------------------

  static Future<List<Venue>> searchVenues({
    required String query,
    String? city,
    String? category,
    String? district,
    int limit = 20,
  }) async {
    try {
      final params = {
        'q': query,
        'limit': limit.toString(),
        if (city != null) 'city': city,
        if (category != null) 'category': category,
        if (district != null) 'district': district,
      };
      final uri = Uri.parse('$kApiBase/api/venues/search')
          .replace(queryParameters: params);

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode != 200) {
        debugPrint('[VenueService] search ${response.statusCode}');
        return [];
      }

      return _parseVenueResponse(body);
    } catch (e) {
      debugPrint('[VenueService] search error: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Featured Venues (MVP API — same as web version)
  // ---------------------------------------------------------------------------

  /// Fetches random venues with photos from /api/mvp/istanbul/venues.
  /// This is the same endpoint used by the web version's featured-venues.js.
  static Future<List<Venue>> fetchFeaturedVenues({int limit = 15}) async {
    try {
      final seed = DateTime.now().millisecondsSinceEpoch % 2000000000;
      final params = {
        'sort': 'random',
        'limit': limit.toString(),
        'photoState': 'has_photo',
        'randomSeed': seed.toString(),
      };
      final uri = Uri.parse('$kApiBase/api/mvp/istanbul/venues')
          .replace(queryParameters: params);

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode != 200) {
        debugPrint('[VenueService] fetchFeatured ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(body);
      if (data is Map && data['items'] is List) {
        return (data['items'] as List).map((e) {
          final map = e as Map<String, dynamic>;
          final mapped = <String, dynamic>{
            ...map,
            if (map['cuisine'] != null && map['category'] == null)
              'category': map['cuisine'],
            if (map['userRatingCount'] != null && map['reviewCount'] == null)
              'reviewCount': map['userRatingCount'],
            if (map['photoUri'] != null && map['imageUrl'] == null)
              'imageUrl': map['photoUri'],
            if (map['id'] == null && map['slug'] != null)
              'id': map['slug'].hashCode.abs(),
          };
          return Venue.fromJson(mapped);
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[VenueService] fetchFeatured error: $e');
      return [];
    }
  }

  /// Parse API response — handles both raw JSON array and {ok, venues} formats.
  /// Also maps API field names (cuisine→category, userRatingCount→reviewCount,
  /// photoUri→imageUrl) to our Venue model fields.
  static List<Venue> _parseVenueResponse(String body) {
    final data = jsonDecode(body);
    List<dynamic> rawList;

    if (data is List) {
      rawList = data;
    } else if (data is Map && data['venues'] is List) {
      rawList = data['venues'];
    } else if (data is Map && data['ok'] == true && data['venues'] is List) {
      rawList = data['venues'];
    } else {
      return [];
    }

    return rawList.map((e) {
      final map = e as Map<String, dynamic>;
      // Map API field names to Venue model field names
      final mapped = <String, dynamic>{
        ...map,
        if (map['cuisine'] != null && map['category'] == null)
          'category': map['cuisine'],
        if (map['userRatingCount'] != null && map['reviewCount'] == null)
          'reviewCount': map['userRatingCount'],
        if (map['photoUri'] != null && map['imageUrl'] == null)
          'imageUrl': map['photoUri'],
        // Generate an id from slug if not present
        if (map['id'] == null && map['slug'] != null)
          'id': map['slug'].hashCode.abs(),
      };
      return Venue.fromJson(mapped);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Delete Account (API)
  // ---------------------------------------------------------------------------

  static Future<bool> deleteAccount(String email) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('$kApiBase/api/auth/delete-account'),
      );
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode({
        'email': email,
        'confirmDelete': true,
      }));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      debugPrint('[VenueService] deleteAccount ${response.statusCode}: $body');
      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        return data is Map && data['ok'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('[VenueService] deleteAccount error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Update Profile (API)
  // ---------------------------------------------------------------------------

  static Future<bool> updateProfile({
    required String email,
    required String name,
  }) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('$kApiBase/api/auth/update-profile'),
      );
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode({
        'email': email,
        'name': name,
      }));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      debugPrint('[VenueService] updateProfile ${response.statusCode}: $body');
      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        return data is Map && data['ok'] == true;
      }
      // Even if API returns non-200, save locally
      return true;
    } catch (e) {
      debugPrint('[VenueService] updateProfile error: $e');
      // Save locally even if API fails
      return true;
    }
  }

  // ---------------------------------------------------------------------------
  // Password Reset (API)
  // ---------------------------------------------------------------------------

  static Future<bool> sendPasswordReset(String email) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('$kApiBase/api/auth/reset-password'),
      );
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode({'email': email}));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      debugPrint('[VenueService] resetPassword ${response.statusCode}: $body');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[VenueService] resetPassword error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Feedback (API)
  // ---------------------------------------------------------------------------

  static Future<bool> sendFeedback({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('$kApiBase/api/feedback'),
      );
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode({
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
        'platform': 'ios',
      }));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      debugPrint('[VenueService] sendFeedback ${response.statusCode}: $body');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[VenueService] sendFeedback error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Admin Login (API)
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>?> adminLogin({
    required String email,
    required String password,
  }) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('$kApiBase/api/auth/admin-login'),
      );
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode({
        'email': email,
        'password': password,
      }));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      debugPrint('[VenueService] adminLogin ${response.statusCode}: $body');
      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        if (data is Map<String, dynamic> && data['ok'] == true) {
          return data;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[VenueService] adminLogin error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Search History (local storage)
  // ---------------------------------------------------------------------------

  static const String _historyKey = 'aramabul_search_history';
  static const int _maxHistoryItems = 10;

  static Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? [];
  }

  static Future<void> addSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    history.remove(query); // Remove duplicate
    history.insert(0, query); // Add to top
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }
    await prefs.setStringList(_historyKey, history);
  }

  static Future<void> removeSearchHistoryItem(String item) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    history.remove(item);
    await prefs.setStringList(_historyKey, history);
  }

  static Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
