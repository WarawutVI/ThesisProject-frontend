# คู่มือ Database — Thai Vowel Pronunciation App

> **Stack:** MySQL · Firebase Auth · Flutter · Flask (Python)  
> **จำนวนตาราง:** 6 tables  
> **อัปเดตล่าสุด:** 2025

---

## ภาพรวม ERD

```
users
 ├──< practice_sessions    (firebase_uid FK)
 ├──< user_lesson_progress (firebase_uid FK)
 └──< user_streaks         (firebase_uid FK)

vowels
 └──< vowel_lessons        (vowel_id FK)
       ├──< user_lesson_progress (lesson_id FK)
       └──< practice_sessions    (lesson_id FK)
```

---

## 1. Table: `users`

เก็บข้อมูล account ผู้ใช้ทั้งที่ login ด้วย Email และ Google

| คอลัมน์ | ประเภท | Constraint | คำอธิบาย | ใช้กับ widget |
|---|---|---|---|---|
| `id` | INT | PK, AUTO_INCREMENT | Primary key | — |
| `firebase_uid` | VARCHAR(128) | NOT NULL, UNIQUE | UID จาก Firebase Auth ใช้เชื่อม Email & Google | ทุก widget |
| `username` | VARCHAR(100) | NOT NULL | ชื่อที่แสดงในแอป | Profile |
| `email` | VARCHAR(255) | NOT NULL, UNIQUE | อีเมลจาก Firebase | Profile |
| `gender` | ENUM('male','female','other') | NOT NULL | เพศผู้ใช้ | Demographic (thesis) |
| `age` | TINYINT UNSIGNED | NOT NULL | อายุผู้ใช้ (0–255) | Demographic (thesis) |
| `login_provider` | ENUM('email','google') | NOT NULL | วิธี login | Profile |
| `created_at` | DATETIME | DEFAULT CURRENT_TIMESTAMP | วันสมัครสมาชิก | — |
| `updated_at` | DATETIME | ON UPDATE CURRENT_TIMESTAMP | วันแก้ไขโปรไฟล์ล่าสุด | — |

### SQL

```sql
CREATE TABLE users (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  firebase_uid    VARCHAR(128) NOT NULL UNIQUE,
  username        VARCHAR(100) NOT NULL,
  email           VARCHAR(255) NOT NULL UNIQUE,
  gender          ENUM('male', 'female', 'other') NOT NULL,
  age             TINYINT UNSIGNED NOT NULL,
  login_provider  ENUM('email', 'google') NOT NULL,
  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Queries

**ดึงข้อมูล Profile**
```sql
SELECT username, email, gender, age, login_provider, created_at
FROM users
WHERE firebase_uid = ?;
```

---

## 2. Table: `user_streaks`

เก็บข้อมูล streak แยกออกจาก `users` เพื่อความสะอาดของ schema

| คอลัมน์ | ประเภท | Constraint | คำอธิบาย | ใช้กับ widget |
|---|---|---|---|---|
| `id` | INT | PK, AUTO_INCREMENT | — | — |
| `firebase_uid` | VARCHAR(128) | FK → users.firebase_uid, UNIQUE | เจ้าของ streak | 🔥 Streak widget |
| `current_streak` | INT | DEFAULT 0 | จำนวนวันที่ฝึกต่อเนื่องปัจจุบัน | 🔥 Streak widget |
| `longest_streak` | INT | DEFAULT 0 | สถิติ streak ยาวที่สุดตลอดกาล | 🔥 Streak widget, Thesis |
| `last_practice_date` | DATE | DEFAULT NULL | วันที่ฝึกล่าสุด ใช้คำนวณ streak | 🔥 Streak widget |
| `updated_at` | DATETIME | ON UPDATE CURRENT_TIMESTAMP | อัปเดตล่าสุด | — |

### SQL

```sql
CREATE TABLE user_streaks (
  id                  INT AUTO_INCREMENT PRIMARY KEY,
  firebase_uid        VARCHAR(128) NOT NULL UNIQUE,
  current_streak      INT DEFAULT 0,
  longest_streak      INT DEFAULT 0,
  last_practice_date  DATE DEFAULT NULL,
  updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (firebase_uid) REFERENCES users(firebase_uid) ON DELETE CASCADE
);
```

### Queries

**ดึง Streak ของ user**
```sql
SELECT current_streak, longest_streak, last_practice_date
FROM user_streaks
WHERE firebase_uid = ?;
```

**สร้าง row ตอน user สมัครสมาชิก**
```sql
-- รันหลัง INSERT users เสร็จ
INSERT INTO user_streaks (firebase_uid) VALUES (?);
```

**อัปเดต Streak หลังฝึกเสร็จแต่ละ session**
```sql
-- ถ้า last_practice_date = เมื่อวาน → streak++
-- ถ้า last_practice_date < เมื่อวาน  → reset เป็น 1
-- ถ้า last_practice_date = วันนี้     → ไม่เปลี่ยน (ฝึกซ้ำในวันเดิม)

UPDATE user_streaks
SET current_streak = CASE
      WHEN last_practice_date = CURDATE() - INTERVAL 1 DAY THEN current_streak + 1
      WHEN last_practice_date < CURDATE() - INTERVAL 1 DAY THEN 1
      ELSE current_streak
    END,
    longest_streak = GREATEST(
      longest_streak,
      CASE
        WHEN last_practice_date = CURDATE() - INTERVAL 1 DAY THEN current_streak + 1
        WHEN last_practice_date < CURDATE() - INTERVAL 1 DAY THEN 1
        ELSE current_streak
      END
    ),
    last_practice_date = CURDATE()
WHERE firebase_uid = ?;
```

---

## 3. Table: `vowels`

รายชื่อสระทั้งหมด 18 ตัว แยก Short / Long

| คอลัมน์ | ประเภท | Constraint | คำอธิบาย | ใช้กับ widget |
|---|---|---|---|---|
| `id` | TINYINT UNSIGNED | PK, AUTO_INCREMENT | id สระ 1–18 | — |
| `symbol` | VARCHAR(10) | NOT NULL | ตัวสระ เช่น อา, อิ, อะ | Practice page, History |
| `vowel_type` | ENUM('short','long') | NOT NULL | Short Vowels / Long Vowels | Practice page, Accuracy donut, Trend |

### SQL

```sql
CREATE TABLE vowels (
  id          TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  symbol      VARCHAR(10) NOT NULL,
  vowel_type  ENUM('short', 'long') NOT NULL
);
```

### Seed Data (สระทั้ง 18 ตัว)

```sql
INSERT INTO vowels (symbol, vowel_type) VALUES
-- Long Vowels (9 ตัว)
('-า',  'long'),
('-ี',  'long'),
('-ื',  'long'),
('-ู',  'long'),
('เ-',  'long'),
('แ-',  'long'),
('โ-',  'long'),
('-อ',  'long'),
('เ-อ', 'long'),
-- Short Vowels (9 ตัว)
('-ะ',  'short'),
('-ิ',  'short'),
('-ึ',  'short'),
('-ุ',  'short'),
('เ-ะ', 'short'),
('แ-ะ', 'short'),
('โ-ะ', 'short'),
('เ-าะ','short'),
('เ-อะ','short');
```

---

## 4. Table: `vowel_lessons`

แบบฝึกย่อยของสระแต่ละตัว เช่น สระ -า มี 9 lessons

| คอลัมน์ | ประเภท | Constraint | คำอธิบาย | ใช้กับ widget |
|---|---|---|---|---|
| `id` | SMALLINT UNSIGNED | PK, AUTO_INCREMENT | Lesson id | — |
| `vowel_id` | TINYINT UNSIGNED | FK → vowels.id | สระที่ lesson นี้สังกัด | Practice page |
| `lesson_order` | TINYINT UNSIGNED | NOT NULL | ลำดับที่ 1–9 หรือ 1–10 | Practice page (card order) |
| `lesson_name` | VARCHAR(100) | NOT NULL | ชื่อแบบฝึกย่อย เช่น กา, ขา, งา | การ์ดบน Practice page |

### SQL

```sql
CREATE TABLE vowel_lessons (
  id            SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  vowel_id      TINYINT UNSIGNED NOT NULL,
  lesson_order  TINYINT UNSIGNED NOT NULL,
  lesson_name   VARCHAR(100) NOT NULL,
  UNIQUE KEY uq_vowel_order (vowel_id, lesson_order),
  FOREIGN KEY (vowel_id) REFERENCES vowels(id)
);
```

---

## 5. Table: `user_lesson_progress`

บันทึกสถานะของ user แต่ละ lesson (สีบนการ์ด)

| คอลัมน์ | ประเภท | Constraint | คำอธิบาย | ใช้กับ widget |
|---|---|---|---|---|
| `id` | INT | PK, AUTO_INCREMENT | — | — |
| `firebase_uid` | VARCHAR(128) | FK → users.firebase_uid | เจ้าของ progress | — |
| `lesson_id` | SMALLINT UNSIGNED | FK → vowel_lessons.id | แบบฝึกย่อยที่ทำ | Practice page cards |
| `is_completed` | BOOLEAN | DEFAULT FALSE | TRUE = สีเขียว, FALSE = สีส้ม | สีการ์ด |
| `best_accuracy` | FLOAT | DEFAULT 0.0 | % accuracy สูงสุดที่เคยทำได้ | — |
| `attempts` | SMALLINT UNSIGNED | DEFAULT 0 | ฝึก lesson นี้กี่ครั้งแล้ว | — |
| `last_practiced_at` | DATETIME | DEFAULT NULL | ฝึกครั้งล่าสุดเมื่อไหร่ | History |

### SQL

```sql
CREATE TABLE user_lesson_progress (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  firebase_uid      VARCHAR(128) NOT NULL,
  lesson_id         SMALLINT UNSIGNED NOT NULL,
  is_completed      BOOLEAN NOT NULL DEFAULT FALSE,
  best_accuracy     FLOAT DEFAULT 0.0,
  attempts          SMALLINT UNSIGNED DEFAULT 0,
  last_practiced_at DATETIME DEFAULT NULL,
  UNIQUE KEY uq_user_lesson (firebase_uid, lesson_id),
  FOREIGN KEY (firebase_uid) REFERENCES users(firebase_uid) ON DELETE CASCADE,
  FOREIGN KEY (lesson_id)    REFERENCES vowel_lessons(id)
);
```

### การ Map สีการ์ดกับ Database

| สถานะ | สี | เงื่อนไข DB |
|---|---|---|
| ยังไม่เคยทำ | 🔲 เทา | ไม่มี row ใน `user_lesson_progress` |
| ทำแต่ไม่สำเร็จ | 🟧 ส้ม | มี row + `is_completed = FALSE` |
| สำเร็จแล้ว | 🟩 เขียว | มี row + `is_completed = TRUE` |

### Queries

**ดึง lessons พร้อมสถานะสีของ user (หน้า Practice)**
```sql
SELECT
  vl.id,
  vl.lesson_order,
  vl.lesson_name,
  ulp.is_completed,     -- NULL = เทา, FALSE = ส้ม, TRUE = เขียว
  ulp.best_accuracy,
  ulp.attempts
FROM vowel_lessons vl
LEFT JOIN user_lesson_progress ulp
  ON vl.id = ulp.lesson_id
  AND ulp.firebase_uid = ?        -- firebase_uid ของ user
WHERE vl.vowel_id = ?             -- id ของสระที่กดเข้ามา
ORDER BY vl.lesson_order;
```

**นับ x/9 บนการ์ดสระ (Overall Progress)**
```sql
-- ตัวเศษ: lessons ที่สำเร็จ
SELECT COUNT(*) AS completed
FROM user_lesson_progress ulp
JOIN vowel_lessons vl ON ulp.lesson_id = vl.id
WHERE ulp.firebase_uid = ?
  AND vl.vowel_id = ?
  AND ulp.is_completed = TRUE;

-- ตัวส่วน: lessons ทั้งหมดของสระนั้น
SELECT COUNT(*) AS total
FROM vowel_lessons
WHERE vowel_id = ?;
```

**อัปเดตหลัง user ฝึกเสร็จ**
```sql
INSERT INTO user_lesson_progress
  (firebase_uid, lesson_id, is_completed, best_accuracy, attempts, last_practiced_at)
VALUES
  (?, ?, ?, ?, 1, NOW())
ON DUPLICATE KEY UPDATE
  is_completed      = GREATEST(is_completed, VALUES(is_completed)),
  best_accuracy     = GREATEST(best_accuracy, VALUES(best_accuracy)),
  attempts          = attempts + 1,
  last_practiced_at = NOW();
```

---

## 6. Table: `practice_sessions`

บันทึกทุกครั้งที่ user กด Record และได้ผลจาก AI model

| คอลัมน์ | ประเภท | Constraint | คำอธิบาย | ใช้กับ widget |
|---|---|---|---|---|
| `id` | INT | PK, AUTO_INCREMENT | — | — |
| `firebase_uid` | VARCHAR(128) | FK → users.firebase_uid | เจ้าของ session | ทุก widget |
| `lesson_id` | SMALLINT UNSIGNED | FK → vowel_lessons.id | lesson ที่ฝึก | Practice count, History |
| `predicted_vowel_id` | TINYINT UNSIGNED | FK → vowels.id, NULL ได้ | AI ทายว่าเป็นสระอะไร | Confusion matrix (thesis) |
| `confidence` | FLOAT | NOT NULL, DEFAULT 0.0 | ค่า confidence จาก CNN (ใช้แทน accuracy) | Trend, Donut, History, Thesis |
| `is_passed` | BOOLEAN | DEFAULT FALSE | ผ่านเกณฑ์หรือไม่ (เช่น ≥ 70%) | History badge |
| `duration_seconds` | TINYINT UNSIGNED | DEFAULT NULL | เวลาที่ใช้ต่อ session (วินาที) | Thesis analysis |
| `practiced_at` | DATETIME | DEFAULT CURRENT_TIMESTAMP | วันเวลาที่ฝึก | Trend (group by date), History |

### SQL

```sql
CREATE TABLE practice_sessions (
  id                  INT AUTO_INCREMENT PRIMARY KEY,
  firebase_uid        VARCHAR(128) NOT NULL,
  lesson_id           SMALLINT UNSIGNED NOT NULL,
  predicted_vowel_id  TINYINT UNSIGNED DEFAULT NULL,
  confidence          FLOAT NOT NULL DEFAULT 0.0,
  is_passed           BOOLEAN NOT NULL DEFAULT FALSE,
  duration_seconds    TINYINT UNSIGNED DEFAULT NULL,
  practiced_at        DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (firebase_uid)       REFERENCES users(firebase_uid) ON DELETE CASCADE,
  FOREIGN KEY (lesson_id)          REFERENCES vowel_lessons(id),
  FOREIGN KEY (predicted_vowel_id) REFERENCES vowels(id)
);
```

### Queries

**บันทึก session ใหม่ (หลัง Flask ส่งผลกลับมา)**
```sql
INSERT INTO practice_sessions
  (firebase_uid, lesson_id, predicted_vowel_id, confidence, is_passed, duration_seconds)
VALUES
  (?, ?, ?, ?, ?, ?);
```

**Practice count bar chart (จำนวนครั้งต่อสระ)**
```sql
SELECT
  v.symbol,
  v.vowel_type,
  COUNT(*) AS session_count
FROM practice_sessions ps
JOIN vowel_lessons vl ON ps.lesson_id = vl.id
JOIN vowels v         ON vl.vowel_id  = v.id
WHERE ps.firebase_uid = ?
  AND v.vowel_type    = 'long'          -- หรือ 'short' ตาม dropdown
GROUP BY v.id, v.symbol
ORDER BY v.id;
```

**Average Accuracy donut (short vs long)**
```sql
SELECT
  v.vowel_type,
  ROUND(AVG(ps.confidence) * 100, 1) AS avg_confidence_pct
FROM practice_sessions ps
JOIN vowel_lessons vl ON ps.lesson_id = vl.id
JOIN vowels v         ON vl.vowel_id  = v.id
WHERE ps.firebase_uid = ?
GROUP BY v.vowel_type;
```

**Accuracy Trend รายวัน (7 วันย้อนหลัง)**
```sql
SELECT
  DATE(ps.practiced_at)              AS day,
  DAYNAME(ps.practiced_at)           AS day_name,
  ROUND(AVG(ps.confidence) * 100, 1) AS avg_confidence_pct,
  COUNT(*)                           AS session_count
FROM practice_sessions ps
JOIN vowel_lessons vl ON ps.lesson_id = vl.id
JOIN vowels v         ON vl.vowel_id  = v.id
WHERE ps.firebase_uid = ?
  AND v.vowel_type    = 'long'          -- หรือ 'short'
  AND ps.practiced_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
GROUP BY DATE(ps.practiced_at)
ORDER BY day;
```

**History list (เรียงล่าสุดก่อน)**
```sql
SELECT
  v.symbol,
  v.vowel_type,
  vl.lesson_name,
  ROUND(ps.confidence * 100, 1) AS confidence_pct,
  ps.is_passed,
  ps.practiced_at
FROM practice_sessions ps
JOIN vowel_lessons vl ON ps.lesson_id = vl.id
JOIN vowels v         ON vl.vowel_id  = v.id
WHERE ps.firebase_uid = ?
ORDER BY ps.practiced_at DESC
LIMIT 20;
```

**สระที่ยังอ่อน (Weak vowels — 3 อันดับต่ำสุด)**
```sql
SELECT
  v.symbol,
  v.vowel_type,
  ROUND(AVG(ps.confidence) * 100, 1) AS avg_confidence_pct,
  COUNT(*) AS attempts
FROM practice_sessions ps
JOIN vowel_lessons vl ON ps.lesson_id = vl.id
JOIN vowels v         ON vl.vowel_id  = v.id
WHERE ps.firebase_uid = ?
GROUP BY v.id, v.symbol, v.vowel_type
ORDER BY avg_confidence_pct ASC
LIMIT 3;
```

**เปรียบเทียบ Short vs Long ทุก metric**
```sql
SELECT
  v.vowel_type,
  ROUND(AVG(ps.confidence) * 100, 1)  AS avg_confidence_pct,
  COUNT(*)                             AS total_sessions,
  SUM(ps.is_passed)                    AS passed_count,
  ROUND(AVG(ps.duration_seconds), 1)   AS avg_duration_sec
FROM practice_sessions ps
JOIN vowel_lessons vl ON ps.lesson_id = vl.id
JOIN vowels v         ON vl.vowel_id  = v.id
WHERE ps.firebase_uid = ?
GROUP BY v.vowel_type;
```

**Summary stats (ตัวเลขด้านบนหน้า Your Progress)**
```sql
SELECT
  COUNT(*)                             AS total_sessions,
  ROUND(AVG(ps.confidence) * 100, 1)  AS overall_avg_pct,
  ROUND(MAX(ps.confidence) * 100, 1)  AS best_confidence_pct,
  SUM(ps.is_passed)                    AS total_passed
FROM practice_sessions ps
WHERE ps.firebase_uid = ?;
```

---

## Flow การทำงาน (Flutter → Flask → MySQL)

```
1. User กด Record
   └── Flutter จับเวลาเริ่ม (duration)

2. ส่งไฟล์เสียงไปยัง Flask /predict
   └── Flask ส่งกลับ: { class_id, confidence, accuracy, model_curve, user_curve }

3. Flutter รับผลแล้ว INSERT practice_sessions
   └── firebase_uid, lesson_id, predicted_vowel_id (class_id),
       confidence, is_passed, duration_seconds

4. Flutter UPDATE user_lesson_progress
   └── is_completed, best_accuracy, attempts, last_practiced_at

5. Flutter UPDATE user_streaks
   └── ตรวจ last_practice_date แล้ว streak++ หรือ reset + อัปเดต longest_streak
```

---

## สรุปตาราง

| ตาราง | จำนวน rows (ประมาณ) | หน้าที่ |
|---|---|---|
| `users` | 1 ต่อ user | เก็บ account |
| `user_streaks` | 1 ต่อ user | เก็บ streak ต่อเนื่อง |
| `vowels` | 18 (fixed) | รายชื่อสระ |
| `vowel_lessons` | ~162 (18×9) | แบบฝึกย่อย |
| `user_lesson_progress` | user × lesson | สถานะสีการ์ด |
| `practice_sessions` | ทุกครั้งที่ record | ประวัติ + dashboard |
