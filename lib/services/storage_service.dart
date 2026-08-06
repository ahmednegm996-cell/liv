import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyProfile = 'liv_profile';
  static const _keyHabits = 'liv_habits';
  static const _keyDreams = 'liv_dreams';
  static const _keyTasks = 'liv_tasks';

  Future<SharedPreferences> get _p async => SharedPreferences.getInstance();

  Future<Map<String, dynamic>?> loadProfile() async {
    final p = await _p;
    final s = p.getString(_keyProfile);
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    final p = await _p;
    await p.setString(_keyProfile, jsonEncode(data));
  }

  Future<List<Map<String, dynamic>>> loadList(String key) async {
    final p = await _p;
    final s = p.getString(key);
    if (s == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(s));
  }

  Future<void> saveList(String key, List<Map<String, dynamic>> list) async {
    final p = await _p;
    await p.setString(key, jsonEncode(list));
  }

  Future<List<Map<String, dynamic>>> loadHabits() => loadList(_keyHabits);
  Future<void> saveHabits(List<Map<String, dynamic>> h) => saveList(_keyHabits, h);
  Future<List<Map<String, dynamic>>> loadDreams() => loadList(_keyDreams);
  Future<void> saveDreams(List<Map<String, dynamic>> d) => saveList(_keyDreams, d);
  Future<List<Map<String, dynamic>>> loadTasks() => loadList(_keyTasks);
  Future<void> saveTasks(List<Map<String, dynamic>> t) => saveList(_keyTasks, t);
}
