class LayoutCoordinate {
  final double left;
  final double top;
  final double width;
  final double height;
  final bool isCompact;
  LayoutCoordinate({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.isCompact = false,
  });
}

List<LayoutCoordinate> calculateLayout({
  required int totalCount,
  required double maxWidth,
  required double maxHeight,
  required int? pinnedIndex,
  required int? activeIndex,
}) {
  List<LayoutCoordinate> coords = [];
  if ((pinnedIndex != null || activeIndex != null) && totalCount > 1) {
    final mainIndex = pinnedIndex ?? activeIndex!;
    final mainHeight = maxHeight * 0.75;
    final listHeight = maxHeight * 0.25;
    final itemWidth = 180.0;

    int secondaryCount = 0;
    for (int i = 0; i < totalCount; i++) {
      if (i == mainIndex) {
        coords.add(
          LayoutCoordinate(
            left: 0,
            top: 0,
            width: maxWidth,
            height: mainHeight,
          ),
        );
      } else {
        coords.add(
          LayoutCoordinate(
            left: secondaryCount * (itemWidth + 8),
            top: mainHeight,
            width: itemWidth,
            height: listHeight,
            isCompact: true,
          ),
        );
        secondaryCount++;
      }
    }
    return coords;
  }

  int columns = totalCount >= 3 ? 2 : 1;
  int rows = (totalCount / columns).ceil();

  if (totalCount > 4) rows = 4;

  double itemWidth = maxWidth / columns;
  double itemHeight = maxHeight / rows;

  for (int i = 0; i < totalCount; i++) {
    int row = i ~/ columns;
    int col = i % columns;
    coords.add(
      LayoutCoordinate(
        left: col * itemWidth,
        top: row * itemHeight,
        width: itemWidth,
        height: itemHeight,
      ),
    );
  }

  return coords;
}
