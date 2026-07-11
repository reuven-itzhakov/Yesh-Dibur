-- ריקון כל התוכן מכל הטבלאות ואיפוס המזהים האוטומטיים במידה וישנם
TRUNCATE TABLE 
    device_tokens,
    notifications,
    messages,
    conversations,
    thread_likes,
    thread_comments,
    threads,
    group_invitations,
    group_members,
    groups,
    blocked_users,
    users
RESTART IDENTITY CASCADE;