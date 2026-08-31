class SquareCropRect {
  const SquareCropRect({
    required this.x,
    required this.y,
    required this.side,
  });

  final int x;
  final int y;
  final int side;

  static SquareCropRect centered(int width, int height) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Image dimensions must be positive.');
    }
    final side = width < height ? width : height;
    return SquareCropRect(
      x: (width - side) ~/ 2,
      y: (height - side) ~/ 2,
      side: side,
    );
  }
}
