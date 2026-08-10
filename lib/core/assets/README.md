# TigerHunt App Icons & Splash Screens

This directory contains the design specifications and Flutter widgets for generating app icons and splash screens.

## App Icon Design

The app icon features:
- **Traditional Indian art style** (Madhubani-inspired border)
- **Stylized tiger face** in the center
- **Warm earth-tone colors**: Orange (#E86A17), Gold (#FFD700), Cream (#F5E6D3), Henna (#8B4513)
- **Corner motifs** with paisley-inspired patterns

### Icon Sizes Required

#### iOS (AppStore)
- 1024x1024 (App Store)
- 180x180 (iPhone @3x)
- 120x120 (iPhone @2x)
- 167x167 (iPad Pro @2x)
- 152x152 (iPad @2x)
- 76x76 (iPad @1x)

#### Android
- 512x512 (Play Store)
- Adaptive icon: 108dp (432px @xxxhdpi)
  - Foreground: Tiger face centered in safe zone (66dp visible)
  - Background: Cream gradient (#F5E6D3 to #E8D5B5)

## Splash Screen Design

The splash screen features:
- **Gradient background**: Parchment to darker cream
- **Warli-style background pattern**: Subtle triangular figures
- **Centered app icon** (150x150)
- **App name**: "TigerHunt" in bold henna color
- **Tagline**: "बाघ चाल • The Ancient Game of Strategy"
- **Loading indicator**: Orange circular progress
- **Bottom decoration**: Tiger and goat emojis

## Generating Icons

Use `flutter_launcher_icons` package:

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
  adaptive_icon_background: "#F5E6D3"
  adaptive_icon_foreground: "assets/icons/adaptive_foreground.png"
```

Then run:
```bash
flutter pub run flutter_launcher_icons
```

## Native Splash Screen

Use `flutter_native_splash` package:

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_native_splash: ^2.3.1

flutter_native_splash:
  color: "#F5E6D3"
  image: assets/splash/splash_logo.png
  android_12:
    icon_background_color: "#F5E6D3"
    image: assets/splash/splash_logo.png
```

Then run:
```bash
flutter pub run flutter_native_splash:create
```

## Color Codes

| Name | Hex | Usage |
|------|-----|-------|
| Primary Orange | #E86A17 | Tiger, accents |
| Accent Gold | #FFD700 | Decorations, highlights |
| Background Cream | #F5E6D3 | Main background |
| Border Henna | #8B4513 | Borders, text |
| Dark Cream | #E8D5B5 | Gradient end |

## File Structure

```
assets/
├── icons/
│   ├── app_icon.png          # Main icon (1024x1024)
│   ├── adaptive_foreground.png  # Android adaptive foreground
│   └── adaptive_background.png  # Android adaptive background
└── splash/
    ├── splash_logo.png       # Splash logo (500x500)
    └── splash_background.png # Full splash image
```
