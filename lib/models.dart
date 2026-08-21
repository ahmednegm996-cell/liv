// كل الموديلات (نماذج البيانات) بتاعة تطبيق Liv في مكان واحد.
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

String todayKey([DateTime? d]) {
  final x = d ?? DateTime.now();
  return '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
}

class Habit {
  String id;
  String name;
  bool isGood; // true = عادة كويسة، false = عادة وحشة
  int pointsValue; // النقط اللي بتتكسب/بتتخسر
  List<String> completedDates; // تواريخ (yyyy-MM-dd) اتعملت/اتكسرت فيها العادة
  String? aiAnalysis; // آخر تحليل AI لتأثير العادة
  DateTime createdAt;
  bool isMonsterOfMonth; // هل دي "وحش الشهر" اللي بنحاول نتخلص منه

  Habit({
    String? id,
    required this.name,
    required this.isGood,
    this.pointsValue = 10,
    List<String>? completedDates,
    this.aiAnalysis,
    DateTime? createdAt,
    this.isMonsterOfMonth = false,
  })  : id = id ?? newId(),
        completedDates = completedDates ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool get doneToday => completedDates.contains(todayKey());

  int get currentStreak {
    int streak = 0;
    DateTime d = DateTime.now();
    while (completedDates.contains(todayKey(d))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isGood': isGood,
        'pointsValue': pointsValue,
        'completedDates': completedDates,
        'aiAnalysis': aiAnalysis,
        'createdAt': createdAt.toIso8601String(),
        'isMonsterOfMonth': isMonsterOfMonth,
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'],
        name: j['name'] ?? '',
        isGood: j['isGood'] ?? true,
        pointsValue: j['pointsValue'] ?? 10,
        completedDates: List<String>.from(j['completedDates'] ?? []),
        aiAnalysis: j['aiAnalysis'],
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        isMonsterOfMonth: j['isMonsterOfMonth'] ?? false,
      );
}

class DreamStep {
  String id;
  String text;
  bool isDone;

  DreamStep({String? id, required this.text, this.isDone = false})
      : id = id ?? newId();

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'isDone': isDone};
  factory DreamStep.fromJson(Map<String, dynamic> j) =>
      DreamStep(id: j['id'], text: j['text'] ?? '', isDone: j['isDone'] ?? false);
}

class Dream {
  String id;
  String title;
  String description;
  List<DreamStep> steps;
  DateTime createdAt;

  Dream({
    String? id,
    required this.title,
    this.description = '',
    List<DreamStep>? steps,
    DateTime? createdAt,
  })  : id = id ?? newId(),
        steps = steps ?? [],
        createdAt = createdAt ?? DateTime.now();

  int get progressPercent {
    if (steps.isEmpty) return 0;
    final done = steps.where((s) => s.isDone).length;
    return ((done / steps.length) * 100).round();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'steps': steps.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Dream.fromJson(Map<String, dynamic> j) => Dream(
        id: j['id'],
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        steps: (j['steps'] as List? ?? [])
            .map((e) => DreamStep.fromJson(e))
            .toList(),
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class WeeklyTask {
  String id;
  String title;
  bool isDone;
  String weekKey; // yyyy-Www

  WeeklyTask({
    String? id,
    required this.title,
    this.isDone = false,
    required this.weekKey,
  }) : id = id ?? newId();

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'isDone': isDone, 'weekKey': weekKey};
  factory WeeklyTask.fromJson(Map<String, dynamic> j) => WeeklyTask(
        id: j['id'],
        title: j['title'] ?? '',
        isDone: j['isDone'] ?? false,
        weekKey: j['weekKey'] ?? '',
      );
}

class Subscription {
  String id;
  String name;
  double price;
  int billingDay; // 1-28

  Subscription({
    String? id,
    required this.name,
    required this.price,
    required this.billingDay,
  }) : id = id ?? newId();

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'price': price, 'billingDay': billingDay};
  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        id: j['id'],
        name: j['name'] ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        billingDay: j['billingDay'] ?? 1,
      );
}

class DailyLog {
  String date; // yyyy-MM-dd
  double value;

  DailyLog({required this.date, required this.value});

  Map<String, dynamic> toJson() => {'date': date, 'value': value};
  factory DailyLog.fromJson(Map<String, dynamic> j) =>
      DailyLog(date: j['date'] ?? '', value: (j['value'] as num?)?.toDouble() ?? 0);
}

class UserProfile {
  String name;
  double? heightCm;
  double? weightKg;
  int? age;
  double? typicalSleepHours;
  int? bedHour; // 0-23
  int? wakeHour; // 0-23
  List<String> hobbies;
  List<String> goals;
  String? jobType;
  String geminiApiKey;
  String geminiModel;
  String aiProvider; // gemini | grok | groq
  int totalPoints;
  int hearts;
  String lastHeartsResetDate;
  String monsterMonthKey;
  String themeMode; // system | light | dark
  String accentColor; // purple | teal | blue | orange | pink
  String locale; // ar_eg | ar | en
  String gender; // male | female | ''
  bool isFemale;
  bool trackPeriod;
  DateTime? lastPeriodStart;
  int cycleLengthDays;
  int periodLengthDays;
  bool hasOnboarded;
  List<Map<String, String>> chatHistory;
  int weeklyMeetingWeekday; // 1=Mon .. 7=Sun
  String lastDailyMeetingDate;
  String lastWeeklyMeetingKey;

  UserProfile({
    this.name = '',
    this.heightCm,
    this.weightKg,
    this.age,
    this.typicalSleepHours,
    this.bedHour,
    this.wakeHour,
    List<String>? hobbies,
    List<String>? goals,
    this.jobType,
    this.geminiApiKey = '',
    this.geminiModel = 'gemini-flash-lite-latest',
    this.aiProvider = 'gemini',
    this.totalPoints = 0,
    this.hearts = 3,
    String? lastHeartsResetDate,
    this.monsterMonthKey = '',
    this.themeMode = 'dark',
    this.accentColor = 'purple',
    this.locale = 'ar_eg',
    this.gender = '',
    this.isFemale = false,
    this.trackPeriod = false,
    this.lastPeriodStart,
    this.cycleLengthDays = 28,
    this.periodLengthDays = 5,
    this.hasOnboarded = false,
    List<Map<String, String>>? chatHistory,
    this.weeklyMeetingWeekday = 7,
    this.lastDailyMeetingDate = '',
    this.lastWeeklyMeetingKey = '',
  })  : hobbies = hobbies ?? [],
        goals = goals ?? [],
        lastHeartsResetDate = lastHeartsResetDate ?? todayKey(),
        chatHistory = chatHistory ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'age': age,
        'typicalSleepHours': typicalSleepHours,
        'bedHour': bedHour,
        'wakeHour': wakeHour,
        'hobbies': hobbies,
        'goals': goals,
        'jobType': jobType,
        'geminiApiKey': geminiApiKey,
        'geminiModel': geminiModel,
        'aiProvider': aiProvider,
        'totalPoints': totalPoints,
        'hearts': hearts,
        'lastHeartsResetDate': lastHeartsResetDate,
        'monsterMonthKey': monsterMonthKey,
        'themeMode': themeMode,
        'accentColor': accentColor,
        'locale': locale,
        'gender': gender,
        'isFemale': isFemale,
        'trackPeriod': trackPeriod,
        'lastPeriodStart': lastPeriodStart?.toIso8601String(),
        'cycleLengthDays': cycleLengthDays,
        'periodLengthDays': periodLengthDays,
        'hasOnboarded': hasOnboarded,
        'chatHistory': chatHistory,
        'weeklyMeetingWeekday': weeklyMeetingWeekday,
        'lastDailyMeetingDate': lastDailyMeetingDate,
        'lastWeeklyMeetingKey': lastWeeklyMeetingKey,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name'] ?? '',
        heightCm: (j['heightCm'] as num?)?.toDouble(),
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        age: j['age'] as int?,
        typicalSleepHours: (j['typicalSleepHours'] as num?)?.toDouble(),
        bedHour: j['bedHour'] as int?,
        wakeHour: j['wakeHour'] as int?,
        hobbies: List<String>.from(j['hobbies'] ?? []),
        goals: List<String>.from(j['goals'] ?? []),
        jobType: j['jobType'],
        geminiApiKey: j['geminiApiKey'] ?? '',
        geminiModel: j['geminiModel'] ?? 'gemini-flash-lite-latest',
        aiProvider: j['aiProvider'] ?? 'gemini',
        totalPoints: j['totalPoints'] ?? 0,
        hearts: j['hearts'] ?? 3,
        lastHeartsResetDate: j['lastHeartsResetDate'] ?? todayKey(),
        monsterMonthKey: j['monsterMonthKey'] ?? '',
        themeMode: j['themeMode'] ?? 'dark',
        accentColor: j['accentColor'] ?? 'purple',
        locale: j['locale'] ?? 'ar_eg',
        gender: j['gender'] ?? '',
        isFemale: j['isFemale'] ?? (j['gender'] == 'female'),
        trackPeriod: j['trackPeriod'] ?? false,
        lastPeriodStart: j['lastPeriodStart'] != null
            ? DateTime.tryParse(j['lastPeriodStart'])
            : null,
        cycleLengthDays: j['cycleLengthDays'] ?? 28,
        periodLengthDays: j['periodLengthDays'] ?? 5,
        hasOnboarded: j['hasOnboarded'] ?? false,
        chatHistory: (j['chatHistory'] as List? ?? [])
            .map((e) => Map<String, String>.from(e as Map))
            .toList(),
        weeklyMeetingWeekday: j['weeklyMeetingWeekday'] ?? 7,
        lastDailyMeetingDate: j['lastDailyMeetingDate'] ?? '',
        lastWeeklyMeetingKey: j['lastWeeklyMeetingKey'] ?? '',
      );
}
