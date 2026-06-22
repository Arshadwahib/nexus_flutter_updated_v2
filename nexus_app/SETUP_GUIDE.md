# 🚀 Nexus App — Complete Setup Guide

---

## STEP 1: Install Flutter

```bash
# macOS
brew install flutter

# Or download from https://flutter.dev/docs/get-started/install

# Verify installation
flutter doctor
```

Make sure you have:
- ✅ Flutter SDK
- ✅ Android Studio (for Android)
- ✅ Xcode (for iOS, macOS only)
- ✅ VS Code with Flutter extension

---

## STEP 2: Create Supabase Project (FREE)

1. Go to **https://supabase.com** → Sign up free
2. Click **"New Project"**
3. Choose a name: `nexus-app`
4. Set a strong database password
5. Choose region closest to your users
6. Wait ~2 minutes for project to initialize

### Get your credentials:
- Go to **Settings → API**
- Copy **Project URL** (looks like: `https://xxxx.supabase.co`)
- Copy **anon public key** (long JWT string)

---

## STEP 3: Configure the App

Open `lib/utils/constants.dart` and replace:

```dart
static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
```

---

## STEP 4: Run the Database Schema

1. In Supabase Dashboard → **SQL Editor** → **New Query**
2. Open `supabase_schema.sql` from this project
3. Select all (Ctrl+A) → Paste → Click **Run**
4. Wait for "Success" message

---

## STEP 5: Create Storage Buckets

In Supabase Dashboard → **Storage** → **New bucket**:

| Bucket Name | Public | Description |
|---|---|---|
| `avatars` | ✅ Yes | Profile pictures & covers |
| `posts` | ✅ Yes | Post images |
| `reels` | ✅ Yes | Video reels |
| `stories` | ✅ Yes | Story media |
| `chat_media` | ❌ No | Private chat attachments |

---

## STEP 6: Enable Real-time

In Supabase Dashboard → **Database** → **Replication**:

Enable replication for these tables:
- ✅ `messages`
- ✅ `notifications`
- ✅ `typing_indicators`
- ✅ `posts`

---

## STEP 7: Install Dependencies

```bash
cd nexus_app
flutter pub get
```

If you get errors:
```bash
flutter clean
flutter pub get
```

---

## STEP 8: Run the App

```bash
# List connected devices
flutter devices

# Run on Android emulator
flutter run

# Run on iOS simulator
flutter run -d ios

# Run with logging
flutter run --verbose

# Build release APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

---

## STEP 9: First Launch

1. The app opens to the **Login screen**
2. Tap **"Sign up"** → Create your first account
3. You're in! 🎉

---

## 🔐 Admin Access (PRIVATE)

**How to access the hidden admin portal:**
1. Go to the Login screen
2. Tap the **empty space at the bottom** of the screen **5 times quickly**
3. The Admin Auth screen appears

**Admin credentials (DO NOT SHARE):**
```
Username: arshadwahib99
Password: arshadwahib99
```

**Admin capabilities:**
- Gold verified badge (auto-assigned)
- Grant/revoke blue ✓ badges to any user
- Access Admin Dashboard
- Ban/suspend accounts
- Delete any content
- Post platform announcements
- View user statistics

---

## 📊 Supabase Free Tier Limits

| Resource | Limit | Notes |
|---|---|---|
| Database | 500 MB | ~1M+ posts |
| Storage | 1 GB | ~5,000 images |
| Monthly Active Users | 50,000 | |
| Bandwidth | 5 GB/month | |
| Real-time connections | 200 concurrent | |
| Edge Functions | 500K/month | |

**To upgrade:** Supabase Pro is $25/month (8GB DB, 100GB storage, unlimited MAU)

---

## 🏗️ Architecture Overview

```
User Action
    ↓
Flutter Widget (UI)
    ↓
Provider (State Management)
    ↓
Service Layer (AuthService, PostService, etc.)
    ↓
Supabase Client (Database, Storage, Auth, Real-time)
    ↓
PostgreSQL Database (Supabase hosted)
```

---

## 🐛 Common Issues & Fixes

### "Supabase not initialized"
Make sure `supabaseUrl` and `supabaseAnonKey` are set in `constants.dart`

### "Permission denied" on storage
Check that storage buckets are created with correct public/private settings

### "Column does not exist" errors
Re-run the SQL schema — make sure you ran the full `supabase_schema.sql`

### Build fails on iOS
```bash
cd ios
pod install
cd ..
flutter run
```

### "Null check operator used on null"
Check your Supabase credentials — app may be failing to connect

### Video not playing on iOS
Add to `ios/Podfile`:
```ruby
config.build_settings['ENABLE_BITCODE'] = 'NO'
```

---

## 🌐 Optional: Custom Domain

1. Deploy a web version: `flutter build web`
2. Host on Vercel/Netlify (free)
3. Or build mobile apps and publish to App Store / Play Store

---

## 📱 Publishing

### Android (Play Store)
```bash
flutter build appbundle --release
# Upload .aab file to Google Play Console
```

### iOS (App Store)
```bash
flutter build ios --release
# Open Xcode → Archive → Distribute App
```

---

## 🔧 Environment Variables (Production)

For production, use `flutter_dotenv` or Dart's `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_KEY=your_key_here
```

Then in `constants.dart`:
```dart
static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_KEY');
```

---

## 📞 Support

If you hit issues:
1. Run `flutter doctor -v` and check all items
2. Check Supabase logs: Dashboard → **Logs** → **API**
3. Check Flutter logs: `flutter run --verbose`
