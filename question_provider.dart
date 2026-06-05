class QuizHistory {
  final int score;
  final int totalQuestions;
  final DateTime date;
  final String message;
  
  QuizHistory({
    required this.score,
    required this.totalQuestions,
    required this.date,
    required this.message,
  });
  
  double get percentage => (score / totalQuestions) * 100;
  
  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'totalQuestions': totalQuestions,
      'date': date.toIso8601String(),
      'message': message,
    };
  }
  
  factory QuizHistory.fromJson(Map<String, dynamic> json) {
    return QuizHistory(
      score: json['score'],
      totalQuestions: json['totalQuestions'],
      date: DateTime.parse(json['date']),
      message: json['message'],
    );
  }
}