# Changelog - TooFast

## [1.1.0] - Refactoring & Architecture Cleanup
### Added
- **AuthService**: Isolated Google Sign-In logic from the provider.
- **DatabaseService**: Isolated all Firestore operations (Stats, Users, Banners).
- **CategoryConstants**: Moved hardcoded category and subcategory lists to a dedicated constants file.

### Changed
- **Provider Cleanup**: Reduced `ToofastProvider` complexity by delegating tasks to specialized services.
- **Improved Sync**: Refined Firestore synchronization logic for better performance.

### Removed
- **Dead Code**: Deleted `main_copy.dart` and `toofast_provider_copy.dart`.

## [1.0.0] - Initial State (Audit)
- **Radar Engine**: Multi-page (up to 5) scraping of Revolico subcategories.
- **AI Analysis**: Gemini-powered deal scoring and technical analysis (Premium only).
- **Membership System**: 3-day hardware-locked trial, multiple tiers (7 days, 1 month, 6 months).
- **Payment Gateway**: Secure Stripe integration.
- **Sync System**: Favorites and user profile synced between local storage and Firestore.
- **UI/UX**: Dark mode theme, adaptive icons, and distortion-free splash screen.
- **Performance**: Battery-saving background logic and batch UI updates.
- **Support**: Integrated FAQ and technical support via email.
- **Promotion**: Standalone promotional landing page (HTML/CSS).

### Fixed
- **Scraping Robustness**: Improved JSON extraction from `__NEXT_DATA__` with HTML cleanup.
- **Category Formatting**: Fixed subcategory URL structure to match Revolico's official requirements.
- **Redirection**: Fixed "Improve Membership" button functionality from nested screens.
- **Stability**: Added null safety checks for ad cards to prevent crashes on corrupt data.
