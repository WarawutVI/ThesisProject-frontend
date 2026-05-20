# App Navigation Flow

## Entry Point

```
main.dart
  └─ Firebase.initializeApp()
  └─ runApp → Wrapper
```

## Wrapper (auth gate)

```
Wrapper
  ├─ logged in  → Homepage
  └─ logged out → Login
```

---

## Auth Flow

### Login page

```
Login
  ├─ Email/password login
  │     ├─ success → Wrapper → Homepage
  │     └─ fail    → snackbar error
  │
  ├─ Google login
  │     ├─ existing user → Wrapper → Homepage
  │     └─ new user      → Signup (with snackbar prompt to sign up first)
  │
  ├─ "Forgot password?" → Forgot
  └─ "Sign up"          → Signup
```

### Signup page

```
Signup
  ├─ Email signup
  │     ├─ validation pass → GenderPage
  │     └─ validation fail → snackbar error
  │
  ├─ Google signup
  │     ├─ existing user → Wrapper → Homepage
  │     └─ new user      → GenderPage
  │
  └─ "Log in" → Login
```

### Onboarding (new users only)

```
GenderPage
  ├─ select gender + Continue → AgePage
  └─ Skip                     → AgePage (gender = null)

AgePage
  └─ "Let's go!" → POST /users → Wrapper → Homepage
```

### POST body sent to backend

```json
{
  "firebase_uid": "...",
  "username":     "...",
  "email":        "...",
  "gender":       "male" | "female" | "other" | null,
  "age":          17,
  "login_provider": "email" | "google"
}
```

---

## Main App (after login)

```
Homepage
  ├─ Lessons  → LessonsPage   (stub)
  ├─ Practice → PracticePage  (stub)
  └─ Progress → ProgreesPage  (stub)
```

---

## File Map

| File | Role |
|------|------|
| `lib/main.dart` | App entry, Firebase init |
| `lib/wrapper.dart` | Auth state gate |
| `lib/auth/login.dart` | Login screen |
| `lib/auth/signup.dart` | Signup screen |
| `lib/auth/gender.dart` | Gender selection (onboarding step 1) |
| `lib/auth/age.dart` | Age selection + backend POST (onboarding step 2) |
| `lib/auth/forgot.dart` | Forgot password screen |
| `lib/auth/profile_setup.dart` | Combined gender+age page (unused, kept for reference) |
| `lib/pages/homepage.dart` | Main home screen |
| `lib/pages/lessonspage.dart` | Lessons (stub) |
| `lib/pages/practicepage.dart` | Practice (stub) |
| `lib/pages/progreespage.dart` | Progress (stub) |
