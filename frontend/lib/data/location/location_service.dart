import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Coordinates captured from `Geolocator.getCurrentPosition()`.
class GeoPosition {
  const GeoPosition({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
}

/// Normalised reverse-geocoding DTO returned by our backend at
/// `GET /api/ubicacion/reverse`. Kept intentionally separate from
/// Nominatim's raw shape so the frontend never depends on that provider.
class ReverseGeocode {
  const ReverseGeocode({
    required this.direccion,
    required this.ciudad,
    required this.provincia,
    required this.pais,
    required this.latitud,
    required this.longitud,
    this.atribucion,
    this.fuente,
    this.cache = false,
  });

  final String direccion;
  final String ciudad;
  final String provincia;
  final String pais;
  final double latitud;
  final double longitud;
  final String? atribucion;
  final String? fuente;
  final bool cache;

  factory ReverseGeocode.fromJson(Map<String, dynamic> json) {
    double toDouble(Object? v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return ReverseGeocode(
      direccion: (json['direccion'] ?? '').toString(),
      ciudad: (json['ciudad'] ?? '').toString(),
      provincia: (json['provincia'] ?? '').toString(),
      pais: (json['pais'] ?? '').toString(),
      latitud: toDouble(json['latitud']),
      longitud: toDouble(json['longitud']),
      atribucion: json['atribucion']?.toString(),
      fuente: json['fuente']?.toString(),
      cache: json['cache'] == true,
    );
  }
}

/// Reasons a location request can fail — surfaced to the UI so the
/// checkout can decide between "ask again", "show fallback banner" or
/// "stay silent".
enum LocationErrorCode {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  reverseGeocodeFailed,
  network,
  unknown,
}

class LocationException implements Exception {
  const LocationException(this.code, this.message);

  final LocationErrorCode code;
  final String message;

  @override
  String toString() => 'LocationException($code): $message';
}

/// Thin wrapper around [Geolocator] + our backend reverse-geocoder.
///
/// The wrapper enforces the interaction rules approved for Aromas Store:
///
/// - The permission prompt is only triggered when the caller invokes
///   [obtenerPosicion]. Neither the wrapper nor the widgets that use it
///   subscribe to a permanent location stream.
/// - Errors are surfaced as [LocationException] with a stable
///   [LocationErrorCode], so the UI can render the correct fallback:
///   snackbar for `permissionDenied`, banner for `permissionDeniedForever`,
///   toast for `serviceDisabled`, etc.
/// - The HTTP call to `GET /api/ubicacion/reverse` is centralised here
///   so the widgets never talk to Nominatim's proxy directly.
class LocationService {
  LocationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Requests the user's current position **once**. Handles all the
  /// permission dance in a single call:
  ///
  /// 1. If location services are disabled system-wide → throws
  ///    [LocationErrorCode.serviceDisabled].
  /// 2. If permission is `denied` we call [Geolocator.requestPermission]
  ///    — that's the exact moment the browser prompt shows.
  /// 3. If the user rejects → [LocationErrorCode.permissionDenied].
  /// 4. If the browser already remembered a rejection →
  ///    [LocationErrorCode.permissionDeniedForever].
  /// 5. On success returns a [GeoPosition] with lat/lng/accuracy.
  Future<GeoPosition> obtenerPosicion({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        LocationErrorCode.serviceDisabled,
        'El navegador o el sistema tienen la ubicación desactivada.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationErrorCode.permissionDeniedForever,
        'Concediste "denegar siempre" a la ubicación. Habilítala manualmente '
            'desde la barra del navegador para volver a usar esta función.',
      );
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        LocationErrorCode.permissionDenied,
        'No se concedió el permiso de ubicación. Puedes ingresar tu '
            'dirección manualmente.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      return GeoPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
    } catch (error) {
      throw LocationException(
        LocationErrorCode.timeout,
        'No pudimos obtener tu ubicación: $error',
      );
    }
  }

  /// Resolves a `(lat, lng)` pair into an address DTO by calling our
  /// backend proxy. The proxy handles rate limiting, caching and
  /// attribution to OpenStreetMap.
  Future<ReverseGeocode> resolverDireccion({
    required double latitud,
    required double longitud,
  }) async {
    final uri = Uri.parse(
      '$apiBaseUrl/ubicacion/reverse?lat=$latitud&lon=$longitud',
    );

    http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
    } on Object catch (error) {
      throw LocationException(
        LocationErrorCode.network,
        'No pudimos contactar el servicio de ubicación: $error',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LocationException(
        LocationErrorCode.reverseGeocodeFailed,
        _extractErrorMessage(response),
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      final dato = decoded is Map ? decoded['dato'] : null;
      if (dato is! Map) {
        throw const LocationException(
          LocationErrorCode.reverseGeocodeFailed,
          'La respuesta del servidor no incluye datos de dirección.',
        );
      }
      return ReverseGeocode.fromJson(dato.cast<String, dynamic>());
    } on LocationException {
      rethrow;
    } catch (_) {
      throw const LocationException(
        LocationErrorCode.reverseGeocodeFailed,
        'No pudimos interpretar la respuesta del servidor.',
      );
    }
  }

  /// Convenience helper: capture position AND resolve address in one call.
  Future<(GeoPosition, ReverseGeocode)> obtenerYResolver({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final pos = await obtenerPosicion(timeout: timeout);
    final geo = await resolverDireccion(
      latitud: pos.latitude,
      longitud: pos.longitude,
    );
    return (pos, geo);
  }

  void dispose() {
    _client.close();
  }

  static String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // fall through to a generic message
    }
    return 'No pudimos obtener la dirección para las coordenadas (HTTP '
        '${response.statusCode}).';
  }
}
