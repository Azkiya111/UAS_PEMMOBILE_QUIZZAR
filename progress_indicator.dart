import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_history.dart';

class QuizService {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  final String _historyKey = 'quiz_history';

  Future<void> saveHistory(QuizHistory history) async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_historyKey);
    
    List<QuizHistory> histories = [];
    if (historyJson != null) {
      List<dynamic> decodedList = json.decode(historyJson);
      histories = decodedList.map((item) => QuizHistory.fromJson(item)).toList();
    }
    
    histories.add(history);
    
    if (histories.length > 20) {
      histories = histories.take(20).toList();
    }
    
    String jsonString = json.encode(histories.map((h) => h.toJson()).toList());
    await prefs.setString(_historyKey, jsonString);
  }

  Future<List<QuizHistory>> getAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_historyKey);
    
    if (historyJson == null) return [];
    
    List<dynamic> decodedList = json.decode(historyJson);
    return decodedList.map((item) => QuizHistory.fromJson(item)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}