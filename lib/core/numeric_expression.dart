/// Bounded arithmetic parser. Never evaluates code, identifiers or functions.
abstract final class NumericExpression {
  static double? tryValue(String raw) {
    if (raw.trim().isEmpty || raw.length > 256) return null;
    try {
      final parser = _Parser(
        raw
            .replaceAll('×', '*')
            .replaceAll('÷', '/')
            .replaceAll('−', '-')
            .replaceAll(',', '.'),
      );
      final value = parser.expression();
      parser.space();
      return parser.index == parser.text.length && value.isFinite
          ? value
          : null;
    } on FormatException {
      return null;
    }
  }

  static int? tryInt(String raw) {
    final value = tryValue(raw);
    return value != null &&
            value.abs() <= 2147483647 &&
            value == value.truncateToDouble()
        ? value.toInt()
        : null;
  }

  static bool looksNumeric(String raw) =>
      RegExp(r'^[\d\s.,eE()+*/×÷−\-]+$').hasMatch(raw);
}

class _Parser {
  _Parser(this.text);
  final String text;
  int index = 0, depth = 0;
  void space() {
    while (index < text.length && text[index].trim().isEmpty) {
      index++;
    }
  }

  bool take(String char) {
    space();
    if (index < text.length && text[index] == char) {
      index++;
      return true;
    }
    return false;
  }

  double expression() {
    var value = term();
    while (true) {
      if (take('+')) {
        value += term();
      } else if (take('-')) {
        value -= term();
      } else {
        return value;
      }
    }
  }

  double term() {
    var value = atom();
    while (true) {
      if (take('*')) {
        value *= atom();
      } else if (take('/')) {
        final divisor = atom();
        if (divisor == 0) throw const FormatException('Division by zero');
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  double atom() {
    if (++depth > 32) throw const FormatException('Expression too deep');
    try {
      if (take('+')) return atom();
      if (take('-')) return -atom();
      if (take('(')) {
        final value = expression();
        if (!take(')')) throw const FormatException('Missing bracket');
        return value;
      }
      space();
      final match = RegExp(r'(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?')
          .matchAsPrefix(text, index);
      if (match == null) throw const FormatException('Expected number');
      index = match.end;
      return double.parse(match[0]!);
    } finally {
      depth--;
    }
  }
}
