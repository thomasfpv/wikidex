import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'error_loading': 'Erreur lors du chargement',
      'error_opening_page': 'Erreur lors de l\'ouverture de la page',
      'loading': 'Chargement du fait...',
      'learn_more': 'En savoir plus',
      'cancel': 'Annuler',
      'ok': 'OK',
      'select_notification_time': 'Sélectionner l\'heure de notification',
      'welcome_title': 'Bienvenue sur WikiDex!',
      'start_button': 'Commencer',
      'notification_scheduled': 'Notification programmée pour %s',
      'notifications_required': 'Les notifications sont nécessaires',
      'notification_error': 'Erreur lors de la programmation de la notification',
      'notification_title': 'Wiki Fact du jour',
      'notification_body': 'Découvrez un nouveau fait intéressant !',
    },
    'en': {
      'app_title': 'WikiDex',
      'loading': 'Loading fact...',
      'learn_more': 'Learn more',
      'error_loading': 'Error loading data',
      'error_opening_page': 'Could not open page',
      'select_notification_time': 'Select notification time',
      'ok': 'OK',
      'cancel': 'Cancel',
      'welcome_title': 'Welcome to WikiDex!',
      'start_button': 'Start',
      'notification_scheduled': 'Notification scheduled for %s',
      'notifications_required': 'Notifications are required',
      'notification_error': 'Error scheduling notification',
      'notification_title': 'Daily Wiki Fact',
      'notification_body': 'Discover a new interesting fact!',
    },
  };

  String get(String key) => _localizedValues[locale.languageCode]?[key] ?? key;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  @override
  bool isSupported(Locale locale) => ['fr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
} 