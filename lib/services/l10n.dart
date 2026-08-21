/// ترجمة بسيطة للغات الثلاث بدون ملفات خارجية
class L10n {
  final String locale; // ar_eg | ar | en
  const L10n(this.locale);

  bool get isEn => locale == 'en';
  bool get isFusha => locale == 'ar';
  bool get isMasry => locale == 'ar_eg';

  String t(String key) {
    final map = _maps[locale] ?? _maps['ar_eg']!;
    return map[key] ?? key;
  }

  /// Phase 8D compatibility: L10n.of(locale)
  static L10n of(String locale) {
    // Normalize common values used by profile
    final loc = (locale == 'ar' || locale == 'ar_eg' || locale == 'en')
        ? locale
        : (locale.startsWith('ar') ? 'ar_eg' : 'en');
    return L10n(loc);
  }

  // Compatibility getters used by Phase-4 screens (route through t)
  String get app_name => t('app_name');
  String get home => t('home');
  String get habits => t('habits');
  String get dreams => t('dreams');
  String get stats => t('stats');
  String get profile => t('profile');
  String get ai => t('ai');
  String get add_habit => t('add_habit');
  String get add_dream => t('add_dream');
  String get no_habits => t('no_habits');
  String get no_dreams => t('no_dreams');
  String get points => t('points');
  String get level => t('level');
  String get goals => t('goals');
  String get age => t('age');
  String get sleep => t('sleep');
  String get name => t('name');
  String get height => t('height');
  String get job_field => t('job_field');
  String get hearts => t('hearts');
  String get periodTracking => t('periodTracking');

  static const Map<String, Map<String, String>> _maps = {
    'ar_eg': {
      'app_name': 'ليف',
      'home': 'الرئيسية',
      'habits': 'العادات',
      'dreams': 'أحلام',
      'stats': 'الإحصائيات',
      'profile': 'الملف',
      'ai': 'المساعد',
      'add_habit': 'عادة جديدة',
      'add_dream': 'حلم جديد',
      'no_habits': 'لسه معملتش عادات',
      'no_dreams': 'لسه معملتش أحلام',
      'points': 'نقاط',
      'level': 'المستوى',
      'goals': 'أحلامك دلوقتي؟',
      'age': 'السن',
      'sleep': 'ساعات النوم',
      'name': 'الاسم',
      'height': 'الطول (سم)',
      'job_field': 'مجال الشغل',
      'hearts': 'قلوب',
      'periodTracking': 'تتبع الدورة',
    },
    'ar': {
      'app_name': 'ليف',
      'home': 'الرئيسية',
      'habits': 'العادات',
      'dreams': 'الأحلام',
      'stats': 'الإحصائيات',
      'profile': 'الملف الشخصي',
      'ai': 'المساعد',
      'add_habit': 'عادة جديدة',
      'add_dream': 'حلم جديد',
      'no_habits': 'لا توجد عادات بعد',
      'no_dreams': 'لا توجد أحلام بعد',
      'points': 'نقاط',
      'level': 'المستوى',
      'goals': 'أحلامك الحالية؟',
      'age': 'العمر',
      'sleep': 'ساعات النوم',
      'name': 'الاسم',
      'height': 'الطول (سم)',
      'job_field': 'مجال العمل',
      'hearts': 'قلوب',
      'periodTracking': 'تتبع الدورة',
    },
    'en': {
      'app_name': 'LIV',
      'home': 'Home',
      'habits': 'Habits',
      'dreams': 'Dreams',
      'stats': 'Stats',
      'profile': 'Profile',
      'ai': 'AI',
      'add_habit': 'New Habit',
      'add_dream': 'New Dream',
      'no_habits': 'No habits yet',
      'no_dreams': 'No dreams yet',
      'points': 'Points',
      'level': 'Level',
      'goals': 'Your dreams now?',
      'age': 'Age',
      'sleep': 'Sleep hours',
      'name': 'Name',
      'height': 'Height (cm)',
      'job_field': 'Work field',
      'hearts': 'Hearts',
      'periodTracking': 'Period tracking',
    },
  };
}
