import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/number_format.dart';

void main() {
  test('display rounds to four decimals without changing stored precision', () {
    expect(formatNumber(0), '0');
    expect(formatNumber(40), '40');
    expect(formatNumber(0.1 + 0.2), '0.3');
    expect(formatNumber(12.3456789), '12.3457');
    expect(formatNumber(0.00001), '0');
    expect(formatNumber(9.99999), '10');
    expect(formatNumber(4.184), '4.184');
    final original = 12.3456789;
    formatNumber(original);
    expect(original, 12.3456789);
  });
}
