import 'dart:math';

enum InterviewCategory { systemDesign, dsa, cloudDevOps, behavioral }

class RubricScore {
  final int technicalAccuracy; // 0-10
  final int clarity;          // 0-10
  final int confidence;       // 0-10
  final int overallScore;     // 0-10
  final String strengths;
  final String improvements;
  final String modelAnswer;

  RubricScore({
    required this.technicalAccuracy,
    required this.clarity,
    required this.confidence,
    required this.overallScore,
    required this.strengths,
    required this.improvements,
    required this.modelAnswer,
  });
}

class InterviewQuestion {
  final String id;
  final String question;
  final InterviewCategory category;
  final String difficulty;
  final List<String> expectedKeywords;

  InterviewQuestion({
    required this.id,
    required this.question,
    required this.category,
    required this.difficulty,
    required this.expectedKeywords,
  });
}

class EnhancedAiInterviewService {
  final _random = Random();

  final List<InterviewQuestion> _questionBank = [
    InterviewQuestion(
      id: 'sd_1',
      question: 'How would you architect a fault-tolerant, low-latency URL Shortener (like Bit.ly) capable of 100k requests/sec?',
      category: InterviewCategory.systemDesign,
      difficulty: 'Hard',
      expectedKeywords: ['Base62', 'Redis Cache', 'Distributed Key Generation', 'Rate Limiter', 'Consistent Hashing'],
    ),
    InterviewQuestion(
      id: 'sd_2',
      question: 'Design an end-to-end Notification System supporting Push (FCM), SMS, and Email with guaranteed delivery and de-duplication.',
      category: InterviewCategory.systemDesign,
      difficulty: 'Medium',
      expectedKeywords: ['Message Queue', 'Kafka', 'Dead Letter Queue', 'Worker Pools', 'Idempotency Key'],
    ),
    InterviewQuestion(
      id: 'dsa_1',
      question: 'Explain how you would find the Median of Two Sorted Arrays in O(log(min(N, M))) time complexity.',
      category: InterviewCategory.dsa,
      difficulty: 'Hard',
      expectedKeywords: ['Binary Search', 'Partitioning', 'Median index', 'Edge case overflow'],
    ),
    InterviewQuestion(
      id: 'dsa_2',
      question: 'How does the LRU (Least Recently Used) Cache work, and why does combining Doubly Linked List with Hash Map achieve O(1) operations?',
      category: InterviewCategory.dsa,
      difficulty: 'Medium',
      expectedKeywords: ['Doubly Linked List', 'HashMap', 'Head Node', 'Tail Eviction', 'O(1) lookups'],
    ),
    InterviewQuestion(
      id: 'cloud_1',
      question: 'Explain how AWS S3 Multi-Part Upload accelerates large binary uploads and how Presigned URLs eliminate backend load.',
      category: InterviewCategory.cloudDevOps,
      difficulty: 'Medium',
      expectedKeywords: ['Multi-Part Parts', 'Presigned PUT', 'IAM Policy', 'Byte Subarrays', 'Zero Backend Overhead'],
    ),
    InterviewQuestion(
      id: 'cloud_2',
      question: 'What is Blue/Green vs Canary deployment in Kubernetes / AWS ECS, and how do you ensure zero-downtime database migrations?',
      category: InterviewCategory.cloudDevOps,
      difficulty: 'Hard',
      expectedKeywords: ['Traffic Weight', 'Load Balancer', 'Backward Compatibility', 'Rollback Strategy'],
    ),
    InterviewQuestion(
      id: 'hr_1',
      question: 'Describe a challenging production incident or technical disagreement you encountered. How did you resolve it collaboratively?',
      category: InterviewCategory.behavioral,
      difficulty: 'Standard',
      expectedKeywords: ['STAR Method', 'Situation', 'Task', 'Action', 'Measurable Result'],
    ),
  ];

  Future<InterviewQuestion> getRandomQuestion(InterviewCategory category) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final filtered = _questionBank.where((q) => q.category == category).toList();
    if (filtered.isEmpty) return _questionBank.first;
    return filtered[_random.nextInt(filtered.length)];
  }

  Future<RubricScore> evaluateAnswer({
    required InterviewQuestion question,
    required String answerText,
    required bool wasVoiceRecorded,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    final words = answerText.toLowerCase().split(RegExp(r'\s+'));
    final matchedCount = question.expectedKeywords.where((kw) => answerText.toLowerCase().contains(kw.toLowerCase())).length;

    int techScore = min(10, max(4, 5 + matchedCount * 2 + (words.length > 50 ? 1 : 0)));
    int clarityScore = words.length >= 40 ? 9 : (words.length >= 20 ? 7 : 5);
    int confidenceScore = wasVoiceRecorded ? 9 : 8;
    int overall = ((techScore * 0.5) + (clarityScore * 0.3) + (confidenceScore * 0.2)).round();

    return RubricScore(
      technicalAccuracy: techScore,
      clarity: clarityScore,
      confidence: confidenceScore,
      overallScore: overall,
      strengths: matchedCount > 0
          ? 'Strong technical vocabulary! Highlighted key architectural concepts (${question.expectedKeywords.take(2).join(", ")}).'
          : 'Clear structure and concise delivery with articulate reasoning.',
      improvements: matchedCount < question.expectedKeywords.length
          ? 'Consider deepening your explanation of ${question.expectedKeywords.last} and providing concrete latency benchmarks.'
          : 'Excellent coverage. Continue practicing delivery under timed conditions.',
      modelAnswer: 'A high-scoring answer would detail ${question.expectedKeywords.join(", ")}, explicitly addressing latency trade-offs, scalability bottlenecks, and failure recovery modes.',
    );
  }
}
