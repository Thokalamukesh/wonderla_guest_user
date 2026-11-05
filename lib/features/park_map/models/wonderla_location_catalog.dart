import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'map_place.dart';

/// Confirmed in-park features and geometry centers from OpenStreetMap.
/// OSM node/way/relation IDs are kept stable so live map data can update these
/// entries when available.
const wonderlaFeaturedLocations = <MapPlace>[
  MapPlace(
    id: 'node-1371763194',
    name: 'Chillies Restaurant',
    position: LatLng(12.8346081, 77.4013064),
    category: PlaceCategory.food,
    kind: 'Restaurant',
    icon: Icons.restaurant_rounded,
  ),
  MapPlace(
    id: 'node-11938901110',
    name: "Greens Restaurant (Veg)",
    position: LatLng(12.8347895, 77.4019356),
    category: PlaceCategory.food,
    kind: 'Vegetarian restaurant',
    icon: Icons.restaurant_rounded,
  ),
  MapPlace(
    id: 'way-1533318789',
    name: 'Multipurpose Hall',
    position: LatLng(12.8341683, 77.4010384),
    category: PlaceCategory.facility,
    kind: 'Event hall',
    icon: Icons.meeting_room_rounded,
  ),
  MapPlace(
    id: 'way-954809065',
    name: 'Wave Pool 1',
    position: LatLng(12.8346540, 77.4000770),
    category: PlaceCategory.attraction,
    kind: 'Wave pool',
    icon: Icons.pool_rounded,
  ),
  MapPlace(
    id: 'way-954810322',
    name: 'Wave Pool 2',
    position: LatLng(12.8347607, 77.4003185),
    category: PlaceCategory.attraction,
    kind: 'Wave pool',
    icon: Icons.pool_rounded,
  ),
  MapPlace(
    id: 'relation-21047672',
    name: 'Lazy River',
    position: LatLng(12.8334050, 77.4000341),
    category: PlaceCategory.attraction,
    kind: 'Lazy river',
    icon: Icons.water_rounded,
  ),
  MapPlace(
    id: 'way-1533885700',
    name: 'Parking',
    position: LatLng(12.8376490, 77.4025038),
    category: PlaceCategory.facility,
    kind: 'Parking area',
    icon: Icons.local_parking_rounded,
  ),
];
