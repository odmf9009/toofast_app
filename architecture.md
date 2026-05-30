# TooFast - Project Architecture

## 🚀 Overview
TooFast is a real-time classifieds tracking platform. It uses a combination of mobile-side scraping (Radar) and cloud-side intelligence (Gemini AI) to help users find the best deals on Revolico.

## 🏗️ Technical Stack
- **Frontend**: Flutter (State Management via `Provider`)
- **Backend**: Firebase (Firestore, Functions, Auth, Storage)
- **AI**: Google Gemini (via Firebase Cloud Functions)
- **Payments**: Stripe
- **Scraping**: Headless InAppWebView (Mobile-side)

## 📁 Folder Structure
- `lib/`: Core application logic.
    - `providers/`: State coordination (Main: `ToofastProvider`).
    - `services/`: Specialized logic.
        - `auth_service.dart`: Google Sign In handler.
        - `database_service.dart`: Firestore manager.
        - `stripe_service.dart`: Payment logic.
    - `core/`: Global shared configuration.
        - `constants/`: Hardcoded maps and lists (Categories).
    - `screens/`: UI views.
    - `models/`: Data structures.
    - `utils/`: Helper functions.
- `functions/`: Firebase Cloud Functions (Node.js).
    - Payment processing.
    - AI Deal Analysis.
    - Scheduled banner scraping.
- `web_landing/`: Promotional website (HTML/CSS).
- `assets/`: Logos, splash screens, and images.

## 🔄 Data Flow
1. **User Input**: User sets filters (category, keyword, price) in `ConfiguracionBusquedaScreen`.
2. **Radar Scanning**: `ToofastProvider` initiates a `HeadlessInAppWebView` to scrape Revolico.
3. **Data Extraction**: Results are extracted from `__NEXT_DATA__` JSON or HTML via RegEx.
4. **Deal Analysis**: Premium users' hits are sent to `analyzeDealWithAI` (Cloud Function -> Gemini API).
5. **Notification**: Hits are filtered (excluding featured ads) and notified via `flutter_local_notifications`.
6. **Persistence**: Favorites and subscription status are synced between local `SharedPreferences` and Firestore.

## 🛡️ Security & Membership
- **Trial Logic**: 3-day trial locked to physical device ID.
- **Premium Tiers**: Controlled via Firestore user document and `ToofastProvider` boolean flags.
- **Secrets**: API keys (Stripe, Gemini) are stored in Firebase Secrets Manager.
