class QuestionModel {
  int? id;
  final String text;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer;
  final String category;
  final String createdAt;

  QuestionModel({
    this.id,
    required this.text,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    required this.category,
    required this.createdAt,
  });

  Map<String, String> get options => {
    'A': optionA,
    'B': optionB,
    'C': optionC,
    'D': optionD,
  };

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'optionA': optionA,
      'optionB': optionB,
      'optionC': optionC,
      'optionD': optionD,
      'correctAnswer': correctAnswer,
      'category': category,
      'createdAt': createdAt,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'],
      text: map['text'],
      optionA: map['optionA'],
      optionB: map['optionB'],
      optionC: map['optionC'],
      optionD: map['optionD'],
      correctAnswer: map['correctAnswer'],
      category: map['category'],
      createdAt: map['createdAt'],
    );
  }

  bool isCorrect(String selectedOption) {
    return selectedOption == correctAnswer;
  }
}