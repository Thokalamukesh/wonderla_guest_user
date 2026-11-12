import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../park_map/park_map_screen.dart';
import '../park_map/models/map_place.dart';
import '../park_map/models/park_map_config.dart';
import '../park_map/models/wonderla_location_catalog.dart';
import '../park_map/services/location_service.dart';
import '../park_map/services/open_street_map_service.dart';
import '../../shared/wonderla_palette.dart';

const _mapNavy = wonderlaCobalt;
const _mapInk = wonderlaNavy;
const _mapCanvas = wonderlaCream;

/// Park map centered on the selected park, with visitor GPS shown only nearby.
class ConfiguredParkMapScreen extends StatefulWidget {
  const ConfiguredParkMapScreen({
    super.key,
    required this.config,
    required this.baseUrl,
    required this.initialPosition,
  });
  final Map<String, dynamic> config;
  final String baseUrl;
  final Position initialPosition;

  @override
  State<ConfiguredParkMapScreen> createState() =>
      _ConfiguredParkMapScreenState();
}

class _ConfiguredParkMapScreenState extends State<ConfiguredParkMapScreen> {
  final _controller = MapController();
  final _location = LocationService();
  final _routingService = OpenStreetMapService();
  final _searchController = TextEditingController();
  StreamSubscription<Position>? _positionSubscription;
  Future<void>? _locationTask;
  LatLng? _center;
  LatLng? _visitorPosition;
  Map<String, dynamic>? _selected;
  WalkingRoute? _route;
  bool _gpsLoading = false;
  bool _routing = false;
  bool _mapReady = false;
  bool _showLayout = false;
  String? _locationMessage;
  String? _routeError;

  Map<String, dynamic> get _map =>
      Map<String, dynamic>.from(widget.config['parkMap'] as Map? ?? const {});
  List<Map<String, dynamic>> get _places => List<Map<String, dynamic>>.from(
    (_map['places'] as List? ?? const []).map(
      (e) => Map<String, dynamic>.from(e as Map),
    ),
  );
  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (Uri.tryParse(path)?.hasScheme == true) return path;
    return '${widget.baseUrl}${path.startsWith('/') ? '' : '/'}$path';
  }

  String get _parkIdentity => [
    widget.config['slug'],
    widget.config['name'],
    widget.config['location'],
    widget.config['city'],
    widget.config['title'],
  ].whereType<Object>().join(' ').toLowerCase();

  bool get _isBengaluruPark {
    if (RegExp(r'\b(bengaluru|bangalore)\b').hasMatch(_parkIdentity)) {
      return true;
    }
    if (RegExp(r'\b(kochi|cochin|hyderabad|bhubaneswar|chennai)\b')
        .hasMatch(_parkIdentity)) {
      return false;
    }
    final lat = double.tryParse('${_map['centerLat']}');
    final lng = double.tryParse('${_map['centerLng']}');
    return lat != null &&
        lng != null &&
        Geolocator.distanceBetween(
              lat,
              lng,
              wonderlaBengaluruLatitude,
              wonderlaBengaluruLongitude,
            ) <
            5000;
  }

  LatLng? _placePosition(Map<String, dynamic> place) {
    final lat = double.tryParse('${place['lat']}');
    final lng = double.tryParse('${place['lng']}');
    if (lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180) {
      return LatLng(lat, lng);
    }

    // These in-park destinations ship with verified coordinates, so they
    // remain routable even when CMS entries have no lat/lng fields.
    if (_isBengaluruPark) {
      final name = _normalizePlaceName(place['name']?.toString() ?? '');
      for (final known in wonderlaFeaturedLocations) {
        final knownName = _normalizePlaceName(known.name);
        if (name == knownName || knownName.startsWith('$name ')) {
          return known.position;
        }
      }
    }
    return null;
  }

  String _normalizePlaceName(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  LatLng? get _configuredCenter {
    // CMS park records may not include the slug in every response path, so
    // identify the selected park from its display name and location too.
    final identity = _parkIdentity;
    for (final entry in wonderlaParkCoordinates.entries) {
      final aliases = switch (entry.key) {
        'bengaluru' => const ['bengaluru', 'bangalore'],
        'kochi' => const ['kochi', 'cochin'],
        _ => [entry.key],
      };
      if (aliases.any(identity.contains)) {
        return LatLng(entry.value.$1, entry.value.$2);
      }
    }
    final lat = double.tryParse('${_map['centerLat']}');
    final lng = double.tryParse('${_map['centerLng']}');
    if (lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180) {
      return LatLng(lat, lng);
    }
    for (final place in _places) {
      final position = _placePosition(place);
      if (position != null) return position;
    }
    if (widget.config['slug'] == 'bengaluru') {
      return const LatLng(
        wonderlaBengaluruLatitude,
        wonderlaBengaluruLongitude,
      );
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _center = _configuredCenter;
    _showLayout =
        _center == null && _imageUrl(_map['img']?.toString()).isNotEmpty;
    final point = LatLng(
      widget.initialPosition.latitude,
      widget.initialPosition.longitude,
    );
    if (_isNearPark(point)) {
      _visitorPosition = point;
      _positionSubscription = _location.watchPosition().listen(
        (position) {
          if (!mounted) return;
          final next = LatLng(position.latitude, position.longitude);
          setState(() {
            _visitorPosition = _isNearPark(next) ? next : null;
            _locationMessage = _visitorPosition == null
                ? 'You are outside the park area. Showing the park map.'
                : null;
          });
          if (_visitorPosition == null &&
              _mapReady &&
              _configuredCenter != null) {
            _controller.move(_configuredCenter!, 16);
          }
        },
        onError: (_) {
          if (mounted)
            setState(() => _locationMessage = 'Live location updates stopped.');
        },
      );
    } else {
      _locationMessage = 'You are outside the park area. Showing the park map.';
    }
  }

  bool _isNearPark(LatLng point) {
    final park = _configuredCenter;
    if (park == null) return false;
    return Geolocator.distanceBetween(
          point.latitude,
          point.longitude,
          park.latitude,
          park.longitude,
        ) <=
        1500;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _searchController.dispose();
    _routingService.dispose();
    super.dispose();
  }

  Future<void> _locateVisitor() {
    final pending = _locationTask;
    if (pending != null) return pending;

    late final Future<void> task;
    task = _fetchVisitorLocation().whenComplete(() {
      if (identical(_locationTask, task)) _locationTask = null;
    });
    _locationTask = task;
    return task;
  }

  Future<void> _fetchVisitorLocation() async {
    if (mounted) {
      setState(() {
        _gpsLoading = true;
        _locationMessage = null;
      });
    }
    final result = await _location.currentPosition();
    if (!mounted) return;
    final position = result.position;
    setState(() {
      _gpsLoading = false;
      _locationMessage = result.message;
      if (position != null) {
        _visitorPosition = LatLng(position.latitude, position.longitude);
        if (!_isNearPark(_visitorPosition!)) {
          _visitorPosition = null;
          _locationMessage =
              'You are outside the park area. Showing the park map.';
        }
        if (_showLayout) {
          _showLayout = false;
          _mapReady = false;
        }
        if (_visitorPosition != null)
          _positionSubscription ??= _location.watchPosition().listen(
            (position) {
              if (!mounted) return;
              final next = LatLng(position.latitude, position.longitude);
              setState(() {
                _visitorPosition = _isNearPark(next) ? next : null;
                _locationMessage = _visitorPosition == null
                    ? 'You are outside the park area. Showing the park map.'
                    : null;
              });
              if (_visitorPosition == null &&
                  _mapReady &&
                  _configuredCenter != null) {
                _controller.move(_configuredCenter!, 16);
              }
            },
            onError: (_) {
              if (mounted) {
                setState(
                  () => _locationMessage = 'Live location updates stopped.',
                );
              }
            },
          );
      }
    });
    if (position != null &&
        _isNearPark(LatLng(position.latitude, position.longitude)) &&
        _mapReady) {
      _controller.move(LatLng(position.latitude, position.longitude), 17);
    } else if (position != null && _mapReady && _configuredCenter != null) {
      _controller.move(_configuredCenter!, 16);
    }
  }

  void _focusPlace(Map<String, dynamic> place) {
    final position = _placePosition(place);
    setState(() {
      _selected = place;
      _route = null;
      _routeError = null;
      if (position != null && _showLayout) {
        _showLayout = false;
        _mapReady = false;
      }
    });
    if (position == null) {
      setState(
        () => _routeError = 'Add this place’s Latitude and Longitude in CMS Admin → Park map → Map places. Save the item and map configuration, then tap it again.',
      );
      return;
    }
    if (_mapReady) _controller.move(position, 18);
    _requestDirections(place);
  }

  Future<void> _requestDirections(Map<String, dynamic> place) async {
    final destination = _placePosition(place);
    if (destination == null) {
      setState(
        () => _routeError = 'Add this place’s latitude and longitude in the CMS to get directions.',
      );
      return;
    }
    if (_visitorPosition == null || !_isNearPark(_visitorPosition!)) {
      await _locateVisitor();
      if (_visitorPosition == null) {
        if (mounted) {
          setState(
            () => _routeError =
                _locationMessage ??
                'Allow location access to get walking directions.',
          );
        }
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _routing = true;
      _routeError = null;
    });
    try {
      final route = await _routingService.findWalkingRoute(
        from: _visitorPosition!,
        to: destination,
      );
      if (!mounted) return;
      setState(() {
        _route = route;
        _routing = false;
      });
      if (_mapReady && route.points.isNotEmpty) {
        _fitRoute(route);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _routing = false;
        _routeError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _fitRoute(WalkingRoute route) {
    if (!_mapReady || route.points.isEmpty) return;
    _controller.fitCamera(
      CameraFit.coordinates(
        coordinates: route.points,
        padding: const EdgeInsets.fromLTRB(36, 112, 72, 56),
        maxZoom: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final places = _places;
    final image = _imageUrl(_map['img']?.toString());
    return Scaffold(
      backgroundColor: _mapCanvas,
      appBar: AppBar(
        backgroundColor: _mapCanvas,
        foregroundColor: _mapInk,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          widget.config['name']?.toString() ?? 'Park map',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final map = _mapPanel(image, places);
              final locations = _placeTray(places);
              if (constraints.maxWidth >= 760) {
                return Row(
                  children: [
                    Expanded(flex: 11, child: map),
                    const SizedBox(width: 12),
                    Expanded(flex: 9, child: locations),
                  ],
                );
              }
              return Column(
                children: [
                  Expanded(child: map),
                  const SizedBox(height: 10),
                  Expanded(child: locations),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _mapPanel(
    String image,
    List<Map<String, dynamic>> places,
  ) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Stack(
      fit: StackFit.expand,
      children: [
        _showLayout ? _layoutMap(image, places) : _liveMap(places),
        Positioned(top: 10, left: 10, right: 10, child: _searchBox()),
        Positioned(
          top: 76,
          right: 12,
          child: Column(
            children: [
              _mapAction(
                Icons.my_location_rounded,
                _locateVisitor,
                tooltip: 'Center on my live location',
                loading: _gpsLoading,
              ),
              if (image.isNotEmpty) ...[
                const SizedBox(height: 8),
                _mapAction(
                  _showLayout ? Icons.map_rounded : Icons.image_outlined,
                  () => setState(() => _showLayout = !_showLayout),
                  tooltip: _showLayout ? 'Show live map' : 'Show park layout',
                ),
              ],
              if (widget.config['slug'] == 'bengaluru') ...[
                const SizedBox(height: 8),
                _mapAction(
                  Icons.directions_walk_rounded,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ParkMapScreen()),
                  ),
                  tooltip: 'Open walking directions map',
                ),
              ],
            ],
          ),
        ),
        if (_routing)
          const Positioned(
            top: 70,
            left: 12,
            right: 12,
            child: LinearProgressIndicator(color: _mapNavy, minHeight: 3),
          ),
        if (_routeError != null)
          Positioned(
            top: 82,
            left: 0,
            right: 58,
            child: _routeNotice(_routeError!),
          )
        else if (_locationMessage != null && !_gpsLoading)
          Positioned(top: 82, left: 0, right: 58, child: _locationBanner()),
        if (_route != null)
          Positioned(left: 12, bottom: 12, child: _routeSummary(_route!)),
      ],
    ),
  );

  Widget _mapAction(
    IconData icon,
    VoidCallback action, {
    required String tooltip,
    bool loading = false,
  }) => Material(
    color: Colors.white,
    elevation: 4,
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      onPressed: loading ? null : action,
      icon: loading
          ? const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, color: _mapNavy),
    ),
  );

  Widget _routeSummary(WalkingRoute route) {
    final distance = _formatDistance(route.distanceMeters);
    final minutes = (route.durationSeconds / 60).ceil();
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_walk_rounded,
              color: _mapNavy,
              size: 18,
            ),
            const SizedBox(width: 7),
            Text(
              '$distance · about $minutes min',
              style: const TextStyle(
                color: _mapInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveMap(List<Map<String, dynamic>> places) {
    final initialCenter = _center;
    if (initialCenter == null) return _noCoordinates();
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 16,
        onMapReady: () {
          _mapReady = true;
          final route = _route;
          if (route != null) {
            _fitRoute(route);
          } else if (_visitorPosition case final position?) {
            _controller.move(position, 17);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'maps_wonderla_flutter',
        ),
        if (_route case final route?)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route.points,
                color: wonderlaBlue,
                strokeWidth: 8,
                borderColor: Colors.white,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (final place in places)
              if (_placePosition(place) case final point?)
                Marker(
                  point: point,
                  width: 46,
                  height: 54,
                  child: _placePin(place),
                ),
            if (_visitorPosition case final point? when _isNearPark(point))
              Marker(
                point: point,
                width: 40,
                height: 40,
                child: _userLocationMarker(),
              ),
          ],
        ),
        RichAttributionWidget(
          attributions: const [
            TextSourceAttribution('© OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }

  Widget _placePin(Map<String, dynamic> place) {
    final selected = _selected?['name'] == place['name'];
    return GestureDetector(
      onTap: () => _focusPlace(place),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: selected ? 38 : 34,
            height: selected ? 38 : 34,
            decoration: BoxDecoration(
              color: selected ? wonderlaGold : _mapNavy,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x44071a3d), blurRadius: 7),
              ],
            ),
            child: Icon(
              _placeIcon(place['category']?.toString()),
              color: selected ? wonderlaNavy : Colors.white,
              size: 18,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: _mapNavy, size: 18),
        ],
      ),
    );
  }

  Widget _userLocationMarker() => Stack(
    alignment: Alignment.center,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _mapNavy.withValues(alpha: .2),
          shape: BoxShape.circle,
        ),
      ),
      Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: wonderlaBlue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x44071a3d), blurRadius: 7)],
        ),
      ),
    ],
  );

  IconData _placeIcon(String? category) {
    final value = (category ?? '').toLowerCase();
    if (value.contains('food') ||
        value.contains('restaurant') ||
        value.contains('shop')) {
      return Icons.restaurant_rounded;
    }
    if (value.contains('facility') ||
        value.contains('first aid') ||
        value.contains('toilet')) {
      return Icons.local_hospital_outlined;
    }
    if (value.contains('entrance')) return Icons.login_rounded;
    return Icons.attractions_rounded;
  }

  Widget _layoutMap(String image, List<Map<String, dynamic>> places) =>
      InteractiveViewer(
        minScale: .8,
        maxScale: 4,
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  image,
                  fit: BoxFit.fill,
                  errorBuilder: (_, _, _) => _noLayout(),
                ),
                for (final place in places)
                  _layoutPin(
                    place,
                    constraints.maxWidth,
                    constraints.maxHeight,
                  ),
              ],
            ),
          ),
        ),
      );
  Widget _layoutPin(Map<String, dynamic> place, double width, double height) {
    final x = (double.tryParse('${place['x']}') ?? 50).clamp(0, 100);
    final y = (double.tryParse('${place['y']}') ?? 50).clamp(0, 100);
    final selected = _selected?['name'] == place['name'];
    return Positioned(
      left: width * x / 100 - 16,
      top: height * y / 100 - 18,
      child: GestureDetector(
        onTap: () => _focusPlace(place),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: selected ? wonderlaGold : _mapNavy,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x44071a3d), blurRadius: 7),
            ],
          ),
          child: Icon(
            _placeIcon(place['category']?.toString()),
            color: selected ? wonderlaNavy : Colors.white,
            size: 17,
          ),
        ),
      ),
    );
  }

  Widget _placeTray(List<Map<String, dynamic>> places) {
    final query = _searchController.text.trim().toLowerCase();
    final visiblePlaces = query.isEmpty
        ? places
        : places
              .where((place) {
                final name = place['name']?.toString().toLowerCase() ?? '';
                final category =
                    place['category']?.toString().toLowerCase() ?? '';
                return name.contains(query) || category.contains(query);
              })
              .toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: wonderlaBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12071a3d),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        query.isEmpty ? 'Explore this park' : 'Search results',
                        style: const TextStyle(
                          color: _mapInk,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${visiblePlaces.length} ${visiblePlaces.length == 1 ? 'place' : 'places'} available',
                        style: const TextStyle(
                          color: wonderlaMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _locationStatus(),
              ],
            ),
          ),
          if (_selected != null) _placeInfo(_selected!),
          Expanded(
            child: _route != null
                ? _directionsPanel(_route!)
                : visiblePlaces.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        query.isEmpty
                            ? 'No park locations are available yet.'
                            : 'No places match “${_searchController.text.trim()}”.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: wonderlaMuted),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                    itemCount: visiblePlaces.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) =>
                        _placeListRow(visiblePlaces[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _locationStatus() {
    final live = _visitorPosition != null;
    final outsidePark =
        _locationMessage?.contains('outside the park area') ?? false;
    final color = _gpsLoading
        ? wonderlaWarning
        : live
        ? wonderlaSuccess
        : wonderlaMuted;
    final label = _gpsLoading
        ? 'Locating'
        : live
        ? 'Live GPS'
        : outsidePark
        ? 'Park map'
        : 'GPS off';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_gpsLoading)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(Icons.my_location_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeListRow(Map<String, dynamic> place) {
    final selected = _selected?['name'] == place['name'];
    final distance = _distanceToVisitor(place);
    return Material(
      color: selected ? const Color(0xfff2f6ff) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _focusPlace(place),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: wonderlaCream,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _placeIcon(place['category']?.toString()),
                  color: _mapNavy,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place['name']?.toString() ?? 'Park place',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mapInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        place['category']?.toString() ?? 'Park place',
                        ?distance,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: wonderlaMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_routing && selected)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.directions_walk_rounded,
                  color: selected ? _mapNavy : wonderlaMuted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _distanceToVisitor(Map<String, dynamic> place) {
    final from = _visitorPosition;
    final to = _placePosition(place);
    if (from == null || to == null) return null;
    final meters = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    return '${_formatDistance(meters)} away';
  }

  Widget _searchBox() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
    child: TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search rides, shops, restaurants…',
        prefixIcon: const Icon(Icons.search_rounded, color: _mapNavy),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: wonderlaNavy),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: _mapNavy, width: 1.5),
        ),
      ),
    ),
  );

  Widget _directionsPanel(WalkingRoute route) {
    final distance = _formatDistance(route.distanceMeters);
    final minutes = (route.durationSeconds / 60).ceil();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 0, 8),
          child: Row(
            children: [
              const Icon(Icons.directions_walk_rounded, color: _mapNavy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$distance · about $minutes min walk',
                  style: const TextStyle(
                    color: _mapInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Clear directions',
                onPressed: () => setState(() {
                  _route = null;
                  _selected = null;
                  _routeError = null;
                }),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        for (var index = 0; index < route.steps.length; index++)
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding: const EdgeInsets.symmetric(horizontal: 2),
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: wonderlaCream,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: _mapNavy,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(
              route.steps[index].instruction,
              style: const TextStyle(fontSize: 13, color: _mapInk),
            ),
            trailing: Text(
              _formatDistance(route.steps[index].distanceMeters),
              style: const TextStyle(fontSize: 11, color: wonderlaMuted),
            ),
          ),
      ],
    );
  }

  String _formatDistance(double meters) => meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(1)} km'
      : '${meters.round()} m';

  Widget _routeNotice(String message) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: wonderlaWhite,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: wonderlaNavy, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: wonderlaNavy, fontSize: 12),
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _routeError = null),
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    ),
  );

  Widget _placeInfo(Map<String, dynamic> place) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: _mapNavy,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        const Icon(Icons.place, color: Colors.white, size: 24),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                place['name']?.toString() ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                [
                  place['category'],
                  if (place['lat'] != null && place['lng'] != null)
                    '${place['lat']}, ${place['lng']}',
                ].whereType<Object>().map((e) => e.toString()).join(' · '),
                style: const TextStyle(color: wonderlaWhite, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _selected = null),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    ),
  );

  Widget _locationBanner() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    color: wonderlaWhite,
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: wonderlaNavy, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _visitorPosition == null
                ? 'The park map is open. ${_locationMessage ?? 'Allow location access to show your live position and get directions.'}'
                : _locationMessage ?? 'Live location is unavailable.',
            style: const TextStyle(color: wonderlaNavy, fontSize: 12),
          ),
        ),
      ],
    ),
  );
  Widget _noCoordinates() => Container(
    color: wonderlaWhite,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_searching, color: _mapNavy, size: 44),
            const SizedBox(height: 10),
            Text(
              _gpsLoading
                  ? 'Finding your location…'
                  : 'Map coordinates are needed',
              style: const TextStyle(
                color: _mapInk,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Set the park latitude and longitude in CMS, or allow location access.',
              textAlign: TextAlign.center,
              style: TextStyle(color: wonderlaNavy),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _noLayout() =>
      const Center(child: Text('Park layout image could not load.'));
}
