import 'package:flutter/foundation.dart';
import '../models.dart';
import 'storage_service.dart';

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

  Future<void> addHabit(Habit h) async {
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
}
