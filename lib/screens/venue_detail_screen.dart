import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../models/venue.dart';
import '../services/venue_service.dart';

/// Native venue detail screen — shows venue information
/// without relying on WebView. Key native screen for
/// Apple Guideline 4.2.2 compliance.
class VenueDetailScreen extends StatefulWidget {
  final Venue venue;

  const VenueDetailScreen({super.key, required this.venue});

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  late Venue _venue;
  bool _isFavorite = false;

  // Similar venues
  List<Venue> _similarVenues = [];
  bool _loadingSimilar = true;

  // User position
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _venue = widget.venue;
    _checkFavorite();
    _loadSimilarVenues();
    _getPosition();
  }

  Future<void> _getPosition() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 5)),
      );
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _checkFavorite() async {
    final isFav = await VenueService.isFavorite(_venue.id);
    if (!mounted) return;
    setState(() => _isFavorite = isFav);
  }

  Future<void> _loadSimilarVenues() async {
    try {
      final results = await VenueService.searchVenues(
        query: _venue.category,
        category: _venue.category,
        district: _venue.district,
        limit: 20,
      );
      if (!mounted) return;
      // Filter out the current venue
      var filtered = results.where((v) => v.id != _venue.id).toList();
      // Client-side district filtering (API may not support district param)
      if (_venue.district != null && _venue.district!.isNotEmpty) {
        final sameDistrict = filtered
            .where((v) => v.district?.toLowerCase() == _venue.district!.toLowerCase())
            .toList();
        if (sameDistrict.isNotEmpty) {
          filtered = sameDistrict;
        }
      }
      setState(() {
        _similarVenues = filtered.take(5).toList();
        _loadingSimilar = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingSimilar = false);
    }
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.mediumImpact();
    await VenueService.toggleFavorite(_venue);
    await _checkFavorite();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite
              ? '${_venue.name} favorilere eklendi'
              : '${_venue.name} favorilerden kaldırıldı',
        ),
        backgroundColor: const Color(0xFF094174),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openDirections() {
    if (_venue.latitude == null || _venue.longitude == null) {
      if (_venue.mapsUrl != null && _venue.mapsUrl!.isNotEmpty) {
        launchUrl(Uri.parse(_venue.mapsUrl!),
            mode: LaunchMode.externalApplication);
      }
      return;
    }
    final lat = _venue.latitude!;
    final lng = _venue.longitude!;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0d2137),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Yol Tarifi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.map_rounded, color: Colors.white),
                title: const Text('Apple Haritalar',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  launchUrl(
                    Uri.parse('https://maps.apple.com/?daddr=$lat,$lng'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions_rounded, color: Colors.white),
                title: const Text('Google Maps',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  launchUrl(
                    Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _callVenue() {
    if (_venue.phone != null && _venue.phone!.isNotEmpty) {
      launchUrl(Uri.parse('tel:${_venue.phone}'));
    }
  }

  void _openWebsite() {
    if (_venue.website != null && _venue.website!.isNotEmpty) {
      launchUrl(Uri.parse(_venue.website!),
          mode: LaunchMode.externalApplication);
    }
  }

  void _shareVenue() {
    final slug = _venue.slug ?? '';
    final url = slug.isNotEmpty
        ? 'https://aramabul.com/mekan/$slug'
        : _venue.mapsUrl ?? 'https://aramabul.com';
    Share.share('${_venue.name} — $url');
  }

  void _navigateToVenue(Venue venue) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VenueDetailScreen(venue: venue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF094174),
      body: CustomScrollView(
        slivers: [
          // Hero app bar with image — 280px height with gradient overlay
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF094174),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _venue.imageUrl != null && _venue.imageUrl!.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _resolveImageUrl(_venue.imageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF094174),
                            child: const Icon(
                              Icons.place_rounded,
                              color: Colors.white38,
                              size: 80,
                            ),
                          ),
                        ),
                        // Multi-stop gradient for better text readability
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x66000000),
                                Colors.transparent,
                                Color(0x33000000),
                                Color(0xDD000000),
                              ],
                              stops: [0.0, 0.25, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: const Color(0xFF094174),
                      child: const Icon(
                        Icons.place_rounded,
                        color: Colors.white38,
                        size: 80,
                      ),
                    ),
            ),
            actions: [
              // Favorite button
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _isFavorite ? const Color(0xFFe74c3c) : Colors.white,
                ),
              ),
              // Share button
              IconButton(
                onPressed: _shareVenue,
                icon: const Icon(Icons.share_rounded),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Venue name
                  Text(
                    _venue.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick actions
                  _buildQuickActions(),
                  const SizedBox(height: 16),

                  // Details card
                  _buildDetailsCard(),
                  const SizedBox(height: 12),

                  // Tag chips (category, distance, rating)
                  _buildTagChips(),
                  const SizedBox(height: 24),

                  // Similar venues
                  _buildSimilarVenues(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFbdd8e9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        if (_venue.phone != null && _venue.phone!.isNotEmpty)
          Expanded(
            child: _ActionButton(
              icon: Icons.phone_rounded,
              label: 'Ara',
              color: const Color(0xFF27ae60),
              onTap: _callVenue,
            ),
          ),
        if (_venue.phone != null && _venue.phone!.isNotEmpty)
          const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.directions_rounded,
            label: 'Yol Tarifi',
            color: const Color(0xFF2980b9),
            onTap: _openDirections,
          ),
        ),
        if (_venue.website != null && _venue.website!.isNotEmpty) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              icon: Icons.language_rounded,
              label: 'Web',
              color: const Color(0xFF8e44ad),
              onTap: _openWebsite,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsCard() {
    final details = <_DetailRow>[];

    if (_venue.address != null && _venue.address!.isNotEmpty) {
      details.add(_DetailRow(
        icon: Icons.location_on_rounded,
        label: 'Adres',
        value: _venue.address!,
      ));
    }

    if (_venue.district != null || _venue.city != null) {
      final location = [_venue.district, _venue.city]
          .where((s) => s != null && s.isNotEmpty)
          .join(', ');
      if (location.isNotEmpty && _venue.address == null) {
        details.add(_DetailRow(
          icon: Icons.location_city_rounded,
          label: 'Konum',
          value: location,
        ));
      }
    }

    if (_venue.phone != null && _venue.phone!.isNotEmpty) {
      details.add(_DetailRow(
        icon: Icons.phone_rounded,
        label: 'Telefon',
        value: _venue.phone!,
      ));
    }

    if (_venue.website != null && _venue.website!.isNotEmpty) {
      details.add(_DetailRow(
        icon: Icons.language_rounded,
        label: 'Website',
        value: _venue.website!,
      ));
    }

    if (details.isEmpty) {
      // Show at least location
      final location = [_venue.district, _venue.city]
          .where((s) => s != null && s.isNotEmpty)
          .join(', ');
      if (location.isNotEmpty) {
        details.add(_DetailRow(
          icon: Icons.location_city_rounded,
          label: 'Konum',
          value: location,
        ));
      }
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFbdd8e9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bilgiler',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1a1a1a),
            ),
          ),
          const SizedBox(height: 12),
          ...details.map((detail) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(detail.icon,
                        size: 20, color: const Color(0xFF094174)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1a1a1a)
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            detail.value,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1a1a1a),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }




  String _resolveImageUrl(String url) {
    if (url.startsWith('http')) return url;
    return 'https://aramabul.com$url';
  }

  String _calcDistance() {
    if (_currentPosition == null || _venue.latitude == null || _venue.longitude == null) return '';
    final d = Geolocator.distanceBetween(
      _currentPosition!.latitude, _currentPosition!.longitude,
      _venue.latitude!, _venue.longitude!,
    );
    if (d > 100000) return ''; // 100km+ = user is outside Istanbul
    if (d < 1000) return '${d.toStringAsFixed(0)} m';
    return '${(d / 1000).toStringAsFixed(1)} km';
  }

  Widget _buildTagChips() {
    final dist = _calcDistance();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: İlçe, Mahalle, Kategori (plain text)
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (_venue.district != null && _venue.district!.isNotEmpty)
              _chip(_venue.district!),
            if (_venue.neighborhood != null && _venue.neighborhood!.isNotEmpty)
              _chip(_venue.neighborhood!),
            _chip(_venue.category),
          ],
        ),
        const SizedBox(height: 6),
        // Row 2: Bütçe, Mesafe, Değerlendirme (with icons)
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _chipImage('assets/cuzdan.png', _budgetLabel()),
            if (dist.isNotEmpty)
              _chipImage('assets/uzak.png', dist),
            if (_venue.rating != null)
              _chipIcon(
                Icons.star_rounded,
                '${_venue.rating!.toStringAsFixed(1)}${_venue.reviewCount != null ? ' (${_formatCount(_venue.reviewCount!)})' : ''}',
                iconColor: const Color(0xFF093826),
              ),
          ],
        ),
      ],
    );
  }

  String _budgetLabel() {
    switch (_venue.budget) {
      case 'low': return 'Uygun';
      case 'mid': return 'Makul';
      case 'high': return 'Yüksek';
      default: return 'Makul';
    }
  }

  String _formatCount(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}B' : n.toString();

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF7bbce8), width: 1),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF093826))),
    );
  }

  Widget _chipIcon(IconData icon, String label, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF7bbce8), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? const Color(0xFF093826)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF093826))),
        ],
      ),
    );
  }

  Widget _chipImage(String assetPath, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF7bbce8), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(assetPath, width: 16, height: 16),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF093826))),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benzer Mekanlar — similar venues horizontal scroll section
  // ---------------------------------------------------------------------------

  Widget _buildSimilarVenues() {
    // Don't render section header until loading is done and there are results
    if (_loadingSimilar) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF7bbce8),
            ),
          ),
        ),
      );
    }

    if (_similarVenues.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Benzer Mekanlar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _similarVenues.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final venue = _similarVenues[index];
              return _SimilarVenueCard(
                venue: venue,
                onTap: () => _navigateToVenue(venue),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _SimilarVenueCard extends StatelessWidget {
  final Venue venue;
  final VoidCallback onTap;

  const _SimilarVenueCard({
    required this.venue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFbdd8e9),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Venue image
            SizedBox(
              height: 100,
              width: double.infinity,
              child: venue.imageUrl != null && venue.imageUrl!.isNotEmpty
                  ? Image.network(
                      venue.imageUrl!.startsWith('http') ? venue.imageUrl! : 'https://aramabul.com${venue.imageUrl!}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF094174),
                        child: const Icon(Icons.place_rounded, color: Colors.white38, size: 36),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF094174),
                      child: const Icon(Icons.place_rounded, color: Colors.white38, size: 36),
                    ),
            ),
            // Venue info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0a3d6b)),
                    ),
                    const SizedBox(height: 2),
                    if (venue.district != null || venue.neighborhood != null)
                      Text(
                        [
                          venue.district,
                          if (venue.neighborhood != null && venue.neighborhood!.isNotEmpty)
                            '${venue.neighborhood} Mah.',
                        ].where((s) => s != null && s.isNotEmpty).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: const Color(0xFF0a3d6b).withValues(alpha: 0.6)),
                      ),
                    const Spacer(),
                    if (venue.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFf59e0b), size: 13),
                          const SizedBox(width: 2),
                          Text(venue.rating!.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0a3d6b))),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
}
