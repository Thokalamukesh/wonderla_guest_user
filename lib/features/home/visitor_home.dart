import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../cms/cms_api.dart';
import 'configured_park_map_screen.dart';
import '../cms/cms_screen.dart';
import '../../shared/scroll_reveal.dart';
import '../../shared/wonderla_palette.dart';

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
      'RIDES & EVENTS',
      'Explore rides and shows',
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
      'LIVE WAIT TIMES',
      'Current ride queues',
      LucideIcons.timer,
      'exploreWaitTimesImageUrl',
    ),
    (
      'RIDE GUIDELINES',
      'Height limits & rules',
      LucideIcons.ruler,
      'exploreGuidelinesImageUrl',
    ),
    (
      'WAVE POOL & RAIN DANCE',
      'Sessions & timings',
      LucideIcons.waves,
      'exploreWaveImageUrl',
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
      _parks = (await _api.parks()).where((p) => p['active'] == true).toList();
      final slug = _requestedSlug();
      if (slug != null) {
        await _loadPark(slug);
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
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ConfiguredParkMapScreen(config: cfg, baseUrl: _api.baseUrl),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            VisitorSectionScreen(title: section, config: cfg, api: _api),
      ),
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
    return Scaffold(
      backgroundColor: _pale,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Spacer(),
                            Image.asset(
                              'assets/images/wonderla_logo.webp',
                              width: 190,
                              height: 62,
                              fit: BoxFit.contain,
                            ),
                            const Spacer(),
                            if (_parks.length > 1)
                              IconButton(
                                tooltip: 'Change park',
                                onPressed: _showParkPicker,
                                icon: const Icon(
                                  Icons.location_on_outlined,
                                  color: _navy,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _HeroCard(
                          name: 'WONDERLA',
                          location:
                              cfg['name']?.toString() ??
                              cfg['location']?.toString() ??
                              '',
                          imageUrl: _imageUrl(cfg['heroImageUrl']?.toString()),
                        ),
                        const SizedBox(height: 28),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'EXPLORE THE PARK',
                            style: TextStyle(
                              color: _navy,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.1,
                              height: .98,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Choose what you want to discover.',
                            style: TextStyle(color: wonderlaNavy, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.crossAxisExtent < 520;
                      final columns = compact ? 2 : 3;
                      return SliverGrid.builder(
                        itemCount: _tiles.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: compact ? 108 : 136,
                          crossAxisSpacing: compact ? 10 : 14,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, i) {
                          final tile = _tiles[i];
                          return _ExploreTile(
                            title: tile.$1,
                            subtitle: tile.$2,
                            icon: tile.$3,
                            imageUrl: _imageUrl(cfg[tile.$4]?.toString()),
                            delay: i * 55,
                            compact: compact,
                            onTap: () => _openSection(tile.$1),
                          );
                        },
                      );
                    },
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
                            style: TextStyle(color: wonderlaNavy),
                          ),
                        ),
                        if (_parks.length > 1)
                          TextButton.icon(
                            onPressed: _showParkPicker,
                            icon: const Icon(Icons.place_outlined, size: 18),
                            label: const Text('Change park'),
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
                        side: const BorderSide(color: wonderlaNavy),
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

  Future<void> _showParkPicker() async {
    final slug = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Choose your park',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            for (final p in _parks)
              ListTile(
                leading: const Icon(Icons.location_on_outlined, color: _navy),
                title: Text(p['name']?.toString() ?? ''),
                subtitle: Text(p['location']?.toString() ?? ''),
                onTap: () => Navigator.pop(ctx, p['slug'] as String),
              ),
          ],
        ),
      ),
    );
    if (slug != null && mounted) await _loadPark(slug);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.name,
    required this.location,
    required this.imageUrl,
  });
  final String name, location, imageUrl;
  @override
  Widget build(BuildContext context) => Container(
    height: 260,
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      color: wonderlaNavy,
      boxShadow: const [
        BoxShadow(
          color: Color(0x22071a3d),
          blurRadius: 23,
          offset: Offset(0, 12),
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
              colors: [Color(0x10071a3d), Color(0xaa071a3d)],
            ),
          ),
        ),
        Positioned(
          right: 28,
          top: 20,
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: .22),
                width: 18,
              ),
            ),
          ),
        ),
        Positioned(
          left: 25,
          right: 20,
          bottom: 27,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: wonderlaFlagRed,
                  border: Border.all(color: wonderlaFlagRed),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'THE FUN STARTS HERE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'WELCOME TO\n${name.toUpperCase()}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.02,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                '📍 $location',
                style: const TextStyle(
                  color: wonderlaWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
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
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .9, end: 1),
    duration: Duration(milliseconds: 360 + delay),
    curve: Curves.easeOutBack,
    builder: (context, value, child) =>
        Transform.scale(scale: value, child: child),
    child: Material(
      color: _white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: EdgeInsets.all(compact ? 8 : 13),
          decoration: BoxDecoration(
            border: Border.all(color: wonderlaCobalt, width: 1.2),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0d071a3d),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(compact ? 14 : 18),
                child: SizedBox(
                  width: compact ? 52 : 68,
                  height: compact ? 52 : 68,
                  child: imageUrl.isEmpty
                      ? Container(
                          color: const Color(0xffe9efff),
                          alignment: Alignment.center,
                          child: Icon(
                            icon,
                            color: wonderlaCobalt,
                            size: compact ? 25 : 30,
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xffe9efff),
                            alignment: Alignment.center,
                            child: Icon(
                              icon,
                              color: wonderlaCobalt,
                              size: compact ? 25 : 30,
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(width: compact ? 8 : 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _navy,
                        fontSize: compact ? 13 : 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.35,
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
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: wonderlaNavy,
                size: compact ? 18 : 24,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class VisitorSectionScreen extends StatefulWidget {
  const VisitorSectionScreen({
    super.key,
    required this.title,
    required this.config,
    required this.api,
  });
  final String title;
  final Map<String, dynamic> config;
  final CmsApi api;
  @override
  State<VisitorSectionScreen> createState() => _VisitorSectionScreenState();
}

class _VisitorSectionScreenState extends State<VisitorSectionScreen> {
  late Map<String, dynamic> _config;
  bool _loading = false;
  String? _error;
  String _rideTab = 'Rides';
  String _menuFilter = 'All';
  @override
  void initState() {
    super.initState();
    _config = Map<String, dynamic>.from(widget.config);
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _config = await widget.api.park(widget.config['slug'] as String);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  String _url(String? value) {
    if (value == null || value.isEmpty) return '';
    if (Uri.tryParse(value)?.hasScheme == true) return value;
    return '${widget.api.baseUrl}${value.startsWith('/') ? '' : '/'}$value';
  }

  List<Map<String, dynamic>> _list(String key) =>
      List<Map<String, dynamic>>.from(
        (_config[key] as List? ?? []).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _pale,
    appBar: AppBar(
      backgroundColor: wonderlaCobalt,
      foregroundColor: Colors.white,
      surfaceTintColor: wonderlaCobalt,
      toolbarHeight: 82,
      title: Text(
        widget.title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
      ),
      actions: ['LIVE WAIT TIMES', 'MAINTENANCE LOG'].contains(widget.title)
          ? [
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ]
          : null,
    ),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          if (_error != null) _notice(_error!, error: true),
          if (_loading) const LinearProgressIndicator(color: _navy),
          ..._content().asMap().entries.map(
            (entry) => ScrollReveal(
              key: ValueKey('${widget.title}-${entry.key}'),
              delay: Duration(milliseconds: entry.key * 45),
              child: entry.value,
            ),
          ),
        ],
      ),
    ),
  );

  List<Widget> _content() => switch (widget.title) {
    'RIDES & EVENTS' => _ridesEvents(),
    'DINING & MENU' => _dining(),
    'LIVE WAIT TIMES' => _waitTimes(),
    'RIDE GUIDELINES' => _guidelines(),
    'WAVE POOL & RAIN DANCE' => _wave(),
    'SAFETY & HYGIENE' => _safety(),
    'MAINTENANCE LOG' => _maintenance(),
    _ => [const SizedBox.shrink()],
  };

  List<Widget> _ridesEvents() {
    final rides = _list('rides'), events = _list('events');
    final items = _rideTab == 'Rides' ? rides : events;
    final tabs = Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final tab in ['Rides', 'Events'])
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _rideTab = tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _rideTab == tab ? _navy : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    tab.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _rideTab == tab ? Colors.white : wonderlaNavy,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    return [
      tabs,
      const SizedBox(height: 14),
      if (items.isEmpty) _empty(_rideTab),
      for (final item in items) _mediaCard(item, event: _rideTab == 'Events'),
    ];
  }

  List<Widget> _dining() => [
    for (final outlet in _list('dining'))
      Card(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: InkWell(
          onTap: () => _diningDetail(outlet),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _thumb(outlet['img']?.toString(), size: 112),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${outlet['name'] ?? 'Dining'}'.toUpperCase(),
                        style: const TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        outlet['description']?.toString() ??
                            outlet['cuisine']?.toString() ??
                            '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: wonderlaNavy,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _tags(outlet['tags']),
                      Text(
                        'EXPLORE MORE  ›',
                        style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
  ];

  Future<void> _diningDetail(Map<String, dynamic> outlet) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final all = List<Map<String, dynamic>>.from(
          (outlet['items'] as List? ?? []).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        );
        return StatefulBuilder(
          builder: (ctx, localSet) {
            final filtered = all
                .where(
                  (it) =>
                      _menuFilter == 'All' ||
                      (_menuFilter == 'Veg'
                          ? it['veg'] == true
                          : it['veg'] != true),
                )
                .toList();
            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: .91,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                      decoration: const BoxDecoration(
                        color: _navy,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${outlet['name'] ?? 'Dining'}'.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            outlet['description']?.toString() ??
                                outlet['cuisine']?.toString() ??
                                '',
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.45,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _tags(outlet['tags']),
                        ],
                      ),
                    ),
                    const SizedBox(height: 17),
                    Text(
                      'EXPLORE MENU',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final f in ['All', 'Veg', 'Non-Veg'])
                          ChoiceChip(
                            label: Text(f),
                            selected: _menuFilter == f,
                            onSelected: (_) => localSet(() => _menuFilter = f),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(14),
                        children: [
                          if (filtered.isEmpty) _empty('Menu items'),
                          for (final item in filtered)
                            Card(
                              color: Colors.white,
                              child: ListTile(
                                leading: _thumb(
                                  item['img']?.toString(),
                                  size: 54,
                                ),
                                title: Text(
                                  item['name']?.toString() ?? '',
                                  style: const TextStyle(
                                    color: _navy,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  item['veg'] == true ? '🟢 Veg' : '🔶 Non-Veg',
                                ),
                                trailing: Text(
                                  item['price']?.toString() ?? '',
                                  style: const TextStyle(
                                    color: _navy,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _waitTimes() {
    final items = _list('liveWaitTimes');
    return [
      const Text(
        'Current ride queues',
        style: TextStyle(
          color: _navy,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Pull down to refresh the latest wait times.',
        style: TextStyle(color: wonderlaNavy),
      ),
      const SizedBox(height: 12),
      if (items.isEmpty) _empty('Live wait times'),
      for (final item in items)
        Card(
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: _thumb(item['img']?.toString(), size: 76),
            title: Text(
              item['title']?.toString() ?? '',
              style: const TextStyle(
                color: _navy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(item['description']?.toString() ?? ''),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: _waitColor(item['time']),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                '${item['time'] ?? 0} min',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Color _waitColor(dynamic value) {
    final n = num.tryParse('$value') ?? 0;
    return n >= 25 ? wonderlaFlagRed : _navy;
  }

  List<Widget> _guidelines() => [
    for (final item in _list('rideGuidelines'))
      _textCard(
        item['title']?.toString() ?? '',
        item['description']?.toString() ?? '',
        icon: Icons.straighten,
        trailing: item['minHeight']?.toString(),
      ),
  ];
  List<Widget> _wave() => [
    for (final item in _list('waveRainDance'))
      Card(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _wideImage(item['img']?.toString()),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']?.toString() ?? '',
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text('Duration: ${item['rideDuration'] ?? 0} minutes'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    children: [
                      for (final t in List<String>.from(
                        item['timeSlot'] as List? ?? [],
                      ))
                        Chip(label: Text(t), backgroundColor: wonderlaWhite),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
  ];
  List<Widget> _safety() => [
    for (final item in _list('safetyHygiene')) _mediaCard(item),
  ];
  List<Widget> _maintenance() => [
    Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            color: _navy,
            padding: const EdgeInsets.all(14),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'Ride',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Last service',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  'Checks',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < _list('maintenanceLog').length; i++)
            Builder(
              builder: (_) {
                final item = _list('maintenanceLog')[i];
                return Container(
                  color: i.isEven ? Colors.white : wonderlaWhite,
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['ride']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item['lastService']?.toString() ?? '',
                          style: const TextStyle(color: wonderlaNavy),
                        ),
                      ),
                      Text(item['checks']?.toString() ?? ''),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    ),
    if (_list('maintenanceLog').isEmpty) _empty('Maintenance log'),
  ];

  Widget _mediaCard(Map<String, dynamic> item, {bool event = false}) => Card(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumb(item['img']?.toString(), size: 110),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event && item['time'] != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _navy,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      item['time'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Text(
                  (item['title'] ?? item['name'] ?? '')
                      .toString()
                      .toUpperCase(),
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['description']?.toString() ?? '',
                  style: const TextStyle(color: wonderlaNavy, height: 1.35),
                ),
                const SizedBox(height: 7),
                _tags(item['tags']),
                if (item['kioskBookingEnabled'] == true)
                  const _BookingCallout(),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _textCard(
    String title,
    String description, {
    required IconData icon,
    String? trailing,
  }) => Card(
    color: Colors.white,
    child: ListTile(
      contentPadding: const EdgeInsets.all(12),
      leading: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: wonderlaWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: _navy, size: 32),
      ),
      title: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: _navy,
          fontWeight: FontWeight.w900,
          fontSize: 17,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(description, style: const TextStyle(height: 1.4)),
      ),
      trailing: trailing == null || trailing.isEmpty
          ? null
          : Text(
              trailing,
              style: const TextStyle(color: _navy, fontWeight: FontWeight.w900),
            ),
    ),
  );
  Widget _thumb(String? path, {double size = 100}) => Container(
    width: size,
    height: size,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: wonderlaWhite,
      borderRadius: BorderRadius.circular(17),
    ),
    child: path == null || path.isEmpty
        ? const Icon(Icons.local_activity_outlined, color: _navy, size: 29)
        : Image.network(
            _url(path),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.local_activity_outlined, color: _navy),
          ),
  );
  Widget _wideImage(String? path) => path == null || path.isEmpty
      ? const SizedBox(height: 130)
      : Image.network(
          _url(path),
          height: 185,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox(height: 130),
        );
  Widget _tags(dynamic raw) {
    final tags = raw is List
        ? raw.map((e) => e.toString()).toList()
        : <String>[];
    if (tags.isEmpty) return const SizedBox(height: 4);
    return Wrap(
      spacing: 6,
      runSpacing: 5,
      children: [
        for (final tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _empty(String title) => Padding(
    padding: const EdgeInsets.all(26),
    child: Column(
      children: [
        const Icon(Icons.inbox_outlined, color: _navy, size: 34),
        const SizedBox(height: 8),
        Text(
          '$title will be available soon.',
          style: const TextStyle(color: wonderlaNavy),
        ),
      ],
    ),
  );
  Widget _notice(String message, {bool error = false}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: error ? wonderlaWhite : wonderlaWhite,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: TextStyle(color: error ? wonderlaNavy : wonderlaNavy),
    ),
  );
}

class _BookingCallout extends StatelessWidget {
  const _BookingCallout();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: wonderlaWhite,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: wonderlaNavy),
    ),
    child: const Row(
      children: [
        Icon(Icons.confirmation_number_outlined, color: _navy),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Book a ride slot at park kiosks',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, color: _navy, size: 42),
          const SizedBox(height: 12),
          const Text(
            'Park guide could not load',
            style: TextStyle(
              color: _navy,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: wonderlaNavy),
          ),
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
