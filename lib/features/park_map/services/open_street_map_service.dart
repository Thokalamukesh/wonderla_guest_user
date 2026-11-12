import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/map_place.dart';

class OpenStreetMapService {
  OpenStreetMapService({http.Client? client})
    : _client = client ?? http.Client();

  static const _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const _nominatimUrl = 'https://nominatim.openstreetmap.org/search';
  static const _footRouterUrl =
      'https://routing.openstreetmap.de/routed-foot/route/v1/foot';
  static Map<String, String> get _headers => {
    // Browsers forbid apps from setting User-Agent. Sending it through
    // BrowserClient makes fetch fail before the routing response is returned.
    if (!kIsWeb) 'User-Agent': 'WonderlaBengaluruFlutterMap/1.0',
    'Accept': 'application/json',
  };

  final http.Client _client;
  DateTime? _lastRouteRequest;
  DateTime? _lastSearchRequest;

  void dispose() => _client.close();

  /// Returns only named OSM features inside the park area containing the
  /// configured Wonderla center. Nearby town places are excluded.
  Future<List<MapPlace>> loadParkPlaces({required LatLng center}) async {
    final query =
        '''
[out:json][timeout:20];
is_in(${center.latitude},${center.longitude})->.enclosing;
area.enclosing["name"~"Wonderla","i"]->.park;
(
  nwr(area.park)["amenity"];
  nwr(area.park)["shop"];
  nwr(area.park)["tourism"];
  nwr(area.park)["leisure"];
  nwr(area.park)["historic"];
  nwr(area.park)["attraction"];
  nwr(area.park)["public_transport"];
);
out center tags;
''';
    final response = await _client
        .post(Uri.parse(_overpassUrl), headers: _headers, body: {'data': query})
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('In-park places returned ${response.statusCode}.');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = payload['elements'] as List<dynamic>? ?? const [];
    final places = <MapPlace>[];
    for (final value in elements) {
      final element = value as Map<String, dynamic>;
      final tags = element['tags'] as Map<String, dynamic>? ?? const {};
      final name = tags['name'] as String?;
      final centerPoint = element['center'] as Map<String, dynamic>?;
      final latitude = ((element['lat'] ?? centerPoint?['lat']) as num?)
          ?.toDouble();
      final longitude = ((element['lon'] ?? centerPoint?['lon']) as num?)
          ?.toDouble();
      if (latitude == null || longitude == null) {
        continue;
      }
      final category = _category(tags);
      final type = _type(tags);
      final displayName = name?.trim().isNotEmpty == true
          ? name!.trim()
          : _title(type);
      places.add(
        MapPlace(
          id: '${element['type']}-${element['id']}',
          name: displayName,
          position: LatLng(latitude, longitude),
          category: category,
          kind: _title(type),
          icon: _icon(category, type),
          address: tags['addr:street'] as String?,
        ),
      );
    }
    return {for (final place in places) place.id: place}.values
        .toList(growable: false);
  }

  /// Runs on explicit submit only; the public Nominatim service is not used
  /// for keystroke autocomplete.
  Future<List<MapPlace>> searchParkPlaces({
    required String query,
    required LatLng near,
    double radiusKm = 2,
  }) async {
    final previous = _lastSearchRequest;
    if (previous != null) {
      final elapsed = DateTime.now().difference(previous);
      if (elapsed < const Duration(seconds: 1)) {
        await Future<void>.delayed(const Duration(seconds: 1) - elapsed);
      }
    }

    final latDelta = radiusKm / 111.0;
    final lonDelta =
        radiusKm / (111.0 * math.cos(near.latitude * math.pi / 180));
    final uri = Uri.parse(_nominatimUrl).replace(
      queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'limit': '12',
        'addressdetails': '1',
        'viewbox': [
          near.longitude - lonDelta,
          near.latitude + latDelta,
          near.longitude + lonDelta,
          near.latitude - latDelta,
        ].join(','),
        'bounded': '1',
      },
    );
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));
    _lastSearchRequest = DateTime.now();
    if (response.statusCode != 200) {
      throw Exception('Place search returned ${response.statusCode}.');
    }

    final results = jsonDecode(response.body) as List<dynamic>;
    return results
        .map((value) {
          final result = value as Map<String, dynamic>;
          final lat = double.parse(result['lat'] as String);
          final lon = double.parse(result['lon'] as String);
          final type = (result['type'] ?? result['class'] ?? 'place') as String;
          final category = _nominatimCategory(result['class'] as String?);
          final name =
              result['name'] as String? ??
              (result['display_name'] as String? ?? query).split(',').first;
          return MapPlace(
            id: 'nominatim-${result['place_id']}',
            name: name,
            position: LatLng(lat, lon),
            category: category,
            kind: _title(type),
            icon: _icon(category, type),
            address: result['display_name'] as String?,
          );
        })
        .toList(growable: false);
  }

  Future<WalkingRoute> findWalkingRoute({
    required LatLng from,
    required LatLng to,
  }) async {
    await _respectRouteLimit();
    final coordinates =
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
    final routeUri = kIsWeb
        ? Uri.base.resolve('/walking-route/$coordinates')
        : Uri.parse('$_footRouterUrl/$coordinates');
    final uri = routeUri.replace(
      queryParameters: const {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'true',
      },
    );
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 25));
    _lastRouteRequest = DateTime.now();
    if (response.statusCode != 200) {
      throw Exception('Walking route returned ${response.statusCode}.');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (payload['code'] != 'Ok') {
      throw Exception('No mapped walking route is available for this place.');
    }
    final routes = payload['routes'] as List<dynamic>? ?? const [];
    if (routes.isEmpty) throw Exception('No walking route was found.');
    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final coordinatesList = geometry['coordinates'] as List<dynamic>;
    final points = coordinatesList
        .map((pair) {
          final coordinate = pair as List<dynamic>;
          return LatLng(
            (coordinate[1] as num).toDouble(),
            (coordinate[0] as num).toDouble(),
          );
        })
        .toList(growable: false);

    final legs = route['legs'] as List<dynamic>? ?? const [];
    final firstLeg = legs.isEmpty ? null : legs.first as Map<String, dynamic>;
    final rawSteps = firstLeg?['steps'] as List<dynamic>? ?? const [];
    final steps = rawSteps
        .map((value) {
          final step = value as Map<String, dynamic>;
          final maneuver =
              step['maneuver'] as Map<String, dynamic>? ?? const {};
          final type = maneuver['type'] as String? ?? 'continue';
          final modifier = maneuver['modifier'] as String?;
          final roadName = step['name'] as String? ?? '';
          return RouteStep(
            instruction: _instruction(type, modifier, roadName),
            distanceMeters: (step['distance'] as num? ?? 0).toDouble(),
          );
        })
        .toList(growable: false);

    return WalkingRoute(
      points: points,
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
      steps: steps,
    );
  }

  Future<void> _respectRouteLimit() async {
    final previous = _lastRouteRequest;
    if (previous == null) return;
    final elapsed = DateTime.now().difference(previous);
    if (elapsed < const Duration(seconds: 1)) {
      await Future<void>.delayed(const Duration(seconds: 1) - elapsed);
    }
  }

  String _type(Map<String, dynamic> tags) =>
      (tags['amenity'] ??
              tags['tourism'] ??
              tags['leisure'] ??
              tags['shop'] ??
              tags['attraction'] ??
              tags['historic'] ??
              tags['public_transport'] ??
              tags['railway'] ??
              'place')
          as String;

  PlaceCategory _category(Map<String, dynamic> tags) {
    if ([
      'restaurant',
      'cafe',
      'fast_food',
      'food_court',
    ].contains(tags['amenity'])) {
      return PlaceCategory.food;
    }
    if (tags['tourism'] == 'hotel') return PlaceCategory.stay;
    if (tags['tourism'] != null ||
        tags['leisure'] != null ||
        tags['historic'] != null ||
        tags['attraction'] != null) {
      return PlaceCategory.attraction;
    }
    if (tags['amenity'] != null || tags['shop'] != null) {
      return PlaceCategory.facility;
    }
    return PlaceCategory.other;
  }

  PlaceCategory _nominatimCategory(String? value) => switch (value) {
    'amenity' || 'shop' => PlaceCategory.facility,
    'tourism' || 'leisure' => PlaceCategory.attraction,
    'building' => PlaceCategory.stay,
    _ => PlaceCategory.other,
  };

  IconData _icon(PlaceCategory category, String type) => switch (type) {
    'restaurant' || 'fast_food' || 'food_court' => Icons.restaurant_rounded,
    'cafe' => Icons.local_cafe_rounded,
    'hotel' => Icons.hotel_rounded,
    'toilets' => Icons.wc_rounded,
    'parking' => Icons.local_parking_rounded,
    'hospital' || 'pharmacy' => Icons.medical_services_rounded,
    'theme_park' || 'attraction' => Icons.attractions_rounded,
    _ => switch (category) {
      PlaceCategory.attraction => Icons.park_rounded,
      PlaceCategory.food => Icons.restaurant_rounded,
      PlaceCategory.facility => Icons.place_rounded,
      PlaceCategory.stay => Icons.hotel_rounded,
      PlaceCategory.other => Icons.place_rounded,
    },
  };

  String _title(String value) => value
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');

  String _instruction(String type, String? modifier, String roadName) {
    final direction = modifier == null ? '' : ' $modifier';
    final action = switch (type) {
      'depart' => 'Start walking',
      'turn' => 'Turn$direction',
      'continue' => 'Continue',
      'new name' => 'Continue',
      'merge' => 'Merge',
      'roundabout' || 'rotary' => 'At the roundabout, continue',
      'arrive' => 'Arrive at your destination',
      _ => 'Continue',
    };
    if (roadName.isEmpty || type == 'arrive') return action;
    return '$action on $roadName';
  }
}
