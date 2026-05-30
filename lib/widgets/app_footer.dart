import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFd7d7d7),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "İstanbul'da aradığın her şey burada!",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF1a1a1a),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Aramabul, İstanbul'daki 29 binden fazla mekanı tek bir noktada toplayan yerel mekan keşif platformudur. Kategoriler, kullanıcı ihtiyacına göre; yeme-içme, gezi, hizmet, sağlık, kültür ve sanat başlıkları altında oluşturulmuştur.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.5,
              color: const Color(0xFF1a1a1a).withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          _item('Yeme-İçme', "İstanbul'un her köşesindeki restoranlar, meyhaneler, kafeler ve pastaneler gibi mekanları keşfedin."),
          _item('Gezi', 'Oteller, butik oteller, pansiyonlar ve kamp alanları gibi seçenekleri inceleyin.'),
          _item('Hizmetler', 'Kuaför, veteriner ve akaryakıt istasyonları gibi günlük yaşam hizmet noktalarını bulun.'),
          _item('Sağlık', 'Hastaneler, aile sağlık merkezleri ve eczaneler gibi sağlık kuruluşlarına ulaşın.'),
          _item('Kültür', 'Müzeler, tarihi camiler, saraylar ve arkeolojik alanları keşfedin.'),
          _item('Sanat', 'Tiyatrolar, galeriler, konser salonları ve etkinlik mekanlarını listeleyin.'),
          const SizedBox(height: 12),
          const Divider(color: Colors.black12, height: 1),
          const SizedBox(height: 10),
          Center(
            child: Text(
              "© 2026 AramaBul · Tüm Hakları Saklıdır",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF1a1a1a).withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.4, color: const Color(0xFF1a1a1a).withValues(alpha: 0.8)),
          children: [
            TextSpan(text: '$title ', style: const TextStyle()),
            TextSpan(text: desc),
          ],
        ),
      ),
    );
  }
}
