import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyClubName = 'club_name';
  static const _keyComment = 'comment';
  static const _keyFrameIndex = 'frame_index';

  static Future<String> loadClubName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyClubName) ?? '';
  }

  static Future<void> saveClubName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyClubName, value);
  }

  static Future<String> loadComment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyComment) ?? '';
  }

  static Future<void> saveComment(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyComment, value);
  }

  static Future<int> loadFrameIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyFrameIndex) ?? 0;
  }

  static Future<void> saveFrameIndex(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFrameIndex, value);
  }
}
