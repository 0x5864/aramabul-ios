import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/venue.dart';
import '../services/venue_service.dart';
import 'venue_detail_screen.dart';

/// Interactive native map screen showing venues on Apple-style map.
/// Key native feature for Apple Guideline 4.2.2 — this experience
/// is impossible to replicate in a mobile web browser.
class MapExploreScreen extends StatefulWidget {
  const MapExploreScreen({super.key});

  @override
  State<MapExploreScreen> createState() => _MapExploreScreenState();
}

class _MapExploreScreenState extends State<MapExploreScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  List<Venue> _venues = [];
  Venue? _selectedVenue;
  bool _isLoading = true;
  Position? _currentPosition;
  String _selectedCategory = '';

  // Istanbul center default
  static const _istanbulCenter = LatLng(41.0082, 28.9784);

  static const List<_MapCategory> _categories = [
    _MapCategory('Tümü', Icons.apps_rounded),
    _MapCategory('Restoran', Icons.restaurant_rounded),
    _MapCategory('Kafe', Icons.coffee_rounded),
    _MapCategory('Bar', Icons.local_bar_rounded),
    _MapCategory('Otel', Icons.hotel_rounded),
    _MapCategory('Gece Hayatı', Icons.nightlife_rounded),
    _MapCategory('Müze', Icons.museum_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _initLocationAndLoad();
  }

  Future<void> _initLocationAndLoad() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {}
    } else if (status.isDenied) {
      final result = await Permission.locationWhenInUse.request();
      if (result.isGranted) {
        try {
          _currentPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 10),
            ),
          );
        } catch (_) {}
      }
    }
    await _loadVenues();
  }

  Future<void> _loadVenues({String? category}) async {
    setState(() => _isLoading = true);
    try {
      final lat = _currentPosition?.latitude ?? _istanbulCenter.latitude;
      final lng = _currentPosition?.longitude ?? _istanbulCenter.longitude;
      final venues = await VenueService.fetchNearbyVenues(
        latitude: lat,
        longitude: lng,
        category: category,
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        if (venues.isNotEmpty) {
          _venues = venues;
        } else {
          // Fallback: show hardcoded venues so map is never empty
          final all = VenueService.fallbackVenues;
          _venues = (category != null && category.isNotEmpty)
              ? all.where((v) => v.category == category).toList()
              : all;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[MapExplore] Error: $e');
      if (!mounted) return;
      setState(() {
        // Fallback on error
        final all = VenueService.fallbackVenues;
        _venues = (category != null && category.isNotEmpty)
            ? all.where((v) => v.category == category).toList()
            : all;
        _isLoading = false;
      });
    }
  }

  void _onCategoryTap(String category) {
    HapticFeedback.selectionClick();
    final cat = category == 'Tümü' ? '' : category;
    setState(() {
      _selectedCategory = cat;
      _selectedVenue = null;
    });
    _loadVenues(category: cat.isNotEmpty ? cat : null);
  }

  void _onMarkerTap(Venue venue) {
    HapticFeedback.mediumImpact();
    setState(() => _selectedVenue = venue);

    // Animate map to venue
    if (venue.latitude != null && venue.longitude != null) {
      _animateMapTo(LatLng(venue.latitude!, venue.longitude!));
    }
  }

  void _animateMapTo(LatLng target) {
    final startZoom = _mapController.camera.zoom;
    final startCenter = _mapController.camera.center;

    final latTween = Tween<double>(
      begin: startCenter.latitude,
      end: target.latitude,
    );
    final lngTween = Tween<double>(
      begin: startCenter.longitude,
      end: target.longitude,
    );
    final zoomTween = Tween<double>(begin: startZoom, end: 15.0);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _goToMyLocation() {
    HapticFeedback.lightImpact();
    if (_currentPosition != null) {
      _animateMapTo(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      );
    }
  }

  void _openVenueDetail(Venue venue) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VenueDetailScreen(venue: venue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _istanbulCenter;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              onTap: (_, __) => setState(() => _selectedVenue = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.aramabul.app',
              ),
              // Venue markers
              MarkerLayer(
                markers: _buildMarkers(),
              ),
              // User location marker
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2980b9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2980b9).withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Top safe area gradient ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Category filter bar ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat.label ||
                      (_selectedCategory.isEmpty && cat.label == 'Tümü');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _onCategoryTap(cat.label),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF094174)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icon,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF094174),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1a1a1a),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Loading indicator ──
          if (_isLoading)
            const Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF094174),
                ),
              ),
            ),

          // ── My Location button ──
          if (_currentPosition != null)
            Positioned(
              right: 16,
              bottom: _selectedVenue != null ? 220 : 24,
              child: GestureDetector(
                onTap: _goToMyLocation,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFF094174),
                    size: 24,
                  ),
                ),
              ),
            ),

          // ── Venue count badge ──
          Positioned(
            left: 16,
            bottom: _selectedVenue != null ? 220 : 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF094174),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${_venues.length} mekan',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // ── Selected venue card ──
          if (_selectedVenue != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _VenueMapCard(
                venue: _selectedVenue!,
                onTap: () => _openVenueDetail(_selectedVenue!),
                onClose: () => setState(() => _selectedVenue = null),
              ),
            ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return _venues
        .where((v) => v.latitude != null && v.longitude != null)
        .map((venue) {
      final isSelected = _selectedVenue?.id == venue.id;
      return Marker(
        point: LatLng(venue.latitude!, venue.longitude!),
        width: isSelected ? 48 : 36,
        height: isSelected ? 48 : 36,
        child: GestureDetector(
          onTap: () => _onMarkerTap(venue),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFe74c3c)
                  : const Color(0xFF094174),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected
                          ? const Color(0xFFe74c3c)
                          : const Color(0xFF094174))
                      .withValues(alpha: 0.4),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _getCategoryIcon(venue.category),
              color: Colors.white,
              size: isSelected ? 22 : 16,
            ),
          ),
        ),
      );
    }).toList();
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'restoran':
        return Icons.restaurant_rounded;
      case 'kafe':
        return Icons.coffee_rounded;
      case 'bar':
        return Icons.local_bar_rounded;
      case 'otel':
        return Icons.hotel_rounded;
      case 'gece hayatı':
        return Icons.nightlife_rounded;
      case 'müze':
        return Icons.museum_rounded;
      case 'alışveriş':
        return Icons.shopping_bag_rounded;
      case 'park':
        return Icons.park_rounded;
      default:
        return Icons.place_rounded;
    }
  }
}

// ---------------------------------------------------------------------------
// Map category model
// ---------------------------------------------------------------------------

class _MapCategory {
  final String label;
  final IconData icon;
  const _MapCategory(this.label, this.icon);
}

// ---------------------------------------------------------------------------
// Venue card shown when a marker is tapped
// ---------------------------------------------------------------------------

class _VenueMapCard extends StatelessWidget {
  final Venue venue;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _VenueMapCard({
    required this.venue,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: venue.imageUrl != null && venue.imageUrl!.isNotEmpty
                    ? Image.network(
                        venue.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: Center(
                            child: Image.asset(
                              'assets/no_image.png',
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF1F5F9),
                        child: Center(
                          child: Image.asset(
                            'assets/no_image.png',
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    venue.name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1a1a1a),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [venue.category, venue.district]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(' · '),
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF1a1a1a).withValues(alpha: 0.5),
                    ),
                  ),
                  if (venue.rating != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: Color(0xFFf59e0b)),
                        const SizedBox(width: 3),
                        Text(
                          venue.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1a1a1a),
                          ),
                        ),
                        if (venue.reviewCount != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${venue.reviewCount})',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF1a1a1a)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF094174),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Detay →',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Close button
            GestureDetector(
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: const Color(0xFF1a1a1a).withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
