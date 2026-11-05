import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'models/map_place.dart';
import 'models/park_map_config.dart';
import 'models/wonderla_location_catalog.dart';
import 'services/location_service.dart';
import 'services/open_street_map_service.dart';

class ParkMapScreen extends StatefulWidget {
  const ParkMapScreen({super.key});

  @override
  State<ParkMapScreen> createState() => _ParkMapScreenState();
}

class _ParkMapScreenState extends State<ParkMapScreen> {
  static const _park = LatLng(
    wonderlaBengaluruLatitude,
    wonderlaBengaluruLongitude,
  );
  static const _green = Color(0xff1268c4);
  static const _ink = Color(0xff173b68);
  static const _wonderlaYellow = Color(0xffffd43b);

  final _map = MapController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _location = LocationService();
  final _osm = OpenStreetMapService();
  StreamSubscription<Position>? _positionSubscription;

  Position? _position;
  List<MapPlace> _places = [...wonderlaFeaturedLocations];
  List<MapPlace> _searchResults = [];
  MapPlace? _selected;
  WalkingRoute? _route;
  PlaceCategory? _category;
  bool _loadingPlaces = true;
  bool _locating = false;
  bool _routing = false;
  bool _tileFailed = false;
  bool _searching = false;
  bool _isMapExpanded = false;
  int _tileRevision = 0;
  int _routeRequestId = 0;
  int _searchRequestId = 0;
  String? _placesError;
  String? _locationError;
  String? _routeError;
  String? _searchError;
  Future<void>? _locationTask;
  DateTime? _lastAutomaticReroute;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocusChanged);
    _loadParkPlaces();
    _locateUser(follow: false);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    _osm.dispose();
    super.dispose();
  }

  Future<void> _loadParkPlaces() async {
    setState(() {
      _loadingPlaces = true;
      _placesError = null;
    });
    try {
      final places = await _osm.loadParkPlaces(center: _park);
      if (!mounted) return;
      final byId = {for (final place in places) place.id: place};
      final featured = wonderlaFeaturedLocations.map(
        (place) => byId.remove(place.id) ?? place,
      );
      setState(() {
        _places = [...featured, ...byId.values];
        _loadingPlaces = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _placesError = 'In-park locations could not load. Check your connection and retry.';
        _loadingPlaces = false;
      });
    }
  }

  Future<void> _locateUser({bool follow = true}) async {
    final pending = _locationTask;
    if (pending != null) {
      await pending;
      if (follow) _centerOnUser();
      return;
    }

    late final Future<void> task;
    task = _fetchLocation().whenComplete(() {
      if (identical(_locationTask, task)) _locationTask = null;
    });
    _locationTask = task;
    await task;
    if (follow) _centerOnUser();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    final result = await _location.currentPosition();
    if (!mounted) return;
    if (result.position == null) {
      setState(() {
        _locating = false;
        _locationError = result.message;
      });
      return;
    }

    setState(() {
      _position = result.position;
      _locating = false;
      _locationError = null;
    });
    _positionSubscription ??= _location.watchPosition().listen(
      (position) {
        if (!mounted) return;
        setState(() => _position = position);
        _checkForReroute(position);
      },
      onError: (_) {
        if (mounted) {
          setState(() => _locationError = 'Live location updates stopped.');
        }
      },
    );
  }

  void _centerOnUser() {
    final position = _position;
    if (position == null) return;
    _map.move(LatLng(position.latitude, position.longitude), 17);
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  void _checkForReroute(Position position) {
    final route = _route;
    final destination = _selected;
    if (route == null ||
        destination == null ||
        _routing ||
        position.accuracy > 50) {
      return;
    }

    final nearestDistance = _distanceFromRoute(position, route.points);
    final deviationLimit = math.max(50.0, position.accuracy * 1.5 + 10);
    if (nearestDistance < deviationLimit) return;
    final lastReroute = _lastAutomaticReroute;
    if (lastReroute != null &&
        DateTime.now().difference(lastReroute) < const Duration(seconds: 15)) {
      return;
    }
    _lastAutomaticReroute = DateTime.now();
    _requestRoute(
      from: LatLng(position.latitude, position.longitude),
      to: destination,
    );
  }

  double _distanceFromRoute(Position position, List<LatLng> points) {
    if (points.isEmpty) return double.infinity;
    if (points.length == 1) {
      return Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        points.first.latitude,
        points.first.longitude,
      );
    }

    const metersPerDegree = 111320.0;
    final longitudeScale =
        metersPerDegree * math.cos(position.latitude * math.pi / 180);
    var nearestDistanceSquared = double.infinity;
    for (var i = 0; i < points.length - 1; i++) {
      final first = points[i];
      final second = points[i + 1];
      final ax = (first.longitude - position.longitude) * longitudeScale;
      final ay = (first.latitude - position.latitude) * metersPerDegree;
      final bx = (second.longitude - position.longitude) * longitudeScale;
      final by = (second.latitude - position.latitude) * metersPerDegree;
      final dx = bx - ax;
      final dy = by - ay;
      final lengthSquared = dx * dx + dy * dy;
      final projection = lengthSquared == 0
          ? 0.0
          : (-(ax * dx + ay * dy) / lengthSquared).clamp(0.0, 1.0);
      final nearestX = ax + projection * dx;
      final nearestY = ay + projection * dy;
      final distanceSquared = nearestX * nearestX + nearestY * nearestY;
      if (distanceSquared < nearestDistanceSquared) {
        nearestDistanceSquared = distanceSquared;
      }
    }
    return math.sqrt(nearestDistanceSquared);
  }

  List<MapPlace> get _visiblePlaces {
    final query = _search.text.trim().toLowerCase();
    final unique = <String, MapPlace>{};
    for (final place in [..._places, ..._searchResults]) {
      unique.putIfAbsent(place.name.trim().toLowerCase(), () => place);
    }
    return unique.values
        .where((place) {
          final matchesCategory =
              _category == null || place.category == _category;
          final matchesSearch =
              query.isEmpty ||
              '${place.name} ${place.kind}'.toLowerCase().contains(query);
          return matchesCategory && matchesSearch;
        })
        .toList(growable: false);
  }

  Future<void> _submitSearch(String value) async {
    final query = value.trim();
    if (query.isEmpty || _searching) return;
    final requestId = ++_searchRequestId;
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _searchError = null;
      _searchResults = [];
    });
    try {
      final results = await _osm.searchParkPlaces(query: query, near: _park);
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _searching = false;
        _searchError =
            'Could not search right now. Check your connection and retry.';
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchRequestId++;
    setState(() {
      _searchResults = [];
      _searchError = null;
      _searching = false;
    });
  }

  void _select(MapPlace place) {
    _searchFocus.unfocus();
    _routeRequestId++;
    _lastAutomaticReroute = null;
    setState(() {
      _selected = place;
      _route = null;
      _routeError = null;
      _routing = false;
    });
    _map.move(place.position, 18);
  }

  void _clearDestination() {
    _routeRequestId++;
    _lastAutomaticReroute = null;
    setState(() {
      _selected = null;
      _route = null;
      _routeError = null;
      _routing = false;
    });
    _map.move(_park, 16.5);
  }

  Future<void> _directionsTo(MapPlace place) async {
    _select(place);
    await _showRoute();
  }

  Future<void> _showRoute() async {
    final destination = _selected;
    if (destination == null || _routing) return;
    if (_position == null) {
      await _locateUser(follow: false);
      if (_position == null) {
        if (mounted) {
          setState(() {
            _routeError =
                _locationError ?? 'Enable location to get directions.';
          });
        }
        return;
      }
    }

    final position = _position!;
    await _requestRoute(
      from: LatLng(position.latitude, position.longitude),
      to: destination,
    );
  }

  Future<void> _requestRoute({
    required LatLng from,
    required MapPlace to,
  }) async {
    if (_routing) return;
    final requestId = ++_routeRequestId;
    setState(() {
      _routing = true;
      _route = null;
      _routeError = null;
    });
    try {
      final route = await _osm.findWalkingRoute(from: from, to: to.position);
      if (!mounted || requestId != _routeRequestId) return;
      setState(() {
        _route = route;
        _routing = false;
        _routeError = null;
      });
      if (route.points.isNotEmpty) {
        _map.fitCamera(
          CameraFit.coordinates(
            coordinates: route.points,
            padding: const EdgeInsets.all(24),
            maxZoom: 18.5,
          ),
        );
      }
    } catch (_) {
      if (!mounted || requestId != _routeRequestId) return;
      setState(() {
        _routing = false;
        _routeError =
            'Route updated unsuccessfully. Check signal and try again.';
      });
    }
  }

  double? _distanceTo(MapPlace place) {
    final position = _position;
    if (position == null) return null;
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      place.position.latitude,
      place.position.longitude,
    );
  }

  String _distanceLabel(double meters) => meters < 1000
      ? '${meters.round()} m'
      : '${(meters / 1000).toStringAsFixed(1)} km';

  void _onTileError(TileImage tile, Object error, StackTrace? stackTrace) {
    if (mounted && !_tileFailed) setState(() => _tileFailed = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f6f3),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (_isMapExpanded) {
              return SizedBox.expand(child: _mapPanel(expanded: true));
            }
            final landscape = constraints.maxWidth > 700;
            if (landscape) {
              return Row(
                children: [
                  Expanded(flex: 11, child: _mapPanel()),
                  Expanded(flex: 10, child: _locationsPanel()),
                ],
              );
            }
            final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
            final mapHeight = keyboardVisible
                ? (constraints.maxHeight * .20).clamp(80.0, 140.0)
                : (constraints.maxHeight * .46).clamp(280.0, 460.0);
            return Column(
              children: [
                SizedBox(height: mapHeight, child: _mapPanel()),
                Expanded(child: _locationsPanel()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _mapPanel({bool expanded = false}) => ClipRRect(
    borderRadius: expanded
        ? BorderRadius.zero
        : const BorderRadius.vertical(bottom: Radius.circular(26)),
    child: Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _map,
          options: const MapOptions(
            initialCenter: _park,
            initialZoom: 16.5,
            minZoom: 16,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              key: ValueKey(_tileRevision),
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'maps_wonderla_flutter',
              maxNativeZoom: 19,
              errorTileCallback: _onTileError,
            ),
            if (_route != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _route!.points,
                    strokeWidth: 6,
                    color: const Color(0xff2488ec),
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                ..._visiblePlaces.map(
                  (place) => Marker(
                    point: place.position,
                    width: 58,
                    height: 68,
                    child: _PlacePin(
                      place: place,
                      selected: place.id == _selected?.id,
                      onTap: () => _select(place),
                    ),
                  ),
                ),
                if (_selected != null &&
                    !_visiblePlaces.any((place) => place.id == _selected!.id))
                  Marker(
                    point: _selected!.position,
                    width: 58,
                    height: 68,
                    child: _PlacePin(
                      place: _selected!,
                      selected: true,
                      onTap: () => _select(_selected!),
                    ),
                  ),
                if (_position != null)
                  Marker(
                    point: LatLng(_position!.latitude, _position!.longitude),
                    width: 40,
                    height: 40,
                    child: const _UserLocationMarker(),
                  ),
              ],
            ),
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomRight,
              showFlutterMapAttribution: false,
              attributions: const [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          top: 14,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Expanded(child: _mapSearch()),
              const SizedBox(width: 10),
              _mapAction(
                Icons.my_location_rounded,
                _locateUser,
                loading: _locating,
                tooltip: 'Show my live location',
              ),
              const SizedBox(width: 8),
              _mapAction(
                expanded
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
                () => setState(() => _isMapExpanded = !_isMapExpanded),
                tooltip: expanded ? 'Show locations list' : 'Expand map',
              ),
            ],
          ),
        ),
        if (_tileFailed)
          Positioned(left: 12, right: 12, bottom: 28, child: _tileNotice()),
        if (_locationError != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 28,
            child: _inlineNotice(_locationError!, Icons.my_location_rounded),
          ),
        if (_route != null)
          Positioned(left: 16, bottom: 28, child: _routeSummary()),
        if (_routing)
          Positioned(
            left: 14,
            bottom: 28,
            child: Material(
              color: Colors.white,
              elevation: 4,
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Updating route from your location…',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _mapSearch() => Material(
    color: Colors.white,
    elevation: 5,
    borderRadius: BorderRadius.circular(16),
    child: TextField(
      controller: _search,
      focusNode: _searchFocus,
      onChanged: _onSearchChanged,
      onSubmitted: _submitSearch,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search rides, food, facilities…',
        prefixIcon: const Icon(Icons.search_rounded, color: _green),
        suffixIcon: _searching
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _search.text.isEmpty
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Search nearby locations',
                    onPressed: () => _submitSearch(_search.text),
                    icon: const Icon(Icons.search_rounded, color: _green),
                  ),
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _search.clear();
                      _onSearchChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _mapAction(
    IconData icon,
    VoidCallback action, {
    bool loading = false,
    required String tooltip,
  }) => Material(
    color: Colors.white,
    elevation: 5,
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      onPressed: loading ? null : action,
      icon: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, color: _green),
    ),
  );

  Widget _locationsPanel() {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _search.text.trim().isEmpty
                      ? 'Explore Wonderla'
                      : 'Search results',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              if (_selected != null)
                IconButton(
                  tooltip: 'Clear selected destination',
                  onPressed: _clearDestination,
                  icon: const Icon(Icons.close_rounded, color: _green),
                )
              else if (_loadingPlaces)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  tooltip: 'Refresh park locations',
                  onPressed: _loadParkPlaces,
                  icon: const Icon(Icons.refresh_rounded, color: _green),
                ),
            ],
          ),
          if (!keyboardVisible) ...[_categoryFilters()],
          if (_routeError != null) ...[
            const SizedBox(height: 8),
            _inlineNotice(_routeError!, Icons.directions_walk_rounded),
          ],
          SizedBox(height: keyboardVisible ? 4 : 8),
          Expanded(child: _placesContent()),
        ],
      ),
    );
  }

  Widget _categoryFilters() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _categoryChip('All', null, Icons.grid_view_rounded),
        _categoryChip(
          'Rides',
          PlaceCategory.attraction,
          Icons.attractions_rounded,
        ),
        _categoryChip('Food', PlaceCategory.food, Icons.restaurant_rounded),
        _categoryChip('Facilities', PlaceCategory.facility, Icons.wc_rounded),
      ],
    ),
  );

  Widget _categoryChip(String label, PlaceCategory? value, IconData icon) {
    final selected = value == _category;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _category = value),
        avatar: Icon(
          icon,
          size: 19,
          color: selected ? _wonderlaYellow : _green,
        ),
        label: Text(label),
        showCheckmark: false,
        selectedColor: _green,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : _ink,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    );
  }

  Widget _placesContent() {
    if (_loadingPlaces && _places.isEmpty && _search.text.trim().isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _green),
            SizedBox(height: 12),
            Text(
              'Loading locations inside the park…',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }
    if (_placesError != null &&
        _places.isEmpty &&
        _search.text.trim().isEmpty) {
      return _emptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Park locations are unavailable',
        message: _placesError!,
        action: 'Try again',
        onAction: _loadParkPlaces,
      );
    }
    final places = _visiblePlaces;
    if (_searching && places.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _green),
            SizedBox(height: 10),
            Text(
              'Searching nearby locations…',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }
    if (places.isEmpty) {
      return _emptyState(
        icon: _search.text.isEmpty
            ? Icons.map_outlined
            : Icons.search_off_rounded,
        title: _search.text.isEmpty
            ? 'No mapped places inside the park yet'
            : 'No matching places',
        message: _search.text.isEmpty
            ? 'Only locations mapped inside Wonderla are shown here. Individual rides may not be available in OpenStreetMap yet.'
            : _searchError ?? 'Try another name or search nearby locations.',
        action: _search.text.trim().isNotEmpty && _searchError == null
            ? 'Search nearby'
            : null,
        onAction: _searchError == null && _search.text.trim().isNotEmpty
            ? () => _submitSearch(_search.text)
            : null,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: places.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(2, 3, 2, 2),
            child: Text(
              _search.text.trim().isNotEmpty || _searchFocus.hasFocus
                  ? 'Suggestions'
                  : 'Locations inside Wonderla',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          );
        }
        return _placeRow(places[index - 1]);
      },
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    String? action,
    VoidCallback? onAction,
  }) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xff789087), size: 36),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(action),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _placeRow(MapPlace place) {
    final isSelected = place.id == _selected?.id;
    final distance = _distanceTo(place);
    return Material(
      color: isSelected ? const Color(0xffe8f2ff) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _directionsTo(place),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xfffff3c4),
                  shape: BoxShape.circle,
                ),
                child: Icon(place.icon, color: _green, size: 26),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${place.kind}${distance == null ? '' : '  ·  ${_distanceLabel(distance)}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Directions to ${place.name}',
                onPressed: _routing ? null : () => _directionsTo(place),
                icon: _routing && isSelected
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.directions_rounded, color: _green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _routeSummary() => Material(
    elevation: 5,
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: _showDirections,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_walk_rounded, color: _green, size: 19),
            const SizedBox(width: 8),
            Text(
              '${_distanceLabel(_route!.distanceMeters)}  ·  ${(_route!.durationSeconds / 60).ceil()} min',
              style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: _green),
          ],
        ),
      ),
    ),
  );

  void _showDirections() {
    final route = _route;
    if (route == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Walking directions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: route.steps.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 66),
                  itemBuilder: (context, index) {
                    final step = route.steps[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xfffff3c4),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(step.instruction),
                      trailing: Text(
                        _distanceLabel(step.distanceMeters),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileNotice() => _inlineNotice(
    'Map tiles could not connect. Check internet or device DNS.',
    Icons.wifi_off_rounded,
    action: TextButton(
      onPressed: () => setState(() {
        _tileFailed = false;
        _tileRevision++;
      }),
      child: const Text('Retry'),
    ),
  );

  Widget _inlineNotice(String text, IconData icon, {Widget? action}) =>
      Material(
        color: const Color(0xfffff8e9),
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xff94621c), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 11))),
              ?action,
            ],
          ),
        ),
      );
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/chikku_happy.png',
    width: 40,
    height: 40,
    fit: BoxFit.contain,
  );
}

class _PlacePin extends StatelessWidget {
  const _PlacePin({
    required this.place,
    required this.selected,
    required this.onTap,
  });

  final MapPlace place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: selected ? 44 : 40,
          height: selected ? 44 : 40,
          decoration: BoxDecoration(
            color: selected
                ? _ParkMapScreenState._green
                : _ParkMapScreenState._wonderlaYellow,
            shape: BoxShape.circle,
            border: Border.all(color: _ParkMapScreenState._green, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
          ),
          child: Icon(
            place.icon,
            size: 22,
            color: selected
                ? _ParkMapScreenState._wonderlaYellow
                : _ParkMapScreenState._green,
          ),
        ),
        Container(width: 3, height: 13, color: _ParkMapScreenState._green),
      ],
    ),
  );
}
