import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressService extends ChangeNotifier {
  static final ProgressService instance = ProgressService._internal();
  ProgressService._internal();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  int _unlockedLevel = 1;
  int get unlockedLevel => _unlockedLevel;

  final Map<int, int> _levelStars = {};
  final Map<int, int> _levelHighScores = {};
  int _totalScore = 0;
  int get totalScore => _totalScore;

  // Coins economy
  int _coins = 150;
  int get coins => _coins;

  // Boosters Inventory
  int _bombBoosters = 3;
  int get bombBoosters => _bombBoosters;

  int _rainbowBoosters = 2;
  int get rainbowBoosters => _rainbowBoosters;

  int _fireballBoosters = 2;
  int get fireballBoosters => _fireballBoosters;

  // Audio & Haptics
  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  // Achievements
  final Set<String> _unlockedAchievements = {};
  Set<String> get unlockedAchievements => _unlockedAchievements;
  void Function(String title, String desc)? onAchievementUnlocked;

  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();

    _unlockedLevel = _prefs.getInt('unlocked_level') ?? 1;
    _soundEnabled = _prefs.getBool('sound_enabled') ?? true;
    _totalScore = _prefs.getInt('total_score') ?? 0;
    _coins = _prefs.getInt('player_coins') ?? 150;

    // Load boosters
    _bombBoosters = _prefs.getInt('booster_bombs') ?? 3;
    _rainbowBoosters = _prefs.getInt('booster_rainbows') ?? 2;
    _fireballBoosters = _prefs.getInt('booster_fireballs') ?? 2;

    // Load achievements
    final achList = _prefs.getStringList('unlocked_achievements') ?? [];
    _unlockedAchievements.addAll(achList);

    // Load stars and high scores for saved levels
    for (int i = 1; i <= max(50, _unlockedLevel + 20); i++) {
      final stars = _prefs.getInt('level_${i}_stars');
      if (stars != null) _levelStars[i] = stars;

      final highScore = _prefs.getInt('level_${i}_high_score');
      if (highScore != null) _levelHighScores[i] = highScore;
    }

    _isInitialized = true;
    notifyListeners();
  }

  int getStarsForLevel(int level) => _levelStars[level] ?? 0;

  int getHighScoreForLevel(int level) => _levelHighScores[level] ?? 0;

  bool isLevelUnlocked(int level) => level <= _unlockedLevel;

  int getTotalStars() {
    return _levelStars.values.fold(0, (sum, stars) => sum + stars);
  }

  // --- Coins Management ---
  void addCoins(int amount) {
    _coins += amount;
    _prefs.setInt('player_coins', _coins);
    notifyListeners();
  }

  bool spendCoins(int amount) {
    if (_coins >= amount) {
      _coins -= amount;
      _prefs.setInt('player_coins', _coins);
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- Booster Usage ---
  bool useBombBooster() {
    if (_bombBoosters > 0) {
      _bombBoosters--;
      _prefs.setInt('booster_bombs', _bombBoosters);
      hapticMedium();
      unlockAchievement('first_booster', 'Power Player!', 'Used your first booster');
      notifyListeners();
      return true;
    }
    return false;
  }

  bool useRainbowBooster() {
    if (_rainbowBoosters > 0) {
      _rainbowBoosters--;
      _prefs.setInt('booster_rainbows', _rainbowBoosters);
      hapticMedium();
      unlockAchievement('first_booster', 'Power Player!', 'Used your first booster');
      notifyListeners();
      return true;
    }
    return false;
  }

  bool useFireballBooster() {
    if (_fireballBoosters > 0) {
      _fireballBoosters--;
      _prefs.setInt('booster_fireballs', _fireballBoosters);
      hapticHeavy();
      unlockAchievement('firestarter', 'Firestarter!', 'Launched a scorching fireball');
      notifyListeners();
      return true;
    }
    return false;
  }

  void addBooster(String type, int count) {
    if (type == 'bomb') {
      _bombBoosters += count;
      _prefs.setInt('booster_bombs', _bombBoosters);
    } else if (type == 'rainbow') {
      _rainbowBoosters += count;
      _prefs.setInt('booster_rainbows', _rainbowBoosters);
    } else if (type == 'fireball') {
      _fireballBoosters += count;
      _prefs.setInt('booster_fireballs', _fireballBoosters);
    }
    notifyListeners();
  }

  // --- Haptics & Feedback ---
  void hapticLight() {
    if (!_soundEnabled) return;
    HapticFeedback.lightImpact();
  }

  void hapticMedium() {
    if (!_soundEnabled) return;
    HapticFeedback.mediumImpact();
  }

  void hapticHeavy() {
    if (!_soundEnabled) return;
    HapticFeedback.heavyImpact();
  }

  void hapticSuccess() {
    if (!_soundEnabled) return;
    HapticFeedback.vibrate();
  }

  void hapticFever() {
    if (!_soundEnabled) return;
    HapticFeedback.heavyImpact();
  }

  // --- Achievements ---
  bool unlockAchievement(String id, String title, String desc) {
    if (!_unlockedAchievements.contains(id)) {
      _unlockedAchievements.add(id);
      _prefs.setStringList('unlocked_achievements', _unlockedAchievements.toList());
      // Bonus coins for every achievement!
      addCoins(50);
      onAchievementUnlocked?.call(title, desc);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> completeLevel(int level, int score, int stars) async {
    final currentStars = _levelStars[level] ?? 0;
    if (stars > currentStars) {
      _levelStars[level] = stars;
      await _prefs.setInt('level_${level}_stars', stars);
    }

    final currentHighScore = _levelHighScores[level] ?? 0;
    if (score > currentHighScore) {
      _levelHighScores[level] = score;
      await _prefs.setInt('level_${level}_high_score', score);
    }

    // Award Coins: 50 base + 20 per star
    final earnedCoins = 50 + (stars * 20);
    addCoins(earnedCoins);

    // Unlock next level (Endless progression!)
    if (level >= _unlockedLevel) {
      _unlockedLevel = level + 1;
      await _prefs.setInt('unlocked_level', _unlockedLevel);

      // Reward a booster every level!
      if (level % 3 == 0) {
        _fireballBoosters += 1;
        await _prefs.setInt('booster_fireballs', _fireballBoosters);
      } else if (level % 2 == 0) {
        _bombBoosters += 1;
        await _prefs.setInt('booster_bombs', _bombBoosters);
      } else {
        _rainbowBoosters += 1;
        await _prefs.setInt('booster_rainbows', _rainbowBoosters);
      }
    }

    if (stars == 3) {
      unlockAchievement('three_stars', 'Perfectionist!', 'Earned 3 stars on a level');
    }

    _totalScore += score;
    await _prefs.setInt('total_score', _totalScore);

    hapticSuccess();
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await _prefs.setBool('sound_enabled', _soundEnabled);
    notifyListeners();
  }

  Future<void> resetProgress() async {
    await _prefs.clear();
    _unlockedLevel = 1;
    _levelStars.clear();
    _levelHighScores.clear();
    _totalScore = 0;
    _coins = 150;
    _bombBoosters = 3;
    _rainbowBoosters = 2;
    _fireballBoosters = 2;
    _unlockedAchievements.clear();
    _soundEnabled = true;
    notifyListeners();
  }
}
