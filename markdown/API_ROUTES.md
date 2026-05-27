# API Routes Reference

| Server | Base URL |
|--------|----------|
| Node.js / Express | `http://10.0.2.2:4000` |
| Flask ML | `http://192.168.0.62:5000` |

---

## Node.js Routes

### POST `/users`
Create user profile after sign-up.

**Body**
```json
{
  "firebase_uid": "abc123",
  "username": "John",
  "email": "john@example.com",
  "gender": "male",
  "age": 21,
  "login_provider": "email"
}
```
**Response** `{ "message": "ok" }` · 200

---

### GET `/vowels`
Vowel grid with per-user completion count.

**Query params** `type=short|long` · `firebase_uid`

**Response**
```json
[{ "vowel_id": 1, "symbol": "-า", "vowel_type": "long", "completed": 7, "total": 9 }]
```

---

### GET `/lessons`
Words for one vowel with per-lesson user progress.

**Query params** `vowel_id` · `firebase_uid`

**Response**
```json
[{
  "lesson_id": 1,
  "lesson_order": 1,
  "lesson_name": "กา",
  "is_completed": null,
  "best_accuracy": 0.0,
  "attempts": 0
}]
```
> `is_completed`: `null` = not attempted · `0` = failed · `1` = passed

---

### POST `/practice_sessions`
Save one recording result.

**Body**
```json
{
  "firebase_uid": "abc123",
  "lesson_id": 2,
  "confidence": 0.82,
  "is_passed": true,
  "duration_seconds": 2
}
```
**Response** `{ "message": "ok" }` · 200

---

### POST `/user_lesson_progress`
Upsert lesson progress (insert or update best accuracy).

**Body**
```json
{
  "firebase_uid": "abc123",
  "lesson_id": 2,
  "is_completed": true,
  "best_accuracy": 0.82
}
```
**Response** `{ "message": "ok" }` · 200

---

### PUT `/user_streaks`
Recalculate and update daily streak after a session.

**Body** `{ "firebase_uid": "abc123" }`

**Response** `{ "message": "ok" }` · 200

---

### GET `/user_streaks`
Get current and longest streak.

**Query params** `firebase_uid`

**Response**
```json
{ "current_streak": 7, "longest_streak": 14, "last_practice_date": "2026-05-20" }
```
> Return zeros if no row exists yet.

---

### GET `/progress/summary`
Overall accuracy stats across all sessions.

**Query params** `firebase_uid`

**Response**
```json
{
  "overall_accuracy": 0.76,
  "total_sessions": 124,
  "best_accuracy": 0.98,
  "long_avg_accuracy": 0.71,
  "short_avg_accuracy": 0.43
}
```
> All values are `0.0–1.0` floats. Return `0.0` for fields with no data.

---

### GET `/progress/vowel_stats`
Per-vowel practice count and average accuracy.

**Query params** `firebase_uid` · `type=short|long`

**Response**
```json
[{ "vowel_id": 1, "symbol": "-า", "vowel_type": "long", "practice_count": 7, "avg_accuracy": 0.54 }]
```

---

### GET `/practice_sessions/recent`
Most recent N sessions with vowel info.

**Query params** `firebase_uid` · `limit` (default `5`)

**Response**
```json
[{ "symbol": "-า", "vowel_type": "long", "confidence": 0.88, "practiced_at": "2026-05-20T14:32:00" }]
```
> `practiced_at` must be ISO 8601 so Dart's `DateTime.parse()` works.

---

### GET `/progress/trend`
Accuracy trend grouped by period.

**Query params**

| Param | Required | Values | Notes |
|-------|----------|--------|-------|
| `firebase_uid` | ✅ | string | |
| `type` | ✅ | `short` \| `long` | |
| `period` | ✅ | `week` \| `month` \| `year` \| `custom` | default `week` |
| `start` | custom only | `YYYY-MM-DD` | range start |
| `end` | custom only | `YYYY-MM-DD` | range end |

**Grouping per period**

| period | GROUP BY | X-axis shown in app |
|--------|----------|---------------------|
| `week` | `DATE()` · last 7 days | Sun Mon Tue … Sat |
| `month` | `WEEK()` · last 4 weeks | W1 W2 W3 W4 |
| `year` | `MONTH()` · last 12 months | J F M A … D |
| `custom` | `DATE()` · `start`→`end` | d/M |

**Response** — always return `date` as ISO date string (first day of the period for month/year grouping)
```json
[{ "date": "2026-05-14", "avg_accuracy": 0.65 }]
```

---

## Flask ML Route

### POST `/predict2`
Predict vowel from a WAV recording.

**Request** `multipart/form-data`

| Field | Type | Description |
|-------|------|-------------|
| `file` | WAV file | 16 kHz mono, ~2 s |
| `index` | string (int) | Vowel index 0–17 (see table below) |

**Vowel index table**

| index | vowel | type  | | index | vowel | type  |
|-------|-------|-------|-|-------|-------|-------|
| 0 | อา | long  | | 9  | อะ  | short |
| 1 | อี | long  | | 10 | อิ  | short |
| 2 | อือ | long | | 11 | อึ  | short |
| 3 | อู | long  | | 12 | อุ  | short |
| 4 | เอ | long  | | 13 | เอะ | short |
| 5 | แอ | long  | | 14 | แอะ | short |
| 6 | โอ | long  | | 15 | โอะ | short |
| 7 | ออ | long  | | 16 | เอาะ | short |
| 8 | เออ | long | | 17 | เออะ | short |

**Response**
```json
{
  "confidence": 0.82,
  "user_formants": { "F1": 720.5, "F2": 1240.3 }
}
```
> `isPassed` is computed in Flutter: `confidence >= 0.70`
