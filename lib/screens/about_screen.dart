import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hakkında ekranı — native
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF094174),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section(
                      'AramaBul Nedir?',
                      'AramaBul, kullanıcının bir yeri ararken en kısa yoldan ve net bilgi bulmasını amaçlayan sade tasarımlı bir yerel keşif platformudur. İstanbul başta olmak üzere Türkiye genelinde binlerce mekan hakkında güncel ve düzenli bilgi sunar.',
                      isTitle: true,
                    ),
                    const SizedBox(height: 20),
                    _section(
                      'Misyonumuz',
                      'İnsanlar çoğu zaman bir yerin adını değil, ihtiyacını bilir. Biz de aramayı ihtiyaçtan başlatıyoruz. Amacımız gereksiz kalabalığı ve çabayı azaltarak, ihtiyaç duyduğunuz hizmet ve mekana daha hızlı ulaşmanızı sağlamaktır.',
                    ),
                    const SizedBox(height: 20),
                    _section(
                      'Nasıl Çalışır?',
                      'AramaBul, mekanları altı ana kategoriye ayırır: Yeme-İçme, Gezi, Hizmetler, Sağlık, Kültür ve Sanat. Her kategori, şehir ve ilçe katmanlarıyla alt kategorilere ayrılır. Böylece aradığınız hizmete en hızlı şekilde ulaşabilirsiniz.',
                    ),
                    const SizedBox(height: 20),
                    _bulletSection('Rakamlarla AramaBul', [
                      '15.000+ kayıtlı mekan',
                      '6 ana kategori, onlarca alt kategori',
                      'İstanbul\'un tüm ilçelerinde kapsam',
                      'Kullanıcı puanları ve değerlendirmeleri',
                      'Güncel adres, telefon ve harita bilgileri',
                    ]),
                    const SizedBox(height: 20),
                    _bulletSection('Temel Yaklaşımımız', [
                      'Basit ve temiz arayüz',
                      'Açık, doğrulanabilir bilgi',
                      'Hızlı ve ayrıntılı yönlendirme',
                      'Kullanıcı odaklı ve kişisel veri güvenliğine önem veren bir keşif deneyimi',
                    ]),
                    const SizedBox(height: 20),
                    const Text('İletişim',
                        style: TextStyle(fontSize: 14, color: Color(0xFF1a1a1a))),
                    const SizedBox(height: 6),
                    Text(
                      'Sorularınız, önerileriniz veya iş birliği teklifleriniz için bizimle iletişime geçebilirsiniz:',
                      style: TextStyle(fontSize: 14, color: const Color(0xFF1a1a1a).withValues(alpha: 0.65), height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => launchUrl(
                        Uri.parse('mailto:info@aramabul.com'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Text(
                        'info@aramabul.com',
                        style: TextStyle(fontSize: 14, color: Color(0xFF2980b9), ),
                      ),
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

  Widget _section(String title, String body, {bool isTitle = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF1a1a1a),
            )),
        const SizedBox(height: 6),
        Text(
          body,
          style: TextStyle(fontSize: 14, color: const Color(0xFF1a1a1a).withValues(alpha: 0.65), height: 1.5),
        ),
      ],
    );
  }

  Widget _bulletSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1a1a1a))),
        const SizedBox(height: 6),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $item',
                style: TextStyle(fontSize: 14, color: const Color(0xFF1a1a1a).withValues(alpha: 0.65), height: 1.5),
              ),
            )),
      ],
    );
  }
}
