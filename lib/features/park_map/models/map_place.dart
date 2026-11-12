import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum PlaceCategory { attraction, food, facility, stay, other }

class MapPlace {
  const MapPlace({
    required this.id,
    required this.name,
    required this.position,
    required this.category,
    required this.kind,
    required this.icon,
    this.address,
  });

  final String id;
  final String name;
  final LatLng position;
  final PlaceCategory category;
  final String kind;
  final IconData icon;
  final String? address;
}

class RouteStep {
  const RouteStep({required this.instruction, required this.distanceMeters});

  final String instruction;
  final double distanceMeters;
}

enum RouteMode { walking, driving }

class WalkingRoute {
  const WalkingRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.steps,
    this.mode = RouteMode.walking,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteStep> steps;
  final RouteMode mode;
}
