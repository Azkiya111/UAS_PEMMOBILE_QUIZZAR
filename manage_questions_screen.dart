import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/question_provider.dart';
import '../models/question_model.dart';

class AddEditQuestionScreen extends StatefulWidget {
  final QuestionModel? question;
  const AddEditQuestionScreen({super.key, this.question});

  @override
  State<AddEditQuestionScreen> createState() => _AddEditQuestionScreenState();
}

class _AddEditQuestionScreenState extends State<AddEditQuestionScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _questionController;
  late TextEditingController _optionAController;
  late TextEditingController _optionBController;
  late TextEditingController _optionCController;
  late TextEditingController _optionDController;
  late TextEditingController _categoryController;
  String _correctAnswer = 'A';
  bool _isSaving = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question?.text ?? '');
    _optionAController = TextEditingController(text: widget.question?.optionA ?? '');
    _optionBController = TextEditingController(text: widget.question?.optionB ?? '');
    _optionCController = TextEditingController(text: widget.question?.optionC ?? '');
    _optionDController = TextEditingController(text: widget.question?.optionD ?? '');
    _categoryController = TextEditingController(text: widget.question?.category ?? 'Pengetahuan Umum');
    _correctAnswer = widget.question?.correctAnswer ?? 'A';
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _categoryController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String? _validateField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    if (value.length < 2) {
      return '$fieldName minimal 2 karakter';
    }
    return null;
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return; // Cegah double click
    
    setState(() => _isSaving = true);
    
    final question = QuestionModel(
      id: widget.question?.id,
      text: _questionController.text,
      optionA: _optionAController.text,
      optionB: _optionBController.text,
      optionC: _optionCController.text,
      optionD: _optionDController.text,
      correctAnswer: _correctAnswer,
      category: _categoryController.text,
      createdAt: widget.question?.createdAt ?? DateTime.now().toIso8601String(),
    );

    final provider = Provider.of<QuestionProvider>(context, listen: false);
    
    if (widget.question == null) {
      await provider.addQuestion(question);
      // Hapus notifikasi dari sini, karena akan ditampilkan di halaman sebelumnya
    } else {
      await provider.updateQuestion(question);
      // Hapus notifikasi dari sini, karena akan ditampilkan di halaman sebelumnya
    }
    
    setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.question == null ? 'Tambah Soal' : 'Edit Soal'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _questionController,
                            decoration: const InputDecoration(
                              labelText: 'Pertanyaan',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.help_outline),
                            ),
                            maxLines: 3,
                            validator: (value) => _validateField(value, 'Pertanyaan'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _optionAController,
                            decoration: const InputDecoration(
                              labelText: 'Pilihan A',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.looks_one),
                            ),
                            validator: (value) => _validateField(value, 'Pilihan A'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _optionBController,
                            decoration: const InputDecoration(
                              labelText: 'Pilihan B',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.looks_two),
                            ),
                            validator: (value) => _validateField(value, 'Pilihan B'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _optionCController,
                            decoration: const InputDecoration(
                              labelText: 'Pilihan C',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.looks_3),
                            ),
                            validator: (value) => _validateField(value, 'Pilihan C'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _optionDController,
                            decoration: const InputDecoration(
                              labelText: 'Pilihan D',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.looks_4),
                            ),
                            validator: (value) => _validateField(value, 'Pilihan D'),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Jawaban Benar',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'A', label: Text('A')),
                                ButtonSegment(value: 'B', label: Text('B')),
                                ButtonSegment(value: 'C', label: Text('C')),
                                ButtonSegment(value: 'D', label: Text('D')),
                              ],
                              selected: {_correctAnswer},
                              onSelectionChanged: (Set<String> newSelection) {
                                setState(() {
                                  _correctAnswer = newSelection.first;
                                });
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                                  (Set<WidgetState> states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.green;
                                    }
                                    return Colors.grey.shade200;
                                  },
                                ),
                                foregroundColor: WidgetStateProperty.resolveWith<Color>(
                                  (Set<WidgetState> states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.white;
                                    }
                                    return Colors.black87;
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _categoryController,
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                            validator: (value) => _validateField(value, 'Kategori'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveQuestion,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(widget.question == null ? 'Simpan Soal' : 'Update Soal'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}