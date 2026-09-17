
class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String topic;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.topic,
  });
}

class LeaderboardRank {
  final int rank;
  final String studentName;
  final String college;
  final int score;
  final int streakDays;

  LeaderboardRank({
    required this.rank,
    required this.studentName,
    required this.college,
    required this.score,
    required this.streakDays,
  });
}

class QuizService {
  QuizService._();
  static final QuizService instance = QuizService._();

  final List<QuizQuestion> questions = [
    QuizQuestion(
      id: 'q1',
      question: 'In Data Structures, what is the worst-case time complexity of searching in a Balanced Binary Search Tree (AVL / Red-Black)?',
      options: ['O(1)', 'O(log N)', 'O(N)', 'O(N log N)'],
      correctIndex: 1,
      explanation: 'Balanced BSTs guarantee height <= O(log N), ensuring search, insert, and delete take logarithmic time.',
      topic: 'DSA',
    ),
    QuizQuestion(
      id: 'q2',
      question: 'Which AWS service is designed specifically for durable, 99.999999999% cloud object storage with presigned URLs?',
      options: ['AWS EC2', 'AWS RDS', 'Amazon S3', 'Amazon DynamoDB'],
      correctIndex: 2,
      explanation: 'Amazon S3 provides 11 9s durability and supports direct presigned PUT/GET URLs.',
      topic: 'Cloud & DevOps',
    ),
    QuizQuestion(
      id: 'q3',
      question: 'What is the primary function of an operating system\'s Translation Lookaside Buffer (TLB)?',
      options: [
        'Cache virtual-to-physical address translations',
        'Schedule CPU threads across multiple cores',
        'Store interrupt service routines',
        'Manage swap disk paging blocks'
      ],
      correctIndex: 0,
      explanation: 'The TLB is a high-speed memory cache storing recent virtual-to-physical page mappings to speed up memory access.',
      topic: 'Operating Systems',
    ),
    QuizQuestion(
      id: 'q4',
      question: 'In Computer Networks, which layer is responsible for end-to-end flow control, sequencing, and TCP 3-way handshake?',
      options: ['Network Layer', 'Transport Layer', 'Data Link Layer', 'Application Layer'],
      correctIndex: 1,
      explanation: 'The Transport Layer (TCP/UDP) handles process-to-process delivery, flow control, and connection handshakes.',
      topic: 'Networking',
    ),
    QuizQuestion(
      id: 'q5',
      question: 'In Flutter, which mechanism enables compiling Flutter apps into single-architecture native binaries to optimize APK size?',
      options: ['Split-per-ABI compilation', 'Tree shaking', 'Just-In-Time compiling', 'Gradle Minification'],
      correctIndex: 0,
      explanation: 'flutter build apk --split-per-abi generates separate APKs for arm64-v8a, armeabi-v7a, and x86_64, reducing download sizes by ~60%.',
      topic: 'Mobile Engineering',
    ),
  ];

  final List<LeaderboardRank> leaderboard = [
    LeaderboardRank(rank: 1, studentName: 'Aditya Verma', college: 'RV College of Engg', score: 2840, streakDays: 14),
    LeaderboardRank(rank: 2, studentName: 'Sneha Patel', college: 'PES University', score: 2710, streakDays: 12),
    LeaderboardRank(rank: 3, studentName: 'Abhimanu S. (You)', college: 'College of Engg & Tech', score: 2650, streakDays: 8),
    LeaderboardRank(rank: 4, studentName: 'Rohan Deshmukh', college: 'BMS College of Engg', score: 2490, streakDays: 9),
    LeaderboardRank(rank: 5, studentName: 'Pooja Hegde', college: 'MS Ramaiah Institute', score: 2320, streakDays: 7),
    LeaderboardRank(rank: 6, studentName: 'Karthik Rao', college: 'NIT Karnataka', score: 2180, streakDays: 5),
  ];
}
