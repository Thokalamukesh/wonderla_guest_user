import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../cms/cms_api.dart';
import 'configured_park_map_screen.dart';
import '../cms/cms_screen.dart';
import '../../shared/scroll_reveal.dart';
import '../../shared/wonderla_palette.dart';

part 'visitor_section_screen.dart';

const _navy = wonderlaNavy;
const _pale = wonderlaCream;
const _white = wonderlaWhite;

class VisitorHome extends StatefulWidget {
  const VisitorHome({super.key, this.initialPark});
  final Map<String, dynamic>? initialPark;
  @override
  State<VisitorHome> createState() => _VisitorHomeState();
}

class _VisitorHomeState extends State<VisitorHome> {
  final _api = CmsApi();
  List<Map<String, dynamic>> _parks = [];
  Map<String, dynamic>? _park;
  bool _loading = true;
  String? _error;

  static const _tiles = <(String, String, IconData, String)>[
    (
      'PARK MAP',
      'Find rides & facilities',
      LucideIcons.mapPinned,
      'exploreParkMapImageUrl',
    ),
    (
      'LIVE WAIT TIMES',
      'See current ride queues',
      LucideIcons.timer,
      'exploreWaitTimesImageUrl',
    ),
    (
      'RIDES & EVENTS',
      'Rides, shows & water activities',
      LucideIcons.ferrisWheel,
      'exploreRidesImageUrl',
    ),
    (
      'DINING & MENU',
      'Food, menus & prices',
      LucideIcons.utensils,
      'exploreDiningImageUrl',
    ),
    (
      'EVENTS',
      'Shows, wave pool & rain dance',
      LucideIcons.calendarDays,
      'exploreRidesImageUrl',
    ),
    (
      'RIDE GUIDELINES',
      'Height limits & rules',
      LucideIcons.ruler,
      'exploreGuidelinesImageUrl',
    ),
    (
      'SAFETY & HYGIENE',
      'Plan a safe visit',
      LucideIcons.shieldCheck,
      'exploreSafetyImageUrl',
    ),
    (
      'MAINTENANCE LOG',
      'Ride service updates',
      LucideIcons.wrench,
      'exploreMaintenanceImageUrl',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPark case final park?) {
      _park = park;
      _parks = [park];
      _loading = false;
    } else {
      _loadInitial();
    }
  }

  String? _requestedSlug() {
    final query = Uri.base.queryParameters['park'];
    if (query != null && query.isNotEmpty) return query;
    final segments = Uri.base.pathSegments;
    final index = segments.indexOf('qr-code');
    if (index >= 0 && index + 1 < segments.length) return segments[index + 1];
    if (segments.length == 1 &&
        segments.first.isNotEmpty &&
        segments.first != 'index.html') {
      return segments.first;
    }
    return null;
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final slug = _requestedSlug();
      if (slug != null) {
        // Shared park links already identify the requested record. Fetching
        // the whole directory first adds an unnecessary network round trip.
        await _loadPark(slug);
      } else {
        _parks = (await _api.parks())
            .where((p) => p['active'] == true)
            .toList();
      }
    } catch (e) {
      _error = _friendlyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadPark(String slug) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.park(slug);
      if (data['active'] == false) {
        throw const CmsApiException(
          'This park guide is not currently available.',
        );
      }
      if (mounted) setState(() => _park = data);
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object error) {
    if (!_api.isConfigured) {
      return 'Set the park guide website URL to connect to park content.';
    }
    return error.toString();
  }

  String _imageUrl(String? value) {
    if (value == null || value.isEmpty) return '';
    if (Uri.tryParse(value)?.hasScheme == true) return value;
    return '${_api.baseUrl}${value.startsWith('/') ? '' : '/'}$value';
  }

  void _openSection(String section) {
    final cfg = _park;
    if (cfg == null) return;
    if (section == 'PARK MAP') {
      _openParkMap(cfg);
      return;
    }
    final title = switch (section) {
      'RIDES & EVENTS' || 'LIVE WAIT TIMES' => 'RIDES & WATER ACTIVITIES',
      _ => section,
    };
    final initialTab = section == 'LIVE WAIT TIMES' ? 'Live wait time' : null;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisitorSectionScreen(
          title: title,
          config: cfg,
          api: _api,
          initialTab: initialTab,
        ),
      ),
    );
  }

  void _openParkMap(Map<String, dynamic> cfg) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ConfiguredParkMapScreen(config: cfg, baseUrl: _api.baseUrl),
      ),
    );
  }

  Widget _tileGrid(
    List<(String, String, IconData, String)> tiles,
    Map<String, dynamic> config, {
    required bool compact,
    required int delayOffset,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width < 720 ? 2 : 4;
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: compact ? 140 : 128,
        crossAxisSpacing: compact ? 8 : 12,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final tile = tiles[index];
        return _ExploreTile(
          title: tile.$1,
          subtitle: tile.$2,
          icon: tile.$3,
          imageUrl: _imageUrl(config[tile.$4]?.toString()),
          delay: (delayOffset + index) * 45,
          compact: compact,
          onTap: () => _openSection(tile.$1),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestedSlug = _requestedSlug();
    if (_loading && requestedSlug != null) {
      return const Scaffold(
        backgroundColor: _pale,
        body: Center(child: CircularProgressIndicator(color: _navy)),
      );
    }
    if (_error != null && requestedSlug != null) {
      return Scaffold(
        backgroundColor: _pale,
        body: SafeArea(
          child: _LoadError(message: _error!, onRetry: _loadInitial),
        ),
      );
    }
    if (_park == null) return _directory();
    final cfg = _park!;
    final compactHome = MediaQuery.sizeOf(context).width < 390;
    final parkName = cfg['name']?.toString() ?? 'Wonderla';
    final heroTitle = parkName.toLowerCase().contains('wonderla')
        ? parkName
        : 'Wonderla $parkName';
    return Scaffold(
      backgroundColor: _pale,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroCard(
                    name: heroTitle,
                    location: cfg['location']?.toString() ?? '',
                    imageUrl: _imageUrl(cfg['heroImageUrl']?.toString()),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        compactHome ? 14 : 22,
                        20,
                        compactHome ? 14 : 22,
                        40,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(26),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Explore Wonderla',
                                  style: TextStyle(
                                    color: _navy,
                                    fontSize: compactHome ? 21 : 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.5,
                                  ),
                                ),
                              ),
                              Text(
                                '4 shortcuts',
                                style: TextStyle(
                                  color: wonderlaMuted,
                                  fontSize: compactHome ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _tileGrid(
                            _tiles.take(4).toList(),
                            cfg,
                            compact: MediaQuery.sizeOf(context).width < 520,
                            delayOffset: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compactHome ? 14 : 22,
                    ),
                    child: _tileGrid(
                      _tiles.skip(4).toList(),
                      cfg,
                      compact: MediaQuery.sizeOf(context).width < 520,
                      delayOffset: 4,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 27, 22, 26),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Have a Wonder-ful day!',
                            style: TextStyle(
                              color: wonderlaMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _directory() => Scaffold(
    backgroundColor: _pale,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 25),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/wonderla_logo.webp',
                        width: 220,
                        height: 85,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'YOUR DAY STARTS HERE',
                        style: TextStyle(
                          color: _navy,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choose your park',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Open your park guide for rides, dining and more.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: wonderlaNavy, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: _parks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final p = _parks[i];
                    return Card(
                      color: _white,
                      elevation: 1,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: wonderlaBorder),
                      ),
                      child: InkWell(
                        onTap: () => _loadPark(p['slug'] as String),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          leading: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: wonderlaWhite,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.park_outlined,
                              color: _navy,
                            ),
                          ),
                          title: Text(
                            p['name']?.toString() ?? '',
                            style: const TextStyle(
                              color: _navy,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(p['location']?.toString() ?? ''),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: _navy,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_loading && _parks.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(color: _navy),
                    ),
                  ),
                )
              else if (_error != null && _parks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
                    child: Column(
                      children: [
                        Text(
                          'We couldn’t load the park list. Check your connection and try again.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _navy),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _loadInitial,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_parks.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No parks are published yet. Please check back soon.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _navy),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CmsScreen()),
                      ),
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Admin'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.name,
    required this.location,
    required this.imageUrl,
  });
  final String name, location, imageUrl;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 560;
      final cardHeight = compact ? 232.0 : 280.0;
      return Container(
        height: cardHeight,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 0 : 26),
          color: wonderlaNavy,
          boxShadow: const [
            BoxShadow(
              color: Color(0x22071a3d),
              blurRadius: 20,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99071a3d),
                    Color(0x16071a3d),
                    Color(0xb8071a3d),
                  ],
                ),
              ),
            ),
            Positioned(
              left: compact ? 20 : 30,
              right: compact ? 20 : 30,
              top: compact ? 22 : 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.1,
                      fontSize: compact ? 25 : 31,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: wonderlaGold,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: wonderlaWhite,
                              fontSize: compact ? 13 : 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.imageUrl,
    required this.delay,
    required this.compact,
    required this.onTap,
  });
  final String title, subtitle;
  final String imageUrl;
  final IconData icon;
  final int delay;
  final bool compact;
  final VoidCallback onTap;

  String _titleCase(String value) => value
      .split(' ')
      .map(
        (word) => word == '&' || word.isEmpty
            ? word
            : '${word[0]}${word.substring(1).toLowerCase()}',
      )
      .join(' ');

  Widget _tileImage({required double iconSize}) {
    Widget fallback() => Container(
      color: const Color(0xffe9efff),
      alignment: Alignment.center,
      child: Icon(icon, color: wonderlaCobalt, size: iconSize),
    );
    if (imageUrl.isEmpty) return fallback();
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback(),
    );
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .96, end: 1),
    duration: Duration(milliseconds: 360 + delay),
    curve: Curves.easeOutCubic,
    builder: (context, value, child) =>
        Transform.scale(scale: value, child: child),
    child: Material(
      color: _white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(compact ? 8 : 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: _tileImage(iconSize: 28),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _titleCase(title),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 12.5,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: wonderlaCobalt,
                          size: 17,
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: _tileImage(iconSize: 27),
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _titleCase(title),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _navy,
                              fontSize: compact ? 13 : 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.15,
                            ),
                          ),
                          SizedBox(height: compact ? 3 : 6),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: wonderlaNavy,
                              fontSize: compact ? 12 : 14,
                              height: 1.3,
                              letterSpacing: .05,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: compact ? 30 : 36,
                      height: compact ? 30 : 36,
                      decoration: BoxDecoration(
                        color: wonderlaCream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: wonderlaCobalt,
                        size: compact ? 16 : 19,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}
