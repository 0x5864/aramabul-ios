import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

import '../models/venue.dart';
import '../services/venue_service.dart';
import 'search_screen.dart';
import 'venue_detail_screen.dart';

/// Native explore screen — provides category browsing and nearby venue
/// discovery without relying on WebView.
/// This screen is the primary answer to Apple Guideline 4.2.2.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Venue> _nearbyVenues = [];
  List<Venue> _popularVenues = [];
  bool _isLoadingNearby = false;
  bool _isLoadingPopular = true;
  bool _locationGranted = false;
  Position? _currentPosition;
  String _selectedCategory = '';

  static const List<_CategoryItem> _categories = [
    _CategoryItem('Restoran', Icons.restaurant_rounded, Color(0xFFe74c3c)),
    _CategoryItem('Kafe', Icons.coffee_rounded, Color(0xFF8B4513)),
    _CategoryItem('Bar', Icons.local_bar_rounded, Color(0xFF9b59b6)),
    _CategoryItem('Otel', Icons.hotel_rounded, Color(0xFF2980b9)),
    _CategoryItem('Gece Hayatı', Icons.nightlife_rounded, Color(0xFFe91e63)),
    _CategoryItem('Müze', Icons.museum_rounded, Color(0xFF16a085)),
    _CategoryItem('Alışveriş', Icons.shopping_bag_rounded, Color(0xFFf39c12)),
    _CategoryItem('Spor', Icons.fitness_center_rounded, Color(0xFF27ae60)),
    _CategoryItem('Sağlık', Icons.local_hospital_rounded, Color(0xFFe53935)),
    _CategoryItem('Eğlence', Icons.attractions_rounded, Color(0xFFff6f00)),
    _CategoryItem('Park', Icons.park_rounded, Color(0xFF2e7d32)),
    _CategoryItem('Tümü', Icons.apps_rounded, Color(0xFF607d8b)),
  ];

  @override
  void initState() {
    super.initState();
    _loadPopularVenues();
    _checkLocationAndLoadNearby();
  }

  Future<void> _checkLocationAndLoadNearby() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      _locationGranted = true;
      await _loadNearbyVenues();
    } else if (status.isDenied) {
      final result = await Permission.locationWhenInUse.request();
      if (result.isGranted) {
        _locationGranted = true;
        await _loadNearbyVenues();
      }
    }
  }

  Future<void> _loadNearbyVenues({String? category}) async {
    if (!_locationGranted) return;
    setState(() => _isLoadingNearby = true);
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final venues = await VenueService.fetchNearbyVenues(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        category: category,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _nearbyVenues = venues.isNotEmpty ? venues : _filterFallback(category);
        _isLoadingNearby = false;
      });
    } catch (e) {
      debugPrint('[Explore] Nearby error: $e');
      if (!mounted) return;
      setState(() {
        _nearbyVenues = _filterFallback(category);
        _isLoadingNearby = false;
      });
    }
  }

  List<Venue> _filterFallback(String? category) {
    final all = VenueService.fallbackVenues;
    if (category == null || category.isEmpty) return all;
    return all.where((v) => v.category == category).toList();
  }

  Future<void> _loadPopularVenues() async {
    setState(() => _isLoadingPopular = true);
    try {
      final venues = await VenueService.searchVenues(
        query: 'istanbul',
        limit: 10,
      );
      if (!mounted) return;
      setState(() {
        _popularVenues = venues.isNotEmpty ? venues : VenueService.fallbackVenues;
        _isLoadingPopular = false;
      });
    } catch (e) {
      debugPrint('[Explore] Popular error: $e');
      if (!mounted) return;
      setState(() {
        _popularVenues = VenueService.fallbackVenues;
        _isLoadingPopular = false;
      });
    }
  }

  void _onCategoryTap(_CategoryItem cat) {
    HapticFeedback.selectionClick();
    final catName = cat.label == 'Tümü' ? '' : cat.label;
    setState(() => _selectedCategory = catName);
    if (_locationGranted) {
      _loadNearbyVenues(category: catName.isNotEmpty ? catName : null);
    }
  }

  void _openVenueDetail(Venue venue) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VenueDetailScreen(venue: venue),
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadPopularVenues(),
      if (_locationGranted)
        _loadNearbyVenues(
          category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF45503f),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2d6b3f),
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              // Header + Search Bar
              SliverToBoxAdapter(child: _buildHeader()),

              // Categories
              SliverToBoxAdapter(child: _buildCategorySection()),

              // Nearby Venues
              if (_locationGranted)
                SliverToBoxAdapter(child: _buildNearbySection()),

              // Popular / Featured Venues
              SliverToBoxAdapter(child: _buildPopularSection()),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand + greeting
          Row(
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'arama',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF093827),
                      ),
                    ),
                    TextSpan(
                      text: 'bul',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_locationGranted && _currentPosition != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'İstanbul',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'İstanbul\'u keşfet!',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),

          // Search bar
          GestureDetector(
            onTap: _openSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFd5e8d3),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFF2d6b3f), size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Mekan, kategori veya ilçe ara...',
                    style: TextStyle(
                      fontSize: 15,
                      color: const Color(0xFF1a1a1a).withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategoriler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = (_selectedCategory == cat.label) ||
                  (_selectedCategory.isEmpty && cat.label == 'Tümü');
              return _CategoryCard(
                item: cat,
                isSelected: isSelected,
                onTap: () => _onCategoryTap(cat),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNearbySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.near_me_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Yakınındaki Mekanlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (_isLoadingNearby)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_nearbyVenues.isEmpty && !_isLoadingNearby)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedCategory.isNotEmpty
                      ? '$_selectedCategory kategorisinde yakınında mekan bulunamadı.'
                      : 'Yakınında mekan bulunamadı.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _nearbyVenues.length,
                itemBuilder: (context, index) {
                  return _VenueHorizontalCard(
                    venue: _nearbyVenues[index],
                    onTap: () => _openVenueDetail(_nearbyVenues[index]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPopularSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Popüler Mekanlar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (_isLoadingPopular)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_popularVenues.isEmpty && !_isLoadingPopular)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Mekanlar yükleniyor...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...List.generate(_popularVenues.length, (index) {
              return _VenueListCard(
                venue: _popularVenues[index],
                index: index + 1,
                onTap: () => _openVenueDetail(_popularVenues[index]),
              );
            }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category data model
// ---------------------------------------------------------------------------

class _CategoryItem {
  final String label;
  final IconData icon;
  final Color color;
  const _CategoryItem(this.label, this.icon, this.color);
}

// ---------------------------------------------------------------------------
// Category card widget
// ---------------------------------------------------------------------------

class _CategoryCard extends StatelessWidget {
  final _CategoryItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2d6b3f)
              : const Color(0xFFd5e8d3),
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2d6b3f).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 28,
              color: isSelected ? Colors.white : item.color,
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF1a1a1a),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Horizontal venue card (for nearby section)
// ---------------------------------------------------------------------------

class _VenueHorizontalCard extends StatelessWidget {
  final Venue venue;
  final VoidCallback onTap;

  const _VenueHorizontalCard({
    required this.venue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFd5e8d3),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 110,
              width: double.infinity,
              child: venue.imageUrl != null && venue.imageUrl!.isNotEmpty
                  ? Image.network(
                      venue.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF45503f).withValues(alpha: 0.3),
                        child: const Icon(
                          Icons.place_rounded,
                          color: Color(0xFF2d6b3f),
                          size: 40,
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF45503f).withValues(alpha: 0.3),
                      child: const Icon(
                        Icons.place_rounded,
                        color: Color(0xFF2d6b3f),
                        size: 40,
                      ),
                    ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a1a1a),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (venue.district != null)
                    Text(
                      venue.district!,
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF1a1a1a).withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (venue.rating != null) ...[
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFf59e0b)),
                        const SizedBox(width: 3),
                        Text(
                          venue.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1a1a1a),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2d6b3f).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          venue.category,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2d6b3f),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vertical venue card (for popular section)
// ---------------------------------------------------------------------------

class _VenueListCard extends StatelessWidget {
  final Venue venue;
  final int index;
  final VoidCallback onTap;

  const _VenueListCard({
    required this.venue,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFd5e8d3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 28,
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2d6b3f).withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: venue.imageUrl != null && venue.imageUrl!.isNotEmpty
                    ? Image.network(
                        venue.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF45503f).withValues(alpha: 0.3),
                          child: const Icon(Icons.place_rounded,
                              color: Color(0xFF2d6b3f), size: 24),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF45503f).withValues(alpha: 0.3),
                        child: const Icon(Icons.place_rounded,
                            color: Color(0xFF2d6b3f), size: 24),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a1a1a),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [venue.category, venue.district]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF1a1a1a).withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            // Rating
            if (venue.rating != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2d6b3f),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFf59e0b)),
                    const SizedBox(width: 3),
                    Text(
                      venue.rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
