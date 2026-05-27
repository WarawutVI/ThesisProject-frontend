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
| `firebase_uid` | VARCHAR(128) | PRIMARY KEY | UID จาก Firebase Auth | ทุก widget |
| `username` | VARCHAR(100) | NOT NULL | ชื่อที่แสดงในแอป | Profile |
| `email` | VARCHAR(255) | NOT NULL | อีเมลจาก Firebase | Profile |
| `gender` | VARCHAR(20) | — | เพศผู้ใช้ | Demographic (thesis) |
| `age` | INT | — | อายุผู้ใช้ | Demographic (thesis) |
| `login_provider` | VARCHAR(20) | — | วิธี login (`email` / `google`) | Profile |
| `created_at` | DATETIME | DEFAULT CURRENT_TIMESTAMP | วันสมัครสมาชิก | — |

### SQL

```sql
CREATE TABLE users (
  firebase_uid   VARCHAR(128) PRIMARY KEY,
  username       VARCHAR(100) NOT NULL,
  email          VARCHAR(255) NOT NULL,
  gender         VARCHAR(20),
  age            INT,
  login_provider VARCHAR(20),
  created_at     DATETIME DEFAULT CURRENT_TIMESTAMP
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
| `firebase_uid` | VARCHAR(128) | PRIMARY KEY | เจ้าของ streak | 🔥 Streak widget |
| `current_streak` | INT | DEFAULT 0 | จำนวนวันที่ฝึกต่อเนื่องปัจจุบัน | 🔥 Streak widget |
| `longest_streak` | INT | DEFAULT 0 | สถิติ streak ยาวที่สุดตลอดกาล | 🔥 Streak widget, Thesis |
| `last_practice_date` | DATE | — | วันที่ฝึกล่าสุด ใช้คำนวณ streak | 🔥 Streak widget |

### SQL

```sql
CREATE TABLE user_streaks (
  firebase_uid       VARCHAR(128) PRIMARY KEY,
  current_streak     INT DEFAULT 0,
  longest_streak     INT DEFAULT 0,
  last_practice_date DATE
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
| `id` | INT | PK, AUTO_INCREMENT | id สระ 1–18 | — |
| `symbol` | VARCHAR(20) | NOT NULL | ตัวสระ เช่น อา, อิ, อะ | Practice page, History |
| `vowel_type` | ENUM('short','long') | NOT NULL | Short Vowels / Long Vowels | Practice page, Accuracy donut, Trend |
| `description_en` | TEXT | — | คำอธิบายสระ (อังกฤษ) | Lessons page |
| `description_th` | TEXT | — | คำอธิบายสระ (ไทย) | Lessons page |
| `lips_en` | VARCHAR(100) | — | วิธีเปล่งเสียง: ริมฝีปาก (อังกฤษ) | Pronunciation guide |
| `lips_th` | VARCHAR(100) | — | วิธีเปล่งเสียง: ริมฝีปาก (ไทย) | Pronunciation guide |
| `tongue_en` | VARCHAR(100) | — | วิธีเปล่งเสียง: ลิ้น (อังกฤษ) | Pronunciation guide |
| `tongue_th` | VARCHAR(100) | — | วิธีเปล่งเสียง: ลิ้น (ไทย) | Pronunciation guide |
| `jaw_en` | VARCHAR(100) | — | วิธีเปล่งเสียง: ขากรรไกร (อังกฤษ) | Pronunciation guide |
| `jaw_th` | VARCHAR(100) | — | วิธีเปล่งเสียง: ขากรรไกร (ไทย) | Pronunciation guide |
| `link_video` | VARCHAR(500) | — | URL วิดีโอประกอบการสอนสระ | Lessons page |
| `f1` | FLOAT | — | ค่า Formant 1 อ้างอิง (Hz) | Pronunciation guide, Thesis |
| `f2` | FLOAT | — | ค่า Formant 2 อ้างอิง (Hz) | Pronunciation guide, Thesis |
| `unicode_phonetic` | VARCHAR(50) | — | สัญลักษณ์ IPA/Unicode เช่น `/aː/`, `/i/` | Lessons page |

### SQL

```sql
CREATE TABLE vowels (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  symbol            VARCHAR(20)  NOT NULL,
  vowel_type        ENUM('short','long') NOT NULL,
  description_en    TEXT,
  description_th    TEXT,
  lips_en           VARCHAR(100),
  lips_th           VARCHAR(100),
  tongue_en         VARCHAR(100),
  tongue_th         VARCHAR(100),
  jaw_en            VARCHAR(100),
  jaw_th            VARCHAR(100),
  link_video        VARCHAR(500),
  f1                FLOAT,
  f2                FLOAT,
  unicode_phonetic  VARCHAR(50)
);
```

### Migration SQL (ถ้า table มีอยู่แล้ว)

```sql
-- ลบ columns เก่า + เพิ่ม columns ใหม่
ALTER TABLE vowels
  DROP COLUMN name_en,
  DROP COLUMN name_th,
  DROP COLUMN duration_en,
  DROP COLUMN duration_th,
  ADD COLUMN link_video       VARCHAR(500),
  ADD COLUMN f1               FLOAT,
  ADD COLUMN f2               FLOAT,
  ADD COLUMN unicode_phonetic VARCHAR(50);
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
| `id` | INT | PK, AUTO_INCREMENT | Lesson id | — |
| `vowel_id` | INT | FK → vowels.id, NOT NULL | สระที่ lesson นี้สังกัด | Practice page |
| `lesson_order` | INT | NOT NULL | ลำดับที่ 1–9 | Practice page (card order) |
| `lesson_name` | VARCHAR(50) | NOT NULL | ชื่อแบบฝึกย่อย เช่น กา, ขา, งา | การ์ดบน Practice page |

### SQL

```sql
CREATE TABLE vowel_lessons (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  vowel_id     INT NOT NULL,
  lesson_order INT NOT NULL,
  lesson_name  VARCHAR(50) NOT NULL,
  FOREIGN KEY (vowel_id) REFERENCES vowels(id)
);
```

### Seed Data (162 rows — 9 words × 18 vowels)

```sql
-- Vowel 1: อา (long)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(1,1,'กา'),(1,2,'ขา'),(1,3,'งา'),(1,4,'จา'),(1,5,'ซา'),
(1,6,'ดา'),(1,7,'นา'),(1,8,'บา'),(1,9,'ปา');

-- Vowel 2: อี (long)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(2,1,'กี'),(2,2,'ขี'),(2,3,'งี'),(2,4,'จี'),(2,5,'ซี'),
(2,6,'ดี'),(2,7,'นี'),(2,8,'บี'),(2,9,'ปี');

-- Vowel 3: อือ (long)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(3,1,'กือ'),(3,2,'ขือ'),(3,3,'งือ'),(3,4,'จือ'),(3,5,'ซือ'),
(3,6,'ดือ'),(3,7,'นือ'),(3,8,'บือ'),(3,9,'ปือ');

-- Vowel 4: อู (long)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(4,1,'กู'),(4,2,'ขู'),(4,3,'งู'),(4,4,'จู'),(4,5,'ซู'),
(4,6,'ดู'),(4,7,'นู'),(4,8,'บู'),(4,9,'ปู');

-- Vowel 5: เอ (long)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(5,1,'เก'),(5,2,'เข'),(5,3,'เง'),(5,4,'เจ'),(5,5,'เซ'),
(5,6,'เด'),(5,7,'เน'),(5,8,'เบ'),(5,9,'เป');

-- Vowel 6: แอ (long)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(6,1,'แก'),(6,2,'แข'),(6,3,'แง'),(6,4,'แจ'),(6,5,'แซ'),
(6,6,'แด'),(6,7,'แน'),(6,8,'แบ'),(6,9,'แป');

-- Vowel 7: โอ (long)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(7,1,'โก'),(7,2,'โข'),(7,3,'โง'),(7,4,'โจ'),(7,5,'โซ'),
(7,6,'โด'),(7,7,'โน'),(7,8,'โบ'),(7,9,'โป');

-- Vowel 8: ออ (long)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(8,1,'กอ'),(8,2,'ขอ'),(8,3,'งอ'),(8,4,'จอ'),(8,5,'ซอ'),
(8,6,'ดอ'),(8,7,'นอ'),(8,8,'บอ'),(8,9,'ปอ');

-- Vowel 9: เออ (long)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(9,1,'เกอ'),(9,2,'เขอ'),(9,3,'เงอ'),(9,4,'เจอ'),(9,5,'เซอ'),
(9,6,'เดอ'),(9,7,'เนอ'),(9,8,'เบอ'),(9,9,'เปอ');

-- Vowel 10: อะ (short)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(10,1,'กะ'),(10,2,'ขะ'),(10,3,'งะ'),(10,4,'จะ'),(10,5,'ซะ'),
(10,6,'ดะ'),(10,7,'นะ'),(10,8,'บะ'),(10,9,'ปะ');

-- Vowel 11: อิ (short)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(11,1,'กิ'),(11,2,'ขิ'),(11,3,'งิ'),(11,4,'จิ'),(11,5,'ซิ'),
(11,6,'ดิ'),(11,7,'นิ'),(11,8,'บิ'),(11,9,'ปิ');

-- Vowel 12: อึ (short)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(12,1,'กึ'),(12,2,'ขึ'),(12,3,'งึ'),(12,4,'จึ'),(12,5,'ซึ'),
(12,6,'ดึ'),(12,7,'นึ'),(12,8,'บึ'),(12,9,'ปึ');

-- Vowel 13: อุ (short)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(13,1,'กุ'),(13,2,'ขุ'),(13,3,'งุ'),(13,4,'จุ'),(13,5,'ซุ'),
(13,6,'ดุ'),(13,7,'นุ'),(13,8,'บุ'),(13,9,'ปุ');

-- Vowel 14: เอะ (short)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(14,1,'เกะ'),(14,2,'เขะ'),(14,3,'เงะ'),(14,4,'เจะ'),(14,5,'เซะ'),
(14,6,'เดะ'),(14,7,'เนะ'),(14,8,'เบะ'),(14,9,'เปะ');

-- Vowel 15: แอะ (short)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(15,1,'แกะ'),(15,2,'แขะ'),(15,3,'แงะ'),(15,4,'แจะ'),(15,5,'แซะ'),
(15,6,'แดะ'),(15,7,'แนะ'),(15,8,'แบะ'),(15,9,'แปะ');

-- Vowel 16: โอะ (short)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(16,1,'โกะ'),(16,2,'โขะ'),(16,3,'โงะ'),(16,4,'โจะ'),(16,5,'โซะ'),
(16,6,'โดะ'),(16,7,'โนะ'),(16,8,'โบะ'),(16,9,'โปะ');

-- Vowel 17: เอาะ (short)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(17,1,'เกาะ'),(17,2,'เขาะ'),(17,3,'เงาะ'),(17,4,'เจาะ'),(17,5,'เซาะ'),
(17,6,'เดาะ'),(17,7,'เนาะ'),(17,8,'เบาะ'),(17,9,'เปาะ');

-- Vowel 18: เออะ (short)
INSERT INTO vowel_lessons (vowel_id, lesson_order, lesson_name) VALUES
(18,1,'เกอะ'),(18,2,'เขอะ'),(18,3,'เงอะ'),(18,4,'เจอะ'),(18,5,'เซอะ'),
(18,6,'เดอะ'),(18,7,'เนอะ'),(18,8,'เบอะ'),(18,9,'เปอะ');
```

---

## 5. Table: `user_lesson_progress`

บันทึกสถานะของ user แต่ละ lesson (สีบนการ์ด)

| คอลัมน์ | ประเภท | Constraint | คำอธิบาย | ใช้กับ widget |
|---|---|---|---|---|
| `id` | INT | PK, AUTO_INCREMENT | — | — |
| `firebase_uid` | VARCHAR(128) | NOT NULL | เจ้าของ progress | — |
| `lesson_id` | INT | FK → vowel_lessons.id, NOT NULL | แบบฝึกย่อยที่ทำ | Practice page cards |
| `is_completed` | TINYINT(1) | DEFAULT 0 | 1 = สีเขียว, 0 = สีส้ม | สีการ์ด |
| `best_accuracy` | FLOAT | DEFAULT 0.0 | % accuracy สูงสุดที่เคยทำได้ | — |
| `attempts` | INT | DEFAULT 0 | ฝึก lesson นี้กี่ครั้งแล้ว | — |
| `last_practiced_at` | DATETIME | — | ฝึกครั้งล่าสุดเมื่อไหร่ | History |

### SQL

```sql
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
| `firebase_uid` | VARCHAR(128) | NOT NULL | เจ้าของ session | ทุก widget |
| `lesson_id` | INT | FK → vowel_lessons.id, NOT NULL | lesson ที่ฝึก | Practice count, History |
| `confidence` | FLOAT | NOT NULL | ค่า confidence จาก CNN (ใช้แทน accuracy) | Trend, Donut, History, Thesis |
| `is_passed` | TINYINT(1) | NOT NULL | ผ่านเกณฑ์หรือไม่ (เช่น ≥ 70%) | History badge |
| `duration_seconds` | INT | DEFAULT 0 | เวลาที่ใช้ต่อ session (วินาที) | Thesis analysis |
| `practiced_at` | DATETIME | DEFAULT CURRENT_TIMESTAMP | วันเวลาที่ฝึก | Trend (group by date), History |

### SQL

```sql
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
```

### Queries

**บันทึก session ใหม่ (หลัง Flask ส่งผลกลับมา)**
```sql
INSERT INTO practice_sessions
  (firebase_uid, lesson_id, confidence, is_passed, duration_seconds)
VALUES
  (?, ?, ?, ?, ?);
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
