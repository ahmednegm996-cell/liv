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
    },
  };
}
