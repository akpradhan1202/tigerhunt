# TigerHunt CI/CD Setup Guide

This document explains how to set up the CI/CD pipelines for TigerHunt.

## GitHub Actions Workflows

### 1. Main CI (`ci.yml`)
Runs on every push and PR:
- Code analysis and formatting check
- Unit tests with coverage
- Android build (APK & AAB)
- iOS build (unsigned)
- Web build with GitHub Pages deployment

### 2. Deploy Android (`deploy-android.yml`)
Deploys to Google Play Store:
- Triggered on version tags (`v*`)
- Manual trigger with track selection (internal/alpha/beta/production)

### 3. Deploy iOS (`deploy-ios.yml`)
Deploys to App Store via TestFlight:
- Triggered on version tags (`v*`)
- Manual trigger with optional App Review submission

### 4. PR Checks (`pr-checks.yml`)
Quality gates for pull requests:
- Formatting and analysis
- Test coverage threshold (60%)
- App size reporting
- Commit message linting

## Required Secrets

### Android Deployment
| Secret | Description |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64 encoded upload keystore |
| `ANDROID_KEY_ALIAS` | Key alias in keystore |
| `ANDROID_KEY_PASSWORD` | Password for the key |
| `ANDROID_STORE_PASSWORD` | Password for the keystore |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Google Play API service account JSON |

### iOS Deployment
| Secret | Description |
|--------|-------------|
| `APPLE_CERTIFICATE_BASE64` | Base64 encoded .p12 certificate |
| `APPLE_CERTIFICATE_PASSWORD` | Certificate password |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Base64 encoded provisioning profile |
| `KEYCHAIN_PASSWORD` | Password for temporary keychain |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect Issuer ID |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64 encoded API key (.p8) |

## Setting Up Secrets

### Generate Android Keystore
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Encode to base64
base64 -i upload-keystore.jks -o keystore.txt
```

### Create Google Play Service Account
1. Go to Google Play Console > Settings > API access
2. Create a new service account
3. Download JSON key
4. Grant "Release manager" permissions

### Create App Store Connect API Key
1. Go to App Store Connect > Users and Access > Keys
2. Generate API Key with "App Manager" role
3. Download .p8 file
4. Note Key ID and Issuer ID

### Encode iOS Certificate
```bash
# Export certificate from Keychain as .p12
base64 -i certificate.p12 -o certificate.txt

# Export provisioning profile
base64 -i profile.mobileprovision -o profile.txt
```

## Creating a Release

### Version Tag Release
```bash
# Update version in pubspec.yaml
# version: 1.2.0+15

git add pubspec.yaml
git commit -m "chore: bump version to 1.2.0"
git tag v1.2.0
git push origin main --tags
```

### Manual Deployment
1. Go to Actions tab in GitHub
2. Select deployment workflow
3. Click "Run workflow"
4. Select track/options
5. Click "Run workflow"

## Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): subject

body

footer
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `test`: Adding tests
- `build`: Build system changes
- `ci`: CI configuration
- `chore`: Other changes

Examples:
```
feat(game): add multiplayer lobby
fix(ai): correct capture validation logic
docs(readme): update installation instructions
```

## Branch Strategy

- `main`: Production releases
- `develop`: Integration branch
- `feature/*`: New features
- `fix/*`: Bug fixes
- `release/*`: Release preparation

## Troubleshooting

### Build Failures
1. Check Flutter version matches workflow
2. Verify all dependencies are published
3. Check for platform-specific issues

### Deployment Failures
1. Verify secrets are correctly set
2. Check certificate/profile expiration
3. Ensure app metadata is complete in stores
4. Check version code is incremented

### Coverage Threshold
If coverage drops below 60%:
1. Add missing unit tests
2. Exclude generated files in lcov
3. Temporarily lower threshold (not recommended)
