# Enabling Online Play (Firebase) — TigerHunt

Your Firebase project is **`tigerhunt-ad97a`**. The app code and credentials are
already wired up correctly, so the "Play Online → technical error" you're seeing
is **not a code bug** — it's the Firebase *backend* that still needs a few things
turned on in the console, plus one security‑rule fix that has to be deployed.

This guide covers **Web (Chrome), Android, and iOS**.

---

## What's already done (no action needed)

- Real Firebase credentials are present for every platform in `lib/firebase_options.dart` (web, Android, iOS, macOS, Windows), so `MultiplayerService.isConfigured` is `true` and the app attempts a live connection.
- `android/app/google-services.json` is in place.
- The web Google sign‑in client ID is set in `web/index.html` (that's why Google login already works — the "Player123" issue was a display bug, now fixed separately).
- `firestore.rules` and `firestore.indexes.json` exist in the repo — but they still need to be **deployed**, and the rules had a join‑blocking bug (fixed below).

---

## What's still required

### 1. Enable Anonymous sign‑in  *(all platforms — most likely cause of your error)*

Matchmaking signs each device in anonymously before touching Firestore
(`signInAnonymously()` in `multiplayer_service.dart`). If Anonymous auth is off,
online play fails immediately — and the app already reports this as
*"Anonymous sign‑in is disabled…"*.

1. Open the console: **https://console.firebase.google.com/project/tigerhunt-ad97a/authentication/providers**
2. **Authentication → Sign‑in method**.
3. Click **Add new provider** (or edit the list) → **Anonymous** → toggle **Enable** → **Save**.
4. While you're here, confirm **Google** is also **Enabled** (it should be, since login works).

### 2. Create the Cloud Firestore database  *(all platforms)*

1. Go to **https://console.firebase.google.com/project/tigerhunt-ad97a/firestore**
2. Click **Create database**.
3. Choose a location (pick the region closest to your players — this is permanent).
4. Start in **Production mode** (the rules in step 3 lock it down properly). Click **Enable**.

### 3. Deploy the security rules + indexes  *(all platforms — includes a bug fix)*

The repo's `firestore.rules` previously **rejected every attempt to join a match**
(the joining player wasn't yet listed on the match document, so the update rule
denied them). I fixed it so a second player can claim an open slot on a
still‑waiting match, while strangers and impersonation are still blocked. This
fix only takes effect once the rules are **deployed**.

**Option A — Firebase CLI (recommended, uses the fixed files in your repo):**

```bash
# from the tigerhunt/ project root, one time:
npm install -g firebase-tools
firebase login

# deploy the corrected rules and the composite indexes:
firebase deploy --only firestore:rules,firestore:indexes
```

**Option B — paste into the console:**

1. Open **https://console.firebase.google.com/project/tigerhunt-ad97a/firestore/rules**
2. Replace the contents with the corrected `firestore.rules` from the repo root, then **Publish**.
3. For indexes, open the **Indexes** tab and add the composite indexes listed in `firestore.indexes.json` (or just let the app surface the one‑click "create index" link — see below).

**About indexes:** the matchmaking query filters on `status + level + timer + createdAt`,
which needs a composite index (already defined in `firestore.indexes.json`). If any
online query ever fails with a *"The query requires an index"* (`failed‑precondition`)
error, Firestore includes a direct link in that error that creates the exact index in
one click — the app now shows a friendly hint pointing you to it.

### 4. Authorized domains  *(Web only)*

For Google/anonymous auth to complete in a browser, the domain must be authorized.

1. **https://console.firebase.google.com/project/tigerhunt-ad97a/authentication/settings**
2. Under **Authorized domains**, confirm `localhost` is listed (it is by default — covers local `flutter run -d chrome`).
3. When you deploy to a real URL (e.g. Firebase Hosting → `tigerhunt-ad97a.web.app`, or your own domain), **add that domain** here too.

### 5. Add `GoogleService-Info.plist`  *(iOS only — currently missing)*

`ios/Runner/GoogleService-Info.plist` is **not** in the project. Anonymous online
play can technically initialize from the inline options, but **Google sign‑in on
iOS needs this file** (and its URL scheme), so add it for a correct iOS build:

1. **https://console.firebase.google.com/project/tigerhunt-ad97a/settings/general**
2. Under **Your apps**, select the **iOS app** (bundle ID `com.tigerhunt.tigerhunt`). If there isn't one, click **Add app → iOS** and use that bundle ID.
3. **Download `GoogleService-Info.plist`.**
4. In Xcode, drag it into the **`Runner/`** group (check *"Copy items if needed"* and target **Runner**). Place it next to `Info.plist`.
5. For Google sign‑in, open the plist, copy the **`REVERSED_CLIENT_ID`**, and add it as a **URL Scheme** under **Runner → Info → URL Types** (or in `Info.plist` under `CFBundleURLTypes`).

### 6. Android  *(already configured — one optional check)*

`google-services.json` is already present, so anonymous online play needs nothing
more here. For **Google sign‑in on Android** to work in release/Play builds, add your
app's **SHA‑1 / SHA‑256** fingerprints:

1. Get them: `cd android && ./gradlew signingReport` (or from Play Console → App integrity).
2. Add each fingerprint at **https://console.firebase.google.com/project/tigerhunt-ad97a/settings/general** → Android app → **Add fingerprint**.
3. Re‑download `google-services.json` if you added fingerprints.

---

## How to test it worked

1. Do steps 1–3 first (Anonymous auth + Firestore + deployed rules) — that alone fixes the "technical error" for matchmaking.
2. Run the app (`flutter run -d chrome` for the quickest check).
3. Tap **Play Online**. You should reach the matchmaking screen with a live online count instead of a red error snackbar.
4. Open a second client (another browser/incognito or a device), tap **Play Online** with the same settings, and confirm the two get matched into a game.

If you still see a red error, read the snackbar text — it now tells you which piece
is missing (e.g. *"Online play is blocked by your Firestore security rules"* means the
rules weren't deployed yet; *"needs a Firestore index"* gives you the create link).

---

## Appendix — the rule bug I fixed

Before, the match `update` rule was:

```
allow update: if request.auth != null
  && (resource.data.tigerPlayerId == request.auth.uid
      || resource.data.goatPlayerId == request.auth.uid);
```

`resource.data` is the document **as it exists before** the write. When a second
player joins, they aren't on the document yet, so both checks were false and the
join was **denied** → the online "technical error." The `create` rule also had an
`&&`/`||` precedence slip that let an unauthenticated client create a match. The
corrected `firestore.rules` (repo root) fixes both: a joiner may claim an *open*
slot on a *waiting* match by writing their own uid into it, and match creation
always requires auth. I verified the rule logic against 12 join/create/deny
scenarios before writing it.
