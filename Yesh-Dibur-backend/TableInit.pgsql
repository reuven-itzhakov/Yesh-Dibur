-- מחיקת כל הטבלאות והסכמות הקיימות במסד הנתונים לצורך אתחול מחדש
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

-- הפעלת תוסף PostGIS לטובת חישובי מיקום ומרחקים (חובה עבור מנוע החיפוש והפיד)
CREATE EXTENSION IF NOT EXISTS postgis;

-- פונקציה לעדכון אוטומטי של שדה updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

---------------------------------------------------------
-- 1. טבלת משתמשים (Users)
---------------------------------------------------------
CREATE TABLE users (
    id VARCHAR(128) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(50),
    bio TEXT,
    profile_image_url TEXT,
    birth_date DATE,
    location GEOGRAPHY(Point, 4326), 
    interests TEXT[], 
    instagram_url TEXT,
    tiktok_url TEXT,
    settings JSONB, 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE 
);

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

---------------------------------------------------------
-- 2. טבלת חסימות (Blocked Users)
---------------------------------------------------------
CREATE TABLE blocked_users (
    blocker_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    blocked_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (blocker_id, blocked_id)
);

---------------------------------------------------------
-- 3. טבלת קבוצות (Groups)
---------------------------------------------------------
CREATE TABLE groups (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    cover_image_url TEXT,
    image_url TEXT,
    is_private BOOLEAN DEFAULT FALSE,
    interests TEXT[],
    admin_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE TRIGGER update_groups_updated_at BEFORE UPDATE ON groups FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

---------------------------------------------------------
-- 4. טבלת חברי קבוצה (Group Members)
---------------------------------------------------------
CREATE TABLE group_members (
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    user_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, user_id)
);

---------------------------------------------------------
-- 5. טבלת הזמנות לקבוצה (Group Invitations)
---------------------------------------------------------
CREATE TABLE group_invitations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    inviter_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    invitee_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'pending', 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_group_invitations_updated_at BEFORE UPDATE ON group_invitations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

---------------------------------------------------------
-- 6. טבלת פוסטים/שרשורים (Threads)
---------------------------------------------------------
CREATE TABLE threads (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    author_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    content TEXT,
    bg_type VARCHAR(50),
    bg_value TEXT,
    aspect_ratio REAL,
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    moderation_status VARCHAR(50) DEFAULT 'pending', 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE TRIGGER update_threads_updated_at BEFORE UPDATE ON threads FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

---------------------------------------------------------
-- 7. טבלת תגובות לפוסטים (Thread Comments)
---------------------------------------------------------
CREATE TABLE thread_comments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    thread_id UUID REFERENCES threads(id) ON DELETE CASCADE,
    author_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    content TEXT,
    image_url TEXT,
    aspect_ratio REAL,
    moderation_status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE TRIGGER update_thread_comments_updated_at BEFORE UPDATE ON thread_comments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

---------------------------------------------------------
-- 8. טבלת לייקים לפוסטים (Thread Likes)
---------------------------------------------------------
CREATE TABLE thread_likes (
    thread_id UUID REFERENCES threads(id) ON DELETE CASCADE,
    user_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (thread_id, user_id)
);

---------------------------------------------------------
-- 9. טבלת שיחות צ'אט (Conversations)
---------------------------------------------------------
CREATE TABLE conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user1_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    user2_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    last_message_id UUID, 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_conversation UNIQUE (user1_id, user2_id),
    CONSTRAINT user_order CHECK (user1_id < user2_id) 
);

---------------------------------------------------------
-- 10. טבלת הודעות צ'אט (Messages)
---------------------------------------------------------
CREATE TABLE messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    receiver_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    content TEXT,
    image_url TEXT,
    aspect_ratio REAL,
    status VARCHAR(50) DEFAULT 'pending_approval', 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE conversations 
ADD CONSTRAINT fk_last_message 
FOREIGN KEY (last_message_id) REFERENCES messages(id) ON DELETE SET NULL;

---------------------------------------------------------
-- 11. טבלת התראות (Notifications)
---------------------------------------------------------
CREATE TABLE notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    sender_id VARCHAR(128) REFERENCES users(id) ON DELETE SET NULL, 
    type VARCHAR(100) NOT NULL, 
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

---------------------------------------------------------
-- 12. טבלת מכשירים לטובת Push Notifications (Device Tokens)
---------------------------------------------------------
CREATE TABLE device_tokens (
    user_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) NOT NULL,
    fcm_token TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, device_id)
);

---------------------------------------------------------
-- יצירת אינדקסים (Indexes) לשיפור ביצועי שליפה וחיפוש
---------------------------------------------------------
CREATE INDEX idx_users_location ON users USING GIST (location);
CREATE INDEX idx_users_name_bio ON users USING GIN (to_tsvector('simple', COALESCE(name, '') || ' ' || COALESCE(bio, '')));
CREATE INDEX idx_groups_name_desc ON groups USING GIN (to_tsvector('simple', COALESCE(name, '') || ' ' || COALESCE(description, '')));
CREATE INDEX idx_users_interests ON users USING GIN (interests);
CREATE INDEX idx_groups_interests ON groups USING GIN (interests);

CREATE INDEX idx_threads_group_id ON threads(group_id);
CREATE INDEX idx_threads_author_id ON threads(author_id);
CREATE INDEX idx_threads_created_at ON threads(created_at DESC);
CREATE INDEX idx_thread_comments_thread_id ON thread_comments(thread_id);
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_conversations_updated_at ON conversations(updated_at DESC);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id) WHERE is_read = FALSE;