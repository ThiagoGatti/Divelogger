import 'package:flutter/foundation.dart';

/// Configuração de ambiente da API.
///
/// Ordem de prioridade:
///  1. `--dart-define=API_BASE_URL=...` (ou `--dart-define-from-file=env/prod.json`)
///  2. Release  -> [productionUrl]
///  3. Debug    -> localhost / emulador Android
///
/// Exemplos:
///   flutter run                                        (emulador, backend local)
///   flutter run --dart-define-from-file=env/dev.json   (celular + backend local: ajuste o IP)
///   flutter run --dart-define-from-file=env/aws-http.json (debug contra a AWS, ainda sem HTTPS)
///   flutter run --dart-define-from-file=env/prod.json  (AWS com HTTPS)
///   flutter build appbundle --dart-define-from-file=env/prod.json
class ApiConfig {
  ApiConfig._();

  /// URL HTTPS pública do backend na AWS (domínio do Load Balancer/CloudFront).
  static const String productionUrl = 'https://api.SEU-DOMINIO.com';

  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  static const Duration requestTimeout = Duration(seconds: 20);

  static String get baseUrl {
    final raw = _fromEnv.isNotEmpty
        ? _fromEnv
        : (kReleaseMode ? productionUrl : _debugDefault);

    final url = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;

    // Em release nunca aceitamos HTTP (assert é removido em release, por isso o throw).
    if (kReleaseMode && !url.startsWith('https://')) {
      throw StateError(
        'Build de release exige API em HTTPS. Configure env/prod.json com a URL https.',
      );
    }
    return url;
  }

  static String get _debugDefault {
    if (kIsWeb) return 'http://localhost:8080';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080'; // localhost do PC visto pelo emulador
      default:
        return 'http://127.0.0.1:8080'; // iOS Simulator / desktop
    }
  }
}
