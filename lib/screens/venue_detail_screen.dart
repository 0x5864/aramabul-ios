import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

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

  @override
  void initState() {
    super.initState();
    _venue = widget.venue;
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final isFav = await VenueService.isFavorite(_venue.id);
    if (!mounted) return;
    setState(() => _isFavorite = isFav);
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
        backgroundColor: const Color(0xFF2d6b3f),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openDirections() {
    if (_venue.latitude != null && _venue.longitude != null) {
      final url =
          'https://maps.apple.com/?daddr=${_venue.latitude},${_venue.longitude}';
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else if (_venue.mapsUrl != null && _venue.mapsUrl!.isNotEmpty) {
      launchUrl(Uri.parse(_venue.mapsUrl!),
          mode: LaunchMode.externalApplication);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF45503f),
      body: CustomScrollView(
        slivers: [
          // Hero app bar with image
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF2d6b3f),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _venue.imageUrl != null && _venue.imageUrl!.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _venue.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF2d6b3f),
                            child: const Icon(
                              Icons.place_rounded,
                              color: Colors.white38,
                              size: 80,
                            ),
                          ),
                        ),
                        // Gradient overlay
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0xCC000000),
                              ],
                              stops: [0.5, 1.0],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: const Color(0xFF2d6b3f),
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
                  const SizedBox(height: 8),

                  // Category badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2d6b3f),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _venue.category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (_venue.subcategory != null &&
                          _venue.subcategory!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _venue.subcategory!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Rating
                  if (_venue.rating != null) ...[
                    _buildInfoCard(
                      child: Row(
                        children: [
                          ...List.generate(5, (i) {
                            final filled = i < (_venue.rating ?? 0).round();
                            return Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: const Color(0xFFf59e0b),
                              size: 24,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            _venue.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1a1a1a),
                            ),
                          ),
                          if (_venue.reviewCount != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(${_venue.reviewCount} değerlendirme)',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF1a1a1a)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Quick actions
                  _buildQuickActions(),
                  const SizedBox(height: 16),

                  // Details card
                  _buildDetailsCard(),
                  const SizedBox(height: 16),

                  // Open in web button
                  _buildOpenInWebButton(),
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
        color: const Color(0xFFd5e8d3),
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
        color: const Color(0xFFd5e8d3),
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
                        size: 20, color: const Color(0xFF2d6b3f)),
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

  Widget _buildOpenInWebButton() {
    final slug = _venue.slug ?? '';
    if (slug.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          final url = 'https://aramabul.com/mekan/$slug';
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
        icon: const Icon(Icons.open_in_browser_rounded, size: 18),
        label: const Text('Detayları Web\'de Görüntüle'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

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
