class L10n {
  final String locale;
  L10n(this.locale);
  static L10n of(String locale) => L10n(locale);
  bool get isAr => locale != 'en';

  String get home => isAr ? 'الرئيسية' : 'Home';
  String get habits => isAr ? 'العادات' : 'Habits';
  String get dreams => isAr ? 'الأحلام' : 'Dreams';
  String get ai => isAr ? 'المساعد' : 'AI';
  String get stats => isAr ? 'الإحصائيات' : 'Stats';
  String get profile => isAr ? 'الملف' : 'Profile';
  String get points => isAr ? 'النقاط' : 'Points';
  String get hearts => isAr ? 'القلوب' : 'Hearts';
  String get level => isAr ? 'المستوى' : 'Level';
  String get next => isAr ? 'التالي' : 'Next';
  String get save => isAr ? 'حفظ' : 'Save';
  String get delete => isAr ? 'حذف' : 'Delete';
  String get add => isAr ? 'إضافة' : 'Add';
  String get morningRoutine => isAr ? 'روتين الصباح' : 'Morning routine';
  String get periodTracking => isAr ? 'تتبع الدورة' : 'Period tracking';
}
