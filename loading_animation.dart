import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final String _usersKey = 'registered_users';
  final String _currentUserKey = 'current_user';

  Future<bool> register(String username, String password, String email) async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersJson = prefs.getString(_usersKey);
    
    List<UserModel> users = [];
    if (usersJson != null) {
      List<dynamic> decodedList = json.decode(usersJson);
      users = decodedList.map((item) => UserModel.fromMap(item)).toList();
      
      if (users.any((u) => u.username == username)) {
        return false;
      }
    }
    
    UserModel newUser = UserModel(
      username: username,
      password: password,
      email: email,
      createdAt: DateTime.now(),
      role: 'user', // Default role user
    );
    
    users.add(newUser);
    String jsonString = json.encode(users.map((u) => u.toMap()).toList());
    await prefs.setString(_usersKey, jsonString);
    
    return true;
  }

  Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersJson = prefs.getString(_usersKey);
    
    if (usersJson == null) return false;
    
    List<dynamic> decodedList = json.decode(usersJson);
    List<UserModel> users = decodedList.map((item) => UserModel.fromMap(item)).toList();
    
    UserModel? user = users.firstWhere(
      (u) => u.username == username && u.password == password,
      orElse: () => UserModel(
        username: '', 
        password: '', 
        email: '', 
        createdAt: DateTime.now(),
        role: '',
      ),
    );
    
    if (user.username.isNotEmpty) {
      await prefs.setString(_currentUserKey, json.encode(user.toMap()));
      return true;
    }
    
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final String? currentUser = prefs.getString(_currentUserKey);
    return currentUser != null;
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? currentUser = prefs.getString(_currentUserKey);
    if (currentUser == null) return null;
    
    Map<String, dynamic> decoded = json.decode(currentUser);
    return UserModel.fromMap(decoded);
  }
}