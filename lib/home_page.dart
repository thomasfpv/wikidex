import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:card_swiper/card_swiper.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:wikidex/l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  static const int _cacheSize = 5;
  final List<Map<String, String>> _facts = [];
  final Set<String> _seenTitles = {};
  late final String _language;
  final List<LinearGradient> _gradients = [
    const LinearGradient(
      colors: [Colors.white, Color(0xFFE8EAF6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Colors.white, Color(0xFFF3E5F5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Colors.white, Color(0xFFE0F7FA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Colors.white, Color(0xFFFFF3E0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];
  int _currentGradient = 0;
  //int _factKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _language = Localizations.localeOf(context).languageCode;
      _loadFirstFactAndCache(_language);
    });
  }

  Future<void> _loadFirstFactAndCache(String language) async {
    await _fetchRandomFact(language);
    _loadCacheInBackground(language);
  }

  Future<void> _loadCacheInBackground(String language) async {
    for (int i = 1; i < _cacheSize; i++) {
      if (!mounted) return;
      Future.microtask(() => _fetchRandomFact(language));
    }
  }

  Future<void> _fetchRandomFact([String? language]) async {
    if (!mounted) return;

    try {
      final apiUrl = 'https://$_language.wikipedia.org/api/rest_v1/page/random/summary';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final title = json['title'] as String;

        if (!_seenTitles.contains(title)) {
          final newFact = {
            'title': title,
            'extract': json['extract'] as String,
            'thumbnail': json['thumbnail']?['source'] as String?,
          }.map((key, value) => MapEntry(key, value?.toString() ?? ''));

          if (mounted) {
            setState(() {
              _facts.add(newFact);
              _seenTitles.add(title);
            });
          }
        } else {
          await _fetchRandomFact(language);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).get('error_loading'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const appColor = Color(0xFF6C63FF);

    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: appColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'WikiDex',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Colors.indigo.shade50,
      body: _facts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.02,
                bottom: MediaQuery.of(context).size.height * 0.08,
              ),
              child: Swiper(
                itemBuilder: (_, __) => _buildCard(_facts[0]),
                itemCount: 1,
                onIndexChanged: (_) {
                  setState(() {
                    _currentGradient = (_currentGradient + 1) % _gradients.length;
                    _facts.removeAt(0);
                  });
                  if (_facts.length < _cacheSize - 1) {
                    _fetchRandomFact();
                  }
                },
                layout: SwiperLayout.TINDER,
                itemWidth: MediaQuery.of(context).size.width * 0.95,
                itemHeight: MediaQuery.of(context).size.height * 0.8,
              ),
            ),
    );
  }

  Widget _buildCard(Map<String, String> fact) {
    const appColor = Color(0xFF6C63FF);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: _gradients[_currentGradient],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fact['thumbnail'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  fact['thumbnail']!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 20),
            AnimatedTextKit(
              key: ValueKey(fact['title']),
              animatedTexts: [
                TyperAnimatedText(
                  fact['title']!,
                  textStyle: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade900,
                  ),
                  speed: const Duration(milliseconds: 50),
                ),
              ],
              isRepeatingAnimation: false,
              displayFullTextOnTap: true,
            ),
            const SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  fact['extract']!,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    color: Colors.indigo.shade800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _openWikipediaPage(fact['title']!),
                icon: const Icon(Icons.open_in_new),
                label: Text(AppLocalizations.of(context).get('learn_more')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openWikipediaPage(String title) async {
    final encodedTitle = Uri.encodeComponent(title);
    final url = Uri.parse('https://$_language.wikipedia.org/wiki/$encodedTitle');

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).get('error_opening_page'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).get('error_opening_page'))),
      );
    }
  }
}
