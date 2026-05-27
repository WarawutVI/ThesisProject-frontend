# Backend Routes Required — Practice Feature

> **Node.js/Express backend** at `http://10.0.2.2:4000`  
> **Flask ML backend** at `http://10.0.2.2:5000`  
> All requests/responses use `Content-Type: application/json` unless noted.

---

## 1. GET `/vowels`

Returns the 9 vowels of a given type with each user's completion count.

**Query params:**
| Param | Type | Example |
|-------|------|---------|
| `type` | `'short'` \| `'long'` | `short` |
| `firebase_uid` | string | `abc123` |

**Response (array):**
```json
[
  {
    "vowel_id": 1,
    "symbol": "-า",
    "vowel_type": "long",
    "completed": 7,
    "total": 9
  }
]
```

**SQL to use (from `database_guide.md`):**
```sql
SELECT
  v.id        AS vowel_id,
  v.symbol,
  v.vowel_type,
  COUNT(CASE WHEN ulp.is_completed = TRUE THEN 1 END) AS completed,
  COUNT(vl.id) AS total
FROM vowels v
LEFT JOIN vowel_lessons vl ON vl.vowel_id = v.id
LEFT JOIN user_lesson_progress ulp
  ON ulp.lesson_id = vl.id AND ulp.firebase_uid = ?
WHERE v.vowel_type = ?
GROUP BY v.id
ORDER BY v.id;
```

---

## 2. GET `/lessons`

Returns all lessons (words) for one vowel with per-lesson status for the user.

**Query params:**
| Param | Type | Example |
|-------|------|---------|
| `vowel_id` | integer | `1` |
| `firebase_uid` | string | `abc123` |

**Response (array):**
```json
[
  {
    "lesson_id": 1,
    "lesson_order": 1,
    "lesson_name": "กา",
    "is_completed": null,
    "best_accuracy": 0.0,
    "attempts": 0
  },
  {
    "lesson_id": 2,
    "lesson_order": 2,
    "lesson_name": "ขา",
    "is_completed": 1,
    "best_accuracy": 0.85,
    "attempts": 3
  }
]
```

> `is_completed`: `null` = not attempted, `0` = failed, `1` = passed

**SQL to use:**
```sql
SELECT
  vl.id           AS lesson_id,
  vl.lesson_order,
  vl.lesson_name,
  ulp.is_completed,
  COALESCE(ulp.best_accuracy, 0.0) AS best_accuracy,
  COALESCE(ulp.attempts, 0)        AS attempts
FROM vowel_lessons vl
LEFT JOIN user_lesson_progress ulp
  ON vl.id = ulp.lesson_id AND ulp.firebase_uid = ?
WHERE vl.vowel_id = ?
ORDER BY vl.lesson_order;
```

---

## 3. POST `/practice_sessions`

Saves one recording result after the Flask model returns a score.

**Request body:**
```json
{
  "firebase_uid": "abc123",
  "lesson_id": 2,
  "confidence": 0.82,
  "is_passed": true,
  "duration_seconds": 2
}
```

**SQL to use:**
```sql
INSERT INTO practice_sessions
  (firebase_uid, lesson_id, confidence, is_passed, duration_seconds)
VALUES (?, ?, ?, ?, ?);
```

**Response:** `{ "message": "ok" }` with status `200`

---

## 4. POST `/user_lesson_progress`

Upserts (insert or update) a user's progress on a specific lesson.

**Request body:**
```json
{
  "firebase_uid": "abc123",
  "lesson_id": 2,
  "is_completed": true,
  "best_accuracy": 0.82
}
```

**SQL to use:**
```sql
INSERT INTO user_lesson_progress
  (firebase_uid, lesson_id, is_completed, best_accuracy, attempts, last_practiced_at)
VALUES (?, ?, ?, ?, 1, NOW())
ON DUPLICATE KEY UPDATE
  is_completed      = GREATEST(is_completed, VALUES(is_completed)),
  best_accuracy     = GREATEST(best_accuracy, VALUES(best_accuracy)),
  attempts          = attempts + 1,
  last_practiced_at = NOW();
```

**Response:** `{ "message": "ok" }` with status `200`

---

## 5. PUT `/user_streaks`

Updates the streak counter after each practice session.

**Request body:**
```json
{
  "firebase_uid": "abc123"
}
```

**SQL to use:**
```sql
UPDATE user_streaks
SET
  current_streak = CASE
    WHEN last_practice_date = CURDATE() - INTERVAL 1 DAY THEN current_streak + 1
    WHEN last_practice_date < CURDATE() - INTERVAL 1 DAY THEN 1
    ELSE current_streak
  END,
  longest_streak = GREATEST(longest_streak,
    CASE
      WHEN last_practice_date = CURDATE() - INTERVAL 1 DAY THEN current_streak + 1
      WHEN last_practice_date < CURDATE() - INTERVAL 1 DAY THEN 1
      ELSE current_streak
    END
  ),
  last_practice_date = CURDATE()
WHERE firebase_uid = ?;
```

**Response:** `{ "message": "ok" }` with status `200`

---

## 6. Flask POST `/predict2`  *(already exists — verify field names)*

**Request:** `multipart/form-data`
| Field | Type | Description |
|-------|------|-------------|
| `file` | WAV audio file | 16kHz mono, ~2 seconds |
| `index` | string (integer) | Vowel index 0–17 (see table below) |

**Vowel index table:**
| index | vowel | type |
|-------|-------|------|
| 0 | อา | long |
| 1 | อี | long |
| 2 | อือ | long |
| 3 | อู | long |
| 4 | เอ | long |
| 5 | แอ | long |
| 6 | โอ | long |
| 7 | ออ | long |
| 8 | เออ | long |
| 9 | อะ | short |
| 10 | อิ | short |
| 11 | อึ | short |
| 12 | อุ | short |
| 13 | เอะ | short |
| 14 | แอะ | short |
| 15 | โอะ | short |
| 16 | เอาะ | short |
| 17 | เออะ | short |

**Response:**
```json
{
  "confidence": 0.82,
  "user_formants": {
    "F1": 720.5,
    "F2": 1240.3
  }
}
```

---

## 7. GET `/user_streaks`

Returns the current and longest streak for the user (read version of route 5).

**Query params:**
| Param | Type | Example |
|-------|------|---------|
| `firebase_uid` | string | `abc123` |

**Response:**
```json
{
  "current_streak": 7,
  "longest_streak": 14,
  "last_practice_date": "2026-05-20"
}
```

**SQL to use:**
```sql
SELECT current_streak, longest_streak, last_practice_date
FROM user_streaks
WHERE firebase_uid = ?;
```

> Return `{ current_streak: 0, longest_streak: 0, last_practice_date: null }` if the row doesn't exist yet.

---

## 8. GET `/progress/summary`

Returns overall accuracy stats across all practice sessions for a user.

**Query params:**
| Param | Type | Example |
|-------|------|---------|
| `firebase_uid` | string | `abc123` |

**Response:**
```json
{
  "overall_accuracy": 0.76,
  "total_sessions": 124,
  "best_accuracy": 0.98,
  "long_avg_accuracy": 0.71,
  "short_avg_accuracy": 0.43
}
```

> All accuracy values are `0.0–1.0` floats (not percentages). Return `0.0` for fields with no data.

**SQL to use:**
```sql
SELECT
  COALESCE(AVG(ps.confidence), 0.0)                                         AS overall_accuracy,
  COUNT(ps.id)                                                               AS total_sessions,
  COALESCE(MAX(ps.confidence), 0.0)                                         AS best_accuracy,
  COALESCE(AVG(CASE WHEN v.vowel_type = 'long'  THEN ps.confidence END), 0.0) AS long_avg_accuracy,
  COALESCE(AVG(CASE WHEN v.vowel_type = 'short' THEN ps.confidence END), 0.0) AS short_avg_accuracy
FROM practice_sessions ps
JOIN vowel_lessons vl ON vl.id = ps.lesson_id
JOIN vowels v          ON v.id  = vl.vowel_id
WHERE ps.firebase_uid = ?;
```

---

## 9. GET `/progress/vowel_stats`

Returns per-vowel practice count and average accuracy for a given vowel type.
Used to power the **Practice Count** bar chart and **Vowels to work on** section.

**Query params:**
| Param | Type | Example |
|-------|------|---------|
| `firebase_uid` | string | `abc123` |
| `type` | `'short'` \| `'long'` | `short` |

**Response (array, one entry per vowel):**
```json
[
  {
    "vowel_id": 10,
    "symbol": "-ะ",
    "vowel_type": "short",
    "practice_count": 7,
    "avg_accuracy": 0.54
  }
]
```

**SQL to use:**
```sql
SELECT
  v.id                                  AS vowel_id,
  v.symbol,
  v.vowel_type,
  COUNT(ps.id)                          AS practice_count,
  COALESCE(AVG(ps.confidence), 0.0)     AS avg_accuracy
FROM vowels v
LEFT JOIN vowel_lessons vl ON vl.vowel_id = v.id
LEFT JOIN practice_sessions ps
  ON ps.lesson_id = vl.id AND ps.firebase_uid = ?
WHERE v.vowel_type = ?
GROUP BY v.id
ORDER BY v.id;
```

---

## 10. GET `/practice_sessions/recent`

Returns the N most recent practice sessions with vowel info.
Used to power the **Recent Sessions** list.

**Query params:**
| Param | Type | Example |
|-------|------|---------|
| `firebase_uid` | string | `abc123` |
| `limit` | integer | `5` |

**Response (array):**
```json
[
  {
    "symbol": "-า",
    "vowel_type": "long",
    "confidence": 0.88,
    "practiced_at": "2026-05-20T14:32:00"
  }
]
```

> `practiced_at` must be ISO 8601 format so Dart's `DateTime.parse()` can parse it.

**SQL to use:**
```sql
SELECT
  v.symbol,
  v.vowel_type,
  ps.confidence,
  ps.practiced_at
FROM practice_sessions ps
JOIN vowel_lessons vl ON vl.id = ps.lesson_id
JOIN vowels v          ON v.id  = vl.vowel_id
WHERE ps.firebase_uid = ?
ORDER BY ps.practiced_at DESC
LIMIT ?;
```

---

## 11. GET `/progress/trend`

Returns daily average accuracy for the last 7 days.
Used to power the **Accuracy Trend** line chart.

**Query params:**
| Param | Type | Example |
|-------|------|---------|
| `firebase_uid` | string | `abc123` |
| `type` | `'short'` \| `'long'` | `short` |

**Response (array, up to 7 entries — only days with at least one session):**
```json
[
  { "date": "2026-05-14", "avg_accuracy": 0.65 },
  { "date": "2026-05-15", "avg_accuracy": 0.71 },
  { "date": "2026-05-20", "avg_accuracy": 0.80 }
]
```

> Days with no sessions are omitted. The chart handles sparse data by plotting points at their index position.

**SQL to use:**
```sql
SELECT
  DATE(ps.practiced_at)         AS date,
  AVG(ps.confidence)            AS avg_accuracy
FROM practice_sessions ps
JOIN vowel_lessons vl ON vl.id = ps.lesson_id
JOIN vowels v          ON v.id  = vl.vowel_id
WHERE ps.firebase_uid = ?
  AND v.vowel_type    = ?
  AND ps.practiced_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
GROUP BY DATE(ps.practiced_at)
ORDER BY date ASC;
```

---

## Also Required — Database Schema (CREATE TABLE)

Run once to create all tables from scratch:

```sql
-- 1. Users
CREATE TABLE users (
  firebase_uid  VARCHAR(128) PRIMARY KEY,
  email         VARCHAR(255) NOT NULL,
  name          VARCHAR(255),
  age           INT,
  gender        VARCHAR(20),
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. Vowels (one row per vowel sound, e.g. อา, อี, ...)
CREATE TABLE vowels (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  symbol          VARCHAR(20)  NOT NULL,
  vowel_type      ENUM('short','long') NOT NULL,

  -- Bilingual name & description for the Lessons page
  name_en         VARCHAR(100),
  name_th         VARCHAR(100),
  description_en  TEXT,
  description_th  TEXT,

  -- Pronunciation guide (bilingual)
  lips_en         VARCHAR(100),
  lips_th         VARCHAR(100),
  tongue_en       VARCHAR(100),
  tongue_th       VARCHAR(100),
  jaw_en          VARCHAR(100),
  jaw_th          VARCHAR(100),
  duration_en     VARCHAR(50),
  duration_th     VARCHAR(50)
);

-- 3. Vowel lessons — individual words to practice (e.g. กา, ขา)
CREATE TABLE vowel_lessons (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  vowel_id     INT NOT NULL,
  lesson_order INT NOT NULL,
  lesson_name  VARCHAR(50) NOT NULL,
  FOREIGN KEY (vowel_id) REFERENCES vowels(id)
);

-- 4. User lesson progress (one row per user+lesson, upserted)
CREATE TABLE user_lesson_progress (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  firebase_uid      VARCHAR(128) NOT NULL,
  lesson_id         INT NOT NULL,
  is_completed      TINYINT(1) DEFAULT 0,
  best_accuracy     FLOAT DEFAULT 0.0,
  attempts          INT DEFAULT 0,
  last_practiced_at DATETIME,
  UNIQUE KEY uq_user_lesson (firebase_uid, lesson_id),
  FOREIGN KEY (lesson_id) REFERENCES vowel_lessons(id)
);

-- 5. Practice sessions (one row per recording attempt)
CREATE TABLE practice_sessions (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  firebase_uid     VARCHAR(128) NOT NULL,
  lesson_id        INT NOT NULL,
  confidence       FLOAT NOT NULL,
  is_passed        TINYINT(1) NOT NULL,
  duration_seconds INT DEFAULT 0,
  practiced_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (lesson_id) REFERENCES vowel_lessons(id)
);

-- 6. User streaks
CREATE TABLE user_streaks (
  firebase_uid       VARCHAR(128) PRIMARY KEY,
  current_streak     INT DEFAULT 0,
  longest_streak     INT DEFAULT 0,
  last_practice_date DATE
);
```

---

## Also Required — Database Seed

Run once before testing:

```sql
-- 1. Seed vowels (18 rows)
INSERT INTO vowels (symbol, vowel_type) VALUES
('-า','long'), ('-ี','long'), ('-ื','long'), ('-ู','long'),
('เ-','long'), ('แ-','long'), ('โ-','long'), ('-อ','long'), ('เ-อ','long'),
('-ะ','short'), ('-ิ','short'), ('-ึ','short'), ('-ุ','short'),
('เ-ะ','short'), ('แ-ะ','short'), ('โ-ะ','short'), ('เ-าะ','short'), ('เ-อะ','short');

-- 2. Seed vowel_lessons (9 words per vowel, example for vowel_id=1 อา)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(1,1,'กา'),(1,2,'ขา'),(1,3,'งา'),(1,4,'จา'),(1,5,'ซา'),
(1,6,'ดา'),(1,7,'นา'),(1,8,'บา'),(1,9,'ปา');
-- Repeat for vowel_id 2–18

-- 3. Create streak row when user signs up (add to POST /users handler)
INSERT INTO user_streaks (firebase_uid) VALUES (?);
```

---

## Also Required — Flutter Assets

Place 18 WAV reference files (16kHz mono) at:
```
assets/references/
  01.wav   ← อา  (long vowel 1)
  02.wav   ← อี
  ...
  09.wav   ← เออ
  s1.wav   ← อะ  (short vowel 1)
  s2.wav   ← อิ
  ...
  s9.wav   ← เออะ
```

Then declare in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/picture/
    - assets/references/
```
