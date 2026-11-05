import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../park_map/park_map_screen.dart';
import '../park_map/models/map_place.dart';
import '../park_map/services/location_service.dart';
import '../park_map/services/open_street_map_service.dart';
import '../../shared/wonderla_palette.dart';

const _mapBlue = wonderlaCobalt;
const _mapInk = wonderlaNavy;
const _mapCanvas = wonderlaWhite;

/// Park specific map. It uses the visitor GPS position as the initial focus,
/// then displays only the coordinates managed for this park in the CMS.
class ConfiguredParkMapScreen extends StatefulWidget {
  const ConfiguredParkMapScreen({
    super.key,
    required this.config,
    required this.baseUrl,
  });
  final Map<String, dynamic> config;
  final String baseUrl;

  @override
  State<ConfiguredParkMapScreen> createState() =>
      _ConfiguredParkMapScreenState();
}

class _ConfiguredParkMapScreenState extends State<ConfiguredParkMapScreen> {
  final _controller = MapController();
  final _location = LocationService();
  final _routingService = OpenStreetMapService();
  final _searchController = TextEditingController();
  LatLng? _center;
  LatLng? _visitorPosition;
  Map<String, dynamic>? _selected;
  WalkingRoute? _route;
  bool _gpsLoading = true;
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

  LatLng? _placePosition(Map<String, dynamic> place) {
    final lat = double.tryParse('${place['lat']}');
    final lng = double.tryParse('${place['lng']}');
    if (lat == null ||
        lng == null ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      return null;
    }
    return LatLng(lat, lng);
  }

  LatLng? get _configuredCenter {
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
    return null;
  }

  @override
  void initState() {
    super.initState();
    _center = _configuredCenter;
    _locateVisitor();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _routingService.dispose();
    super.dispose();
  }

  Future<void> _locateVisitor() async {
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
        _center = _visitorPosition;
      }
    });
    if (position != null && _mapReady) {
      _controller.move(LatLng(position.latitude, position.longitude), 17);
    }
  }

  void _focusPlace(Map<String, dynamic> place) {
    final position = _placePosition(place);
    setState(() {
      _selected = place;
      _route = null;
      _routeError = null;
      _showLayout = false;
    });
    if (position != null && _mapReady) _controller.move(position, 18);
    _requestDirections(place);
  }

  List<Map<String, dynamic>> get _searchResults {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return _places
        .where((place) {
          final name = place['name']?.toString().toLowerCase() ?? '';
          final category = place['category']?.toString().toLowerCase() ?? '';
          return name.contains(query) || category.contains(query);
        })
        .take(6)
        .toList(growable: false);
  }

  Future<void> _requestDirections(Map<String, dynamic> place) async {
    final destination = _placePosition(place);
    if (destination == null) {
      setState(
        () => _routeError = 'Add this place’s latitude and longitude in the CMS to get directions.',
      );
      return;
    }
    if (_visitorPosition == null) {
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
        _controller.fitCamera(
          CameraFit.coordinates(
            coordinates: route.points,
            padding: const EdgeInsets.fromLTRB(52, 80, 52, 72),
            maxZoom: 18,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _routing = false;
        _routeError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final places = _places;
    final image = _imageUrl(_map['img']?.toString());
    return Scaffold(
      backgroundColor: _mapCanvas,
      appBar: AppBar(
        backgroundColor: _mapBlue,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.config['name'] ?? 'Park'} map',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          if (image.isNotEmpty)
            IconButton(
              tooltip: _showLayout ? 'Show live map' : 'Show park layout',
              onPressed: () => setState(() => _showLayout = !_showLayout),
              icon: Icon(
                _showLayout ? Icons.map_outlined : Icons.image_outlined,
              ),
            ),
          IconButton(
            tooltip: _gpsLoading
                ? 'Finding your location'
                : 'Center on my location',
            onPressed: _gpsLoading ? null : _locateVisitor,
            icon: _gpsLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.my_location_rounded),
          ),
          if (widget.config['slug'] == 'bengaluru')
            IconButton(
              tooltip: 'Open walking directions map',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ParkMapScreen()),
              ),
              icon: const Icon(Icons.directions_walk_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_locationMessage != null && !_gpsLoading) _locationBanner(),
          _searchBox(),
          if (_searchController.text.trim().isNotEmpty) _searchSuggestions(),
          if (_routeError != null) _routeNotice(_routeError!),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _showLayout
                    ? _layoutMap(image, places)
                    : _liveMap(places),
              ),
            ),
          ),
          if (_routing)
            const LinearProgressIndicator(color: _mapBlue, minHeight: 3),
          if (_selected != null) _placeInfo(_selected!),
          if (_route != null) _directionsPanel(_route!),
          _placeTray(places),
        ],
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
          final pos = _visitorPosition;
          if (pos != null) _controller.move(pos, 17);
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
                color: wonderlaCobalt,
                strokeWidth: 7,
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
            if (_visitorPosition case final point?)
              Marker(
                point: point,
                width: 28,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: wonderlaCobalt,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [
                      BoxShadow(color: Color(0x44071a3d), blurRadius: 8),
                    ],
                  ),
                ),
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
              color: selected ? wonderlaCobalt : _mapBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x44071a3d), blurRadius: 7),
              ],
            ),
            child: Icon(
              _placeIcon(place['category']?.toString()),
              color: selected ? _mapInk : Colors.white,
              size: 18,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: _mapBlue, size: 18),
        ],
      ),
    );
  }

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
        onTap: () => setState(() => _selected = place),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: selected ? wonderlaCobalt : _mapBlue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x44071a3d), blurRadius: 7),
            ],
          ),
          child: Icon(
            _placeIcon(place['category']?.toString()),
            color: selected ? _mapInk : Colors.white,
            size: 17,
          ),
        ),
      ),
    );
  }

  Widget _placeTray(List<Map<String, dynamic>> places) => Container(
    height: 124,
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 2),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'PLACES IN THIS PARK',
                  style: TextStyle(
                    color: _mapInk,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),
              if (_gpsLoading)
                const Text(
                  'Finding you…',
                  style: TextStyle(color: wonderlaNavy, fontSize: 12),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              for (final place in places)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ActionChip(
                    avatar: const Icon(Icons.place, color: _mapBlue, size: 18),
                    label: Text(place['name']?.toString() ?? ''),
                    onPressed: () => _focusPlace(place),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _searchBox() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
    child: TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search rides, shops, restaurants…',
        prefixIcon: const Icon(Icons.search_rounded, color: _mapBlue),
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
          borderSide: const BorderSide(color: wonderlaCobalt),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: _mapBlue, width: 1.5),
        ),
      ),
    ),
  );

  Widget _searchSuggestions() {
    final results = _searchResults;
    return Container(
      constraints: const BoxConstraints(maxHeight: 190),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1a071a3d),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: results.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'No matching places in this park yet.',
                style: TextStyle(color: wonderlaNavy),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              itemCount: results.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 52),
              itemBuilder: (context, index) {
                final place = results[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: wonderlaWhite,
                    child: Icon(
                      _placeIcon(place['category']?.toString()),
                      color: _mapBlue,
                      size: 19,
                    ),
                  ),
                  title: Text(
                    place['name']?.toString() ?? '',
                    style: const TextStyle(
                      color: _mapInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(place['category']?.toString() ?? 'Park place'),
                  trailing: const Icon(
                    Icons.directions_walk_rounded,
                    color: _mapBlue,
                  ),
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    _focusPlace(place);
                  },
                );
              },
            ),
    );
  }

  Widget _directionsPanel(WalkingRoute route) {
    final distance = route.distanceMeters >= 1000
        ? '${(route.distanceMeters / 1000).toStringAsFixed(1)} km'
        : '${route.distanceMeters.round()} m';
    final minutes = (route.durationSeconds / 60).ceil();
    return Container(
      height: 170,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14071a3d),
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_walk_rounded, color: _mapBlue),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '$distance  ·  about $minutes min walk',
                  style: const TextStyle(
                    color: _mapInk,
                    fontWeight: FontWeight.w900,
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
          Expanded(
            child: ListView.builder(
              itemCount: route.steps.length,
              itemBuilder: (context, index) => ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 13,
                  backgroundColor: wonderlaWhite,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: _mapBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: Text(
                  route.steps[index].instruction,
                  style: const TextStyle(fontSize: 13, color: _mapInk),
                ),
                trailing: Text(
                  _formatDistance(route.steps[index].distanceMeters),
                  style: const TextStyle(fontSize: 11, color: wonderlaNavy),
                ),
              ),
            ),
          ),
        ],
      ),
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
      color: _mapBlue,
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
            _center == null
                ? 'Location unavailable. Add this park’s coordinates in CMS to show its map.'
                : 'Showing the park map. ${_locationMessage ?? 'Turn on location to center the map on you.'}',
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
            const Icon(Icons.location_searching, color: _mapBlue, size: 44),
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
