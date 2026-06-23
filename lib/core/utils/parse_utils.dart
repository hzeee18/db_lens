/// Utilitas parsing nilai dari berbagai engine penyimpanan.
abstract final class ParseUtils {
  static int asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
