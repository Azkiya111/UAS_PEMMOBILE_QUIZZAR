import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/question_model.dart';

class QuestionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  List<QuestionModel> _allQuestions = [];
  List<QuestionModel> _filteredQuestions = [];
  bool _isLoading = false;
  String _searchQuery = '';
  
  List<QuestionModel> get questions => _filteredQuestions;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  
  Future<void> loadAllQuestions({bool forceRefresh = false}) async {
    if (forceRefresh) {
      // Invalidate cache di database service
      _db.invalidateCache();
    }
    
    _isLoading = true;
    notifyListeners();
    
    _allQuestions = await _db.getAllQuestions();
    _applyFilter();
    
    _isLoading = false;
    notifyListeners();
  }
  
  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredQuestions = List.from(_allQuestions);
    } else {
      _filteredQuestions = _allQuestions.where((q) =>
        q.text.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        q.category.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
  }
  
  void searchQuestions(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }
  
  Future<void> addQuestion(QuestionModel question) async {
    await _db.addQuestion(question);
    await loadAllQuestions();
  }
  
  Future<void> updateQuestion(QuestionModel question) async {
    await _db.updateQuestion(question);
    await loadAllQuestions();
  }
  
  Future<void> deleteQuestion(int id) async {
    await _db.deleteQuestion(id);
    await loadAllQuestions();
  }
  
  void clearSearch() {
    _searchQuery = '';
    _applyFilter();
    notifyListeners();
  }
}