# Project Map - TooFast

## 📍 Root Files
- `architecture.md`: Technical design documentation.
- `changelog.md`: History of changes.
- `pubspec.yaml`: Flutter dependencies and asset configuration.
- `firebase.json` / `.firebaserc`: Firebase configuration.

## 📱 Frontend (lib/)
- `main.dart`: Entry point of the app.
- `providers/toofast_provider.dart`: **CORE LOGIC**. Handles scraping, auth, and global state.
- `screens/`:
    - `configuracion_busqueda_screen.dart`: Home/Search configuration.
    - `estado_escaneo_screen.dart`: Scanning visualizer.
    - `alertas_ofertas_screen.dart`: List of results.
    - `guardados_screen.dart`: Favorites.
    - `perfil_screen.dart`: User profile and settings entrance.
    - `ajustes_categorias_screen.dart`: Premium menu customization.
    - `faq_screen.dart` / `acerca_de_screen.dart`: Help and info.
- `widgets/` / `components/`:
    - `oferta_card.dart`: The item display widget with contact options.
    - `app_drawer.dart`: Multi-level category menu.
- `services/stripe_service.dart`: Handles payment flow.
- `utils/app_utils.dart`: UI dialogs and snackbars.

## ☁️ Backend (functions/)
- `index.js`: Main server logic.
    - `createStripePaymentIntent`: Payment handler.
    - `analyzeDealWithAI`: Gemini AI integration.
    - `revolicoScraper`: Periodic banner update task.

## 🎨 Assets
- `assets/logo_centro.png`: Official app logo.
- `assets/splash.png`: App load screen image.

## 🌐 Web
- `web_landing/`: Standalone promotional website.
