import 'package:flutter/foundation.dart';
import '../models.dart';
import 'storage_service.dart';
import 'gemini_service.dart';

class AppState extends ChangeNotifier {
  final _storage = StorageService();
  UserProfile profile = UserProfile();
  List<Habit> habits = [];
  List<Dream> dreams = [];
  List<TaskItem> tasks = [];
  bool isLoading = true;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      final pj = await _storage.loadProfile();
      if (pj != null) profile = UserProfile.fromJson(pj);
      final hj = await _storage.loadHabits();
      habits = hj.map((e) => Habit.fromJson(e)).toList();
      final dj = await _storage.loadDreams();
      dreams = dj.map((e) => Dream.fromJson(e)).toList();
      final tj = await _storage.loadTasks();
      tasks = tj.map((e) => TaskItem.fromJson(e)).toList();
    } catch (_) {}
    isLoading = false;
    notifyListeners();
  }

  Future<void> saveProfile() async {
    await _storage.saveProfile(profile.toJson());
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    profile.hasOnboarded = true;
    await saveProfile();
  }

  Future<void> addPoints(int n) async {
    profile.points += n;
    while (profile.points >= profile.level * 100) {
      profile.points -= profile.level * 100;
      profile.level++;
    }
    await saveProfile();
  }

  /// Phase-4 primary + Phase-8D AI-overlay compatibility.
  /// Accepts either a Habit instance or (name, isGood) from the AI overlay.
  Future<void> addHabit(Object nameOrHabit, [bool isGood = true], {int points = 10}) async {
    final Habit h;
    if (nameOrHabit is Habit) {
      h = nameOrHabit;
    } else if (nameOrHabit is String) {
      h = Habit(title: nameOrHabit, isGood: isGood);
    } else {
      throw ArgumentError('addHabit expects Habit or String');
    }
    habits.add(h);
    await _storage.saveHabits(habits.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  Future<void> removeHabit(String id) async {
    habits.removeWhere((e) => e.id == id);
    await _storage.saveHabits(habits.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  Future<void> addDream(Dream d) async {
    dreams.add(d);
    await _storage.saveDreams(dreams.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  Future<void> removeDream(String id) async {
    dreams.removeWhere((e) => e.id == id);
    await _storage.saveDreams(dreams.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  Future<void> addTask(TaskItem t) async {
    tasks.add(t);
    await _storage.saveTasks(tasks.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  Future<void> removeTask(String id) async {
    tasks.removeWhere((e) => e.id == id);
    await _storage.saveTasks(tasks.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  Future<void> toggleTask(String id) async {
    final i = tasks.indexWhere((e) => e.id == id);
    if (i < 0) return;
    tasks[i].done = !tasks[i].done;
    if (tasks[i].done) await addPoints(tasks[i].points);
    await _storage.saveTasks(tasks.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  // ========== Phase 8D Option-B compatibility layer ==========

  Future<void> updateProfile(UserProfile Function(UserProfile) updater) async {
    profile = updater(profile);
    await saveProfile();
  }

  Future<void> addWeeklyTask(String title) async {
    await addTask(TaskItem(title: title, category: 'daily', points: 10));
  }

  Future<void> addDreamWithAISteps(String title, String description) async {
    await addDream(Dream(title: title, description: description.isEmpty ? null : description));
  }

  GeminiService get ai {
    return GeminiService(
      apiKey: profile.geminiApiKey,
      model: profile.geminiModel,
      provider: profile.aiProvider,
    );
  }

  String get aiContext {
    final buf = StringBuffer();
    buf.writeln('User: ${profile.name.isEmpty ? "Guest" : profile.name}');
    buf.writeln('Level: ${profile.level}, Points: ${profile.points}, Hearts: ${profile.hearts}');
    if (profile.goals.isNotEmpty) buf.writeln('Goals: ${profile.goals.join(", ")}');
    if (habits.isNotEmpty) {
      buf.writeln('Habits: ${habits.take(8).map((h) => h.title).join(", ")}');
    }
    if (dreams.isNotEmpty) {
      buf.writeln('Dreams: ${dreams.take(5).map((d) => d.title).join(", ")}');
    }
    if (tasks.isNotEmpty) {
      final open = tasks.where((t) => !t.done).take(5).map((t) => t.title);
      if (open.isNotEmpty) buf.writeln('Open tasks: ${open.join(", ")}');
    }
    return buf.toString().trim();
  }

}
