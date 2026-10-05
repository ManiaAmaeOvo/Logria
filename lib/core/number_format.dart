/// Display only: preserve full stored precision and trim floating-point noise.
String formatNumber(double value) =>
    value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
