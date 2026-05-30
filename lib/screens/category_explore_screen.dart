import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/venue.dart';
import '../services/venue_service.dart';
import 'venue_detail_screen.dart';
import '../widgets/app_footer.dart';
import '../widgets/maps_sheet.dart';
import '../widgets/venue_dialog.dart';

// ─── Colors ────────────────────
const _kBg = Color(0xFF094174);
const _kCardBg = Color(0xFFbdd8e9);
const _kChipBg = Color(0xFFFDF8F0);
const _kChipBorder = Color(0xFF7bbce8);
const _kCatBg = Color(0xFF48769f);

/// Yeme-İçme (and other main category) page — matches Android exactly.
class CategoryExploreScreen extends StatefulWidget {
  final String mainCategoryKey;
  final String mainCategoryTitle;

  const CategoryExploreScreen({
    super.key,
    required this.mainCategoryKey,
    required this.mainCategoryTitle,
  });

  @override
  State<CategoryExploreScreen> createState() => _CategoryExploreScreenState();
}

class _CategoryExploreScreenState extends State<CategoryExploreScreen> {
  static const List<String> _categories = [
    'Yeme-İçme', 'Gezi', 'Hizmetler',
    'Sağlık', 'Kültür', 'Sanat',
  ];

  // Data
  List<Venue> _venues = [];
  int _totalCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = true;
  Position? _currentPosition;
  int? _randomSeed;

  // Filters
  String? _selectedDistrict;
  String? _selectedNeighborhood;
  String? _selectedSubcategory;
  String? _selectedBudget;
  List<String> _neighborhoods = [];

  // ── İstanbul ilçeleri ──
  static const List<String> _districts = [
    'Adalar', 'Arnavutköy', 'Ataşehir', 'Avcılar', 'Bağcılar', 'Bahçelievler',
    'Bakırköy', 'Başakşehir', 'Bayrampaşa', 'Beşiktaş', 'Beykoz', 'Beylikdüzü',
    'Beyoğlu', 'Büyükçekmece', 'Çatalca', 'Çekmeköy', 'Esenler', 'Esenyurt',
    'Eyüpsultan', 'Fatih', 'Gaziosmanpaşa', 'Güngören', 'Kadıköy', 'Kağıthane',
    'Kartal', 'Küçükçekmece', 'Maltepe', 'Pendik', 'Sancaktepe', 'Sarıyer',
    'Silivri', 'Sultanbeyli', 'Sultangazi', 'Şile', 'Şişli', 'Tuzla',
    'Ümraniye', 'Üsküdar', 'Zeytinburnu',
  ];

  // ── Alt kategoriler (Yeme-İçme) ──
  static const Map<String, List<String>> _subcategories = {
    'yeme-icme': ['Restoran', 'Kafe', 'Pastane', 'Fırın', 'Kebap', 'Börek', 'Balık', 'Meyhane', 'Fast Food', 'Tatlıcı', 'Dondurma', 'Kahvaltı'],
    'gezi': ['Otel', 'Butik Otel', 'Pansiyon', 'Tatil Köyü', 'Kamp Alanı'],
    'hizmetler': ['Kuaför', 'Oto Yıkama', 'Veteriner', 'Kargo', 'Akaryakıt', 'Eczane'],
    'saglik': ['Hastane', 'Poliklinik', 'Diş Kliniği', 'Aile Sağlık Merkezi'],
    'kultur': ['Müze', 'Cami', 'Kilise', 'Saray', 'Kütüphane'],
    'sanat': ['Tiyatro', 'Galeri', 'Konser Salonu', 'Sinema'],
  };

  static const List<String> _budgets = ['Uygun', 'Makul', 'Yüksek'];

  // ── Guide content (full text from web version) ──
  static const Map<String, Map<String, String>> _guideContent = {
    'yeme-icme': {
      'title': 'İstanbul Yeme-İçme Rehberi',
      'body':
          "İstanbul, binlerce yıllık tarihiyle Doğu ile Batı mutfaklarının buluştuğu benzersiz bir gastronomi başkentidir. "
          "Boğaz kıyısında taze balıktan Kapalıçarşı sokaklarında geleneksel Türk kahvaltısına, "
          "meyhane kültüründen modern fine-dining deneyimlerine kadar geniş bir yelpaze sunar. "
          "İstanbul'da en çok tercih edilen mutfak türleri arasında geleneksel Türk mutfağı, "
          "balık restoranları, kebapçılar, kafeler ve pastaneler yer alır.\n\n"
          "Kadıköy'de, özellikle Moda, Fenerbahçe ve Bağdat Caddesi şık restoranlar, kafeler ve "
          "meyhane kültürünün merkezi olarak öne çıkar. Beyoğlu ve İstiklal Caddesi çevresinde yerel ve "
          "uluslararası mutfaklar, tarihi mekanlar ile gece hayatı bir arada bulunur. Beşiktaş ve Bebek "
          "sahilinde deniz manzaralı restoranlar, Sarıyer'de Boğaz balıkçıları dikkat çeker. Anadolu "
          "yakasında Üsküdar ve Çengelköy semtlerinde ise keyifli Türk kahvaltı mekanları yer alır.\n\n"
          "Mekan Seçerken Nelere Dikkat Etmeli?\n"
          "• 4,0 üzeri değerlendirme puana sahip ve en az 50 yorum alan mekanlar genellikle güvenilir bir tercih sunar.\n"
          "• Aramabul'da uygun, makul ve yüksek bütçe seçenekleriyle arama yaparak beklentinize uygun mekanları kolayca bulabilirsiniz.\n"
          "• İlçe ve mahalle filtreleri sayesinde size en yakın veya gitmek istediğiniz bölgedeki mekanları listeleyebilirsiniz.\n"
          "• Restoran, meyhane, pastane ve kafe gibi alt kategorilerle aramanızı daraltabilirsiniz.\n\n"
          "Aramabul ile Nasıl Keşfedersiniz?\n\n"
          "Aramabul, keyifli bir zaman geçireceği veya sevdikleriyle uygun bir buluşma yeri arayan kullanıcıların "
          "ihtiyaç duyduğu mekana, \"Yakındaki Mekanlar\" seçimini yaparak veya istediği ilçe ve mahalle bilgisi "
          "ile kısa yoldan ulaşmasını sağlar. Seçtiğiniz mekanın, adres, telefon, varsa web sitesi ve Instagram "
          "sayfası bilgileri ile haritadaki yeri gibi ayrıntılı bilgileri gösterir.",
    },
    'gezi': {
      'title': 'İstanbul Gezi ve Konaklama Rehberi',
      'body':
          "İstanbul, her yıl milyonlarca yerli ve yabancı turisti ağırlayan, Avrupa ile Asya'yı birleştiren "
          "dünyanın sayılı metropollerinden biridir. Tarihi yarımada, Boğaz kıyıları ve adaları ile hem kültürel "
          "hem doğal zenginliklere ev sahipliği yapar. Bu bölüm, İstanbul'da konaklama ve gezi noktalarını "
          "keşfetmenizi kolaylaştırır.\n\n"
          "Konaklama Seçenekleri\n\n"
          "İstanbul'da her bütçeye uygun konaklama alternatifleri bulunur. Kültür ve Turizm Bakanlığı belgeli "
          "oteller, butik oteller, apart oteller ve pansiyonlar en yaygın tercihler arasındadır. Sultanahmet ve "
          "Taksim bölgesi tarihi mekanlara yakınlığıyla, Kadıköy ve Beşiktaş ise yerel yaşam deneyimi sunmasıyla öne çıkar.\n\n"
          "Öne Çıkan Gezi Bölgeleri\n\n"
          "Tarihi Yarımada'da Ayasofya, Topkapı Sarayı ve Sultanahmet Camii; Beyoğlu'nda İstiklal Caddesi ve "
          "Galata Kulesi; Boğaz hattında Ortaköy, Bebek ve Kanlıca; Adalar'da Büyükada ve Heybeliada İstanbul'un "
          "en popüler gezi noktalarıdır. Anadolu yakasında Çamlıca Tepesi ve Kuzguncuk sokakları sakin bir keşif "
          "deneyimi sunar.\n\n"
          "Konaklama Seçerken İpuçları\n"
          "• Konum: Ziyaret etmek istediğiniz noktalara toplu taşıma ile erişim kolaylığını değerlendirin.\n"
          "• Tesis türü: Otel, butik otel, pansiyon veya apart otel gibi seçenekleri ihtiyacınıza göre filtreleyin.\n"
          "• Değerlendirmeler: Google puanları ve kullanıcı yorumları, mekanın gerçek deneyimini yansıtır.\n"
          "• Sezon: Yaz aylarında ve bayram dönemlerinde erken rezervasyon önemlidir.\n\n"
          "Aramabul'da Gezi Araması\n\n"
          "Gezi bölümünde İstanbul'daki oteller, pansiyonlar, butik oteller ve diğer konaklama tesislerini "
          "ilçe bazında filtreleyebilirsiniz. Her mekanın detay sayfasında adres, iletişim bilgileri, harita "
          "konumu ve kullanıcı değerlendirmeleri yer almaktadır.",
    },
    'hizmetler': {
      'title': "İstanbul'da Günlük Hizmetler Rehberi",
      'body':
          "İstanbul'da günlük yaşamın vazgeçilmez parçası olan hizmet sektörü, kuaförden tamirciye, "
          "terzi'den kuru temizlemeciye kadar geniş bir yelpazede hizmet sunar. Aramabul'un Hizmetler bölümü, "
          "bu ihtiyaçlarınıza en yakın ve en kaliteli çözümleri bulmanızı sağlar.\n\n"
          "Sık Aranan Hizmet Kategorileri\n\n"
          "İstanbul'da en çok aranan hizmet türleri arasında kuaför ve güzellik salonları, oto yıkama ve tamir "
          "servisleri, terzi ve kuru temizleme, veteriner klinikleri, eczaneler ve fotoğrafçılar yer alır. "
          "Her mahallede bu hizmetlerin birden fazla alternatifi bulunur; doğru seçimi yapmak için kullanıcı "
          "değerlendirmelerine bakmak faydalıdır.\n\n"
          "İlçelere Göre Hizmet Yoğunluğu\n\n"
          "Kadıköy, Beşiktaş ve Şişli gibi yoğun nüfuslu ilçeler hizmet çeşitliliği açısından zengindir. "
          "Bakırköy, Ataşehir ve Ümraniye'de de güçlü bir esnaf altyapısı mevcuttur. Daha sakin semtlerde "
          "az sayıda ancak uzmanlaşmış hizmet sağlayıcılar öne çıkar.\n\n"
          "Doğru Hizmet Sağlayıcıyı Seçmek\n"
          "• Kullanıcı yorumları: Gerçek deneyimler, hizmet kalitesi hakkında en güvenilir bilgiyi verir.\n"
          "• Konum ve mesafe: Günlük hizmetlerde yakınlık büyük avantajdır; \"Yakındaki Mekanlar\" özelliğini kullanın.\n"
          "• İletişim bilgileri: Telefon ve web sitesi olan işletmeler genellikle daha profesyonel hizmet sunar.\n"
          "• Çalışma saatleri: Hizmet sektöründe çalışma saatleri değişkendir; ziyaret öncesi arayarak teyit etmeniz önerilir.\n\n"
          "Aramabul ile Hizmet Arama\n\n"
          "Hizmetler bölümünde İstanbul'un 39 ilçesindeki hizmet sağlayıcıları mahalle bazında filtreleyebilirsiniz. "
          "Detay sayfalarında adres, telefon, web sitesi ve harita bilgisi ile birlikte Google kullanıcı puanlarını inceleyebilirsiniz.",
    },
    'saglik': {
      'title': "İstanbul'da Sağlık Hizmetleri Rehberi",
      'body':
          "İstanbul, Türkiye'nin en gelişmiş sağlık altyapısına sahip şehridir. Devlet hastaneleri, üniversite "
          "hastaneleri, özel sağlık kuruluşları, eczaneler ve klinikler şehrin her ilçesine yayılmış durumdadır. "
          "Aramabul'un Sağlık bölümü, acil veya planlı sağlık ihtiyaçlarınız için en yakın ve en uygun sağlık "
          "hizmetini bulmanızı kolaylaştırır.\n\n"
          "Sağlık Hizmet Türleri\n\n"
          "İstanbul'da hastaneler, aile sağlığı merkezleri, diş klinikleri, göz merkezleri, eczaneler ve "
          "laboratuvarlar en çok aranan sağlık hizmetleri arasındadır. Bunun yanı sıra fizyoterapi merkezleri, "
          "diyetisyen ofisleri ve psikolojik danışmanlık hizmetleri de giderek artan bir talep görmektedir.\n\n"
          "İlçelere Göre Sağlık Altyapısı\n\n"
          "Fatih, Şişli ve Bakırköy büyük devlet ve üniversite hastaneleriyle öne çıkar. Kadıköy, Üsküdar ve "
          "Ataşehir'de yoğun özel klinik ve muayenehane ağı bulunur. Başakşehir'de Türkiye'nin en büyük şehir "
          "hastanesi hizmet vermekte olup, Anadolu yakasında Pendik ve Kartal'da da büyük sağlık kampüsleri "
          "yer almaktadır.\n\n"
          "Sağlık Hizmeti Seçerken Dikkat Edilecekler\n"
          "• Acil durumlar: 112 Acil Çağrı Merkezi her zaman ulaşılabilir durumdadır; en yakın hastaneyi bulmak için konum filtresini kullanın.\n"
          "• Uzmanlık alanı: İhtiyacınıza uygun branşta hizmet veren kuruluşları kategori filtresiyle daraltabilirsiniz.\n"
          "• Nöbetçi eczaneler: Gece ve hafta sonu için nöbetçi eczane bilgisine ulaşmak önemlidir.\n"
          "• Kullanıcı deneyimleri: Sağlık hizmeti tercihinde Google puanları ve yorumlar yol gösterici olabilir.\n\n"
          "Aramabul'da Sağlık Araması\n\n"
          "Sağlık bölümünde İstanbul genelindeki sağlık kuruluşlarını ilçe ve mahalle bazında listeleyebilirsiniz. "
          "Detay sayfalarında adres, telefon, konum bilgisi ve kullanıcı değerlendirmelerini inceleyerek ihtiyacınıza "
          "en uygun sağlık hizmetini seçebilirsiniz.",
    },
    'kultur': {
      'title': 'İstanbul Kültürel Miras Rehberi',
      'body':
          "İstanbul, Roma, Bizans ve Osmanlı İmparatorluklarının mirasını taşıyan dünyanın en zengin kültürel "
          "başkentlerinden biridir. UNESCO Dünya Mirası Listesi'nde yer alan tarihi alanları, müzeleri, camileri "
          "ve saraylarıyla şehir başlı başına açık hava müzesi niteliğindedir. Kültür bölümü, İstanbul'un bu "
          "eşsiz mirasını keşfetmenize rehberlik eder.\n\n"
          "Müzeler ve Tarihi Mekanlar\n\n"
          "İstanbul Arkeoloji Müzeleri, Topkapı Sarayı Müzesi, Ayasofya, Kariye Müzesi ve İstanbul Modern, "
          "şehrin en çok ziyaret edilen kültür mekanlarıdır. Pera Müzesi, Rahmi M. Koç Müzesi ve Sakıp Sabancı "
          "Müzesi de ulusal ve uluslararası sergilere ev sahipliği yapan önemli kurumlardır.\n\n"
          "UNESCO Dünya Mirası Alanları\n\n"
          "İstanbul'un Tarihi Yarımadası, 1985 yılından bu yana UNESCO Dünya Mirası Listesi'ndedir. Sultanahmet "
          "Camii, Ayasofya, Yerebatan Sarnıcı, Süleymaniye Camii ve Topkapı Sarayı bu koruma alanı içindeki "
          "en önemli yapılardır. Bu alanlar yıl boyunca yerli ve yabancı turistlerin en yoğun ilgi gösterdiği "
          "noktalar arasında yer alır.\n\n"
          "Kültürel Keşif İçin Öneriler\n"
          "• Müze kartları: İstanbul Müze Kart ile birçok müzeye indirimli veya ücretsiz giriş yapılabilir.\n"
          "• Tarihi yarımada yürüyüşü: Sultanahmet, Eminönü ve Balat arasında yürüyerek birçok tarihi noktayı keşfedebilirsiniz.\n"
          "• Rehberli turlar: Özellikle ilk kez gelenler için lisanslı rehberli turlar zengin bir deneyim sunar.\n"
          "• Ziyaret saatleri: Müze ve ören yerlerinin kapanış saatlerini ve kapalı günlerini önceden kontrol edin.\n\n"
          "Aramabul'da Kültür Araması\n\n"
          "Kültür bölümünde İstanbul'daki müzeler, tarihi camiler, kiliseler, saraylar ve arkeolojik alanları "
          "ilçe bazında listeleyebilirsiniz. Her mekanın detay sayfasında konum, iletişim bilgileri ve ziyaretçi "
          "değerlendirmelerini bulabilirsiniz.",
    },
    'sanat': {
      'title': 'İstanbul Sanat ve Etkinlik Rehberi',
      'body':
          "İstanbul, çağdaş sanat, tiyatro, müzik ve edebiyat alanlarında Türkiye'nin en canlı ve üretken "
          "şehridir. Galeri ve müzelerden sokaklara yayılan sanat atmosferi, uluslararası bienaller ve festivaller "
          "şehri küresel bir sanat merkezine dönüştürmektedir. Sanat bölümü, İstanbul'daki etkinlik odaklı "
          "mekanları keşfetmenizi sağlar.\n\n"
          "Tiyatrolar ve Sahne Sanatları\n\n"
          "İstanbul Devlet Tiyatrosu, Şehir Tiyatroları ve çok sayıda özel tiyatro topluluğu her sezon onlarca "
          "farklı oyun sahnelemektedir. Beyoğlu'ndaki Pera semti, Kadıköy Süreyya Operası ve Harbiye Muhsin "
          "Ertuğrul Sahnesi şehrin en bilinen tiyatro merkezleridir. Alternatif sahne sanatları için Galata, "
          "Karaköy ve Kadıköy'deki bağımsız mekanlar tercih edilmektedir.\n\n"
          "Galeriler ve Çağdaş Sanat\n\n"
          "İstanbul Modern, ARTER, Salt Beyoğlu ve Salt Galata çağdaş sanat alanında öncü kurumlardır. Nişantaşı, "
          "Karaköy ve Bomonti'de çok sayıda bağımsız galeri faaliyet göstermektedir. İstanbul Bienali, her iki "
          "yılda bir düzenlenen ve uluslararası sanat dünyasının dikkatle takip ettiği bir etkinliktir.\n\n"
          "Etkinlik ve Mekan Seçimi\n"
          "• Etkinlik takvimi: Tiyatro ve konser biletlerini önceden temin etmek, özellikle popüler gösteriler için önemlidir.\n"
          "• Bölge seçimi: Beyoğlu sanat galerilerinin, Kadıköy ise bağımsız sanat mekanlarının yoğunlaştığı bölgedir.\n"
          "• Ücretsiz etkinlikler: Pek çok müze ve galeri belirli günlerde ücretsiz giriş veya açılış etkinlikleri düzenlemektedir.\n"
          "• Ulaşım: Şehir merkezindeki sanat mekanlarına metro ve tramvay ile kolayca ulaşabilirsiniz.\n\n"
          "Aramabul'da Sanat Araması\n\n"
          "Sanat bölümünde İstanbul'daki tiyatrolar, galeriler, konser salonları ve diğer sanat mekanlarını "
          "ilçe bazında listeleyebilirsiniz. Detay sayfalarında adres, iletişim bilgileri, konum ve kullanıcı "
          "değerlendirmelerini inceleyerek ilgi alanınıza uygun mekanları keşfedebilirsiniz.",
    },
  };

  @override
  void initState() {
    super.initState();
    _loadVenues();
    _getPosition();
  }

  void _onRefresh() {
    setState(() {
      _selectedDistrict = null;
      _selectedNeighborhood = null;
      _selectedSubcategory = null;
      _selectedBudget = null;
      _neighborhoods = [];
    });
    _loadVenues(page: 1);
    _getPosition();
  }

  Future<void> _getPosition() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('[CategoryExplore] Position error: $e');
    }
  }

  Future<void> _loadVenues({int page = 1}) async {
    setState(() => _isLoading = true);

    try {
      if (page == 1) {
        _randomSeed = DateTime.now().millisecondsSinceEpoch % 2000000000;
      }

      // We perform a request with a larger limit (100 items)
      // to ensure a rich buffer of photo-endowed venues for organic discoverability.
      final params = <String, String>{
        'mainCategoryKey': widget.mainCategoryKey,
        'limit': '100',
        'page': page.toString(),
        'sort': 'random',
        if (_randomSeed != null) 'randomSeed': _randomSeed!.toString(),
      };
      if (_selectedDistrict != null) params['district'] = _selectedDistrict!;
      if (_selectedNeighborhood != null) params['neighborhood'] = _selectedNeighborhood!;
      if (_selectedSubcategory != null) params['category'] = _selectedSubcategory!;
      if (_selectedBudget != null) {
        final budgetMap = {'Uygun': 'low', 'Makul': 'mid', 'Yüksek': 'high'};
        params['budget'] = budgetMap[_selectedBudget!] ?? 'mid';
      }

      final uri = Uri.parse('${VenueService.kApiBase}/api/mvp/istanbul/venues')
          .replace(queryParameters: params);

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (!mounted) return;

      final data = jsonDecode(body);
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

      final List<Venue> loadedItems = (data['items'] as List? ?? []).map((e) {
        final map = e as Map<String, dynamic>;
        final mapped = <String, dynamic>{
          ...map,
          if (map['cuisine'] != null && map['category'] == null) 'category': map['cuisine'],
          if (map['userRatingCount'] != null && map['reviewCount'] == null) 'reviewCount': map['userRatingCount'],
          if (map['photoUri'] != null && map['imageUrl'] == null) 'imageUrl': map['photoUri'],
          if (map['id'] == null && map['slug'] != null) 'id': map['slug'].hashCode.abs(),
        };
        return Venue.fromJson(mapped);
      }).toList();

      // Shuffle loaded venues for organic discoverability
      loadedItems.shuffle();

      // Sort so those with photos are displayed first! Only for yeme-icme and gezi
      // where photos are dense. For other categories (saglik, hizmetler, kultur, sanat),
      // we disable photos-first sorting so cards randomize completely on every load.
      if (widget.mainCategoryKey == 'yeme-icme' || widget.mainCategoryKey == 'gezi') {
        loadedItems.sort((a, b) {
          final hasA = a.imageUrl != null && a.imageUrl!.isNotEmpty && a.imageUrl!.startsWith('http');
          final hasB = b.imageUrl != null && b.imageUrl!.isNotEmpty && b.imageUrl!.startsWith('http');
          if (hasA && !hasB) return -1;
          if (!hasA && hasB) return 1;
          return 0;
        });
      }

      setState(() {
        _venues = loadedItems;
        _totalCount = pagination['total'] ?? 0;
        _currentPage = page;
        const aggregateLimit = 100;
        _totalPages = (_totalCount / aggregateLimit).ceil();
        if (_totalPages < 1) _totalPages = 1;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[CategoryExplore] Load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static Map<String, List<String>>? _cachedIstanbulNeighborhoods;

  Future<void> _loadNeighborhoods(String district) async {
    if (_cachedIstanbulNeighborhoods != null) {
      if (mounted) {
        setState(() {
          _neighborhoods = _cachedIstanbulNeighborhoods![district] ?? [];
        });
      }
      return;
    }

    try {
      final uri = Uri.parse('${VenueService.kApiBase}/data/location-neighborhoods.json');
      debugPrint('[CategoryExplore] Loading neighborhoods from: $uri');
      final client = HttpClient();
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final istanbulData = data['İstanbul'] as Map<String, dynamic>?;
        if (istanbulData != null) {
          final Map<String, List<String>> parsed = {};
          istanbulData.forEach((key, val) {
            if (val is List) {
              parsed[key] = val.cast<String>();
            }
          });
          _cachedIstanbulNeighborhoods = parsed;
          if (mounted) {
            setState(() {
              _neighborhoods = _cachedIstanbulNeighborhoods![district] ?? [];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[CategoryExplore] Load neighborhoods error: $e');
    }
  }

  String _calcDistance(Venue v) {
    if (v.latitude == null || v.longitude == null) return '';
    final lat = _currentPosition?.latitude ?? 41.0370;
    final lng = _currentPosition?.longitude ?? 28.9850;
    final d = Geolocator.distanceBetween(
      lat, lng,
      v.latitude!, v.longitude!,
    );
    if (d > 100000) return '';
    if (d < 1000) return '${d.toStringAsFixed(0)} m';
    return '${(d / 1000).toStringAsFixed(1)} km';
  }

  String _budgetLabel(Venue venue) {
    switch (venue.budget) {
      case 'low': return 'Uygun';
      case 'mid': return 'Makul';
      case 'high': return 'Yüksek';
      default: return 'Makul';
    }
  }

  String _formatCount(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}B' : n.toString();

  void _goPage(int page) {
    if (page < 1 || page > _totalPages) return;
    _loadVenues(page: page);
  }
  void _showBusinessForm(BuildContext ctx) {
    final isletmeAdi = TextEditingController();
    final isletmeciAdi = TextEditingController();
    final telefon = TextEditingController();
    final adres = TextEditingController();
    final eposta = TextEditingController();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: BoxDecoration(
            color: const Color(0xFFe8f4fd),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('İşletme Başvuru Formu',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, color: const Color(0xFF094174),
                          )),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Color(0xFF094174), size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'İşletmenizi platformumuzda öne çıkarmak için aşağıdaki formu doldurun. En kısa sürede sizinle iletişime geçeceğiz.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF1a1a1a).withValues(alpha: 0.7), height: 1.4),
                ),
                const SizedBox(height: 16),
                _formLabel('İşletme Adı', true),
                _formField(isletmeAdi, 'ör. Lezzet Durağı'),
                const SizedBox(height: 12),
                _formLabel('İşletmeci Adı Soyadı', true),
                _formField(isletmeciAdi, 'ör. Ahmet Yılmaz'),
                const SizedBox(height: 12),
                _formLabel('Telefon', true),
                _formField(telefon, '05XX XXX XX XX', keyboard: TextInputType.phone),
                const SizedBox(height: 12),
                _formLabel('Adres', false),
                _formField(adres, 'İstanbul, ilçe, mahalle, sokak...'),
                const SizedBox(height: 12),
                _formLabel('E-posta', false),
                _formField(eposta, 'info@isletme.com', keyboard: TextInputType.emailAddress),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isletmeAdi.text.trim().isEmpty || isletmeciAdi.text.trim().isEmpty || telefon.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Lütfen zorunlu alanları doldurun.'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      final body = 'İşletme Adı: ${isletmeAdi.text}\n'
                          'İşletmeci: ${isletmeciAdi.text}\n'
                          'Telefon: ${telefon.text}\n'
                          'Adres: ${adres.text}\n'
                          'E-posta: ${eposta.text}';
                      final uri = Uri(
                        scheme: 'mailto',
                        path: 'metin.tuncgenc@gmail.com',
                        queryParameters: {
                          'subject': 'AramaBul İşletme Başvurusu - ${isletmeAdi.text}',
                          'body': body,
                        },
                      );
                      launchUrl(uri);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Başvurunuz iletildi!'), backgroundColor: Color(0xFF094174)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF094174),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Gönder', style: GoogleFonts.plusJakartaSans(fontSize: 14, )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formLabel(String text, bool required) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          text: text,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF1a1a1a)),
          children: [
            if (required) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            if (!required) TextSpan(text: ' (isteğe bağlı)', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF1a1a1a).withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _formField(TextEditingController controller, String hint, {TextInputType? keyboard}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF1a1a1a)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF1a1a1a).withValues(alpha: 0.35)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subcats = _subcategories[widget.mainCategoryKey] ?? [];
    final guide = _guideContent[widget.mainCategoryKey];

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // ── Category Grid (3x2) ──
                  _buildCategoryGrid(),
                  const SizedBox(height: 16),



                  // ── Filter card: Konum + Mahalle + Kategori ──
                  _filterCard([
                    Row(
                      children: [
                        Expanded(
                          child: _filterDropdown(
                            label: 'Konum',
                            value: _selectedDistrict,
                            hint: 'Tüm ilçeler',
                            items: _districts,
                            onChanged: (val) {
                              setState(() {
                                _selectedDistrict = val;
                                _selectedNeighborhood = null;
                                _neighborhoods = [];
                              });
                              if (val != null) _loadNeighborhoods(val);
                              _loadVenues();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _filterDropdown(
                            label: 'Mahalle',
                            value: _selectedNeighborhood,
                            hint: _selectedDistrict == null ? 'Önce ilçe seç' : 'Tüm mahalleler',
                            items: _neighborhoods,
                            onChanged: _selectedDistrict == null
                                ? null
                                : (val) {
                                    setState(() => _selectedNeighborhood = val);
                                    _loadVenues();
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _filterDropdown(
                      label: 'Kategori',
                      value: _selectedSubcategory,
                      hint: 'Tüm kategoriler',
                      items: subcats,
                      onChanged: (val) {
                        setState(() => _selectedSubcategory = val);
                        _loadVenues();
                      },
                    ),
                  ]),

                  const SizedBox(height: 12),

                  // Action buttons (only for yeme-icme, gezi, hizmetler)
                  if (widget.mainCategoryKey == 'yeme-icme' ||
                      widget.mainCategoryKey == 'gezi' ||
                      widget.mainCategoryKey == 'hizmetler') ...[
                    GestureDetector(
                      onTap: () => _showBusinessForm(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a1e3d),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text('İşletmenizi öne çıkarmak ister misiniz?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, color: Colors.white,
                            )),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _loadVenues();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a1e3d),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Yakındakiler',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, color: Colors.white,
                            )),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Count
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$_totalCount mekan listeleniyor',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Venues ──
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator(color: _kChipBorder)),
                    )
                  else if (_venues.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('Bu filtrelere uygun mekan bulunamadı',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
                      ),
                    )
                  else ...[
                    ..._venues.map((v) => _buildVenueCard(v)),

                    // Pagination
                    const SizedBox(height: 12),
                    _buildPagination(),
                  ],

                   // ── Guide section ──
                  if (guide != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(guide['title']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1a1a1a),
                              )),
                          const SizedBox(height: 12),
                          ..._buildGuideBody(guide['body']!),
                        ],
                      ),
                    ),
                  ],
                  const AppFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Guide Body with bold sub-headings ──
  List<Widget> _buildGuideBody(String body) {
    final paragraphs = body.split('\n');
    final widgets = <Widget>[];
    for (final p in paragraphs) {
      if (p.trim().isEmpty) continue;
      final isBullet = p.trim().startsWith('•');
      final isSubHeading = !isBullet &&
          p.trim().length < 60 &&
          !p.trim().contains('.') &&
          p.trim().isNotEmpty &&
          !p.trim().startsWith('•');

      if (isSubHeading) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Text(p.trim(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF1a1a1a),
              )),
        ));
      } else if (isBullet) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(p.trim(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.5,
                color: const Color(0xFF1a1a1a).withValues(alpha: 0.7),
              )),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(p.trim(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.6,
                color: const Color(0xFF1a1a1a).withValues(alpha: 0.7),
              )),
        ));
      }
    }
    return widgets;
  }

  // ── Filter Card ──
  Widget _filterCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ── Filter Dropdown ──
  Widget _filterDropdown({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    ValueChanged<String?>? onChanged,
  }) {
    return AramaBulDropdown(
      label: label,
      value: value,
      hint: hint,
      items: items,
      onChanged: onChanged,
    );
  }

  Future<void> _launchMaps(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
  // ── Venue Card ──
  Widget _buildVenueCard(Venue venue) {
    final distance = _calcDistance(venue);
    final isNoImageCategory = widget.mainCategoryKey == 'hizmetler' ||
        widget.mainCategoryKey == 'saglik' ||
        widget.mainCategoryKey == 'kultur' ||
        widget.mainCategoryKey == 'sanat';

    if (isNoImageCategory) {
      return GestureDetector(
        onTap: () => showVenuePopup(context, venue),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Text(
                  venue.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1a1a1a),
                  ),
                ),
              ),

              // Address
              if (venue.address != null && venue.address!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                  child: Text(
                    venue.address!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF1a1a1a).withValues(alpha: 0.6),
                      height: 1.3,
                    ),
                  ),
                ),

              // Phone
              if (venue.phone != null && venue.phone!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                  child: Text(
                    'Tel: ${venue.phone!}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF1a1a1a).withValues(alpha: 0.6),
                    ),
                  ),
                ),

              // Tags (First Row of Chips)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (venue.district != null && venue.district!.isNotEmpty)
                      _TagChip(venue.district!),
                    if (venue.neighborhood != null && venue.neighborhood!.isNotEmpty)
                      _TagChip(venue.neighborhood!),
                    _TagChip(venue.category),
                  ],
                ),
              ),
              // Info row (identical to Yeme-İçme)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Budget chip
                    _InfoImageChip(assetPath: 'assets/cuzdan.png', label: _budgetLabel(venue)),
                    // Distance chip
                    if (distance.isNotEmpty)
                      _InfoImageChip(assetPath: 'assets/uzak.png', label: distance),
                    // Rating chip
                    if (venue.rating != null)
                      _InfoChip(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFf59e0b),
                        label: '${venue.rating!.toStringAsFixed(1)}${venue.reviewCount != null ? ' (${_formatCount(venue.reviewCount!)})' : ''}',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default design for food and travel categories (with image, star, budget)
    String? imageUrl;
    if (venue.imageUrl != null && venue.imageUrl!.isNotEmpty) {
      imageUrl = venue.imageUrl!.startsWith('http') ? venue.imageUrl! : 'https://aramabul.com${venue.imageUrl!}';
    }

    return GestureDetector(
      onTap: () => showVenuePopup(context, venue),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 180,
              width: double.infinity,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF1F5F9),
                        child: Center(
                          child: Image.asset(
                            'assets/no_image.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7bbce8))),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFFF1F5F9),
                      child: Center(
                        child: Image.asset(
                          'assets/no_image.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
            ),

            // Name
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Text(venue.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1a1a1a),
                  )),
            ),

            // Tags
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (venue.district != null && venue.district!.isNotEmpty) _TagChip(venue.district!),
                  if (venue.neighborhood != null && venue.neighborhood!.isNotEmpty) _TagChip(venue.neighborhood!),
                  _TagChip(venue.category),
                ],
              ),
            ),

            // Info row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  // Budget chip
                  _InfoImageChip(assetPath: 'assets/cuzdan.png', label: _budgetLabel(venue)),
                  // Distance chip
                  if (distance.isNotEmpty)
                    _InfoImageChip(assetPath: 'assets/uzak.png', label: distance),
                  // Rating chip
                  if (venue.rating != null)
                    _InfoChip(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFf59e0b),
                      label: '${venue.rating!.toStringAsFixed(1)}${venue.reviewCount != null ? ' (${_formatCount(venue.reviewCount!)})' : ''}',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pagination ──
  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _paginationButton('Geri', _currentPage > 1 ? () => _goPage(_currentPage - 1) : null),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$_currentPage / $_totalPages',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        _paginationButton('İleri', _currentPage < _totalPages ? () => _goPage(_currentPage + 1) : null),
      ],
    );
  }

  Widget _paginationButton(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: onTap != null ? const Color(0xFF1a1a1a) : Colors.white.withValues(alpha: 0.3),
            )),
      ),
    );
  }

  // ── Category Grid ──
  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.8,
      ),
      itemCount: _categories.length,
      itemBuilder: (_, i) {
        final isCurrent = _categories[i].toLowerCase() == widget.mainCategoryTitle.toLowerCase() ||
            (_categories[i] == 'Yeme-İçme' && widget.mainCategoryTitle == 'Yeme-İçme');
        return GestureDetector(
          onTap: () => _onCategoryTap(_categories[i]),
          child: Container(
            decoration: BoxDecoration(
              color: isCurrent ? const Color(0xFF0a1e3d) : _kCatBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _categories[i],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  void _onCategoryTap(String category) {
    HapticFeedback.selectionClick();
    final keyMap = {
      'Yeme-İçme': 'yeme-icme',
      'Gezi': 'gezi',
      'Hizmetler': 'hizmetler',
      'Sağlık': 'saglik',
      'Kültür': 'kultur',
      'Sanat': 'sanat',
    };
    final key = keyMap[category] ?? category.toLowerCase();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CategoryExploreScreen(
          mainCategoryKey: key,
          mainCategoryTitle: category,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Custom Dropdown Widget — allows elegant hover, splash, and compact 38px height
// ═══════════════════════════════════════════════════════════════════════════

class AramaBulDropdown extends StatefulWidget {
  final String label;
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  const AramaBulDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    this.onChanged,
  });

  @override
  State<AramaBulDropdown> createState() => _AramaBulDropdownState();
}

class _AramaBulDropdownState extends State<AramaBulDropdown> {
  final LayerLink _layerLink = LayerLink();
  final ScrollController _scrollController = ScrollController();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant AramaBulDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isOpen) {
          _overlayEntry?.markNeedsBuild();
        }
      });
    }
  }

  @override
  void dispose() {
    if (_isOpen && _overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _scrollController.dispose();
    super.dispose();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss barrier
          GestureDetector(
            onTap: _closeDropdown,
            behavior: HitTestBehavior.translucent,
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: SizedBox(
              width: size.width,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 240),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12, width: 0.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: [
                          // Null / Hint option
                          _buildDropdownItem(null, widget.hint),
                          ...widget.items.map((item) => _buildDropdownItem(item, item)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownItem(String? itemValue, String text) {
    final isSelected = widget.value == itemValue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onChanged?.call(itemValue);
          _closeDropdown();
        },
        hoverColor: const Color(0xFFe8f4fd),
        splashColor: const Color(0xFFd0e8f9),
        highlightColor: const Color(0xFFe8f4fd),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black12, width: 0.5),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: isSelected ? const Color(0xFF094174) : const Color(0xFF1a1a1a),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: widget.onChanged == null ? null : _toggleDropdown,
            child: Container(
              decoration: BoxDecoration(
                color: widget.onChanged == null ? Colors.white.withValues(alpha: 0.6) : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: 40,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.value ?? widget.hint,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: widget.value == null
                            ? const Color(0xFF333333)
                            : const Color(0xFF1a1a1a),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    size: 20,
                    color: const Color(0xFF1a1a1a).withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Haritalarda Aç Chip — customized Google Maps blue color (#1a73e7)
// ═══════════════════════════════════════════════════════════════════════════

class _MapsChip extends StatelessWidget {
  final VoidCallback onTap;
  const _MapsChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE8FDF0), // soft green background
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB5F4CD), width: 0.8), // light green border
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/welcome/detail.png', width: 16, height: 16),
            const SizedBox(width: 5),
            Text(
              'Ayrıntılı Bilgi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF0D8A43), // emerald green text
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tag Chip — cream background with blue border (exactly like Home page)
// ═══════════════════════════════════════════════════════════════════════════

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _kChipBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kChipBorder, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: const Color(0xFF093826),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Info Chip — with icon (budget, distance, rating)
// ═══════════════════════════════════════════════════════════════════════════

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  const _InfoChip({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kChipBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kChipBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? const Color(0xFF093826)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF093826),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoImageChip extends StatelessWidget {
  final String assetPath;
  final String label;
  const _InfoImageChip({required this.assetPath, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kChipBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kChipBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(assetPath, width: 16, height: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF093826),
            ),
          ),
        ],
      ),
    );
  }
}
