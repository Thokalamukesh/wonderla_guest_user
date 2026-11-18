import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomeShortcutDefinition {
  const HomeShortcutDefinition({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.section,
    this.imageConfigKey,
    this.initialTab,
  });

  final String keyName;
  final String label;
  final IconData icon;
  final String section;
  final String? imageConfigKey;
  final String? initialTab;
}

abstract final class HomeShortcutCatalog {
  static const definitions = <HomeShortcutDefinition>[
    HomeShortcutDefinition(
      keyName: 'parkMap',
      label: 'Park Map',
      icon: LucideIcons.mapPinned,
      imageConfigKey: 'exploreParkMapImageUrl',
      section: 'PARK MAP',
    ),
    HomeShortcutDefinition(
      keyName: 'rides',
      label: 'Rides',
      icon: LucideIcons.ferrisWheel,
      imageConfigKey: 'exploreRidesImageUrl',
      section: 'RIDES & WATER ACTIVITIES',
      initialTab: 'Rides',
    ),
    HomeShortcutDefinition(
      keyName: 'events',
      label: 'Events',
      icon: LucideIcons.calendarDays,
      imageConfigKey: 'exploreEventsImageUrl',
      section: 'EVENTS',
    ),
    HomeShortcutDefinition(
      keyName: 'diningMenu',
      label: 'Dining & Menu',
      icon: LucideIcons.utensils,
      imageConfigKey: 'exploreDiningImageUrl',
      section: 'DINING & MENU',
    ),
    HomeShortcutDefinition(
      keyName: 'liveWaitTimes',
      label: 'Live Wait Times',
      icon: LucideIcons.timer,
      imageConfigKey: 'exploreWaitTimesImageUrl',
      section: 'RIDES & WATER ACTIVITIES',
      initialTab: 'Live wait time',
    ),
    HomeShortcutDefinition(
      keyName: 'rideGuidelines',
      label: 'Ride Guidelines',
      icon: LucideIcons.ruler,
      imageConfigKey: 'exploreGuidelinesImageUrl',
      section: 'RIDE GUIDELINES',
    ),
    HomeShortcutDefinition(
      keyName: 'wavePool',
      label: 'Wave Pool & Rain Dance',
      icon: LucideIcons.waves,
      imageConfigKey: 'exploreWaveImageUrl',
      section: 'RIDES & WATER ACTIVITIES',
      initialTab: 'Water activities',
    ),
    HomeShortcutDefinition(
      keyName: 'safetyHygiene',
      label: 'Safety & Hygiene',
      icon: LucideIcons.shieldCheck,
      imageConfigKey: 'exploreSafetyImageUrl',
      section: 'SAFETY & HYGIENE',
    ),
    HomeShortcutDefinition(
      keyName: 'maintenanceLog',
      label: 'Maintenance Log',
      icon: LucideIcons.wrench,
      imageConfigKey: 'exploreMaintenanceImageUrl',
      section: 'MAINTENANCE LOG',
    ),
  ];

  static const defaultKeys = <String>[
    'parkMap',
    'rides',
    'events',
    'diningMenu',
    'rideGuidelines',
    'safetyHygiene',
    'maintenanceLog',
  ];

  static HomeShortcutDefinition? byKey(String key) {
    for (final definition in definitions) {
      if (definition.keyName == key) return definition;
    }
    return null;
  }
}
