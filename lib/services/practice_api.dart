import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String _base = 'https://perkiness-shadiness-extras.ngrok-free.dev';
const String _flaskBase = 'https://perkiness-shadiness-extras.ngrok-free.dev';

class VowelDetail {
  final int id;
  final String symbol;
  final String vowelType;
  final String? unicodePhonetic;
  final String? descriptionEn;
  final String? descriptionTh;
  final String? lipsEn;
  final String? lipsTh;
  final String? tongueEn;
  final String? tongueTh;
  final String? jawEn;
  final String? jawTh;
  final String? linkVideo;

  const VowelDetail({
    required this.id,
    required this.symbol,
    required this.vowelType,
    this.unicodePhonetic,
    this.descriptionEn,
    this.descriptionTh,
    this.lipsEn,
    this.lipsTh,
    this.tongueEn,
    this.tongueTh,
    this.jawEn,
    this.jawTh,
    this.linkVideo,
  });

  factory VowelDetail.fromJson(Map<String, dynamic> j) => VowelDetail(
        id: j['id'] as int,
        symbol: j['symbol'] as String,
        vowelType: j['vowel_type'] as String,
        unicodePhonetic: j['unicode_phonetic'] as String?,
        descriptionEn: j['description_en'] as String?,
        descriptionTh: j['description_th'] as String?,
        lipsEn: j['lips_en'] as String?,
        lipsTh: j['lips_th'] as String?,
        tongueEn: j['tongue_en'] as String?,
        tongueTh: j['tongue_th'] as String?,
        jawEn: j['jaw_en'] as String?,
        jawTh: j['jaw_th'] as String?,
        linkVideo: j['link_video'] as String?,
      );
}

class VowelProgress {
  final int vowelId;
  final String symbol;
  final String vowelType;
  final int completed;
  final int total;

  const VowelProgress({
    required this.vowelId,
    required this.symbol,
    required this.vowelType,
    required this.completed,
    required this.total,
  });

  factory VowelProgress.fromJson(Map<String, dynamic> j) => VowelProgress(
        vowelId: j['vowel_id'] as int,
        symbol: j['symbol'] as String,
        vowelType: j['vowel_type'] as String,
        completed: (j['completed'] ?? 0) as int,
        total: (j['total'] ?? 9) as int,
      );
}


class LessonProgress {
  final int lessonId;
  final int lessonOrder;
  final String lessonName;
  final bool? isCompleted; // null = not attempted
  final double bestAccuracy;
  final int attempts;

  const LessonProgress({
    required this.lessonId,
    required this.lessonOrder,
    required this.lessonName,
    required this.isCompleted,
    required this.bestAccuracy,
    required this.attempts,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> j) => LessonProgress(
        lessonId: j['lesson_id'] as int,
        lessonOrder: j['lesson_order'] as int,
        lessonName: j['lesson_name'] as String,
        isCompleted: j['is_completed'] == null ? null : (j['is_completed'] as int) == 1,
        bestAccuracy: (j['best_accuracy'] ?? 0.0).toDouble(),
        attempts: (j['attempts'] ?? 0) as int,
      );
}

class VowelFormant {
  final double f1;
  final double f2;

  const VowelFormant({required this.f1, required this.f2});

  factory VowelFormant.fromJson(Map<String, dynamic> j) => VowelFormant(
        f1: (j['f1'] as num).toDouble(),
        f2: (j['f2'] as num).toDouble(),
      );
}

class PredictResult {
  final double confidence;
  final bool isPassed;
  final double userF1;
  final double userF2;

  const PredictResult({
    required this.confidence,
    required this.isPassed,
    required this.userF1,
    required this.userF2,
  });

  factory PredictResult.fromJson(Map<String, dynamic> j) {
    final conf = (j['confidence'] as num? ?? 0.0).toDouble();
    final formants = j['user_formants'] as Map<String, dynamic>? ?? {};
    return PredictResult(
      confidence: conf,
      isPassed: conf >= 0.70,
      userF1: (formants['F1'] as num? ?? 0.0).toDouble(),
      userF2: (formants['F2'] as num? ?? 0.0).toDouble(),
    );
  }
}

class UserStreak {
  final int currentStreak;
  final int longestStreak;
  final String? lastPracticeDate;

  const UserStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastPracticeDate,
  });

  factory UserStreak.fromJson(Map<String, dynamic> j) => UserStreak(
        currentStreak: (j['current_streak'] ?? 0) as int,
        longestStreak: (j['longest_streak'] ?? 0) as int,
        lastPracticeDate: j['last_practice_date'] as String?,
      );
}

class ProgressSummary {
  final double overallAccuracy;
  final int totalSessions;
  final double bestAccuracy;
  final double longAvgAccuracy;
  final double shortAvgAccuracy;

  const ProgressSummary({
    required this.overallAccuracy,
    required this.totalSessions,
    required this.bestAccuracy,
    required this.longAvgAccuracy,
    required this.shortAvgAccuracy,
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> j) => ProgressSummary(
        overallAccuracy: (j['overall_accuracy'] ?? 0.0).toDouble(),
        totalSessions: (j['total_sessions'] ?? 0) as int,
        bestAccuracy: (j['best_accuracy'] ?? 0.0).toDouble(),
        longAvgAccuracy: (j['long_avg_accuracy'] ?? 0.0).toDouble(),
        shortAvgAccuracy: (j['short_avg_accuracy'] ?? 0.0).toDouble(),
      );
}

class VowelStats {
  final int vowelId;
  final String symbol;
  final String vowelType;
  final int practiceCount;
  final double avgAccuracy;

  const VowelStats({
    required this.vowelId,
    required this.symbol,
    required this.vowelType,
    required this.practiceCount,
    required this.avgAccuracy,
  });

  factory VowelStats.fromJson(Map<String, dynamic> j) => VowelStats(
        vowelId: j['vowel_id'] as int,
        symbol: j['symbol'] as String,
        vowelType: j['vowel_type'] as String,
        practiceCount: (j['practice_count'] ?? 0) as int,
        avgAccuracy: (j['avg_accuracy'] ?? 0.0).toDouble(),
      );
}

class SessionRecord {
  final String symbol;
  final String vowelType;
  final String lessonName;
  final double confidence;
  final DateTime practicedAt;

  const SessionRecord({
    required this.symbol,
    required this.vowelType,
    required this.lessonName,
    required this.confidence,
    required this.practicedAt,
  });

  factory SessionRecord.fromJson(Map<String, dynamic> j) => SessionRecord(
        symbol: j['symbol'] as String,
        vowelType: j['vowel_type'] as String,
        lessonName: j['lesson_name'] as String,
        confidence: (j['confidence'] ?? 0.0).toDouble(),
        practicedAt: DateTime.parse(j['practiced_at'] as String),
      );
}

class DailyTrend {
  final DateTime date;
  final double avgAccuracy;

  const DailyTrend({required this.date, required this.avgAccuracy});

  factory DailyTrend.fromJson(Map<String, dynamic> j) => DailyTrend(
        date: DateTime.parse(j['date'] as String),
        avgAccuracy: (j['avg_accuracy'] ?? 0.0).toDouble(),
      );
}

class PracticeApi {
  // POST /users — call once after sign-up
  static Future<void> createUser({
    required String firebaseUid,
    required String username,
    required String email,
    required String gender,
    required int age,
    required String loginProvider,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebase_uid': firebaseUid,
        'username': username,
        'email': email,
        'gender': gender,
        'age': age,
        'login_provider': loginProvider,
      }),
    );
    if (res.statusCode != 200) throw Exception('Failed to create user');
  }

  // GET /vowels?type=short|long&firebase_uid=X
  static Future<List<VowelProgress>> fetchVowels(
      String firebaseUid, String type) async {
    final uri = Uri.parse('$_base/vowels')
        .replace(queryParameters: {'type': type, 'firebase_uid': firebaseUid});
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load vowels');
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => VowelProgress.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /lessons?vowel_id=X&firebase_uid=Y
  static Future<List<LessonProgress>> fetchLessons(
      String firebaseUid, int vowelId) async {
    final uri = Uri.parse('$_base/lessons').replace(queryParameters: {
      'vowel_id': vowelId.toString(),
      'firebase_uid': firebaseUid,
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load lessons');
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => LessonProgress.fromJson(e as Map<String, dynamic>)).toList();
  }

  // POST Flask /predict2 — file: WAV audio, index: vowel index 0–17
  static Future<PredictResult> predict(File audioFile, int vowelIndex) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_flaskBase/predict2'));
    req.fields['index'] = vowelIndex.toString();
    req.files.add(await http.MultipartFile.fromPath('file', audioFile.path));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) throw Exception('Prediction failed: ${res.statusCode}');
    return PredictResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // POST /practice_sessions
  static Future<void> saveSession({
    required String firebaseUid,
    required int lessonId,
    required double confidence,
    required bool isPassed,
    required int durationSeconds,
  }) async {
    await http.post(
      Uri.parse('$_base/practice_sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebase_uid': firebaseUid,
        'lesson_id': lessonId,
        'confidence': confidence,
        'is_passed': isPassed,
        'duration_seconds': durationSeconds,
      }),
    );
  }

  // POST /user_lesson_progress (UPSERT)
  static Future<void> saveProgress({
    required String firebaseUid,
    required int lessonId,
    required bool isCompleted,
    required double bestAccuracy,
  }) async {
    await http.post(
      Uri.parse('$_base/user_lesson_progress'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebase_uid': firebaseUid,
        'lesson_id': lessonId,
        'is_completed': isCompleted,
        'best_accuracy': bestAccuracy,
      }),
    );
  }

  // PUT /user_streaks
  static Future<void> updateStreak(String firebaseUid) async {
    await http.put(
      Uri.parse('$_base/user_streaks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'firebase_uid': firebaseUid}),
    );
  }

  // GET /user_streaks?firebase_uid=X
  static Future<UserStreak> fetchStreak(String firebaseUid) async {
    final uri = Uri.parse('$_base/user_streaks')
        .replace(queryParameters: {'firebase_uid': firebaseUid});
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load streak');
    return UserStreak.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // GET /progress/summary?firebase_uid=X
  static Future<ProgressSummary> fetchSummary(String firebaseUid) async {
    final uri = Uri.parse('$_base/progress/summary')
        .replace(queryParameters: {'firebase_uid': firebaseUid});
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load progress summary');
    return ProgressSummary.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // GET /progress/vowel_stats?firebase_uid=X&type=short|long
  static Future<List<VowelStats>> fetchVowelStats(
      String firebaseUid, String type) async {
    final uri = Uri.parse('$_base/progress/vowel_stats')
        .replace(queryParameters: {'firebase_uid': firebaseUid, 'type': type});
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load vowel stats');
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => VowelStats.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /practice_sessions/recent?firebase_uid=X&limit=N
  static Future<List<SessionRecord>> fetchRecentSessions(
      String firebaseUid, {int limit = 5}) async {
    final uri = Uri.parse('$_base/practice_sessions/recent').replace(
        queryParameters: {
          'firebase_uid': firebaseUid,
          'limit': limit.toString()
        });
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load sessions');
    final List data = jsonDecode(res.body) as List;
    return data
        .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /vowels/:vowelId/formants
  static Future<VowelFormant> fetchVowelFormant(int vowelId) async {
    final res = await http.get(Uri.parse('$_base/vowels/$vowelId/formants'));
    if (res.statusCode != 200) throw Exception('Failed to load vowel formant');
    return VowelFormant.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // GET /vowels/details — all 18 vowels with pronunciation guide data
  static Future<List<VowelDetail>> fetchVowelDetails() async {
    final res = await http.get(Uri.parse('$_base/vowels/details'));
    if (res.statusCode != 200) throw Exception('Failed to load vowel details');
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => VowelDetail.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /progress/trend?firebase_uid=X&type=short|long&period=week|month|year&start=YYYY-MM-DD&end=YYYY-MM-DD
  static Future<List<DailyTrend>> fetchTrend(
    String firebaseUid,
    String type, {
    String period = 'week',
    String? start,
    String? end,
  }) async {
    final params = <String, String>{
      'firebase_uid': firebaseUid,
      'type': type,
      'period': period,
    };
    if (start != null) params['start'] = start;
    if (end != null) params['end'] = end;
    final uri = Uri.parse('$_base/progress/trend').replace(queryParameters: params);
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load trend');
    final List data = jsonDecode(res.body) as List;
    return data
        .map((e) => DailyTrend.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
