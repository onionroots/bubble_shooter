import 'package:flutter/material.dart';

enum BubbleType {
  red,     // Strawberry / Cherry
  blue,    // Blue Raspberry / Sky Bubble
  green,   // Green Apple / Lime Jelly
  yellow,  // Lemon Drops / Sunny Honey
  purple,  // Grape Candy / Magic Berry
  orange,  // Sweet Tangerine / Orange Drop
  pink,    // Bubblegum / Cotton Candy
  cyan,    // Mint Freeze / Ice Crystal
  bomb,    // Cute Dynamite / Star Bomb
  rainbow, // Magical Rainbow Candy
  fireball,// Blazing Meteor Fireball
}

class BubbleColorData {
  final BubbleType type;
  final String name;
  final Color baseColor;
  final Color highlightColor;
  final Color shadowColor;
  final Color glowColor;
  final IconData? icon;

  const BubbleColorData({
    required this.type,
    required this.name,
    required this.baseColor,
    required this.highlightColor,
    required this.shadowColor,
    required this.glowColor,
    this.icon,
  });

  static const Map<BubbleType, BubbleColorData> data = {
    BubbleType.red: BubbleColorData(
      type: BubbleType.red,
      name: 'Strawberry',
      baseColor: Color(0xFFFF2E63),
      highlightColor: Color(0xFFFF8DA1),
      shadowColor: Color(0xFFC70039),
      glowColor: Color(0xFFFF5277),
    ),
    BubbleType.blue: BubbleColorData(
      type: BubbleType.blue,
      name: 'Blueberry',
      baseColor: Color(0xFF2292F9),
      highlightColor: Color(0xFF8FD3FE),
      shadowColor: Color(0xFF0D5CB6),
      glowColor: Color(0xFF4BACFD),
    ),
    BubbleType.green: BubbleColorData(
      type: BubbleType.green,
      name: 'Lime Jelly',
      baseColor: Color(0xFF10D078),
      highlightColor: Color(0xFF86F3B8),
      shadowColor: Color(0xFF088A4E),
      glowColor: Color(0xFF34E897),
    ),
    BubbleType.yellow: BubbleColorData(
      type: BubbleType.yellow,
      name: 'Sunny Lemon',
      baseColor: Color(0xFFFFC300),
      highlightColor: Color(0xFFFFF199),
      shadowColor: Color(0xFFD49100),
      glowColor: Color(0xFFFFD54F),
    ),
    BubbleType.purple: BubbleColorData(
      type: BubbleType.purple,
      name: 'Grape Candy',
      baseColor: Color(0xFFA259FF),
      highlightColor: Color(0xFFDBBCFF),
      shadowColor: Color(0xFF6B26C8),
      glowColor: Color(0xFFB87CFF),
    ),
    BubbleType.orange: BubbleColorData(
      type: BubbleType.orange,
      name: 'Juicy Orange',
      baseColor: Color(0xFFFF8A00),
      highlightColor: Color(0xFFFFC580),
      shadowColor: Color(0xFFC75F00),
      glowColor: Color(0xFFFFA733),
    ),
    BubbleType.pink: BubbleColorData(
      type: BubbleType.pink,
      name: 'Cotton Candy',
      baseColor: Color(0xFFFF66C4),
      highlightColor: Color(0xFFFFBDE6),
      shadowColor: Color(0xFFC8278A),
      glowColor: Color(0xFFFF88D2),
    ),
    BubbleType.cyan: BubbleColorData(
      type: BubbleType.cyan,
      name: 'Mint Drop',
      baseColor: Color(0xFF00E5FF),
      highlightColor: Color(0xFFB2F8FF),
      shadowColor: Color(0xFF009BB5),
      glowColor: Color(0xFF33ECFF),
    ),
    BubbleType.bomb: BubbleColorData(
      type: BubbleType.bomb,
      name: 'Star Bomb',
      baseColor: Color(0xFF4A4E69),
      highlightColor: Color(0xFF9A8C98),
      shadowColor: Color(0xFF22223B),
      glowColor: Color(0xFFFFD166),
      icon: Icons.local_fire_department_rounded,
    ),
    BubbleType.rainbow: BubbleColorData(
      type: BubbleType.rainbow,
      name: 'Magic Rainbow',
      baseColor: Color(0xFFFFD700),
      highlightColor: Color(0xFFFFFFFF),
      shadowColor: Color(0xFFFF69B4),
      glowColor: Color(0xFFFFDF00),
      icon: Icons.auto_awesome_rounded,
    ),
    BubbleType.fireball: BubbleColorData(
      type: BubbleType.fireball,
      name: 'Blazing Fireball',
      baseColor: Color(0xFFFF3D00),
      highlightColor: Color(0xFFFF9E80),
      shadowColor: Color(0xFFBF360C),
      glowColor: Color(0xFFFF6E40),
      icon: Icons.whatshot_rounded,
    ),
  };

  static BubbleColorData get(BubbleType type) {
    return data[type] ?? data[BubbleType.red]!;
  }
}
