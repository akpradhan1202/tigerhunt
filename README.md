# TigerHunt 🐯🐐 — बाघ चाल

A beautiful cross-platform mobile game based on the ancient Indian/Nepali strategy game **Bagh-Chal** (Tiger vs Goats), featuring traditional Madhubani & Warli-inspired artwork.

![Flutter](https://img.shields.io/badge/Flutter-3.19+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
[![CI](https://github.com/yourusername/tigerhunt/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/tigerhunt/actions/workflows/ci.yml)

## 🎮 About the Game

TigerHunt is a strategic two-player game where one player controls **4 tigers** and the other controls **20 goats**:

- **Tigers** win by capturing 5 goats (jumping over them like in checkers)
- **Goats** win by trapping all tigers so they can't move

### Game Rules

1. All four tigers start at the corners of the board
2. Goats are placed one at a time (goats move first)
3. Tigers can move or capture from the start
4. Once all 20 goats are placed, goats can move
5. Tigers capture by jumping over adjacent goats to an empty space
6. Goats cannot jump

## ✨ Features

### 🎯 Game Modes
- **Play vs AI** - 4 difficulty levels (Beginner → Hard) with Minimax AI
- **Pass & Play** - Two players, one device
- **Online Multiplayer** - Play with friends or random opponents
- **Timed Games** - 5, 10, 15, 30, 60 minute options

### 📊 Rating System
- **ELO-based ratings** like Chess.com
- Separate ratings for Tiger and Goat play
- **Rating Tiers**: Newcomer → Bronze → Silver → Gold → Platinum → Diamond → Master → Grandmaster
- **Points & Levels** for progression
- **Achievements** to unlock
- **Leaderboards**

### 🎨 Three Board Levels
| Level | Description | Difficulty |
|-------|-------------|------------|
| 🔺 **Pyramid** | Triangle board | Beginner (Ages 4+) |
| ⬛ **Square** | Grid with diagonals | Intermediate |
| ✦ **Traditional** | Classic Bagh-Chal | Advanced |

### 🎭 Visual Themes
- **Traditional** - Classic warm earth tones (default)
- **Night Mode** - Dark theme for night play
- **Diwali** - Festival of lights theme
- **Holi** - Festival of colors theme
- **Royal** - Elegant gold & purple
- **Nature** - Fresh forest greens
- **Ocean** - Cool blue tones

### 📚 Additional Features
- **Interactive Tutorial** - 13-step guide to learn the game
- **Daily Challenges** - Puzzles with difficulty ratings
- **Tournaments** - Knockout, Swiss, Round Robin, Arena formats
- **Game History** - Move-by-move replay
- **In-Game Chat** - With quick emoji presets
- **Achievements System** - Unlock badges and titles

## 🚀 Getting Started

### Prerequisites
- Flutter 3.19.0 or higher
- Dart 3.0 or higher
- Firebase project (for online features)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/tigerhunt.git
cd tigerhunt
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Firebase** (for online features)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli
flutterfire configure
```

4. **Run the app**
```bash
flutter run
```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── core/
│   ├── theme/
│   │   ├── app_theme.dart       # Traditional Indian theme
│   │   └── board_themes/        # Multiple board themes
│   ├── assets/
│   │   └── app_icon_design.dart # Icon & splash designs
│   └── services/
│       └── multiplayer_service.dart
├── features/
│   ├── auth/
│   │   └── models/
│   │       ├── user_profile.dart
│   │       └── rating_system.dart
│   ├── game/
│   │   ├── models/
│   │   │   ├── game_models.dart
│   │   │   ├── game_state.dart
│   │   │   ├── board_connections.dart
│   │   │   ├── game_engine.dart
│   │   │   └── ai_engine.dart
│   │   ├── screens/
│   │   │   └── game_screen.dart
│   │   └── widgets/
│   │       ├── game_board.dart
│   │       ├── custom_pieces.dart
│   │       └── decorative_elements.dart
│   ├── tutorial/                # Interactive tutorial
│   ├── history/                 # Game replay
│   ├── chat/                    # In-game chat
│   ├── challenges/              # Daily puzzles
│   └── tournaments/             # Tournament system
└── test/
    ├── game_engine_test.dart
    └── ai_engine_test.dart
```

## 🎨 Design System

### Colors
| Name | Hex | Usage |
|------|-----|-------|
| Saffron | `#FF6B35` | Accents, highlights |
| Terracotta | `#D4533A` | Primary actions |
| Forest Green | `#2D5A27` | Goat elements |
| Henna | `#8B4513` | Borders, text |
| Cream | `#FFF8E7` | Backgrounds |
| Peacock Blue | `#0077B6` | Interactive elements |
| Turmeric | `#E9B824` | Gold accents |

## 🛠️ Tech Stack

- **Framework**: Flutter 3.19+
- **State Management**: Riverpod
- **Navigation**: go_router
- **Backend**: Firebase (Auth, Firestore, Realtime DB, Storage)
- **AI**: Minimax with Alpha-Beta pruning
- **Art Style**: Custom painters (Madhubani/Warli inspired)

## 🔄 CI/CD

Automated workflows for:
- Code analysis & testing on every push/PR
- Android APK/AAB builds
- iOS builds
- Web deployment to GitHub Pages
- Play Store deployment
- App Store deployment via TestFlight

See [CI/CD Setup Guide](.github/CI_CD_SETUP.md) for details.

## 🎯 Roadmap

- [x] Core game engine with all 3 board types
- [x] AI with multiple difficulties
- [x] Interactive tutorial system
- [x] Game history/replay
- [x] ELO rating system
- [x] Tournament system
- [x] Daily challenges & puzzles
- [x] Multiple visual themes
- [x] CI/CD pipelines
- [ ] Voice chat in multiplayer
- [ ] Spectator mode
- [ ] Clan/team system
- [ ] Seasonal events
- [ ] Apple Watch companion

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines first.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes following [Conventional Commits](https://www.conventionalcommits.org/)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Traditional Bagh-Chal game from Nepal/India
- Madhubani & Warli art traditions for visual inspiration
- Chess.com for UI/UX inspiration
- Flutter community for excellent packages

## 📧 Contact

- **Website**: [tigerhunt.app](https://tigerhunt.app)
- **Email**: support@tigerhunt.app
- **Twitter**: [@tigerhuntgame](https://twitter.com/tigerhuntgame)

---

Made with ❤️ and 🎨 Traditional Indian Art

**Play the ancient game of strategy. Will you hunt or be hunted?** 🐯🐐
