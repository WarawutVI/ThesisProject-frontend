# Thai Vowel Pronunciation App — Project Documentation

> Flutter frontend for a Thai vowel pronunciation learning app.  
> Users practice speaking Thai vowels, take lessons, and track their progress over time.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart SDK `^3.10.4`) |
| Auth | Firebase Auth — email/password + Google Sign-In |
| State / Navigation | GetX `^4.7.3` — `Get.to()` / `Get.offAll()` |
| Backend API | Node.js / Express at `http://10.0.2.2:4000` |
| ML Model | Flask at `http://192.168.0.62:5000` |
| Database | MySQL (via Node.js backend) |
| Charts | fl_chart `^0.69.0` |
| Audio | record `^6.2.0` |

---

## Key Dependencies (`pubspec.yaml`)

```yaml
firebase_core: ^4.4.0
firebase_auth: ^6.1.4
cloud_firestore: ^6.1.2
google_sign_in: ^5.4.2
get: ^4.7.3
http: ^1.6.0
fl_chart: ^0.69.0
record: ^6.2.0
path_provider: ^2.1.5
intl: ^0.20.2
```

---

## Commands

```bash
flutter run                        # run on connected device / emulator
flutter run -d chrome              # run on Chrome
flutter run -d windows             # run on Windows
flutter build apk                  # build Android APK
flutter analyze                    # lint
flutter test                       # run all tests
flutterfire configure              # regenerate firebase_options.dart
```

---

## File Map

```
lib/
├── main.dart                      # App entry — Firebase init, root widget
├── wrapper.dart                   # Auth gate (StreamBuilder on authStateChanges)
├── firebase_options.dart          # Auto-generated — do not hand-edit
│
├── auth/
│   ├── login.dart                 # Login (email + Google)
│   ├── signup.dart                # Sign-up (email + Google)
│   ├── gender.dart                # Onboarding step 1 — gender picker
│   ├── age.dart                   # Onboarding step 2 — age picker + POST /users
│   ├── forgot.dart                # Forgot-password screen
│   └── profile_setup.dart         # Combined gender+age (unused, kept for reference)
│
├── pages/
│   ├── homepage.dart              # Main hub — streak banner + 3 nav cards
│   ├── lessonspage.dart           # Lessons (stub — under development)
│   ├── practicepage.dart          # Practice entry — Short vs Long vowel selector
│   ├── progreespage.dart          # Thin coordinator — loads data, lays out progressELM children
│   ├── practice/
│   │   ├── vowel_grid_page.dart   # 3×3 vowel grid with completion badges
│   │   ├── word_grid_page.dart    # Word grid for a selected vowel
│   │   └── recording_page.dart    # Mic recording + ML prediction + result modal
│   └── progressELM/
│       ├── progress_shared.dart   # ProgressCard wrapper, FilterPill, shared helpers (pt, accuracyColor)
│       ├── summary_card.dart      # Summary hero card (overall %, sessions, best, streak)
│       ├── practice_count_chart.dart  # Bar chart (long/short toggle)
│       ├── avg_accuracy_donuts.dart   # Side-by-side donut charts (long vs short)
│       ├── trend_card.dart        # Accuracy trend chart + custom date range picker
│       ├── recent_sessions_list.dart  # Session history list
│       └── weak_vowels_list.dart  # Weak vowels CTA ("Try again" → WordGridPage)
│
├── services/
│   ├── practice_api.dart          # All HTTP calls to Node.js + Flask backends
│   └── vowel_utils.dart           # WAV decode, waveform preprocessing, vowel index mapping
│
└── widgets/
    └── waveform_display.dart      # Waveform comparison widget (ref vs user)
```

---

## Navigation Flow

```
main.dart
  └─ Firebase.initializeApp()
  └─ GetMaterialApp → Wrapper

Wrapper (auth gate)
  ├─ logged in  → Homepage
  └─ logged out → Login
```

### Auth Flow

```
Login
  ├─ Email/password → success → Homepage
  ├─ Google         → existing user → Homepage
  │                 → new user     → GenderPage
  ├─ "Forgot?"      → ForgotPage
  └─ "Sign up"      → SignupPage

Signup
  ├─ Email          → GenderPage
  ├─ Google         → existing user → Homepage
  │                 → new user     → GenderPage
  └─ "Log in"       → Login

GenderPage → AgePage → POST /users → Wrapper → Homepage
```

### Practice Flow (fully implemented)

```
Homepage
  └─ Practice card → Practicepage
        ├─ Short Vowel → VowelGridPage(type:'short')
        └─ Long Vowel  → VowelGridPage(type:'long')

VowelGridPage (3×3 grid of 9 vowels, shows completed/total per vowel)
  └─ tap vowel → WordGridPage(vowelId, vowelSymbol, vowelType)

WordGridPage (3×3 grid of 9 words, shows pass/fail badges)
  ├─ ℹ️ button    → articulation guide dialog
  └─ tap word    → RecordingPage(lessonId, vowelId, word, vowelSymbol)

RecordingPage
  └─ tap mic → 2 s recording → Flask /predict2
             → save session, save progress, update streak (fire-and-forget)
             → result modal (score bar + waveform comparison + formants)
                  ├─ "Try Again" → close modal (stay on RecordingPage)
                  └─ "Finish"   → back to WordGridPage (reloads progress)
```

### Progress Flow (fully implemented)

```
Homepage → Progress card → ProgreesPage

ProgreesPage (analytics dashboard)
  ├─ Summary hero card        (overall %, sessions, best, streak)
  ├─ Practice count bar chart (long/short toggle)
  ├─ Average accuracy donuts  (long vs short side-by-side)
  ├─ Accuracy trend chart     (period: Week / Month / Year / 📅 Custom)
  │     └─ Custom → date range bottom sheet (quick chips + date pickers)
  ├─ Recent sessions list
  └─ Weak vowels CTA          ("Try again" → WordGridPage)
```

---

## Bilingual UI Pattern

Every page holds a local `bool isEnglish` state and a helper:

```dart
String t(String en, String th) => isEnglish ? en : th;
```

The language icon (🌐) in each AppBar toggles `isEnglish`. No i18n library is used — all strings are inline `t()` calls.

---

## Color Scheme

| Token | Hex | Used on |
|-------|-----|---------|
| Primary | `#1A7A50` | Buttons, active states, success |
| Primary dark | `#1A6B45` | Gradient end |
| Primary accent | `#2A9B6A` | Gradient, badges |
| Warning / short | `#FF8C42` | Short-vowel donut, failed state, weak-vowel CTA |
| Error | `#E05C6A` | Low accuracy |
| Background | `#F4FAF7` / `#EEF8F3` | Page backgrounds |
| Card | `#FFFFFF` | Card surfaces |

Pass threshold: **confidence ≥ 0.70**

---

## Database Schema

### `users`
| Column | Type | Notes |
|--------|------|-------|
| `firebase_uid` | VARCHAR(128) PK | |
| `email` | VARCHAR(255) | |
| `username` | VARCHAR(255) | |
| `age` | INT | |
| `gender` | VARCHAR(20) | `male` / `female` / `other` / NULL |
| `login_provider` | VARCHAR(20) | `email` / `google` |
| `created_at` | DATETIME | DEFAULT NOW() |

### `vowels`
| Column | Type | Notes |
|--------|------|-------|
| `id` | INT PK | |
| `symbol` | VARCHAR(20) | e.g. `-า`, `เ-` |
| `vowel_type` | ENUM | `short` / `long` |
| `name_en` | VARCHAR(100) | Lessons page bilingual name |
| `name_th` | VARCHAR(100) | |
| `description_en` | TEXT | |
| `description_th` | TEXT | |
| `lips_en` | VARCHAR(100) | Pronunciation guide |
| `lips_th` | VARCHAR(100) | |
| `tongue_en` | VARCHAR(100) | |
| `tongue_th` | VARCHAR(100) | |
| `jaw_en` | VARCHAR(100) | |
| `jaw_th` | VARCHAR(100) | |
| `duration_en` | VARCHAR(50) | e.g. `Long` |
| `duration_th` | VARCHAR(50) | e.g. `เสียงยาว` |

### `vowel_lessons`
| Column | Type | Notes |
|--------|------|-------|
| `id` | INT PK | |
| `vowel_id` | INT FK → vowels | |
| `lesson_order` | INT | 1–9 |
| `lesson_name` | VARCHAR(50) | Thai word e.g. `กา` |

### `user_lesson_progress`
| Column | Type | Notes |
|--------|------|-------|
| `firebase_uid` | VARCHAR(128) | |
| `lesson_id` | INT FK → vowel_lessons | |
| `is_completed` | TINYINT(1) | 0 = failed, 1 = passed |
| `best_accuracy` | FLOAT | 0.0–1.0 |
| `attempts` | INT | |
| `last_practiced_at` | DATETIME | |
| UNIQUE | `(firebase_uid, lesson_id)` | upsert key |

### `practice_sessions`
| Column | Type | Notes |
|--------|------|-------|
| `id` | INT PK | |
| `firebase_uid` | VARCHAR(128) | |
| `lesson_id` | INT FK | |
| `confidence` | FLOAT | 0.0–1.0 from Flask |
| `is_passed` | TINYINT(1) | confidence ≥ 0.70 |
| `duration_seconds` | INT | |
| `practiced_at` | DATETIME | DEFAULT NOW() |

### `user_streaks`
| Column | Type | Notes |
|--------|------|-------|
| `firebase_uid` | VARCHAR(128) PK | |
| `current_streak` | INT | days in a row |
| `longest_streak` | INT | all-time best |
| `last_practice_date` | DATE | |

---

## API Routes Summary

> Full request/response shapes: see [API_ROUTES.md](API_ROUTES.md)  
> SQL queries and seed data: see [BACKEND_ROUTES.md](BACKEND_ROUTES.md)

### Node.js (`http://10.0.2.2:4000`)

| Method | Route | Flutter call | Purpose |
|--------|-------|-------------|---------|
| POST | `/users` | `age.dart` direct | Create user on sign-up |
| GET | `/vowels` | `fetchVowels()` | Vowel grid with completion |
| GET | `/lessons` | `fetchLessons()` | Words for one vowel |
| POST | `/practice_sessions` | `saveSession()` | Save recording result |
| POST | `/user_lesson_progress` | `saveProgress()` | Upsert lesson progress |
| PUT | `/user_streaks` | `updateStreak()` | Recalculate streak |
| GET | `/user_streaks` | `fetchStreak()` | Read streak |
| GET | `/progress/summary` | `fetchSummary()` | Overall stats |
| GET | `/progress/vowel_stats` | `fetchVowelStats()` | Per-vowel chart data |
| GET | `/practice_sessions/recent` | `fetchRecentSessions()` | Session history |
| GET | `/progress/trend` | `fetchTrend()` | Trend chart (week/month/year/custom) |

### Flask (`http://192.168.0.62:5000`)

| Method | Route | Flutter call | Purpose |
|--------|-------|-------------|---------|
| POST | `/predict2` | `predict()` | Vowel prediction from WAV |

---

## Vowel Index Mapping

Flask uses index 0–17. DB uses id 1–18. Conversion: `index = vowelId - 1`

| DB id | Flask index | Symbol | Type | Asset |
|-------|------------|--------|------|-------|
| 1–9 | 0–8 | อา อี อือ อู เอ แอ โอ ออ เออ | long | `01.wav`–`09.wav` |
| 10–18 | 9–17 | อะ อิ อึ อุ เอะ แอะ โอะ เอาะ เออะ | short | `s1.wav`–`s9.wav` |

Assets path: `assets/references/`

---

## Recording Pipeline

```
User taps mic
  → AudioRecorder records 2 s WAV (16 kHz, mono)
  → File saved to app documents dir
  → POST Flask /predict2 (multipart: file + index)
  → Returns { confidence, user_formants: { F1, F2 } }
  → isPassed = confidence >= 0.70
  → Fire-and-forget (parallel):
      POST /practice_sessions
      POST /user_lesson_progress  (UPSERT)
      PUT  /user_streaks
  → Show result modal:
      - Score bar (green ≥75%, orange ≥50%, red <50%)
      - Waveform comparison (reference WAV orange, user WAV green)
      - Formant table (F1, F2 Hz)
```

---

## Progress Page — Trend Chart Periods

The `/progress/trend` endpoint must support a `period` query param that controls SQL grouping:

| `period` | SQL GROUP BY | X-axis in app | Extra params |
|----------|-------------|---------------|-------------|
| `week` | `DATE()` last 7 days | Sun Mon … Sat | — |
| `month` | `WEEK()` last 4 weeks | W1 W2 W3 W4 | — |
| `year` | `MONTH()` last 12 months | Jan Feb … Dec | — |
| `custom` | `DATE()` in range | d/M | `start`, `end` (YYYY-MM-DD) |

Response always uses `"date"` key as ISO date string (first day of period for month/year).

---

## Current Development Status

| Feature | Status |
|---------|--------|
| Auth (email + Google) | ✅ Complete |
| Onboarding (gender + age) | ✅ Complete |
| Homepage with streak | ✅ Complete |
| Practice flow (record → ML → save) | ✅ Complete |
| Progress analytics dashboard | ✅ Complete |
| Lessons page | 🔲 Stub — under development |

### Lessons Page — Planned Fields

The `vowels` table has bilingual pronunciation guide columns ready:
- `name_en` / `name_th` — vowel name
- `description_en` / `description_th` — description
- `lips_en` / `lips_th` — lip position
- `tongue_en` / `tongue_th` — tongue position
- `jaw_en` / `jaw_th` — jaw position
- `duration_en` / `duration_th` — duration (e.g. Long / Short)

---

## Reference Files

| File | Purpose |
|------|---------|
| [API_ROUTES.md](API_ROUTES.md) | All API routes with request/response shapes |
| [BACKEND_ROUTES.md](BACKEND_ROUTES.md) | SQL queries + DB seed data |
| [knbase/FLOW.md](knbase/FLOW.md) | Navigation flow diagrams |
| [knbase/yourprogressupdate.md](knbase/yourprogressupdate.md) | Progress page spec (UI + SQL) |
| [knbase/database_guide.md](knbase/database_guide.md) | Database setup guide |
| [knbase/detail.md](knbase/detail.md) | Additional detail notes |
