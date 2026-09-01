import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyClubName = 'club_name';
  static const _keyComment = 'comment';
  static const _keyFrameIndex = 'frame_index';
  static const _keyClubNameHistory = 'club_name_history';
  static const _keyCommentHistory = 'comment_history';
  static const _maxHistoryEntries = 20;

  static Future<String> loadClubName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyClubName) ?? '';
  }

  static Future<void> saveClubName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyClubName, value);
    if (value.trim().isNotEmpty) {
      await _addToHistory(prefs, _keyClubNameHistory, value);
    }
  }

  static Future<List<String>> loadClubNameHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyClubNameHistory) ?? [];
  }

  static Future<void> removeClubNameFromHistory(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_keyClubNameHistory) ?? [];
    history.remove(value);
    await prefs.setStringList(_keyClubNameHistory, history);
  }

  static Future<String> loadComment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyComment) ?? '';
  }

  static Future<void> saveComment(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyComment, value);
    if (value.trim().isNotEmpty) {
      await _addToHistory(prefs, _keyCommentHistory, value);
    }
  }

  static Future<List<String>> loadCommentHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyCommentHistory) ?? [];
  }

  static Future<void> removeCommentFromHistory(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_keyCommentHistory) ?? [];
    history.remove(value);
    await prefs.setStringList(_keyCommentHistory, history);
  }

  static Future<void> _addToHistory(
      SharedPreferences prefs, String key, String value) async {
    final history = prefs.getStringList(key) ?? [];
    history.remove(value);
    history.insert(0, value);
    if (history.length > _maxHistoryEntries) {
      history.removeRange(_maxHistoryEntries, history.length);
    }
    await prefs.setStringList(key, history);
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
