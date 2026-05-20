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
