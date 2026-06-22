# NEXUS — Social Media App
### Twitter × Instagram hybrid · Flutter · Supabase (Free)

---

## 📱 Features

### Core Social Features
| Feature | Details |
|---|---|
| **Posts** | Text, images (up to 10), videos |
| **Reels** | Short-form vertical videos (up to 90s) |
| **Stories** | 24-hour ephemeral photo/video content |
| **Threads** | Long-form connected posts |
| **Polls** | Multi-option polls with expiry |
| **Reposts** | Repost with or without quote |
| **Bookmarks** | Save posts for later |
| **Hashtags & Mentions** | Clickable #tags and @mentions |
| **Trending** | Trending hashtags in Explore |
| **Pin Post** | Pin one post to your profile |
| **Visibility** | Everyone / Followers / Mutuals / Only Me |

### Social Graph
| Feature | Details |
|---|---|
| **Follow / Unfollow** | Follow friends and creators |
| **Private Accounts** | Send follow requests |
| **Suggestions** | Discover new people |
| **Followers / Following lists** | Browse social connections |

### Chat & Messaging
| Feature | Details |
|---|---|
| **Real-time DMs** | Supabase real-time subscriptions |
| **Group Chats** | Named groups with avatars |
| **Media Sharing** | Images, videos, audio, GIFs, files |
| **Voice Messages** | Record and send audio |
| **Message Reactions** | React with emojis |
| **Reply to message** | Threaded replies |
| **Typing indicators** | Live typing status |
| **Read receipts** | Delivered / Read ticks |
| **Delete messages** | Delete for everyone |
| **Share posts** | Share a post into chat |
| **Stickers & GIFs** | Rich media messages |

### Notifications
| Feature | Details |
|---|---|
| **Like, comment, follow, mention** | All standard notifs |
| **Repost, reply, poll vote** | Full activity coverage |
| **Verified badge granted** | Special admin notification |
| **Story views** | Who viewed your story |
| **Live alerts** | Notify when someone goes live |
| **Push notifications** | FCM via Supabase Edge Functions |

### Explore / Discover
| Feature | Details |
|---|---|
| **Search users** | Name and username search |
| **Search posts** | Full-text post search |
| **Search hashtags** | Find trending topics |
| **Trending tab** | Hot topics in last 24h |
| **Curated grid** | Instagram-style media grid |
| **Suggested users** | Algorithm-sorted recommendations |

### Profile
| Feature | Details |
|---|---|
| **Cover photo** | Wide cover image |
| **Avatar** | Profile picture |
| **Bio, website, location** | Full profile info |
| **Post / Reel / Like tabs** | Profile content tabs |
| **Stats** | Followers, Following, Posts count |
| **Edit profile** | Full profile editor |
| **Private account toggle** | |

### 🛡️ Admin Features (CONFIDENTIAL)
| Feature | Details |
|---|---|
| **Admin login** | Via hidden entry point (tap bottom of login 5×) |
| **Blue tick** | Admins have gold verified badge |
| **Grant blue tick** | Admins can verify any user |
| **Revoke blue tick** | Admins can remove verification |
| **Ban users** | Suspend accounts |
| **Delete any post** | Content moderation |
| **Platform announcements** | System messages to all users |
| **Admin dashboard** | Stats, user management, reports |
| **Admin signup** | Separate hidden admin registration |

### 🆕 Unique Features (Beyond Twitter/Instagram)
| Feature | Details |
|---|---|
| **Dark / Light mode** | Full system-aware theming |
| **Double-tap to like** | Instagram-style heart animation |
| **Post visibility control** | Granular audience settings |
| **Polls with expiry** | Time-limited community polls |
| **Thread chains** | Nested conversation threads |
| **Audio posts** | Voice-only content |
| **Group video calls** | (Planned via WebRTC) |
| **Spaces / Live audio** | Twitter Spaces equivalent |
| **Location tagging** | Tag location on posts |
| **Skeleton loading** | Smooth shimmer placeholders |
| **Haptic feedback** | Subtle tactile interactions |
| **Infinite scroll** | Pagination on all lists |
| **Pull-to-refresh** | Every list/feed |
| **Post editing** | Edit posts after publishing |

---

## 🗄️ Backend: Supabase (Free)

**Why Supabase?**
- ✅ Free tier: 500MB database, 1GB storage, 50,000 MAU
- ✅ PostgreSQL — relational, powerful, SQL-native
- ✅ Built-in real-time subscriptions (perfect for chat)
- ✅ Auth (email/password + social OAuth)
- ✅ Row-Level Security (fine-grained access control)
- ✅ Official Flutter SDK
- ✅ Auto-generated REST & GraphQL APIs
- ✅ File storage for media

### Free Tier Limits
| Resource | Limit |
|---|---|
| Database | 500 MB |
| Storage | 1 GB |
| Monthly Active Users | 50,000 |
| Bandwidth | 5 GB/month |
| Edge Functions | 500,000 invocations |
| Real-time connections | 200 concurrent |

---

## 🚀 Setup Guide

### Step 1: Create Supabase Project
1. Sign up free at [supabase.com](https://supabase.com)
2. Create a new project
3. Go to **Settings → API** and copy:
   - Project URL
   - anon/public key

### Step 2: Configure the App
Open `lib/utils/constants.dart` and replace:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### Step 3: Run the Database Schema
1. In Supabase Dashboard → **SQL Editor**
2. Paste the entire contents of `supabase_schema.sql`
3. Click **Run**

### Step 4: Create Storage Buckets
In Supabase Dashboard → **Storage → New bucket**, create:
- `avatars` (public)
- `posts` (public)
- `reels` (public)
- `stories` (public)
- `chat_media` (private)

### Step 5: Install Flutter Dependencies
```bash
cd nexus_app
flutter pub get
```

### Step 6: Run the App
```bash
# Android
flutter run

# iOS
flutter run --device-id <ios-device-id>

# Debug with verbose
flutter run -v
```

---

## 🔐 Admin Access (CONFIDENTIAL)

> ⚠️ This section is known only to you and the developer.

**How to access admin login:**
1. Open the app to the Login screen
2. Tap the **empty area at the bottom** of the screen **5 times quickly**
3. The hidden Admin Auth screen will appear

**Admin credentials:**
- Admin Username: `arshadwahib99`
- Admin Secret: `arshadwahib99`

**Admin capabilities:**
- Grant/revoke blue verified badges to any user
- Access Admin Dashboard (`/admin` route)
- Ban/suspend user accounts
- Delete any post
- Post platform-wide announcements
- Admin accounts automatically receive gold verified badge ✓

---

## 📁 Project Structure

```
nexus_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── theme/
│   │   └── app_theme.dart           # Light/dark theme system
│   ├── utils/
│   │   └── constants.dart           # App config + admin credentials
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── post_model.dart
│   │   ├── message_model.dart
│   │   └── notification_model.dart
│   ├── services/
│   │   ├── auth_service.dart        # Auth + admin auth
│   │   ├── post_service.dart        # Posts CRUD + feed
│   │   ├── chat_service.dart        # Real-time messaging
│   │   └── follow_service.dart      # Follow/unfollow
│   ├── providers/
│   │   ├── auth_provider.dart       # Auth state
│   │   ├── theme_provider.dart      # Theme mode
│   │   ├── feed_provider.dart       # Feed state
│   │   ├── chat_provider.dart       # Chat state
│   │   └── notification_provider.dart
│   ├── router/
│   │   └── app_router.dart          # GoRouter navigation
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   └── admin_auth_screen.dart  ← HIDDEN
│   │   ├── home/
│   │   │   ├── main_shell.dart      # Bottom nav
│   │   │   ├── post_card.dart       # Feed post widget
│   │   │   ├── story_bar.dart
│   │   │   ├── post_detail_screen.dart
│   │   │   └── create_post_screen.dart
│   │   ├── feed/
│   │   │   └── feed_screen.dart
│   │   ├── explore/
│   │   │   └── explore_screen.dart
│   │   ├── reels/
│   │   │   └── reels_screen.dart
│   │   ├── chat/
│   │   │   ├── conversations_screen.dart
│   │   │   └── chat_screen.dart
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   └── edit_profile_screen.dart
│   │   ├── notifications/
│   │   │   └── notifications_screen.dart
│   │   └── admin/
│   │       └── admin_dashboard_screen.dart
│   └── widgets/
│       ├── nexus_logo.dart
│       ├── nexus_text_field.dart
│       ├── nexus_button.dart
│       ├── verified_badge.dart
│       └── user_avatar.dart
├── supabase_schema.sql              # Full database schema
└── pubspec.yaml                     # Dependencies
```

---

## 🎨 Design System

- **Palette:** Pure black (#000000) / Pure white (#FFFFFF)
- **Accent:** Twitter blue (#1D9BF0)
- **Admin badge:** Gold (#FFD700)
- **Verified tick:** Blue for users, Gold for admins
- **Fonts:** SF Pro Display / SF Pro Text (system)
- **Corner radius:** 12–24px throughout
- **Animations:** Flutter Animate, custom transitions

---

## 📦 Key Dependencies

| Package | Use |
|---|---|
| `supabase_flutter` | Backend (DB, Auth, Storage, Real-time) |
| `provider` | State management |
| `go_router` | Navigation |
| `cached_network_image` | Image caching |
| `video_player` + `chewie` | Video playback |
| `image_picker` | Camera/gallery |
| `flutter_animate` | Animations |
| `timeago` | Relative timestamps |
| `crypto` | Admin password hashing |
| `shared_preferences` | Local settings |
| `flutter_secure_storage` | Secure token storage |
| `emoji_picker_flutter` | Emoji keyboard |
