class ApiConstants {
  static const String apiVersion = '/api/v1';

  // משתמשים
  static const String register = '$apiVersion/users/register';
  static const String profile = '$apiVersion/users/profile';
  static const String deviceToken = '$apiVersion/users/device';
  static const String userGroups = '$apiVersion/users/groups';

  // פיד
  static const String discoveryFeed = '$apiVersion/feeds/discovery';
  static const String myGroupsFeed = '$apiVersion/feeds/my-groups';

  // חיפוש
  static const String search = '$apiVersion/search';

  // קבוצות ופוסטים
  static const String groups = '$apiVersion/groups';
  static const String threads = '$apiVersion/threads';

  // צ'אט
  static const String chats = '$apiVersion/chats';
}