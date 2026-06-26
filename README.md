#  EdTech Content Aggregator

A cross-platform mobile app that pulls educational content from multiple platforms into one personalized feed, ranks results based on your interests, and uses Google Gemini AI to generate structured notes from any video or article.

---

##  Screenshots

> To be added soon

---

##  Features

-  **Authentication** — Secure email/password signup and login via Firebase Auth
-  **Personalized Onboarding** — Pick topics you care about on first launch
-  **Multi-source Search** — Search YouTube videos and Dev.to articles simultaneously from one search bar
-  **Smart Ranking** — Results ranked by keyword relevance, content popularity, and your personal watch/save history
- **Article Viewer** — Open Dev.to articles in the browser with one tap
-  **Save Content** — Bookmark videos and articles for later
-  **AI Notes Generator** — Generate structured, editable notes from any video transcript or article using Google Gemini
-  **Notes Library** — All your AI-generated notes in one place, editable anytime
-  **Personalized Home Feed** — Content recommendations based on your most saved/watched categories

---

##  Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Video Content | YouTube Data API v3 |
| Article Content | Dev.to REST API |
| AI Notes | Google Gemini API |
| Transcript Extraction | youtubetranscript (Dart package) |
| Note Rendering | flutter_markdown |
| Environment Variables | flutter_dotenv |

---

##  Architecture

```
Flutter App
├── Auth Layer        → Firebase Authentication (email/password)
├── Data Layer        → Cloud Firestore (users, saved content, notes)
├── Content Layer     → YouTube Data API + Dev.to REST API + Wikipedia API
├── Ranking Engine    → Custom scoring algorithm
│                       (keyword match + popularity + user preference)
└── AI Layer          → Video/Article → Gemini API → Editable Notes
```

## Folder Structure

```
lib/
├── models/
│   ├── content_model.dart      # Unified model for videos + articles
│   ├── user_model.dart         # User profile + category scores
│   └── note_model.dart         # AI-generated note model
├── services/
│   ├── auth_service.dart       # Firebase Auth (signup, login, logout)
│   ├── firestore_service.dart  # All Firestore reads/writes
│   ├── youtube_service.dart    # YouTube Data API integration
│   ├── devto_service.dart      # Dev.to API integration
│   ├── ranking_service.dart    # Multi-source content ranking
│   ├── gemini_service.dart     # Gemini AI notes generation
│   ├── wikipedia_service.dart  # Wikipedia API integration
│   ├── cache_service.dart  # Cache home feed 
│   └── transcript_service.dart # YouTube transcript + article text extraction
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── onboarding/
│   │   └── interest_picker_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── search/
│   │   └── search_screen.dart
│   ├── detail/
│   │   ├── video_detail_screen.dart
│   │   └── article_detail_screen.dart
│   ├── saved/
│   │   └── saved_screen.dart
│   └── notes/
│       ├── saved_notes_screen.dart
│       └── note_detail_screen.dart
└── widgets/
    └── content_card.dart       # Reusable card for videos + articles
```

---

## Firestore Schema

```
users/{uid}
  ├── name, email
  ├── interests: [string]
  ├── categoryScores: { "programming": 4, "math": 1, ... }
  ├── savedContent/{contentId}
  │     title, thumbnail, source, contentType, url, category, savedAt
  └── savedNotes/{noteId}
        title, content, sourceUrl, sourceType, createdAt
```

---

##  Getting Started

### Prerequisites

- Flutter SDK (3.x or above)
- A Firebase account
- A Google Cloud account (for YouTube API key)
- A Google AI Studio account (for Gemini API key)

### 1. Clone the repo

```bash
git clone https://github.com/yourusername/edtech-app.git
cd edtech-app
flutter pub get
```

### 2. Firebase Setup

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project
3. Enable **Authentication** (Email/Password)
4. Enable **Firestore Database** (start in test mode, lock down rules before deploying)
5. Run:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
This auto-generates `firebase_options.dart` and `google-services.json`.

### 3. API Keys

Create a `.env` file in the project root (never commit this):

```
GEMINI_API_KEY=your_gemini_key_here
YOUTUBE_API_KEY=your_youtube_key_here
```

Getting the keys:
- **Gemini** → [aistudio.google.com](https://aistudio.google.com) → Get API Key
- **YouTube** → [Google Cloud Console](https://console.cloud.google.com) → Enable YouTube Data API v3 → Create credentials → API Key

### 4. Run the app

```bash
flutter run
```

---

##  Cost

This project runs entirely on free tiers:

| Service | Free Limit |
|---------|-----------|
| Firebase Auth | Unlimited users |
| Firestore | 50,000 reads/day, 20,000 writes/day |
| YouTube Data API | 10,000 units/day (~100 searches) |
| Dev.to API | Unlimited |
| Gemini API | 1,500 requests/day, 15 requests/min |
| Wikipedia API | Unlimited |
---

##  License

MIT License — feel free to use this project as a reference.