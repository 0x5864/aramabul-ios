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
      final params = {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'limit': limit.toString(),
        if (category != null) 'category': category,
      };
      final uri = Uri.parse('$kApiBase/api/venues/nearby')
          .replace(queryParameters: params);

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode != 200) {
        debugPrint('[VenueService] fetchNearby ${response.statusCode}: $body');
        return [];
      }

      final data = jsonDecode(body);
      if (data is Map && data['ok'] == true && data['venues'] is List) {
        return (data['venues'] as List)
            .map((e) => Venue.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
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
    int limit = 20,
  }) async {
    try {
      final params = {
        'q': query,
        'limit': limit.toString(),
        if (city != null) 'city': city,
        if (category != null) 'category': category,
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
        debugPrint('[VenueService] search ${response.statusCode}: $body');
        return [];
      }

      final data = jsonDecode(body);
      if (data is Map && data['ok'] == true && data['venues'] is List) {
        return (data['venues'] as List)
            .map((e) => Venue.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[VenueService] search error: $e');
      return [];
    }
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
