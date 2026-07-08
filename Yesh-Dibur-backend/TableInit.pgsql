-- 1. הפעלת הרחבת PostGIS עבור חיפושים מרחביים (מיקום ורדיוס)
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. יצירת טיפוסי נתונים (Enums) לסטטוסים וסוגים מוגדרים מראש
CREATE TYPE notification_type AS ENUM ('like', 'comment', 'message', 'group_invite');
CREATE TYPE invitation_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE background_type AS ENUM ('image', 'color');
CREATE TYPE moderation_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE message_status AS ENUM ('pending_approval', 'approved', 'read');
CREATE TYPE report_status AS ENUM ('pending', 'reviewed', 'resolved');
CREATE TYPE report_target_type AS ENUM ('user', 'thread', 'comment');

-- 3. יצירת טבלאות

-- טבלת משתמשים (Users)
CREATE TABLE users (
    id VARCHAR(128) PRIMARY KEY, -- מזהה ייחודי מ-Firebase
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),          -- נוסף מהשינוי
    phone VARCHAR(50),           -- נוסף מהשינוי
    birth_date DATE NOT NULL,
    location GEOMETRY(Point, 4326), -- קואורדינטות בפורמט PostGIS
    interests TEXT[],
    bio TEXT,
    instagram_url VARCHAR(255),
    tiktok_url VARCHAR(255),
    profile_image_url TEXT,
    settings JSONB DEFAULT '{}'::jsonb,
    deleted_at TIMESTAMP, -- למחיקה רכה
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- טבלת ניהול מכשירים והתראות (Device_Tokens)
CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) NOT NULL,
    fcm_token TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, device_id)
);

-- טבלת התראות פנים (Notifications)
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE, -- המקבל
    type notification_type NOT NULL,
    sender_id VARCHAR(128) REFERENCES users(id) ON DELETE SET NULL, -- השולח
    content TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- טבלת קבוצות (Groups)
CREATE TABLE groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    cover_image_url TEXT,
    interests TEXT[],
    admin_id VARCHAR(128) REFERENCES users(id) ON DELETE RESTRICT,
    is_private BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- טבלת חברי קבוצה (Group_Members) - טבלת גישור
CREATE TABLE group_members (
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    user_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, user_id)
);

-- טבלת הזמנות לקבוצות (Group_Invitations)
CREATE TABLE group_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inviter_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    invitee_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    status invitation_status DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- טבלת פוסטים ודיונים (Threads)
CREATE TABLE threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    author_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    bg_type background_type NOT NULL,
    bg_value TEXT NOT NULL,
    aspect_ratio NUMERIC(5,2),
    moderation_status moderation_status DEFAULT 'pending',
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    deleted_at TIMESTAMP, -- מחיקה רכה
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- טבלת תגובות לפוסטים (Thread_Comments)
CREATE TABLE thread_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID REFERENCES threads(id) ON DELETE CASCADE,
    author_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_url TEXT,
    aspect_ratio NUMERIC(5,2),
    moderation_status moderation_status DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- טבלת מעקב לייקים (Thread_Likes) - טבלת גישור
CREATE TABLE thread_likes (
    thread_id UUID REFERENCES threads(id) ON DELETE CASCADE,
    user_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (thread_id, user_id)
);

-- טבלת תיבות שיחה (Conversations)
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    user2_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    last_message_id UUID, -- המפתח הזר יוגדר בסוף עקב התלות המעגלית
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user1_id, user2_id)
);

-- טבלת הודעות פרטיות (Messages)
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    receiver_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_url TEXT,
    aspect_ratio NUMERIC(5,2),
    status message_status DEFAULT 'pending_approval',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- הוספת המפתח הזר של last_message_id לטבלת Conversations
ALTER TABLE conversations 
ADD CONSTRAINT fk_last_message 
FOREIGN KEY (last_message_id) REFERENCES messages(id) ON DELETE SET NULL;

-- טבלת דיווחי משתמשים (Reports)
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id VARCHAR(128) REFERENCES users(id) ON DELETE SET NULL,
    reported_content_id VARCHAR(255) NOT NULL, -- יכול להכיל ID של משתמש, פוסט או תגובה
    reported_type report_target_type NOT NULL,
    reason TEXT NOT NULL,
    status report_status DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- טבלת משתמשים חסומים (Blocked_Users)
CREATE TABLE blocked_users (
    blocker_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    blocked_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (blocker_id, blocked_id)
);

-- 4. יצירת אינדקסים לביצועים ואופטימיזציה

-- אינדקסים מרחביים (PostGIS Spatial Index) לחיפושי רדיוס מהירים
CREATE INDEX idx_users_location ON users USING GIST (location);

-- אינדקסים של חיפוש טקסט מלא (Full-Text Search) ואינדקסי GIN על מערכים
-- אינדקס על מערכי תחומי העניין
CREATE INDEX idx_users_interests ON users USING GIN (interests);
CREATE INDEX idx_groups_interests ON groups USING GIN (interests);

-- אינדקס חיפוש טקסטואלי על שמות (משתמשים וקבוצות)
CREATE INDEX idx_users_name_fts ON users USING GIN (to_tsvector('simple', name));
CREATE INDEX idx_groups_name_fts ON groups USING GIN (to_tsvector('simple', name));

-- אינדקסים רגילים על תאריכים ומונים לשליפה מהירה
CREATE INDEX idx_threads_created_at ON threads (created_at DESC);
CREATE INDEX idx_threads_likes_count ON threads (likes_count DESC);
CREATE INDEX idx_threads_comments_count ON threads (comments_count DESC);
CREATE INDEX idx_thread_comments_created_at ON thread_comments (created_at ASC);
CREATE INDEX idx_conversations_updated_at ON conversations (updated_at DESC);
CREATE INDEX idx_messages_created_at ON messages (created_at ASC);