import 'dart:math';
import 'bubble_color.dart';

class LevelData {
  final int levelNumber;
  final String title;
  final int maxShots;
  final List<BubbleType> availableColors;
  final List<List<BubbleType?>> initialGrid;
  final int star1Score;
  final int star2Score;
  final int star3Score;

  const LevelData({
    required this.levelNumber,
    required this.title,
    required this.maxShots,
    required this.availableColors,
    required this.initialGrid,
    required this.star1Score,
    required this.star2Score,
    required this.star3Score,
  });

  int get bubbleCount {
    int count = 0;
    for (final row in initialGrid) {
      for (final cell in row) {
        if (cell != null) count++;
      }
    }
    return count;
  }

  static const int standardCols = 8;

  static final List<String> _levelTitles = [
    'Sugar Valley',
    'Jelly Meadow',
    'Berry Hills',
    'Candy Grove',
    'Honey Hive',
    'Lollipop Peaks',
    'Rainbow Reef',
    'Marshmallow Dunes',
    'Caramel Cavern',
    'Cosmic Confection',
  ];

  /// Fetch level data. Generates a fresh, dynamic board every time a level is played or reset!
  static LevelData getLevel(int levelNumber, {int? seed}) {
    // Use random seed if none provided, ensuring fresh bubble layouts on each restart
    final rand = seed != null ? Random(seed) : Random();

    // 1. Color Palette progression based on level difficulty
    final List<BubbleType> colorPalette;
    if (levelNumber <= 3) {
      colorPalette = [BubbleType.red, BubbleType.blue, BubbleType.green];
    } else if (levelNumber <= 7) {
      colorPalette = [
        BubbleType.red,
        BubbleType.blue,
        BubbleType.green,
        BubbleType.yellow,
      ];
    } else if (levelNumber <= 14) {
      colorPalette = [
        BubbleType.red,
        BubbleType.blue,
        BubbleType.green,
        BubbleType.yellow,
        BubbleType.purple,
      ];
    } else {
      colorPalette = [
        BubbleType.red,
        BubbleType.blue,
        BubbleType.green,
        BubbleType.yellow,
        BubbleType.purple,
        BubbleType.orange,
      ];
    }

    // 2. Row count progression
    final int rows;
    if (levelNumber == 1) {
      rows = 3;
    } else if (levelNumber <= 3) {
      rows = 4;
    } else if (levelNumber <= 10) {
      rows = 5;
    } else {
      rows = min(7, 5 + (levelNumber ~/ 10));
    }

    // 3. Shots limit (friendly for kids, gradual challenge)
    final int maxShots = max(18, 28 - (levelNumber ~/ 5));

    // 4. Generate dynamic clustered bubble grid
    final grid = <List<BubbleType?>>[];
    for (int r = 0; r < rows; r++) {
      final cols = (r % 2 == 0) ? standardCols : standardCols - 1;
      final row = <BubbleType?>[];

      BubbleType clusterColor = colorPalette[rand.nextInt(colorPalette.length)];
      int clusterLength = 2 + rand.nextInt(3); // 2 to 4 bubbles of same color

      for (int c = 0; c < cols; c++) {
        if (clusterLength <= 0) {
          clusterColor = colorPalette[rand.nextInt(colorPalette.length)];
          clusterLength = 2 + rand.nextInt(3);
        }
        clusterLength--;

        // Optional gap on lower rows for fun organic shapes
        if (r >= 2 && levelNumber > 1 && rand.nextDouble() < 0.08) {
          row.add(null);
          continue;
        }

        // Embedded Special Bomb Booster inside the grid (Level 4+)
        if (levelNumber >= 4 && rand.nextDouble() < 0.04) {
          row.add(BubbleType.bomb);
          continue;
        }

        // Embedded Rainbow Bubble (Level 7+)
        if (levelNumber >= 7 && rand.nextDouble() < 0.03) {
          row.add(BubbleType.rainbow);
          continue;
        }

        row.add(clusterColor);
      }
      grid.add(row);
    }

    final titleIndex = (levelNumber - 1) % _levelTitles.length;
    final title = '${_levelTitles[titleIndex]} $levelNumber';
    final baseScore = 500 + levelNumber * 200;

    return LevelData(
      levelNumber: levelNumber,
      title: title,
      maxShots: maxShots,
      availableColors: colorPalette,
      initialGrid: grid,
      star1Score: baseScore,
      star2Score: (baseScore * 1.6).toInt(),
      star3Score: (baseScore * 2.3).toInt(),
    );
  }
}
