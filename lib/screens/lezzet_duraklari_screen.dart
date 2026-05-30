import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'venue_detail_screen.dart';
import '../services/venue_service.dart';
import '../models/venue.dart';

const _kBg = Color(0xFF094174);
const _kCardBg = Color(0xFF7bbce8);

/// Native "Lezzet Durakları" screen — replaces the web page.
/// Shows curated venue lists by Mehmet Yaşin & Teoman Hünal.
class LezzetDuraklariScreen extends StatelessWidget {
  const LezzetDuraklariScreen({super.key});

  static const List<_SemtEntry> _semtler = [
    _SemtEntry('Eminönü', ['Hacı Bekir Lokumları', 'Filibe Köftecisi', 'Hocapaşa Pidecisi', 'Hafız Mustafa Tatlıcısı', 'Orient Express']),
    _SemtEntry('Ortaköy', ['Feriye Lokantası']),
    _SemtEntry('Beykoz', ['Kök Kardeşler']),
    _SemtEntry('Harbiye', ['Dragon Restaurant', 'Dubb Indian', 'La Petite Maison']),
    _SemtEntry('Fatih', ['Ersoy Turşuları', 'Öz Kilis Lahmacun', 'Şeref Büryan', 'Unkapanı Pilavcısı', 'Fatih Sarmacısı']),
    _SemtEntry('Balat', ['Forno', 'Cumbalı Kahve', 'Coffee Department']),
    _SemtEntry('Şile', ['Marin Balık', 'Çamlık Mercan Köşk Restaurant']),
    _SemtEntry('Kadıköy', ['Menemenci Cemal Usta', 'Borsam Taşfırın Lahmacun', 'Reks Kokoreç', 'Ciğerci Hulusi', 'Gakgoş Usta']),
    _SemtEntry('Karaköy', ['Mükellef', 'Karaköy Çorbacısı', 'Nato Esnaf Lokantası', 'Burger Lab']),
    _SemtEntry('Moda', ['Çay Tarlası', 'Pişi', 'Basta', 'Asuman', 'Aida']),
    _SemtEntry('Sarıyer', ['Sarıyer Börekçisi', 'Pideban', 'Sarıyer Muhallebicisi', 'Anzer Sofrası']),
    _SemtEntry('Beyoğlu', ['Beyoğlu Söğüş Kelle', 'Canım Ciğerim', 'Kalkanoğlu Pilavcı']),
    _SemtEntry('Beşiktaş', ['Balkan Lokantası', 'Soydan Turşuları', 'Sinop Mantı']),
    _SemtEntry('İstanbul (Fine Dining)', ['Şans Restaurant', 'Mikla Restaurant', 'Mürver Restaurant', 'Spago', 'Sunset']),
    _SemtEntry('Büyükada', ['Yalovalı Kardeşler Şarküteri', 'Prinkipo', 'İstikamet Fıstık Ahmet', 'Fıçı', 'Büyükadalı', 'Dolci Pastanesi', 'Milto', 'Büyükada Roma Dondurmacısı']),
    _SemtEntry('Yenibosna', ['İkizler Kuru Keyfi', 'Sahra Erzurum', 'Hüsmen Ağa', 'Nalia Karadeniz Mutfağı']),
    _SemtEntry('Cihangir', ['Savoy Pastanesi', 'Jash İstanbul', 'Asri Turşucu']),
    _SemtEntry('Ümraniye', ['Sarıhan İşkembe', 'Kalbur Et Kebap', 'Karagöz Sofrası', 'Yaşar Usta']),
    _SemtEntry('Ataşehir', ['Hatay Gurme', 'Dedecan Ocakbaşı']),
    _SemtEntry('Dünya Mutfağı', ['Zeferan Restaurant', 'Asuman Restoran', 'Ayaspaşa Rus Lokantası', 'Çam Süt Mangal Restaurant', 'Pera Thai', 'Tandoori İstanbul', 'Tahin']),
    _SemtEntry('Tuzla', ['Merkez Et Lokantası', 'Tatlı Konyalılar Etli Ekmek', 'Meraklı Köfteci', 'Sandzak Balkan Mutfağı', 'Has Fırın']),
    _SemtEntry('Yeşilköy', ['Şefo Mantı', 'İhtiyar Balıkçı Restaurant', 'Yeşilköy Roma Dondurmacısı', 'Dilim Pizza', 'Gelik Restaurant']),
    _SemtEntry('Reşitpaşa', ['Havan\'dan', 'Bysteak Steakhouse', 'Odun Pizza']),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text('Lezzet Durakları', style: GoogleFonts.plusJakartaSans()),
        backgroundColor: _kBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 32),
        children: [
          // ── Hero section ──
          Container(
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mehmet Yaşin ve Teoman Hünal — İstanbul Lezzet Durakları',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1a1a1a),
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6, color: const Color(0xFF1a1a1a).withValues(alpha: 0.8)),
                    children: const [
                      TextSpan(text: "İstanbul'un zengin mutfak kültürünü keşfetmek denildiğinde akla gelen ilk isimlerden ikisi, gastronomi yazarı "),
                      TextSpan(text: 'Mehmet Yaşin', style: TextStyle()),
                      TextSpan(text: ' ve The North Shield Pub zincirinin kurucusu, içki kültürü uzmanı '),
                      TextSpan(text: "Teoman Hünal", style: TextStyle()),
                      TextSpan(text: "'dır."),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    'https://aramabul.com/assets/gorevimiz-yemek.jpg',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: _kBg.withValues(alpha: 0.3),
                      child: const Center(child: Icon(Icons.image, size: 40, color: Colors.white54)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Title ──
          Text(
            'Lezzet Duraklarını AramaBul ile Keşfet!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 14),

          // ── Semt list ──
          ..._semtler.map((s) => _SemtSection(entry: s)),
        ],
      ),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────

class _SemtEntry {
  final String semt;
  final List<String> venues;
  const _SemtEntry(this.semt, this.venues);
}

// ─── Semt section widget ─────────────────────────────────────────────────

class _SemtSection extends StatelessWidget {
  final _SemtEntry entry;
  const _SemtSection({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Semt title
            Text(
              '• ${entry.semt}:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            // Venue names as tappable chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.venues.map((name) {
                return GestureDetector(
                  onTap: () => _searchVenue(context, name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF8F0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kCardBg, width: 1),
                    ),
                    child: Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF094174),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _searchVenue(BuildContext context, String name) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _kCardBg)),
    );

    try {
      final venues = await VenueService.searchVenues(query: name, limit: 5);
      if (!context.mounted) return;
      Navigator.of(context).pop(); // close loading

      if (venues.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => VenueDetailScreen(venue: venues.first)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name bulunamadı'),
            backgroundColor: const Color(0xFF094174),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
    }
  }
}
