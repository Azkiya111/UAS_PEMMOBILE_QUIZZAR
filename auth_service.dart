import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/question_provider.dart';
import '../models/question_model.dart';
import 'add_edit_question_screen.dart';

class ManageQuestionsScreen extends StatefulWidget {
  const ManageQuestionsScreen({super.key});

  @override
  State<ManageQuestionsScreen> createState() => _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends State<ManageQuestionsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
    
    // Load data hanya sekali saat pertama kali
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<QuestionProvider>(context, listen: false);
    await provider.loadAllQuestions();
    setState(() {
      _isInitialLoad = false;
    });
  }

  Future<void> _refreshQuestions() async {
    final provider = Provider.of<QuestionProvider>(context, listen: false);
    await provider.loadAllQuestions(forceRefresh: true);
  }

  Future<void> _editQuestion(QuestionModel question) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditQuestionScreen(question: question),
      ),
    );
    if (result == true && mounted) {
      await _refreshQuestions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Soal berhasil diupdate!')),
        );
      }
    }
  }

  Future<void> _addQuestion() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditQuestionScreen(),
      ),
    );
    if (result == true && mounted) {
      await _refreshQuestions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Soal berhasil ditambahkan!')),
        );
      }
    }
  }

  void _confirmDelete(QuestionModel question) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Soal'),
        content: Text('Hapus soal "${question.text}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final provider = Provider.of<QuestionProvider>(context, listen: false);
              await provider.deleteQuestion(question.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Soal berhasil dihapus')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showSearch() {
    final TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cari Soal'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Cari berdasarkan pertanyaan atau kategori',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final provider = Provider.of<QuestionProvider>(context, listen: false);
              provider.searchQuestions(searchController.text);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  void _clearSearch() {
    final provider = Provider.of<QuestionProvider>(context, listen: false);
    provider.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Soal'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
            tooltip: 'Cari Soal',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshQuestions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<QuestionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && _isInitialLoad) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat daftar soal...'),
                ],
              ),
            );
          }
          
          if (provider.questions.isEmpty && !provider.isLoading) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: _refreshQuestions,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  if (provider.searchQuery.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.blue.shade100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search, size: 16),
                          const SizedBox(width: 8),
                          Text('Hasil pencarian: "${provider.searchQuery}"'),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: _clearSearch,
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.questions.length,
                      itemBuilder: (context, index) {
                        final question = provider.questions[index];
                        return _buildQuestionCard(question, index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addQuestion,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Soal'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          const Text(
            'Belum ada soal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Text(
            'Tekan tombol + untuk menambah soal',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text('${index + 1}'),
        ),
        title: Text(
          question.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('Kategori: ${question.category}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _editQuestion(question),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(question),
              tooltip: 'Hapus',
            ),
          ],
        ),
      ),
    );
  }
}