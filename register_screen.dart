import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart';
import 'manage_questions_screen.dart';
import 'quiz_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  String _username = '';
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _username = user?.username ?? 'User';
      });
    }
  }

  Future<void> _logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  void _toggleDarkMode() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(themeProvider.isDarkMode ? '🌙 Dark Mode Aktif' : '☀️ Light Mode Aktif'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _startQuiz() async {
    final totalQuestions = await _dbService.getTotalQuestions();
    
    if (!mounted) return;
    
    if (totalQuestions == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada soal. Silakan tambahkan soal terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    final jumlahSoal = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        int selected = totalQuestions >= 5 ? 5 : totalQuestions;
        final TextEditingController controller = TextEditingController(text: selected.toString());
        
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Pilih Jumlah Soal'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: isDarkMode ? Colors.blue.shade300 : Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Total soal tersedia: $totalQuestions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Pilih jumlah soal yang ingin dikerjakan:',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: selected.toDouble(),
                          min: 1,
                          max: totalQuestions.toDouble(),
                          divisions: totalQuestions - 1,
                          label: selected.toString(),
                          activeColor: Colors.green,
                          onChanged: (val) {
                            setStateDialog(() {
                              selected = val.toInt();
                              controller.text = selected.toString();
                            });
                          },
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextFormField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            suffixText: 'soal',
                            suffixStyle: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          onChanged: (value) {
                            int? newVal = int.tryParse(value);
                            if (newVal != null && newVal >= 1 && newVal <= totalQuestions) {
                              setStateDialog(() {
                                selected = newVal;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(dialogContext, null),
                          icon: const Icon(Icons.close),
                          label: const Text('Batal'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(dialogContext, selected),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Mulai Quiz'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    
    if (!mounted) return;
    
    if (jumlahSoal != null && jumlahSoal > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(questionCount: jumlahSoal),
        ),
      );
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quiz Interaktif'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 100,
              child: Lottie.asset(
                'assets/animations/Quiz.json',
                repeat: true,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            const Text('QuizZAR v1.0.0', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 10),
            const Text('🎯 Quiz Interaktif', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text(
              '• Pilih jumlah soal sendiri\n• Soal diacak setiap quiz\n• Kelola soal sendiri\n• Riwayat nilai tersimpan\n• Animasi menarik\n• Suara efek interaktif',
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 5),
            const Text('Dibuat untuk UAS Pemrograman Mobile', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;
    final isTablet = screenWidth >= 600 && screenWidth < 800;
    
    int crossAxisCount;
    double maxWidth;
    
    if (isDesktop) {
      crossAxisCount = 4;
      maxWidth = 1000;
    } else if (isTablet) {
      crossAxisCount = 2;
      maxWidth = 600;
    } else {
      crossAxisCount = 2;
      maxWidth = double.infinity;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuizZAR'),
        centerTitle: true,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: _toggleDarkMode,
                tooltip: 'Ganti Tema',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: themeProvider.isDarkMode
                      ? [Colors.grey.shade900, Colors.grey.shade800]
                      : [Colors.blue.shade50, Colors.white],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: SizedBox(
                      width: maxWidth,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: themeProvider.isDarkMode ? Colors.black26 : Colors.grey.shade200,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.person, size: 30, color: Colors.blue),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Selamat Datang,', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          Text(_username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 45,
                                      height: 45,
                                      child: Lottie.asset(
                                        'assets/animations/Quiz.json',
                                        repeat: true,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.0,
                              children: [
                                _buildMenuCard(
                                  icon: Icons.quiz,
                                  title: 'Mulai Quiz',
                                  subtitle: 'Pilih jumlah soal',
                                  color: Colors.green,
                                  onTap: _startQuiz,
                                  isDarkMode: themeProvider.isDarkMode,
                                ),
                                _buildMenuCard(
                                  icon: Icons.edit_note,
                                  title: 'Kelola Soal',
                                  subtitle: 'Tambah/edit/hapus',
                                  color: Colors.blue,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ManageQuestionsScreen()),
                                    );
                                  },
                                  isDarkMode: themeProvider.isDarkMode,
                                ),
                                _buildMenuCard(
                                  icon: Icons.history,
                                  title: 'Riwayat Quiz',
                                  subtitle: 'Lihat skor',
                                  color: Colors.orange,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const HistoryScreen()),
                                    );
                                  },
                                  isDarkMode: themeProvider.isDarkMode,
                                ),
                                _buildMenuCard(
                                  icon: Icons.info_outline,
                                  title: 'Tentang',
                                  subtitle: 'Informasi aplikasi',
                                  color: Colors.purple,
                                  onTap: _showAboutDialog,
                                  isDarkMode: themeProvider.isDarkMode,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}