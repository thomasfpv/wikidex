import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'dart:convert';
import 'package:card_swiper/card_swiper.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:wikidex/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

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
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = false;
  int _factKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _language = Localizations.localeOf(context).languageCode;
      _loadNotificationTime();
      _loadFirstFactAndCache(_language);
    });
  }

  Future<void> _loadNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notification_hour') ?? 9;
    final minute = prefs.getInt('notification_minute') ?? 0;
    setState(() {
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
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
    if (_isLoading) return;
    setState(() => _isLoading = true);

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
              _factKey++;
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectNotificationTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      cancelText: AppLocalizations.of(context).get('cancel'),
      confirmText: AppLocalizations.of(context).get('ok'),
      helpText: AppLocalizations.of(context).get('select_notification_time'),
    );

    if (picked != null) {
      setState(() {
        _notificationTime = picked;
      });

      try {
        final status = await Permission.notification.request();
        if (status.isGranted) {
          final now = DateTime.now();
          final selectedTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
          
          await NotificationService().scheduleDailyNotification(selectedTime);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(
                AppLocalizations.of(context).get('notification_scheduled').replaceAll('%s', picked.format(context))
              )),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context).get('notifications_required'))),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).get('notification_error'))),
          );
        }
      }
    }
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: appColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: const Icon(Icons.schedule),
              onPressed: _selectNotificationTime,
            ),
          ),
        ],
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

    if (_isLoading) {
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(appColor),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context).get('loading'),
                  style: TextStyle(
                    fontSize: 20,
                    color: appColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              key: ValueKey(_factKey),
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
}
