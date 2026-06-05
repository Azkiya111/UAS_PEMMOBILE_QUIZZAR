import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import '../services/database_service.dart';
import '../services/quiz_service.dart';
import '../models/question_model.dart';
import '../models/quiz_history.dart';
import '../providers/theme_provider.dart';
import '../widgets/answer_button.dart';
import '../widgets/progress_indicator.dart';
import 'home_screen.dart';

class QuizScreen extends StatefulWidget {
  final int questionCount;
  const QuizScreen({super.key, required this.questionCount});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final QuizService _quizService = QuizService();
  
  List<QuestionModel> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _showFeedback = false;
  bool _isCorrectAnswer = false;
  bool _isLoading = true;
  
  // Audio
  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _bgMusicPlayer = AudioPlayer();
  bool _isMusicPlaying = true;
  bool _soundEnabled = true;
  
  late ConfettiController _confettiController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _loadRandomQuestions();
    _fadeController.forward();
    _playBackgroundMusic();
  }

  @override
  void dispose() {
    _effectPlayer.dispose();
    _bgMusicPlayer.dispose();
    _confettiController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _playBackgroundMusic() async {
    try {
      await _bgMusicPlayer.setVolume(0.3);
      await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgMusicPlayer.play(AssetSource('sound/bg_music.wav'));
    } catch (e) {
      debugPrint('Background music error: $e');
    }
  }

  Future<void> _playSoundEffect(bool isCorrect) async {
    if (!_soundEnabled) return;
    try {
      String soundFile = isCorrect ? 'sound/betul.wav' : 'sound/salah.wav';
      await _effectPlayer.stop();
      await _effectPlayer.play(AssetSource(soundFile));
    } catch (e) {
      debugPrint('Sound effect error: $e');
    }
  }

  void _toggleBackgroundMusic() {
    setState(() {
      _isMusicPlaying = !_isMusicPlaying;
      if (_isMusicPlaying) {
        _bgMusicPlayer.resume();
      } else {
        _bgMusicPlayer.pause();
      }
    });
  }

  void _toggleSoundEffect() {
    setState(() {
      _soundEnabled = !_soundEnabled;
    });
  }

  void _toggleDarkMode() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();
  }

  Future<void> _loadRandomQuestions() async {
    setState(() {
      _isLoading = true;
      _currentIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _showFeedback = false;
      _isCorrectAnswer = false;
    });
    _questions = await _db.getRandomQuestions(widget.questionCount);
    setState(() => _isLoading = false);
  }

  void _checkAnswer(String optionKey) {
    if (_showFeedback) return;
    if (_currentIndex >= _questions.length) return;
    
    bool answerIsCorrect = _questions[_currentIndex].isCorrect(optionKey);
    
    _playSoundEffect(answerIsCorrect);
    
    setState(() {
      _selectedAnswer = optionKey;
      _showFeedback = true;
      _isCorrectAnswer = answerIsCorrect;
      if (answerIsCorrect) _score++;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(answerIsCorrect ? Icons.check_circle : Icons.cancel, color: Colors.white),
            const SizedBox(width: 10),
            Text(answerIsCorrect ? '✅ Benar!' : '❌ Salah!'),
          ],
        ),
        backgroundColor: answerIsCorrect ? Colors.green : Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        if (_currentIndex + 1 >= _questions.length) {
          _bgMusicPlayer.pause();
          _showResultDialog();
        } else {
          setState(() {
            _currentIndex++;
            _selectedAnswer = null;
            _showFeedback = false;
            _isCorrectAnswer = false;
          });
        }
      }
    });
  }

  Future<void> _showResultDialog() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    if (_questions.isNotEmpty) {
      final history = QuizHistory(
        score: _score,
        totalQuestions: _questions.length,
        date: DateTime.now(),
        message: _getScoreMessage(),
      );
      await _quizService.saveHistory(history);
    }
    
    if (_score == _questions.length && _questions.isNotEmpty) {
      _confettiController.play();
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🏆 Kuis Selesai!'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 70, color: Colors.amber),
            const SizedBox(height: 15),
            Text(
              'Skor Akhir Anda',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '$_score / ${_questions.length}',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _getScoreMessage(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Kembali ke Home'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentIndex = 0;
                        _score = 0;
                        _selectedAnswer = null;
                        _showFeedback = false;
                        _isCorrectAnswer = false;
                      });
                      _loadRandomQuestions();
                      _confettiController.stop();
                      _playBackgroundMusic();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Ulangi Quiz'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getScoreMessage() {
    if (_questions.isEmpty) return 'Mulai quiz sekarang!';
    double percentage = (_score / _questions.length) * 100;
    if (percentage >= 80) return '🌟 Luar biasa! Pengetahuan Anda sangat baik!';
    if (percentage >= 60) return '👍 Bagus! Tingkatkan lagi pengetahuan Anda!';
    if (percentage >= 40) return '📚 Terus belajar ya!';
    return '💪 Jangan menyerah, coba lagi!';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.isDarkMode;
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Quiz (${widget.questionCount} soal)'),
            centerTitle: true,
            backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.blue.shade700,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: _toggleDarkMode,
                tooltip: 'Ganti Tema',
              ),
              IconButton(
                icon: Icon(_isMusicPlaying ? Icons.music_note : Icons.music_off),
                onPressed: _toggleBackgroundMusic,
                tooltip: _isMusicPlaying ? 'Matikan Musik' : 'Hidupkan Musik',
              ),
              IconButton(
                icon: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off),
                onPressed: _toggleSoundEffect,
                tooltip: _soundEnabled ? 'Matikan Suara Efek' : 'Hidupkan Suara Efek',
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode
                    ? [Colors.grey.shade900, Colors.grey.shade800]
                    : [Colors.blue.shade50, Colors.white],
              ),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _questions.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning, size: 60, color: Colors.orange),
                            SizedBox(height: 20),
                            Text('Belum ada soal yang tersedia'),
                            SizedBox(height: 10),
                            Text('Tambahkan soal terlebih dahulu'),
                            SizedBox(height: 20),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: ConfettiWidget(
                              confettiController: _confettiController,
                              blastDirectionality: BlastDirectionality.explosive,
                              shouldLoop: false,
                              colors: const [
                                Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple
                              ],
                              numberOfParticles: 50,
                              gravity: 0.2,
                            ),
                          ),
                          SafeArea(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 24,
                                vertical: 16,
                              ),
                              child: Column(
                                children: [
                                  QuizProgressIndicator(
                                    currentQuestion: _currentIndex + 1,
                                    totalQuestions: _questions.length,
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDarkMode 
                                          ? Colors.grey.shade700 
                                          : Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Soal ${_currentIndex + 1} dari ${_questions.length}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    margin: const EdgeInsets.all(16),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.blue, Colors.purple],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(20),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _questions[_currentIndex].text,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Column(
                                      children: [
                                        AnswerButton(
                                          optionKey: 'A',
                                          optionText: _questions[_currentIndex].optionA,
                                          onPressed: () => _checkAnswer('A'),
                                          isSelected: _selectedAnswer == 'A',
                                          isCorrect: _selectedAnswer == 'A' && _isCorrectAnswer,
                                        ),
                                        AnswerButton(
                                          optionKey: 'B',
                                          optionText: _questions[_currentIndex].optionB,
                                          onPressed: () => _checkAnswer('B'),
                                          isSelected: _selectedAnswer == 'B',
                                          isCorrect: _selectedAnswer == 'B' && _isCorrectAnswer,
                                        ),
                                        AnswerButton(
                                          optionKey: 'C',
                                          optionText: _questions[_currentIndex].optionC,
                                          onPressed: () => _checkAnswer('C'),
                                          isSelected: _selectedAnswer == 'C',
                                          isCorrect: _selectedAnswer == 'C' && _isCorrectAnswer,
                                        ),
                                        AnswerButton(
                                          optionKey: 'D',
                                          optionText: _questions[_currentIndex].optionD,
                                          onPressed: () => _checkAnswer('D'),
                                          isSelected: _selectedAnswer == 'D',
                                          isCorrect: _selectedAnswer == 'D' && _isCorrectAnswer,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isDarkMode 
                                            ? Colors.grey.shade700 
                                            : Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDarkMode 
                                                ? Colors.black26 
                                                : Colors.blue.shade100,
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Skor: $_score',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode ? Colors.white : Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        );
      },
    );
  }
}