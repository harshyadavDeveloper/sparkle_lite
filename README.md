# 🌸 Sparkle — Women & Family Health Companion

A simplified but functional Flutter health companion app built as a take-home assignment for Earth On Sky (EOS / Zoom My Life). Sparkle helps users manage their health journey in one place — privately, calmly, and across both mobile and web.

**Live Web Demo:** https://sparkle-lite-523e6.web.app  
**GitHub:** https://github.com/harshyadavDeveloper/sparkle_lite  
**Android APK:** Available in [GitHub Releases v1.0.0](https://github.com/harshyadavDeveloper/sparkle_lite/releases/tag/v1.0.0)

---

## 📋 Project Overview

Sparkle Lite is a cross-platform Flutter application targeting women and family health management. The app allows users to:

- Create a private health profile
- Track period and gynaecology-related symptoms
- Upload and manage health records
- View a unified personal health timeline
- Receive responsible AI-style health insights using mock logic
- Prepare a doctor visit summary
- Manage privacy and notification preferences
- Add and manage family member profiles
- Use the experience on both Android and web

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.35.7 |
| Language | Dart |
| State Management | Provider |
| Routing | Navigator 2.0 |
| Authentication | Firebase Auth (Email/Password + Google Sign-In) |
| Database | Cloud Firestore |
| File Storage | Mock implementation (see Known Limitations) |
| HTTP Client | Dio |
| Local Storage | SharedPreferences |
| Hosting | Firebase Hosting |
| Date Formatting | smart_date_formatter (pub.dev) |
| CI/CD | GitHub Actions |

---

## 🌿 Flutter Version

```
Flutter 3.35.7 • channel stable
Framework • revision adc9010625
```

---

## ⚙️ Setup Instructions

### Prerequisites
- Flutter 3.35.7 or higher
- Dart SDK ^3.9.2
- Android Studio or VS Code
- A Firebase project (see Firebase Setup below)

### Clone and Install

```bash
git clone https://github.com/harshyadavDeveloper/sparkle_lite.git
cd sparkle_lite
flutter pub get
```

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** → Email/Password and Google Sign-In
3. Enable **Cloud Firestore** in test mode
4. Run `flutterfire configure` to generate `firebase_options.dart`
5. Add your Android SHA-1 fingerprint to Firebase project settings:
```bash
cd android && ./gradlew signingReport
```
6. Download and replace `android/app/google-services.json`

---

## 📱 How to Run Mobile

```bash
flutter run
```

Ensure a device or emulator is connected. The app will launch on Android by default.

---

## 🌐 How to Run Web

```bash
flutter run -d chrome
```

The web version automatically shows the desktop dashboard layout with sidebar navigation instead of the mobile layout.

---

## 🧪 How to Run Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/data/models/symptom_log_test.dart
```

### Test Coverage

**Unit Tests (7):**
- `SymptomLog` model — serialization, optional fields, pain level bounds
- `HealthRecord` model — serialization, optional fields, valid record types
- `UserProfile` model — serialization, optional conditions and medications
- `PrivacySettings` model — default values, generic notifications ON by default
- `FirebaseAuthService` — sign up, sign in, sign out, auth state changes

**Widget Tests (3):**
- `LoginScreen` — form renders, empty validation, invalid email, short password, valid form
- `AddSymptomScreen` — form renders, required field validation, chip selection
- `HealthRecordsScreen` — empty state, emoji, FAB visibility, loading state, error state

---

## 🏗 Architecture

The project follows a **feature-first folder structure** with clear separation of concerns:

```
lib/
  core/
    constants/       → App-wide enums and string constants
    theme/           → AppTheme, colors, typography
    routing/         → Navigator 2.0 router and route constants
    utils/           → Logger, validators, helpers
    widgets/         → Shared reusable widgets
  features/
    auth/            → Login, signup, onboarding, AuthProvider
    profile/         → Health profile setup, ProfileProvider
    dashboard/       → Mobile dashboard, web dashboard
    symptom_tracker/ → Add/edit/delete logs, SymptomProvider
    records/         → Upload/edit/delete records, HealthRecordProvider
    timeline/        → Unified timeline screen
    ai_insight/      → Mock AI engine, AiInsightProvider
    doctor_visit/    → Doctor summary, DoctorSummaryProvider
    privacy/         → Privacy settings, notification preferences
    family/          → Family member management
  data/
    models/          → SymptomLog, HealthRecord, AiInsight, etc.
    repositories/    → Firestore CRUD abstraction per feature
    services/        → FirebaseAuthService, MockAiEngine
  main.dart
```

Business logic lives exclusively in Provider classes and Repository classes. Widgets contain zero business logic — they call Provider methods and render state.

---

## 🔄 State Management — Why Provider

Provider was chosen over Riverpod, BLoC, or GetX for the following reasons:

- **Production-proven:** Used in a live travel app serving 5,000+ monthly active users at current employer (Bizzmirth Holidays), so the approach is battle-tested not experimental
- **Appropriate complexity:** The app's state is feature-scoped with no complex cross-feature reactive chains — Provider handles this cleanly without boilerplate overhead
- **Explicit and readable:** Every state change is traceable through `notifyListeners()` calls, making code review straightforward
- **README justification required by PDF:** Provider's simplicity makes the architecture easy to explain during code review

Each feature has its own `ChangeNotifier` provider. All providers are registered at the `MaterialApp` level and bootstrapped from the dashboard on login.

---

## 🗄 Data Model Explanation

### Firestore Collection Structure

```
users/{userId}
profiles/{userId}
symptomLogs/{userId}/logs/{logId}
healthRecords/{userId}/records/{recordId}
aiInsights/{userId}/insights/{insightId}
doctorSummaries/{userId}/summaries/{summaryId}
familyMembers/{userId}/members/{memberId}
privacySettings/{userId}
notificationPreferences/{userId}
```

All data is scoped to `userId` — no user can access another user's data.

### Key Models

**SymptomLog** — date, periodStatus, flowLevel, painLevel (0–10), mood, symptoms (List), notes (optional)

**HealthRecord** — title, recordType, recordDate, doctorName (optional), fileUrl, localFilePath (session-only, see Known Limitations), notes (optional)

**AiInsight** — summary, possiblePattern, careGuidance, doctorQuestions (List), disclaimer (non-diagnostic)

**PrivacySettings** — useGenericNotificationText defaults to `true` per privacy-first design requirement

---

## 🔒 Privacy Considerations

Privacy is a first-class concern throughout the app:

- **Generic notifications by default** — notification text shows "You have a health reminder" instead of specific health details, controlled by `useGenericNotificationText` flag which defaults to `true`
- **Sensitive fields optional** — known conditions, medications, and notes are never required
- **Family data separation** — family member records are stored in a completely separate Firestore subcollection from personal gynaecology data. The two never mix
- **No diagnosis** — the AI insight feature explicitly avoids diagnostic language. Responses always include: *"This is not a diagnosis and does not replace medical advice."*
- **Confirmation before sharing** — privacy settings include a `requireConfirmationBeforeSharing` flag
- **Dashboard privacy mode** — users can hide sensitive details from the main dashboard

---

## 🤖 Mock AI Engine

The AI health insight feature uses local rule-based mock logic instead of a real API. Insight rules follow the PDF specification:

| Condition | Insight Generated |
|---|---|
| Pain level 8+ | Suggest discussing severe pain with a doctor |
| Heavy flow + dizziness note | Show stronger care guidance |
| Irregular bleeding selected | Suggest tracking dates and preparing doctor questions |
| Anxious mood across multiple logs | Suggest discussing emotional wellbeing |
| Multiple logs, no major symptoms | Show gentle wellness summary |
| No symptoms | Show gentle wellness summary |

All responses include a non-diagnostic disclaimer and suggested doctor questions. The AI response never uses language like "You have PCOS", "You are pregnant", or "You do not need a doctor."

---

## ⚠️ Known Limitations

**1. File Upload (Firebase Storage)**
Firebase Storage requires the Blaze (pay-as-you-go) billing plan. To keep the project entirely on the free Spark plan, file upload uses a mock implementation that stores a reference URL in Firestore. In production, replacing the mock with real Firebase Storage upload requires a single method change in `HealthRecordRepository.uploadFile()`.

Image previews work during the current app session using the local file path. On app restart, metadata persists in Firestore but the local preview is no longer available.

**2. Offline Cache**
Isar local database offline caching was scoped out due to time constraints. The architecture is designed for it — repositories are abstracted so an Isar layer can be inserted between the UI and Firestore without changing any Provider or widget code. This is the same offline-first pattern used in production at Bizzmirth Holidays (Isar + Provider, serving 5,000+ users).

**3. Push Notifications**
Notification preferences are stored in Firestore and respect the generic text setting. Actual push notification delivery via Firebase Cloud Messaging is not implemented — this is a UI and preference layer only.

**4. Google Sign-In SHA-1**
Google Sign-In requires the debug SHA-1 fingerprint of the development machine to be registered in Firebase. If testing on a different machine, add its SHA-1 via Firebase Console → Project Settings → Android App → Add fingerprint.

---

## 🔀 Trade-offs

**1. Provider over Riverpod**
Riverpod offers better testability and compile-time safety. Provider was chosen for production familiarity and lower boilerplate. For a larger team or longer-lived codebase, Riverpod would be the better choice.

**2. Navigator 2.0 over go_router**
Navigator 2.0 gives full control over the navigation stack and handles web URL routing natively. go_router would be simpler to configure but Navigator 2.0 was chosen for existing production experience and its native web deep-linking support — important since this app targets both mobile and web.

**3. Mock file upload over real Firebase Storage**
Real Firebase Storage requires the Blaze billing plan. Mock implementation was chosen to keep the project entirely free while demonstrating the correct architecture. The abstraction means switching to real storage is a one-method change.

**4. Dio over http package**
Dio was chosen over the standard `http` package for its built-in retry logic, request/response interceptors, and structured logging. This is particularly valuable in a health app where network reliability matters and failed requests need to be retried gracefully.

**5. SharedPreferences + Firestore dual storage for preferences**
Notification toggle states are stored both in SharedPreferences (for instant local read on app start) and Firestore (for persistence across devices). This avoids a Firestore read on every app launch for UI preferences while keeping them synced.

**6. Feature-first over layer-first architecture**
A layer-first structure (all models in one folder, all providers in one folder) would be simpler initially. Feature-first was chosen because it scales better as features grow, makes code review easier since all related code is co-located, and is easier to hand off to another developer.

---

## 🚀 What I Would Do Next in Production

- Replace mock file upload with real Firebase Storage (single method change)
- Add Isar offline cache layer between repositories and Firestore
- Implement real push notifications via Firebase Cloud Messaging
- Add biometric authentication (fingerprint/Face ID) for app lock
- Add localization — smart_date_formatter already supports 16 languages
- Add dark mode — ThemeMode toggle is architecturally straightforward

---

## 📸 Screenshots

Mobile and web screenshots available in the demo video.

---

## 🎬 Demo Video

A 7–12 minute screen-recorded walkthrough covering all modules, web dashboard, state management approach, privacy decisions, and known limitations is submitted alongside this repository.

---

## 📦 Open Source Integration

This project integrates [smart_date_formatter](https://pub.dev/packages/smart_date_formatter) — a Flutter DateTime toolkit published by the developer on pub.dev with 16-language localization, auto-refreshing widgets, and streak analytics. It is used throughout the app for human-readable relative dates ("Today", "Yesterday") with exact date tooltips on demand.

The app name was renamed across all platforms using [rename_app](https://pub.dev/packages/rename_app), a pub.dev package to which the developer is an active contributor.

---

## 👨‍💻 Developer

**Harsh Yadav**  
Flutter Developer — 3+ years production experience  
GitHub: [@harshyadavDeveloper](https://github.com/harshyadavDeveloper)  
pub.dev: [smart_date_formatter](https://pub.dev/packages/smart_date_formatter) • [fl_pretty_charts](https://pub.dev/packages/fl_pretty_charts)

---

*Built with 🌸 for Earth On Sky / Zoom My Life take-home assignment*