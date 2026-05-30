class LayoutResult {
  final List<LayoutCoordinate> layoutCoordinate;
  final double? lenghtList;
  final double? lenghtRibbon;

  LayoutResult({
    required this.layoutCoordinate,
    this.lenghtRibbon,
    this.lenghtList,
  });
}

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

LayoutResult calculateLayout({
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
    final itemWidth = maxWidth * 0.5;

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
            left: secondaryCount * itemWidth,
            top: mainHeight,
            width: itemWidth,
            height: listHeight,
            isCompact: true,
          ),
        );
        secondaryCount++;
      }
    }

    final double lenghtRibbon = (totalCount - 1) * itemWidth;
    return LayoutResult(layoutCoordinate: coords, lenghtRibbon: lenghtRibbon);
  }

  int columns = totalCount >= 3 ? 2 : 1;
  int realRows = (totalCount / columns).ceil();

  int visibleRows = totalCount > 4 ? 4 : realRows;

  double itemWidth = maxWidth / columns;
  double itemHeight = maxHeight / visibleRows;

  for (int i = 0; i < totalCount; i++) {
    int row = i ~/ columns;
    int col = i % columns;
    coords.add(
      LayoutCoordinate(
        left: col * itemWidth,
        top: row * itemHeight,
        width: itemWidth,
        height: itemHeight,
        isCompact: totalCount > 4,
      ),
    );
  }

  int totalPages = (realRows / visibleRows).ceil();

  final double lenghtList = totalPages * maxHeight;

  return LayoutResult(layoutCoordinate: coords, lenghtList: lenghtList);
}
