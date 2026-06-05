import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/quiz_service.dart';
import '../models/quiz_history.dart';
import '../providers/theme_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  final QuizService _quizService = QuizService();
  List<QuizHistory> _histories = [];
  bool _isLoading = true;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    _histories = await _quizService.getAllHistory();
    setState(() => _isLoading = false);
    _fadeController.forward();
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text('Apakah Anda yakin ingin menghapus semua riwayat?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _quizService.clearHistory();
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Riwayat berhasil dihapus')),
        );
      }
    }
  }

  String _getScoreMessage(int score, int total) {
    double percentage = (score / total) * 100;
    if (percentage >= 80) return 'Sangat Baik';
    if (percentage >= 60) return 'Baik';
    if (percentage >= 40) return 'Cukup';
    return 'Kurang';
  }

  Color _getScoreColor(int score, int total, bool isDarkMode) {
    double percentage = (score / total) * 100;
    if (percentage >= 80) {
      return isDarkMode ? Colors.green.shade300 : Colors.green.shade700;
    }
    if (percentage >= 60) {
      return isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700;
    }
    if (percentage >= 40) {
      return isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700;
    }
    return isDarkMode ? Colors.red.shade300 : Colors.red.shade700;
  }

  Color _getMessageColor(String message, bool isDarkMode) {
    if (message.contains('Luar biasa')) {
      return isDarkMode ? Colors.green.shade300 : Colors.green.shade700;
    }
    if (message.contains('Bagus')) {
      return isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700;
    }
    if (message.contains('belajar')) {
      return isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700;
    }
    return isDarkMode ? Colors.red.shade300 : Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.isDarkMode;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Riwayat Quiz'),
            centerTitle: true,
            backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.blue.shade700,
            foregroundColor: Colors.white,
            actions: [
              if (_histories.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: _clearHistory,
                  tooltip: 'Hapus Semua',
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _histories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 80, color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
                              const SizedBox(height: 20),
                              Text(
                                'Belum ada riwayat quiz',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Mainkan quiz untuk melihat riwayat',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadHistory,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _histories.length,
                            itemBuilder: (context, index) {
                              final history = _histories[index];
                              final isHighest = index == 0;
                              final scoreCategory = _getScoreMessage(history.score, history.totalQuestions);
                              final scoreColor = _getScoreColor(history.score, history.totalQuestions, isDarkMode);
                              final messageColor = _getMessageColor(history.message, isDarkMode);
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: isDarkMode 
                                    ? (isHighest ? Colors.grey.shade700 : Colors.grey.shade800)
                                    : (isHighest ? Colors.amber.shade50 : Colors.white),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: scoreColor.withAlpha(30),
                                            child: Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                color: scoreColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Skor: ${history.score}/${history.totalQuestions}',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDarkMode ? Colors.white : Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: scoreColor.withAlpha(20),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    scoreCategory,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: scoreColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: scoreColor.withAlpha(20),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${history.percentage.toInt()}%',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: scoreColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        history.message,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: messageColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${history.date.day}/${history.date.month}/${history.date.year} ${history.date.hour}:${history.date.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ),
        );
      },
    );
  }
}