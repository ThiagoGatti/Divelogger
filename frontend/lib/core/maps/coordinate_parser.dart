/// Lê coordenadas escritas de várias formas, para o admin não errar ao copiar de outro app:
///   -25.4991, -48.3202          (decimal, ponto)
///   -25,4991  -48,3202          (decimal, vírgula do português; separador espaço ou ;)
///   25°29'56.8"S 48°19'12.7"W   (graus, minutos e segundos; N/S/E/W ou L/O)
/// Se a latitude e a longitude vierem trocadas (latitude fora de -90..90), inverte sozinho.
class CoordinateParser {
  CoordinateParser._();

  static String _normalize(String text) => text
      .replaceAll('\u2212', '-') // sinal de menos "bonito"
      .replaceAll('\u2013', '-')
      .trim();

  static final RegExp _number = RegExp(r'-?\d+(?:[.,]\d+)?');
  static final RegExp _dmsPart = RegExp('\\d+\\s*[°º][^NSEWOLnsewol]*[NSEWOLnsewol]');

  static double _toDouble(String s) => double.parse(s.replaceAll(',', '.'));

  static double? _parseDms(String part) {
    final nums = RegExp(r'\d+(?:[.,]\d+)?').allMatches(part).map((m) => _toDouble(m.group(0)!)).toList();
    if (nums.isEmpty) return null;
    final deg = nums[0];
    final min = nums.length > 1 ? nums[1] : 0.0;
    final sec = nums.length > 2 ? nums[2] : 0.0;
    if (min >= 60 || sec >= 60) return null;

    var value = deg + min / 60 + sec / 3600;
    final trimmed = part.trim().toUpperCase();
    final last = trimmed.isEmpty ? '' : trimmed[trimmed.length - 1];
    if (last == 'S' || last == 'W' || last == 'O') value = -value;
    if (trimmed.startsWith('-')) value = -value.abs();
    return value;
  }

  /// Uma coordenada isolada (decimal ou graus/minutos/segundos).
  static double? parseSingle(String text) {
    final t = _normalize(text);
    if (t.isEmpty) return null;
    if (t.contains('°') || t.contains('º')) return _parseDms(t);
    if (!RegExp(r'^-?\d+(?:[.,]\d+)?$').hasMatch(t)) return null;
    return _toDouble(t);
  }

  static bool _validLat(double v) => v >= -90 && v <= 90;
  static bool _validLng(double v) => v >= -180 && v <= 180;

  static ({double lat, double lng})? _order(double a, double b) {
    if (_validLat(a) && _validLng(b)) return (lat: a, lng: b);
    if (_validLat(b) && _validLng(a)) return (lat: b, lng: a); // vieram trocadas
    return null;
  }

  /// Um PAR de coordenadas num só texto (ex.: copiado do Google Maps). Devolve null se não houver exatamente duas.
  static ({double lat, double lng})? parsePair(String text) {
    final t = _normalize(text);
    if (t.isEmpty) return null;

    if (t.contains('°') || t.contains('º')) {
      final parts = _dmsPart.allMatches(t).map((m) => m.group(0)!).toList();
      if (parts.length != 2) return null;
      final a = _parseDms(parts[0]);
      final b = _parseDms(parts[1]);
      if (a == null || b == null) return null;

      // pela letra: N/S = latitude; E/W/L/O = longitude
      final firstTrim = parts[0].trim().toUpperCase();
      final firstLetter = firstTrim[firstTrim.length - 1];
      final firstIsLng = 'EWLO'.contains(firstLetter);
      return firstIsLng ? _order(b, a) : _order(a, b);
    }

    final nums = _number.allMatches(t).map((m) => _toDouble(m.group(0)!)).toList();
    if (nums.length != 2) return null;
    return _order(nums[0], nums[1]);
  }

  /// Latitude e longitude já separadas em dois campos.
  static ({double lat, double lng})? tryPair(String latText, String lngText) {
    final a = parseSingle(latText);
    final b = parseSingle(lngText);
    if (a == null || b == null || !_validLat(a) || !_validLng(b)) return null;
    return (lat: a, lng: b);
  }
}
