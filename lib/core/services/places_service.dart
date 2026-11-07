import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/place_detail.dart';
import '../../data/models/place_prediction.dart';

class PlacesService {
  static String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  final Dio _dio;
  String? _sessionToken;
  static const _uuid = Uuid();

  final Map<String, _CachedAddress> _geocodeCache = {};
  static const int _maxCacheSize = 50;

  PlacesService({Dio? dio}) : _dio = dio ?? Dio();

  void startSession() {
    _sessionToken = _uuid.v4();
  }

  void _endSession() {
    _sessionToken = null;
  }

  Future<List<PlacePrediction>> getAutoComplete(String input) async {
    if (input.trim().isEmpty) return [];
    _sessionToken ??= _uuid.v4();

    try {
      final response = await _dio.get(
        '$_baseUrl/autocomplete/json',
        queryParameters: {
          'input': input,
          'key': _apiKey,
          'components': 'country:ng',
          'sessiontoken': _sessionToken,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        debugPrint('[PlacesService] autocomplete status=$status');
        return [];
      }

      final predictions = data['predictions'] as List<dynamic>? ?? [];
      return predictions
          .map((p) => PlacePrediction.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[PlacesService] autocomplete error: $e');
      return [];
    }
  }

  Future<PlaceDetail?> getPlaceDetail(String placeId) async {
    if (placeId.isEmpty) return null;

    try {
      final response = await _dio.get(
        '$_baseUrl/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'formatted_address,geometry,place_id',
          'key': _apiKey,
          if (_sessionToken != null) 'sessiontoken': _sessionToken,
        },
      );

      _endSession();

      final data = response.data as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;

      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) return null;
      return PlaceDetail.fromJson(result);
    } catch (e) {
      debugPrint('[PlacesService] detail error: $e');
      return null;
    }
  }

  Future<({double lat, double lng})?> getLatLngFromAddress(
      String address) async {
    if (address.trim().isEmpty) return null;
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {'address': address, 'key': _apiKey},
      );
      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      if (results != null && results.isNotEmpty) {
        final location = results[0]['geometry']?['location'];
        if (location != null) {
          return (
            lat: (location['lat'] as num).toDouble(),
            lng: (location['lng'] as num).toDouble(),
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('[PlacesService] forward geocode error: $e');
      return null;
    }
  }

  Future<String?> getAddressFromLatLng(double lat, double lng) async {
    final cacheKey = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    final cached = _geocodeCache[cacheKey];
    if (cached != null && !cached.isExpired) return cached.address;

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': _apiKey,
          'result_type': 'street_address|route|neighborhood',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      if (results != null && results.isNotEmpty) {
        final address = results[0]['formatted_address'] as String?;
        if (address != null) {
          if (_geocodeCache.length >= _maxCacheSize) {
            _geocodeCache.remove(_geocodeCache.keys.first);
          }
          _geocodeCache[cacheKey] = _CachedAddress(address);
        }
        return address;
      }
      return null;
    } catch (e) {
      debugPrint('[PlacesService] reverse geocode error: $e');
      return null;
    }
  }
}

class _CachedAddress {
  final String address;
  final DateTime _createdAt;

  _CachedAddress(this.address) : _createdAt = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(_createdAt) > const Duration(minutes: 10);
}
