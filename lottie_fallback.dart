import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/question_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final String _questionsKey = 'quiz_questions';
  final Random _random = Random();
  
  // Cache untuk menyimpan data sementara (mempercepat loading)
  List<QuestionModel>? _cachedQuestions;
  DateTime? _lastCacheTime;
  final Duration _cacheDuration = const Duration(minutes: 5);
  
  bool get isSqliteSupported => !kIsWeb && (Platform.isWindows || Platform.isAndroid || Platform.isIOS);

  // Invalidate cache (panggil setelah add/update/delete)
  void invalidateCache() {
    _cachedQuestions = null;
    _lastCacheTime = null;
    debugPrint('Cache invalidated');
  }

  Future<void> initDatabase() async {
    if (!isSqliteSupported) return;
    
    if (Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      join(dbPath, 'quiz_database.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE questions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            optionA TEXT NOT NULL,
            optionB TEXT NOT NULL,
            optionC TEXT NOT NULL,
            optionD TEXT NOT NULL,
            correctAnswer TEXT NOT NULL,
            category TEXT,
            createdAt TEXT
          )
        ''');
        await _insertSampleData(db);
      },
    );
  }

  Future<void> _insertSampleData(Database db) async {
    // Cek apakah sudah ada data
    final result = await db.query('questions');
    if (result.isNotEmpty) return;
    
    List<Map<String, dynamic>> sampleQuestions = [
      {
        'text': 'Siapakah ilmuan yang mengemukakan teori relativitas khusus dan umum?',
        'optionA': 'Albert Einstein',
        'optionB': 'Isaac Newton',
        'optionC': 'Nikola Tesla',
        'optionD': 'Galileo Galilei',
        'correctAnswer': 'A',
        'category': 'Sains',
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'text': 'Siapa presiden pertama Indonesia?',
        'optionA': 'Soeharto',
        'optionB': 'Soekarno',
        'optionC': 'BJ Habibie',
        'optionD': 'Megawati',
        'correctAnswer': 'B',
        'category': 'Sejarah',
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'text': 'Gunung tertinggi di Indonesia adalah?',
        'optionA': 'Gunung Merapi',
        'optionB': 'Gunung Bromo',
        'optionC': 'Gunung Rinjani',
        'optionD': 'Puncak Jaya',
        'correctAnswer': 'D',
        'category': 'Geografi',
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'text': 'Hewan endemik khas Indonesia adalah?',
        'optionA': 'Harimau Sumatra',
        'optionB': 'Panda',
        'optionC': 'Kanguru',
        'optionD': 'Gajah Afrika',
        'correctAnswer': 'A',
        'category': 'Fauna',
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'text': 'Tari Kecak berasal dari daerah?',
        'optionA': 'Jawa Barat',
        'optionB': 'Bali',
        'optionC': 'Yogyakarta',
        'optionD': 'Papua',
        'correctAnswer': 'B',
        'category': 'Budaya',
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];
    for (var q in sampleQuestions) {
      await db.insert('questions', q);
    }
  }

  // GET ALL QUESTIONS with CACHE
  Future<List<QuestionModel>> getAllQuestions() async {
    // Gunakan cache jika masih valid
    if (_cachedQuestions != null && _lastCacheTime != null) {
      if (DateTime.now().difference(_lastCacheTime!) < _cacheDuration) {
        debugPrint('Using cached questions (${_cachedQuestions!.length} questions)');
        return _cachedQuestions!;
      }
    }
    
    debugPrint('Loading fresh questions from database...');
    
    // Load dari database
    List<QuestionModel> questions;
    if (isSqliteSupported) {
      questions = await _getQuestionsFromSqlite();
    } else {
      questions = await _getQuestionsFromSharedPrefs();
    }
    
    // Simpan ke cache
    _cachedQuestions = questions;
    _lastCacheTime = DateTime.now();
    debugPrint('Cached ${questions.length} questions');
    
    return questions;
  }

  Future<List<QuestionModel>> _getQuestionsFromSqlite() async {
    await initDatabase();
    final List<Map<String, dynamic>> maps = await _database!.query('questions', orderBy: 'id ASC');
    debugPrint('SQLite: Loaded ${maps.length} questions');
    return List.generate(maps.length, (i) => QuestionModel.fromMap(maps[i]));
  }

  Future<List<QuestionModel>> _getQuestionsFromSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? questionsJson = prefs.getString(_questionsKey);
    
    if (questionsJson == null) {
      await _initDefaultQuestionsSharedPrefs();
      return _getQuestionsFromSharedPrefs();
    }
    
    List<dynamic> decodedList = json.decode(questionsJson);
    debugPrint('SharedPrefs: Loaded ${decodedList.length} questions');
    return decodedList.map((item) => QuestionModel.fromMap(item)).toList();
  }

  Future<void> _initDefaultQuestionsSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    final existingData = prefs.getString(_questionsKey);
    if (existingData != null) return;
    
    List<QuestionModel> defaultQuestions = [
      QuestionModel(
        id: 1,
        text: 'Apakah samudra terluas di planet bumi?',
        optionA: 'Samudra Hindia',
        optionB: 'Samudra Pasifik',
        optionC: 'Samudra Atlantik',
        optionD: 'Samudra Arktik',
        correctAnswer: 'B',
        category: 'Geografi',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 2,
        text: 'Berapakah jumlah tulang yang dimiliki manusia dewasa normal?',
        optionA: '150 tulang',
        optionB: '206 tulang',
        optionC: '300 tulang',
        optionD: '250 tulang',
        correctAnswer: 'B',
        category: 'Biologi',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 3,
        text: 'Mata uang yang resmi digunakan negara Jepang adalah?',
        optionA: 'Won',
        optionB: 'Ringgit',
        optionC: 'Yuan',
        optionD: 'Yen',
        correctAnswer: 'D',
        category: 'Ekonomi',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 4,
        text: 'Apakah nama zat hijau daun yang berperan penting dalam proses fotosintesis tumbuhan?',
        optionA: 'Stomata',
        optionB: 'Karotenoid',
        optionC: 'Klorofil',
        optionD: 'Sitoplasma',
        correctAnswer: 'C',
        category: 'Sains',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 5,
        text: 'Tari Kecak berasal dari daerah?',
        optionA: 'Jawa Barat',
        optionB: 'Bali',
        optionC: 'Yogyakarta',
        optionD: 'Papua',
        correctAnswer: 'B',
        category: 'Budaya',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 6,
        text: 'Planet yang dikenal sebagai planet merah adalah?',
        optionA: 'Venus',
        optionB: 'Mars',
        optionC: 'Jupiter',
        optionD: 'Saturnus',
        correctAnswer: 'B',
        category: 'Sains',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 7,
        text: 'Kepanjangan dari CPU adalah?',
        optionA: 'Central Processing Unit',
        optionB: 'Computer Personal Unit',
        optionC: 'Central Program Unit',
        optionD: 'Computer Processor Unit',
        correctAnswer: 'A',
        category: 'Teknologi',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 8,
        text: 'Hasil dari 8 x 7 adalah?',
        optionA: '54',
        optionB: '56',
        optionC: '64',
        optionD: '48',
        correctAnswer: 'B',
        category: 'Matematika',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 9,
        text: 'Jumlah pemain dalam satu tim sepak bola di lapangan adalah?',
        optionA: '9',
        optionB: '10',
        optionC: '11',
        optionD: '12',
        correctAnswer: 'C',
        category: 'Olahraga',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 10,
        text: 'Negara dengan jumlah penduduk terbanyak saat ini adalah...',
        optionA: 'Amerika Serikat',
        optionB: 'India',
        optionC: 'Rusia',
        optionD: 'Jepang',
        correctAnswer: 'B',
        category: 'Pengetahuan Umum',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 11,
        text: 'Organ tubuh manusia yang berfungsi memompa darah adalah...',
        optionA: 'Paru-paru',
        optionB: 'Ginjal',
        optionC: 'Jantung',
        optionD: 'Hati',
        correctAnswer: 'C',
        category: 'Sains',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 12,
        text: 'Kalimat yang memiliki subjek dan predikat disebut...',
        optionA: 'Frasa',
        optionB: 'Klausa',
        optionC: 'Kata Ulang',
        optionD: 'Majas',
        correctAnswer: 'B',
        category: 'Bahasa Indonesia',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 13,
        text: 'Hewan tercepat di dunia adalah...',
        optionA: 'Singa',
        optionB: 'Elang',
        optionC: 'Cheetah',
        optionD: 'Harimau',
        correctAnswer: 'C',
        category: 'Hewan',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 14,
        text: 'Benua terbesar di dunia adalah...',
        optionA: 'Afrika',
        optionB: 'Asia',
        optionC: 'Eropa',
        optionD: 'Amerika',
        correctAnswer: 'B',
        category: 'Geografi',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 15,
        text: 'Film animasi Frozen diproduksi oleh...',
        optionA: 'Pixar',
        optionB: 'DreamWorks',
        optionC: 'Disney',
        optionD: 'Universal',
        correctAnswer: 'C',
        category: 'Hiburan',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 16,
        text: 'Perangkat yang digunakan untuk mencetak dokumen disebut...',
        optionA: 'Scanner',
        optionB: 'Keyboard',
        optionC: 'Printer',
        optionD: 'Router',
        correctAnswer: 'C',
        category: 'Teknologi',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 17,
        text: 'Sinonim dari kata indah adalah...',
        optionA: 'Buruk',
        optionB: 'Cantik',
        optionC: 'Gelap',
        optionD: 'Cepat',
        correctAnswer: 'B',
        category: 'Bahasa Indonesia',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 18,
        text: 'Candi Borobudur berada di provinsi...',
        optionA: 'Jawa Barat',
        optionB: 'Jawa Timur',
        optionC: 'Jawa Tengah',
        optionD: 'Bali',
        correctAnswer: 'C',
        category: 'Geografi',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 19,
        text: 'Sungai terpanjang di dunia adalah...',
        optionA: 'Sungai Nil',
        optionB: 'Sungai Amazon',
        optionC: 'Sungai Kapuas',
        optionD: 'Sungai Mississippi',
        correctAnswer: 'A',
        category: 'Geografi',
        createdAt: DateTime.now().toIso8601String(),
      ),
      QuestionModel(
        id: 20,
        text: 'Tokoh utama dalam serial kartun Doraemon adalah...',
        optionA: 'Nobita',
        optionB: 'Suneo',
        optionC: 'Giant',
        optionD: 'Doraemon',
        correctAnswer: 'D',
        category: 'Hiburan',
        createdAt: DateTime.now().toIso8601String(),
      ),
    ];
    
    String jsonString = json.encode(defaultQuestions.map((q) => q.toMap()).toList());
    await prefs.setString(_questionsKey, jsonString);
  }

  Future<int> _getNextId() async {
    final questions = await getAllQuestions();
    if (questions.isEmpty) return 1;
    final maxId = questions.map((q) => q.id ?? 0).reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }

  // CREATE - Tambah soal baru
  Future<int> addQuestion(QuestionModel question) async {
    invalidateCache(); // Clear cache sebelum insert
    
    final newId = await _getNextId();
    final newQuestion = QuestionModel(
      id: newId,
      text: question.text,
      optionA: question.optionA,
      optionB: question.optionB,
      optionC: question.optionC,
      optionD: question.optionD,
      correctAnswer: question.correctAnswer,
      category: question.category,
      createdAt: DateTime.now().toIso8601String(),
    );

    int result;
    if (isSqliteSupported) {
      await initDatabase();
      result = await _database!.insert('questions', newQuestion.toMap());
      debugPrint('SQLite: Added question with id=$newId, result=$result');
    } else {
      final prefs = await SharedPreferences.getInstance();
      final questions = await getAllQuestions();
      questions.add(newQuestion);
      String jsonString = json.encode(questions.map((q) => q.toMap()).toList());
      await prefs.setString(_questionsKey, jsonString);
      result = newId;
      debugPrint('SharedPrefs: Added question with id=$newId');
    }
    return result;
  }

  // UPDATE - Update soal
  Future<int> updateQuestion(QuestionModel question) async {
    invalidateCache(); // Clear cache sebelum update
    
    if (isSqliteSupported) {
      await initDatabase();
      return await _database!.update(
        'questions',
        question.toMap(),
        where: 'id = ?',
        whereArgs: [question.id],
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      final questions = await getAllQuestions();
      final index = questions.indexWhere((q) => q.id == question.id);
      if (index != -1) {
        questions[index] = question;
        String jsonString = json.encode(questions.map((q) => q.toMap()).toList());
        await prefs.setString(_questionsKey, jsonString);
        return 1;
      }
      return 0;
    }
  }

  // DELETE - Hapus soal
  Future<int> deleteQuestion(int id) async {
    invalidateCache(); // Clear cache sebelum delete
    
    if (isSqliteSupported) {
      await initDatabase();
      return await _database!.delete(
        'questions',
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      final questions = await getAllQuestions();
      questions.removeWhere((q) => q.id == id);
      String jsonString = json.encode(questions.map((q) => q.toMap()).toList());
      await prefs.setString(_questionsKey, jsonString);
      return 1;
    }
  }

  Future<QuestionModel?> getQuestion(int id) async {
    final questions = await getAllQuestions();
    try {
      return questions.firstWhere((q) => q.id == id);
    } catch (e) {
      return null;
    }
  }

  // Dapatkan total jumlah pertanyaan
  Future<int> getTotalQuestions() async {
    final questions = await getAllQuestions();
    return questions.length;
  }

  // Dapatkan soal acak sebanyak count
  Future<List<QuestionModel>> getRandomQuestions(int count) async {
    final questions = await getAllQuestions();
    
    if (questions.isEmpty) {
      return [];
    }
    
    if (questions.length <= count) {
      final shuffledList = List<QuestionModel>.from(questions);
      shuffledList.shuffle(_random);
      return shuffledList;
    }
    
    final shuffledList = List<QuestionModel>.from(questions);
    for (int i = shuffledList.length - 1; i > 0; i--) {
      int j = _random.nextInt(i + 1);
      final temp = shuffledList[i];
      shuffledList[i] = shuffledList[j];
      shuffledList[j] = temp;
    }
    
    return shuffledList.take(count).toList();
  }
}