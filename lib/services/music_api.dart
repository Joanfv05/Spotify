import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MusicApi {
  // Aumentamos el timeout y añadimos reintentos
  static const Duration _timeoutDuration = Duration(seconds: 15);
  static const int _maxRetries = 3;

  // Lista de proxies alternativos (por si allorigins falla)
  static final List<String> _proxyUrls = [
    "https://api.allorigins.win/get?url=",
    "https://corsproxy.io/?",
    "https://api.codetabs.com/v1/proxy?quest=",
  ];

  // Endpoint directo de Deezer (sin proxy, para probar)
  static const String _directDeezerUrl = "https://api.deezer.com/search?q=";

  Future<List<Map<String, dynamic>>> buscarCanciones(String query) async {
    if (query.trim().isEmpty) return [];

    // Limpiar y formatear la query
    final cleanQuery = Uri.encodeQueryComponent(query.trim());

    // Intentar con diferentes estrategias
    return await _tryWithRetry(cleanQuery);
  }

  Future<List<Map<String, dynamic>>> _tryWithRetry(String query, {int retryCount = 0}) async {
    try {
      // Estrategia 1: Intentar directo (sin proxy)
      if (retryCount == 0) {
        try {
          final result = await _tryDirectConnection(query);
          if (result.isNotEmpty) return result;
        } catch (e) {
          print("⚠ Falló conexión directa: $e");
        }
      }

      // Estrategia 2: Usar proxy con round-robin
      final proxyIndex = retryCount % _proxyUrls.length;
      return await _tryWithProxy(query, proxyIndex);

    } on TimeoutException {
      print("⚠ Timeout en intento $retryCount");

      // Reintentar si no hemos alcanzado el máximo
      if (retryCount < _maxRetries) {
        // Esperar un momento antes de reintentar
        await Future.delayed(Duration(seconds: 1 * (retryCount + 1)));
        return _tryWithRetry(query, retryCount: retryCount + 1);
      }

      return [];
    } catch (e) {
      print("⚠ Error en intento $retryCount: $e");

      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: 2));
        return _tryWithRetry(query, retryCount: retryCount + 1);
      }

      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _tryDirectConnection(String query) async {
    final url = Uri.parse("$_directDeezerUrl$query&limit=25");

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'SpotifyFlutter/1.0',
      },
    ).timeout(_timeoutDuration);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data["data"] ?? []);
    }

    throw Exception("Direct connection failed: ${response.statusCode}");
  }

  Future<List<Map<String, dynamic>>> _tryWithProxy(String query, int proxyIndex) async {
    final encodedDeezerUrl = Uri.encodeComponent("$_directDeezerUrl$query&limit=25");
    final proxyUrl = _proxyUrls[proxyIndex];
    final url = Uri.parse("$proxyUrl$encodedDeezerUrl");

    print("🔄 Usando proxy ${proxyIndex + 1}: ${_proxyUrls[proxyIndex]}");

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'SpotifyFlutter/1.0',
      },
    ).timeout(_timeoutDuration);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      // Diferentes proxies tienen diferentes estructuras de respuesta
      if (proxyUrl.contains("allorigins.win")) {
        if (decoded["contents"] == null) return [];
        final deezerJson = json.decode(decoded["contents"]);
        return List<Map<String, dynamic>>.from(deezerJson["data"] ?? []);
      } else if (proxyUrl.contains("corsproxy.io") || proxyUrl.contains("codetabs.com")) {
        // Estos proxies devuelven la respuesta directa
        return List<Map<String, dynamic>>.from(decoded["data"] ?? []);
      }
    }

    throw Exception("Proxy failed: ${response.statusCode}");
  }

  // Método adicional para obtener datos mock si todo falla
  Future<List<Map<String, dynamic>>> buscarCancionesConFallback(String query) async {
    final results = await buscarCanciones(query);

    if (results.isEmpty) {
      print("📦 Usando datos mock como fallback");
      return _getMockData(query);
    }

    return results;
  }

  List<Map<String, dynamic>> _getMockData(String query) {
    // Datos mock de ejemplo
    return [
      {
        "id": 1,
        "title": "Blinding Lights",
        "artist": {"name": "The Weeknd"},
        "album": {"title": "After Hours", "cover_medium": "https://e-cdns-images.dzcdn.net/images/cover/2e018122cb56986277102d2041a592c8/250x250-000000-80-0-0.jpg"},
        "preview": "https://cdns-preview.dzcdn.net/stream/c-6fb58f6e89d5a5a3e5287df5e7b6c2d5-4.mp3",
        "duration": 200
      },
      {
        "id": 2,
        "title": "Stay",
        "artist": {"name": "The Kid LAROI, Justin Bieber"},
        "album": {"title": "F*CK LOVE 3", "cover_medium": "https://e-cdns-images.dzcdn.net/images/cover/2e018122cb56986277102d2041a592c8/250x250-000000-80-0-0.jpg"},
        "preview": "https://cdns-preview.dzcdn.net/stream/c-6fb58f6e89d5a5a3e5287df5e7b6c2d5-4.mp3",
        "duration": 141
      },
      // Añade más canciones mock según necesites
    ];
  }
}