// كل الموديلات (نماذج البيانات) بتاعة تطبيق Liv في مكان واحد للتبسيط.
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

class UserProfile {
  String name;
  String locale; // 'en' or 'ar'
  String themeMode; // system/light/dark
  String accentColor;
  bool hasOnboarded;
  int hearts;
  int points;
  int level;
  double heightCm;
  double weightKg;
  DateTime? birthDate;
  List<String> jobs;
  List<String> goals;
  bool isFemale;
  DateTime? lastPeriodStart;
  int cycleLengthDays;
  int periodLengthDays;
  Map<String, dynamic> extras;

  UserProfile({
    this.name = '',
    this.locale = 'en',
    this.themeMode = 'system',
    this.accentColor = 'indigo',
    this.hasOnboarded = false,
    this.hearts = 5,
    this.points = 0,
    this.level = 1,
    this.heightCm = 170,
    this.weightKg = 70,
    this.birthDate,
    this.jobs = const [],
    this.goals = const [],
    this.isFemale = false,
    this.lastPeriodStart,
    this.cycleLengthDays = 28,
    this.periodLengthDays = 5,
    Map<String, dynamic>? extras,
  }) : extras = extras ?? {};

  Map<String, dynamic> toJson() => {
        'name': name,
        'locale': locale,
        'themeMode': themeMode,
        'accentColor': accentColor,
        'hasOnboarded': hasOnboarded,
        'hearts': hearts,
        'points': points,
        'level': level,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'birthDate': birthDate?.toIso8601String(),
        'jobs': jobs,
        'goals': goals,
        'isFemale': isFemale,
        'lastPeriodStart': lastPeriodStart?.toIso8601String(),
        'cycleLengthDays': cycleLengthDays,
        'periodLengthDays': periodLengthDays,
        'extras': extras,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name'] ?? '',
        locale: j['locale'] ?? 'en',
        themeMode: j['themeMode'] ?? 'system',
        accentColor: j['accentColor'] ?? 'indigo',
        hasOnboarded: j['hasOnboarded'] ?? false,
        hearts: j['hearts'] ?? 5,
        points: j['points'] ?? 0,
        level: j['level'] ?? 1,
        heightCm: (j['heightCm'] ?? 170).toDouble(),
        weightKg: (j['weightKg'] ?? 70).toDouble(),
        birthDate: j['birthDate'] != null ? DateTime.tryParse(j['birthDate']) : null,
        jobs: List<String>.from(j['jobs'] ?? []),
        goals: List<String>.from(j['goals'] ?? []),
        isFemale: j['isFemale'] ?? false,
        lastPeriodStart: j['lastPeriodStart'] != null ? DateTime.tryParse(j['lastPeriodStart']) : null,
        cycleLengthDays: j['cycleLengthDays'] ?? 28,
        periodLengthDays: j['periodLengthDays'] ?? 5,
        extras: Map<String, dynamic>.from(j['extras'] ?? {}),
      );
}

class Habit {
  String id;
  String title;
  String? titleAr;
  int targetPerDay;
  int currentStreak;
  int totalCompletions;
  bool isActive;
  DateTime createdAt;
  List<String> completedDates; // yyyy-MM-dd

  Habit({
    String? id,
    required this.title,
    this.titleAr,
    this.targetPerDay = 1,
    this.currentStreak = 0,
    this.totalCompletions = 0,
    this.isActive = true,
    DateTime? createdAt,
    List<String>? completedDates,
  })  : id = id ?? newId(),
        createdAt = createdAt ?? DateTime.now(),
        completedDates = completedDates ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'titleAr': titleAr,
        'targetPerDay': targetPerDay,
        'currentStreak': currentStreak,
        'totalCompletions': totalCompletions,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'completedDates': completedDates,
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'],
        title: j['title'] ?? '',
        titleAr: j['titleAr'],
        targetPerDay: j['targetPerDay'] ?? 1,
        currentStreak: j['currentStreak'] ?? 0,
        totalCompletions: j['totalCompletions'] ?? 0,
        isActive: j['isActive'] ?? true,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        completedDates: List<String>.from(j['completedDates'] ?? []),
      );
}

class Dream {
  String id;
  String title;
  String? description;
  int progress; // 0-100
  bool completed;
  DateTime createdAt;

  Dream({
    String? id,
    required this.title,
    this.description,
    this.progress = 0,
    this.completed = false,
    DateTime? createdAt,
  })  : id = id ?? newId(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'progress': progress,
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Dream.fromJson(Map<String, dynamic> j) => Dream(
        id: j['id'],
        title: j['title'] ?? '',
        description: j['description'],
        progress: j['progress'] ?? 0,
        completed: j['completed'] ?? false,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class TaskItem {
  String id;
  String title;
  bool done;
  int points;
  DateTime? due;
  String category; // morning, daily, custom

  TaskItem({
    String? id,
    required this.title,
    this.done = false,
    this.points = 10,
    this.due,
    this.category = 'daily',
  }) : id = id ?? newId();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'done': done,
        'points': points,
        'due': due?.toIso8601String(),
        'category': category,
      };

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
        id: j['id'],
        title: j['title'] ?? '',
        done: j['done'] ?? false,
        points: j['points'] ?? 10,
        due: j['due'] != null ? DateTime.tryParse(j['due']) : null,
        category: j['category'] ?? 'daily',
      );
}

class ChatMessage {
  String id;
  String role; // user / assistant
  String content;
  DateTime ts;

  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    DateTime? ts,
  })  : id = id ?? newId(),
        ts = ts ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'ts': ts.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'],
        role: j['role'] ?? 'user',
        content: j['content'] ?? '',
        ts: DateTime.tryParse(j['ts'] ?? '') ?? DateTime.now(),
      );
}
