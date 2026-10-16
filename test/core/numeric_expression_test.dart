import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/numeric_expression.dart';

void main() {
  test(
    'arithmetic handles precedence, parentheses, decimals and unary signs',
    () {
      for (final entry in {
        '20+2.5*2': 25.0,
        '(20+5)×2': 50.0,
        '150÷2': 75.0,
        '8/2-1': 3.0,
        '-(-2)+.5': 2.5,
        '1,5+2': 3.5,
        '1e2/4': 25.0,
      }.entries) {
        expect(NumericExpression.tryValue(entry.key), entry.value);
      }
    },
  );
  test('malformed and dangerous expressions never evaluate', () {
    for (final input in [
      '',
      '1/0',
      '0/0',
      '2+',
      '1 2',
      '(2',
      '2)',
      '1e999',
      'NaN',
      'Infinity',
      '2**3',
      'sqrt(4)',
      'print(1)',
      'a+1',
      '1;2',
      '${List.filled(40, '(').join()}1${List.filled(40, ')').join()}',
      '1' * 257,
    ]) {
      expect(NumericExpression.tryValue(input), isNull, reason: input);
    }
  });
  test(
    'count fields reject fractional or oversized results without rounding',
    () {
      expect(NumericExpression.tryInt('2+1'), 3);
      expect(NumericExpression.tryInt('9/3'), 3);
      expect(NumericExpression.tryInt('3/2'), isNull);
      expect(NumericExpression.tryInt('1e20'), isNull);
      expect(NumericExpression.looksNumeric('20+'), true);
      expect(NumericExpression.looksNumeric('bodyweight + band'), false);
    },
  );
}
