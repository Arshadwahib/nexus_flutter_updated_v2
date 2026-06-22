-- ═══════════════════════════════════════════════════════════════════════
-- NEXUS APP — Supabase Database Schema
-- Run this in your Supabase SQL Editor at https://supabase.com
-- Free tier includes: 500MB DB, 1GB storage, 50,000 MAU
-- ═══════════════════════════════════════════════════════════════════════

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For full-text search

-- ─────────────────────────────────────────────────────────────────────
-- PROFILES (extends Supabase Auth users)
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id             UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email          TEXT NOT NULL,
  username       TEXT UNIQUE NOT NULL,
  display_name   TEXT NOT NULL,
  avatar_url     TEXT,
  cover_image_url TEXT,
  bio            TEXT,
  website        TEXT,
  location       TEXT,
  is_verified    BOOLEAN DEFAULT FALSE,
  is_admin       BOOLEAN DEFAULT FALSE,
  role           TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  followers_count INT DEFAULT 0,
  following_count INT DEFAULT 0,
  posts_count    INT DEFAULT 0,
  is_private     BOOLEAN DEFAULT FALSE,
  is_active      BOOLEAN DEFAULT TRUE,
  interests      TEXT[] DEFAULT '{}',
  notifications_enabled BOOLEAN DEFAULT TRUE,
  push_token     TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast username lookup
CREATE INDEX idx_profiles_username ON profiles USING GIN (username gin_trgm_ops);
CREATE INDEX idx_profiles_display_name ON profiles USING GIN (display_name gin_trgm_ops);

-- ─────────────────────────────────────────────────────────────────────
-- POSTS
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS posts (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type           TEXT NOT NULL CHECK (type IN ('text','image','video','reel','story','poll','thread','audio')),
  text           TEXT,
  media          JSONB DEFAULT '[]',
  poll_options   JSONB,
  poll_expires_at TIMESTAMPTZ,
  visibility     TEXT DEFAULT 'everyone' CHECK (visibility IN ('everyone','followers','mutuals','onlyMe')),
  reply_to_id    UUID REFERENCES posts(id) ON DELETE SET NULL,
  thread_id      UUID REFERENCES posts(id) ON DELETE SET NULL,
  repost_of_id   UUID REFERENCES posts(id) ON DELETE SET NULL,
  hashtags       TEXT[] DEFAULT '{}',
  mentions       TEXT[] DEFAULT '{}',
  location       TEXT,
  metadata       JSONB,
  likes_count    INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  reposts_count  INT DEFAULT 0,
  views_count    INT DEFAULT 0,
  shares_count   INT DEFAULT 0,
  bookmarks_count INT DEFAULT 0,
  is_pinned      BOOLEAN DEFAULT FALSE,
  is_edited      BOOLEAN DEFAULT FALSE,
  is_deleted     BOOLEAN DEFAULT FALSE,
  expires_at     TIMESTAMPTZ,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  edited_at      TIMESTAMPTZ,
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_posts_author ON posts(author_id);
CREATE INDEX idx_posts_type ON posts(type);
CREATE INDEX idx_posts_created ON posts(created_at DESC);
CREATE INDEX idx_posts_hashtags ON posts USING GIN (hashtags);
CREATE INDEX idx_posts_text ON posts USING GIN (text gin_trgm_ops);

-- ─────────────────────────────────────────────────────────────────────
-- LIKES
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS post_likes (
  id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id  UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);
CREATE INDEX idx_likes_post ON post_likes(post_id);
CREATE INDEX idx_likes_user ON post_likes(user_id);

-- ─────────────────────────────────────────────────────────────────────
-- REPOSTS
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS post_reposts (
  id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id  UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- ─────────────────────────────────────────────────────────────────────
-- BOOKMARKS
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS post_bookmarks (
  id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id  UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- ─────────────────────────────────────────────────────────────────────
-- FOLLOWS
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS follows (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  follower_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);
CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);

-- ─────────────────────────────────────────────────────────────────────
-- FOLLOW REQUESTS (for private accounts)
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS follow_requests (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status       TEXT DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected')),
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(requester_id, target_id)
);

-- ─────────────────────────────────────────────────────────────────────
-- NOTIFICATIONS
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type             TEXT NOT NULL,
  actor_id         UUID REFERENCES profiles(id) ON DELETE CASCADE,
  post_id          UUID REFERENCES posts(id) ON DELETE CASCADE,
  post_preview_url TEXT,
  comment_text     TEXT,
  message          TEXT DEFAULT '',
  is_read          BOOLEAN DEFAULT FALSE,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);

-- ─────────────────────────────────────────────────────────────────────
-- CONVERSATIONS
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS conversations (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  is_group         BOOLEAN DEFAULT FALSE,
  group_name       TEXT,
  group_avatar_url TEXT,
  participant_ids  UUID[] NOT NULL,
  created_by       UUID REFERENCES profiles(id),
  is_archived      BOOLEAN DEFAULT FALSE,
  is_muted         BOOLEAN DEFAULT FALSE,
  metadata         JSONB,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_conversations_participants ON conversations USING GIN (participant_ids);

-- ─────────────────────────────────────────────────────────────────────
-- CONVERSATION PARTICIPANTS
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS conversation_participants (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  is_admin        BOOLEAN DEFAULT FALSE,
  joined_at       TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(conversation_id, user_id)
);

-- ─────────────────────────────────────────────────────────────────────
-- MESSAGES
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
  id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id      UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id            UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type                 TEXT DEFAULT 'text' CHECK (type IN ('text','image','video','audio','gif','sticker','post','story','location','deleted')),
  text                 TEXT,
  media_url            TEXT,
  media_thumbnail_url  TEXT,
  media_aspect_ratio   FLOAT,
  reply_to_id          UUID REFERENCES messages(id) ON DELETE SET NULL,
  shared_post_id       UUID REFERENCES posts(id) ON DELETE SET NULL,
  metadata             JSONB,
  status               TEXT DEFAULT 'sent' CHECK (status IN ('sending','sent','delivered','read','failed')),
  reactions            JSONB DEFAULT '{}',
  is_edited            BOOLEAN DEFAULT FALSE,
  created_at           TIMESTAMPTZ DEFAULT NOW(),
  edited_at            TIMESTAMPTZ,
  deleted_at           TIMESTAMPTZ
);
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at ASC);

-- ─────────────────────────────────────────────────────────────────────
-- TYPING INDICATORS
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS typing_indicators (
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  is_typing       BOOLEAN DEFAULT FALSE,
  updated_at      TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (conversation_id, user_id)
);

-- ─────────────────────────────────────────────────────────────────────
-- COMMENTS (nested, linked to posts)
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS comments (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id     UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  author_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  text        TEXT NOT NULL,
  parent_id   UUID REFERENCES comments(id) ON DELETE CASCADE,
  likes_count INT DEFAULT 0,
  is_deleted  BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_comments_post ON comments(post_id, created_at);

-- ─────────────────────────────────────────────────────────────────────
-- HASHTAG TRENDING (materialized view)
-- ─────────────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW trending_hashtags AS
SELECT
  unnest(hashtags) AS tag,
  COUNT(*) AS post_count
FROM posts
WHERE created_at > NOW() - INTERVAL '24 hours'
  AND is_deleted = FALSE
GROUP BY tag
ORDER BY post_count DESC
LIMIT 30;

-- ─────────────────────────────────────────────────────────────────────
-- STORAGE BUCKETS
-- ─────────────────────────────────────────────────────────────────────
-- Run these in Supabase Dashboard > Storage > New bucket
-- Or via API:
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('posts', 'posts', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('reels', 'reels', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('stories', 'stories', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('chat_media', 'chat_media', false);

-- ─────────────────────────────────────────────────────────────────────
-- RPC HELPER FUNCTIONS
-- ─────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION increment_posts_count(user_id UUID)
RETURNS VOID AS $$
  UPDATE profiles SET posts_count = posts_count + 1 WHERE id = user_id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION increment_likes_count(post_id UUID)
RETURNS VOID AS $$
  UPDATE posts SET likes_count = likes_count + 1 WHERE id = post_id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION decrement_likes_count(post_id UUID)
RETURNS VOID AS $$
  UPDATE posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = post_id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION increment_reposts_count(post_id UUID)
RETURNS VOID AS $$
  UPDATE posts SET reposts_count = reposts_count + 1 WHERE id = post_id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION decrement_reposts_count(post_id UUID)
RETURNS VOID AS $$
  UPDATE posts SET reposts_count = GREATEST(reposts_count - 1, 0) WHERE id = post_id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION increment_followers_count(user_id UUID)
RETURNS VOID AS $$
  UPDATE profiles SET followers_count = followers_count + 1 WHERE id = user_id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION decrement_followers_count(user_id UUID)
RETURNS VOID AS $$
  UPDATE profiles SET followers_count = GREATEST(followers_count - 1, 0) WHERE id = user_id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION increment_following_count(user_id UUID)
RETURNS VOID AS $$
  UPDATE profiles SET following_count = following_count + 1 WHERE id = user_id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION decrement_following_count(user_id UUID)
RETURNS VOID AS $$
  UPDATE profiles SET following_count = GREATEST(following_count - 1, 0) WHERE id = user_id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_trending_hashtags()
RETURNS TABLE(tag TEXT, post_count BIGINT) AS $$
  SELECT tag, COUNT(*) as post_count
  FROM posts, unnest(hashtags) as tag
  WHERE created_at > NOW() - INTERVAL '24 hours' AND is_deleted = FALSE
  GROUP BY tag
  ORDER BY post_count DESC
  LIMIT 20;
$$ LANGUAGE SQL;

-- ─────────────────────────────────────────────────────────────────────
-- ROW LEVEL SECURITY (RLS)
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_reposts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Profiles: anyone can read active profiles
CREATE POLICY "public_profiles" ON profiles FOR SELECT USING (is_active = TRUE);
CREATE POLICY "own_profile_update" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Posts: anyone can read public posts
CREATE POLICY "read_public_posts" ON posts FOR SELECT
  USING (visibility = 'everyone' AND is_deleted = FALSE);
CREATE POLICY "insert_own_posts" ON posts FOR INSERT
  WITH CHECK (auth.uid() = author_id);
CREATE POLICY "update_own_posts" ON posts FOR UPDATE
  USING (auth.uid() = author_id);

-- Likes: authenticated users
CREATE POLICY "manage_likes" ON post_likes FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "read_likes" ON post_likes FOR SELECT USING (TRUE);

-- Notifications: own only
CREATE POLICY "own_notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);

-- Conversations: participants only
CREATE POLICY "participant_conversations" ON conversations FOR ALL
  USING (auth.uid() = ANY(participant_ids));

-- Messages: conversation participants
CREATE POLICY "participant_messages" ON messages FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = conversation_id AND auth.uid() = ANY(c.participant_ids)
    )
  );

-- ─────────────────────────────────────────────────────────────────────
-- REAL-TIME SUBSCRIPTIONS
-- Enable for live chat and notifications
-- ─────────────────────────────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE typing_indicators;
ALTER PUBLICATION supabase_realtime ADD TABLE posts;

-- ─────────────────────────────────────────────────────────────────────
-- TRIGGER: Auto-update updated_at
-- ─────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at_profiles
  BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_posts
  BEFORE UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_conversations
  BEFORE UPDATE ON conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─────────────────────────────────────────────────────────────────────
-- TRIGGER: Auto-create profile on user signup
-- ─────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, username, display_name, is_admin, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'is_admin')::BOOLEAN, FALSE),
    COALESCE(NEW.raw_user_meta_data->>'role', 'user')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();
