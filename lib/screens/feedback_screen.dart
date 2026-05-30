import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/venue_service.dart';

/// Geribildirim ekranı — API üzerinden gönderir
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _nameController.text = prefs.getString('auth_user_name') ?? '';
    _emailController.text = prefs.getString('auth_user_email') ?? '';
  }

  Future<void> _send() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen mesajınızı yazın.'), backgroundColor: Color(0xFFe74c3c)),
      );
      return;
    }

    setState(() => _sending = true);

    final success = await VenueService.sendFeedback(
      name: name,
      email: email,
      subject: subject.isNotEmpty ? subject : 'AramaBul iOS Geribildirim',
      message: message,
    );

    if (!mounted) return;
    setState(() => _sending = false);

    if (success) {
      _subjectController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geribildiriminiz gönderildi. Teşekkürler!'), backgroundColor: Color(0xFF094174)),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gönderilemedi. Lütfen tekrar deneyin.'), backgroundColor: Color(0xFFe74c3c)),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

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
                  const Text('Geribildirim',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1a1a1a))),
                  const SizedBox(height: 4),
                  Text('Mesajını konu seçerek hızlıca iletebilirsin.',
                      style: TextStyle(fontSize: 14, color: const Color(0xFF1a1a1a).withValues(alpha: 0.5))),
                  const SizedBox(height: 20),

                  _buildField(_nameController, 'Ad Soyad'),
                  const SizedBox(height: 12),
                  _buildField(_emailController, 'E-posta'),
                  const SizedBox(height: 12),
                  _buildField(_subjectController, 'Konu'),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Mesaj',
                      hintStyle: TextStyle(color: const Color(0xFF1a1a1a).withValues(alpha: 0.35)),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: const Color(0xFF1a1a1a).withValues(alpha: 0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: const Color(0xFF1a1a1a).withValues(alpha: 0.15)),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF1a1a1a)),
                  ),

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF094174),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF094174).withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: _sending
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Gönder', style: TextStyle(fontSize: 14, )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFF1a1a1a).withValues(alpha: 0.35)),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color(0xFF1a1a1a).withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color(0xFF1a1a1a).withValues(alpha: 0.15)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      style: const TextStyle(fontSize: 14, color: Color(0xFF1a1a1a)),
    );
  }
}
