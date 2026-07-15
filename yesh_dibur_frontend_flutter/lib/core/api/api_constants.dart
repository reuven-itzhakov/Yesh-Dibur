class ApiConstants {
  static const String apiVersion = '/api/v1';

  // משתמשים
  static const String register = '$apiVersion/users/register';
  static const String profile = '$apiVersion/users/profile';
  static const String deviceToken = '$apiVersion/users/device';

  // פיד
  static const String discoveryFeed = '$apiVersion/feed/discovery';
  static const String myGroupsFeed = '$apiVersion/feed/my-groups';

  // חיפוש
  static const String search = '$apiVersion/search';

  // קבוצות ופוסטים
  static const String groups = '$apiVersion/groups';
  static const String threads = '$apiVersion/threads';

  // צ'אט
  static const String chats = '$apiVersion/chats';
}