import 'package:flutter/material.dart';

/// Yardım ekranı — Android'deki gibi SSS
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Yardım',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1a1a1a))),
                  const SizedBox(height: 4),
                  Text(
                    'En çok sorulan temel konuları kısa cevaplarla burada topladık.',
                    style: TextStyle(fontSize: 14, color: const Color(0xFF1a1a1a).withValues(alpha: 0.55), height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _faqItem(
                    'Nasıl arama yaparım?',
                    'Üst arama alanından doğrudan mekan adı yazabilir ya da anasayfadan kategori seçebilirsin.',
                  ),
                  const SizedBox(height: 16),
                  _faqItem(
                    'Bilgi yanlışsa ne yapmalıyım?',
                    'Geribildirim sekmesinden kısa bir not bırakabilir ya da iletişim sayfasından bize yazabilirsin.',
                  ),
                  const SizedBox(height: 16),
                  _faqItem(
                    'Hesap şart mı?',
                    'Temel gezinme için hesap gerekmez. Kayıtlı kullanıcı ayarları için hesap alanını kullanabilirsin.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1a1a1a))),
        const SizedBox(height: 6),
        Text(
          answer,
          style: TextStyle(fontSize: 14, color: const Color(0xFF1a1a1a).withValues(alpha: 0.65), height: 1.5),
        ),
      ],
    );
  }
}
