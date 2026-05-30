import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'welcome_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/search_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/// Live URL — used only for deep links and API base.
const String kLiveUrl = 'https://aramabul.com';

/// App version string.
const String kAppVersion = '1.0.1';

const String _kWelcomeSeenKey = 'welcome_seen';

/// Global app language selected on welcome screen (e.g. 'TR', 'EN', 'DE', 'RU')
// ignore: unused_element
String _globalAppLanguage = 'TR';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize AdMob SDK
  await MobileAds.instance.initialize();
  // Load saved language
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('app_language');
  if (savedLang != null && savedLang.isNotEmpty) {
    _globalAppLanguage = savedLang.toUpperCase();
  }
  runApp(const AramaBulApp());
}

class AramaBulApp extends StatelessWidget {
  const AramaBulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AramaBul',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF094174)),
        scaffoldBackgroundColor: const Color(0xFF094174),
        hoverColor: const Color(0xFFe8f4fd),
        splashColor: const Color(0xFFd0e8f9),
        highlightColor: const Color(0xFFe8f4fd),
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme.copyWith(
            displayLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            displayMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            displaySmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            headlineLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            headlineMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            headlineSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            titleLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            titleMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            bodyLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            bodySmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            labelMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            labelSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        ),
      ),
      home: const AppEntryPoint(),
    );
  }
}

/// Decides whether to show the welcome screen or go directly to the app.
class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool? _showWelcome;
  bool _googleInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '849707147159-94nfr5dv3ic23d3t80qfdvfhoq9gd4mv.apps.googleusercontent.com',
      );
      _googleInitialized = true;
    } catch (e) {
      debugPrint('[GoogleSignIn] Init failed: $e');
    }
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_kWelcomeSeenKey) ?? false;
    if (!mounted) return;
    setState(() => _showWelcome = !seen);
  }

  Future<void> _onWelcomeComplete(String? route) async {
    if (!mounted) return;

    switch (route) {
      case 'login':
      case 'register':
        // No WebView login — show snackbar directing to social login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen Google veya Apple ile giriş yapın.'),
            backgroundColor: Color(0xFF094174),
          ),
        );
        break;

      case 'google_signin':
        await _handleGoogleSignIn();
        break;

      case 'apple_signin':
        await _handleAppleSignIn();
        break;

      case 'facebook_signin':
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Facebook ile giriş yakında aktif olacak.'),
            backgroundColor: Color(0xFF094174),
          ),
        );
        break;

      case 'privacy':
        launchUrl(
          Uri.parse('https://aramabul.com/gizlilik-politikasi.html'),
          mode: LaunchMode.externalApplication,
        );
        break;

      case 'terms':
        launchUrl(
          Uri.parse('https://aramabul.com/kullanim-kosullari.html'),
          mode: LaunchMode.externalApplication,
        );
        break;

      case 'lang_tr':
      case 'lang_en':
      case 'lang_de':
      case 'lang_ru':
        final langCode = route!.replaceFirst('lang_', '');
        final prefsL = await SharedPreferences.getInstance();
        await prefsL.setString('app_language', langCode);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(langCode == 'tr'
                ? 'Dil: Türkçe'
                : langCode == 'en'
                    ? 'Language: English'
                    : langCode == 'de'
                        ? 'Sprache: Deutsch'
                        : 'Язык: Русский'),
            backgroundColor: const Color(0xFF094174),
            duration: const Duration(seconds: 1),
          ),
        );
        _globalAppLanguage = langCode.toUpperCase();
        break;

      default:
        // Guest — just go to home
        final prefsG = await SharedPreferences.getInstance();
        await prefsG.setBool(_kWelcomeSeenKey, true);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TabShell()),
        );
    }
  }

  /// Register social login user with backend
  Future<void> _registerSocialLogin({
    required String provider,
    required String email,
    required String name,
    String? providerId,
  }) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('https://aramabul.com/api/auth/social-login'),
      );
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode({
        'provider': provider,
        'email': email,
        'name': name,
        'providerId': providerId ?? '',
      }));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      debugPrint('[SocialLogin] $provider -> ${response.statusCode}: $body');
      client.close();
    } catch (e) {
      debugPrint('[SocialLogin] Backend registration failed: $e');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      if (!_googleInitialized) {
        await _initGoogleSignIn();
      }
      final account = await GoogleSignIn.instance.authenticate();
      // ignore: unnecessary_null_comparison
      if (account == null) return;

      final name = account.displayName ?? '';
      final email = account.email;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kWelcomeSeenKey, true);
      await prefs.setString('auth_user_name', name);
      await prefs.setString('auth_user_email', email);

      _registerSocialLogin(
        provider: 'google',
        email: email,
        name: name,
        providerId: account.id,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const TabShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google ile giriş başarısız: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apple ile giriş bu cihazda desteklenmiyor.'),
            backgroundColor: Color(0xFF094174),
          ),
        );
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.aramabul.app.signin',
          redirectUri:
              Uri.parse('https://aramabul.com/api/auth/apple-callback'),
        ),
      );

      final name = [
        credential.givenName ?? '',
        credential.familyName ?? '',
      ].where((s) => s.isNotEmpty).join(' ');
      final email = credential.email ?? '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kWelcomeSeenKey, true);
      if (name.isNotEmpty) await prefs.setString('auth_user_name', name);
      if (email.isNotEmpty) await prefs.setString('auth_user_email', email);
      if (credential.userIdentifier != null) {
        await prefs.setString('auth_apple_id', credential.userIdentifier!);
      }

      _registerSocialLogin(
        provider: 'apple',
        email: email,
        name: name,
        providerId: credential.userIdentifier,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const TabShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Apple ile giriş başarısız: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcome == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF094174),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_showWelcome!) {
      return WelcomeScreen(onContinue: _onWelcomeComplete);
    }

    return const TabShell();
  }
}

// ==========================================================================
// TabShell — 100% Native bottom navigation with IndexedStack
// ==========================================================================

class TabShell extends StatefulWidget {
  const TabShell({super.key});

  @override
  State<TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<TabShell> {
  int _currentIndex = 0;

  final GlobalKey<NavigatorState> _exploreNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _searchNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _favoritesNavigatorKey = GlobalKey<NavigatorState>();

  // AdMob banner
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3016888060216617/4581966772',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob] Banner failed: $error');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _goToWelcome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppEntryPoint()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF094174),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            Navigator(
              key: _exploreNavigatorKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => const ExploreScreen(),
              ),
            ),
            Navigator(
              key: _searchNavigatorKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => const SearchScreen(),
              ),
            ),
            Navigator(
              key: _favoritesNavigatorKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => const FavoritesScreen(),
              ),
            ),
            SettingsScreen(onSignOut: _goToWelcome),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bottom nav bar
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF094174),
              border: Border(
                top: BorderSide(color: Color(0xFF1a5a8a), width: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                    _NavItem(
                      assetPath: 'assets/welcome/ev.png',
                      label: 'Ana Sayfa',
                      isActive: _currentIndex == 0,
                      onTap: () {
                        if (_currentIndex == 0) {
                          _exploreNavigatorKey.currentState?.popUntil((route) => route.isFirst);
                        } else {
                          setState(() => _currentIndex = 0);
                        }
                      },
                    ),
                    _NavItem(
                      icon: Icons.search_rounded,
                      label: 'Ara',
                      isActive: _currentIndex == 1,
                      onTap: () {
                        if (_currentIndex == 1) {
                          _searchNavigatorKey.currentState?.popUntil((route) => route.isFirst);
                        } else {
                          setState(() => _currentIndex = 1);
                        }
                      },
                    ),
                    _NavItem(
                      assetPath: 'assets/welcome/fav.png',
                      label: 'Favoriler',
                      isActive: _currentIndex == 2,
                      onTap: () {
                        if (_currentIndex == 2) {
                          _favoritesNavigatorKey.currentState?.popUntil((route) => route.isFirst);
                        } else {
                          setState(() => _currentIndex = 2);
                        }
                      },
                    ),
                    _NavItem(
                      assetPath: 'assets/welcome/ayar.png',
                      label: 'Ayarlar',
                      isActive: _currentIndex == 3,
                      onTap: () => setState(() => _currentIndex = 3),
                    ),
                ],
              ),
            ),
          ),
          // AdMob banner
          if (_isBannerLoaded && _bannerAd != null)
            SafeArea(
              top: false,
              child: Container(
                color: const Color(0xFF094174),
                width: double.infinity,
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================================================
// Navigation bar item
// ==========================================================================

class _NavItem extends StatelessWidget {
  final IconData? icon;
  final String? assetPath;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    this.icon,
    this.assetPath,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? const Color(0xFF7bbce8)
        : Colors.white.withValues(alpha: 0.7);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (assetPath != null)
              Image.asset(
                assetPath!,
                width: 20,
                height: 20,
                color: color,
                fit: BoxFit.contain,
              )
            else
              Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
