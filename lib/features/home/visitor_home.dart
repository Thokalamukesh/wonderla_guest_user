import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../cms/cms_api.dart';
import 'configured_park_map_screen.dart';
import 'home_shortcut_catalog.dart';
import '../cms/cms_screen.dart';
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
  final Map<String, Map<String, dynamic>> _parkCache = {};
  final Map<String, Future<Map<String, dynamic>>> _parkRequests = {};

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
        for (final park in _parks) {
          final identity = '${park['name']} ${park['location']} ${park['slug']}'
              .toLowerCase();
          if (identity.contains('bengaluru') ||
              identity.contains('bangalore')) {
            unawaited(_prefetchPark(park['slug'] as String));
          }
        }
      }
    } catch (e) {
      _error = _friendlyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadPark(String slug) async {
    final cached = _parkCache[slug];
    if (cached != null) {
      if (mounted) {
        setState(() {
          _park = cached;
          _loading = false;
          _error = null;
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _requestPark(slug);
      if (data['active'] == false) {
        throw const CmsApiException(
          'This park guide is not currently available.',
        );
      }
      _parkCache[slug] = data;
      if (mounted) setState(() => _park = data);
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _prefetchPark(String slug) async {
    try {
      await _requestPark(slug);
    } catch (_) {
      // Keep the directory usable if background preloading fails.
    }
  }

  Future<Map<String, dynamic>> _requestPark(String slug) {
    final cached = _parkCache[slug];
    if (cached != null) return Future.value(cached);
    final pending = _parkRequests[slug];
    if (pending != null) return pending;
    late final Future<Map<String, dynamic>> request;
    request = _api
        .park(slug)
        .then((data) {
          _parkCache[slug] = data;
          return data;
        })
        .whenComplete(() => _parkRequests.remove(slug));
    _parkRequests[slug] = request;
    return request;
  }

  String _friendlyError(Object error) {
    if (!_api.isConfigured) {
      return 'Set the park guide website URL to connect to park content.';
    }
    final message = error.toString().toLowerCase();
    if (message.contains('failed to fetch') ||
        message.contains('xmlhttprequest error') ||
        message.contains('clientexception') ||
        message.contains('connection refused') ||
        message.contains('network is unreachable')) {
      return 'Could not connect to the park content server at ${_api.baseUrl}. Start the CMS/API server at http://localhost:3000 and allow the local Flutter web origin in its CORS settings, or run Flutter with --dart-define=API_BASE_URL=<server-url>.';
    }
    return error.toString();
  }

  String _imageUrl(String? value) {
    if (value == null || value.isEmpty) return '';
    if (Uri.tryParse(value)?.hasScheme == true) return value;
    return '${_api.baseUrl}${value.startsWith('/') ? '' : '/'}$value';
  }

  void _openSection(HomeShortcutDefinition shortcut) {
    final cfg = _park;
    if (cfg == null) return;
    if (shortcut.keyName == 'parkMap') {
      _openParkMap(cfg);
      return;
    }
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (_, _, _) => VisitorSectionScreen(
          title: shortcut.section,
          config: cfg,
          api: _api,
          initialTab: shortcut.initialTab,
        ),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
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

  List<HomeShortcutDefinition> _configuredShortcuts(
    Map<String, dynamic> config,
  ) {
    final configured = config['homeShortcuts'];
    if (configured is List) {
      return configured
          .whereType<Map>()
          .where((setting) => setting['visible'] != false)
          .map(
            (setting) =>
                HomeShortcutCatalog.byKey(setting['key']?.toString() ?? ''),
          )
          .whereType<HomeShortcutDefinition>()
          .toList();
    }

    // Read the earlier visibility format until the CMS saves the ordered list.
    final legacyVisibility = config['homeCardVisibility'] as Map?;
    final keys = [...HomeShortcutCatalog.defaultKeys];
    for (final key in const ['liveWaitTimes', 'wavePool']) {
      if (legacyVisibility?[key] == true) keys.add(key);
    }
    return keys
        .where((key) {
          final specific = legacyVisibility == null
              ? null
              : legacyVisibility[key];
          final combined = legacyVisibility == null
              ? null
              : legacyVisibility['ridesEvents'];
          final value =
              specific ?? (key == 'rides' || key == 'events' ? combined : null);
          return value != false;
        })
        .map(HomeShortcutCatalog.byKey)
        .whereType<HomeShortcutDefinition>()
        .toList();
  }

  Widget _tileGrid(
    List<HomeShortcutDefinition> shortcuts,
    Map<String, dynamic> config, {
    required bool compact,
    required int delayOffset,
  }) {
    if (shortcuts.isEmpty) return const SizedBox.shrink();
    final columns = MediaQuery.sizeOf(context).width < 355 ? 1 : 2;
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.none,
      itemCount: shortcuts.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: columns == 1
            ? 4.0
            : compact
            ? 1.82
            : 1.7,
        crossAxisSpacing: compact ? 10 : 14,
        mainAxisSpacing: compact ? 10 : 16,
      ),
      itemBuilder: (context, index) {
        final shortcut = shortcuts[index];
        final labels = config['homeCardLabels'] as Map?;
        final labelValue = labels == null ? null : labels[shortcut.keyName];
        final customTitle = labelValue?.toString().trim();
        final hasCustomTitle = customTitle != null && customTitle.isNotEmpty;
        return ShortcutCard(
          title: hasCustomTitle ? customTitle : shortcut.label,
          titleCase: !hasCustomTitle,
          icon: shortcut.icon,
          imageUrl: _imageUrl(
            shortcut.imageConfigKey == null
                ? null
                : config[shortcut.imageConfigKey!]?.toString(),
          ),
          delay: (delayOffset + index) * 45,
          compact: compact,
          onTap: () => _openSection(shortcut),
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final heroHeight = constraints.maxWidth < 560
                          ? 320.0
                          : 360.0;
                      const overlap = 58.0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: heroHeight,
                            child: _HeroCard(
                              name: heroTitle,
                              location: cfg['location']?.toString() ?? '',
                              imageUrl: _imageUrl(
                                cfg['heroImageUrl']?.toString(),
                              ),
                              videoUrl: _imageUrl(
                                cfg['heroVideoUrl']?.toString(),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: heroHeight - overlap),
                            child: Container(
                              padding: EdgeInsets.fromLTRB(
                                compactHome ? 18 : 28,
                                26,
                                compactHome ? 18 : 28,
                                40,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xffeaf1f8),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(60),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x26344a64),
                                    blurRadius: 30,
                                    spreadRadius: 1,
                                    offset: Offset(0, -12),
                                  ),
                                  BoxShadow(
                                    color: Color(0x12344a64),
                                    blurRadius: 10,
                                    offset: Offset(0, -3),
                                  ),
                                ],
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
                                            fontSize: compactHome ? 25 : 29,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  _tileGrid(
                                    _configuredShortcuts(cfg),
                                    cfg,
                                    compact: constraints.maxWidth < 520,
                                    delayOffset: 0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                              fontWeight: FontWeight.w900,
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
    required this.videoUrl,
  });
  final String name, location, imageUrl, videoUrl;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 560;
      final cardHeight = compact ? 320.0 : 360.0;
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
            if (videoUrl.isNotEmpty) _HeroVideoBackground(url: videoUrl),
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
            Positioned(
              left: compact ? 10 : 24,
              right: compact ? 10 : 24,
              bottom: compact ? 78 : 82,
              child: _HeroSlogan(compact: compact),
            ),
          ],
        ),
      );
    },
  );
}

class _HeroVideoBackground extends StatefulWidget {
  const _HeroVideoBackground({required this.url});
  final String url;

  @override
  State<_HeroVideoBackground> createState() => _HeroVideoBackgroundState();
}

class _HeroVideoBackgroundState extends State<_HeroVideoBackground> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant _HeroVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _start();
  }

  Future<void> _start() async {
    final old = _controller;
    _controller = null;
    await old?.dispose();
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.expand();
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _HeroSlogan extends StatelessWidget {
  const _HeroSlogan({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const slogan = "INDIA'S LARGEST\nAMUSEMENT PARK CHAIN!";
    final size = compact ? 19.0 : 31.0;
    final base = TextStyle(
      fontSize: size,
      height: .98,
      fontWeight: FontWeight.w900,
      letterSpacing: compact ? .1 : .6,
      fontFamily: 'Arial',
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            slogan,
            textAlign: TextAlign.center,
            style: base.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = compact ? 1.4 : 2.1
                ..color = const Color(0xffffdf00),
              shadows: const [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 6,
                  offset: Offset(1, 3),
                ),
              ],
            ),
          ),
          Text(
            slogan,
            textAlign: TextAlign.center,
            style: base.copyWith(
              color: const Color(0xffd8aa00),
              shadows: const [
                Shadow(
                  color: Color(0x99000000),
                  blurRadius: 3,
                  offset: Offset(1, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShortcutCard extends StatelessWidget {
  const ShortcutCard({
    super.key,
    required this.title,
    required this.titleCase,
    required this.icon,
    required this.imageUrl,
    required this.delay,
    required this.compact,
    required this.onTap,
  });

  final String title;
  final bool titleCase;
  final String imageUrl;
  final IconData icon;
  final int delay;
  final bool compact;
  final VoidCallback? onTap;

  String _titleCase(String value) => value
      .split(' ')
      .map(
        (word) => word == '&' || word.isEmpty
            ? word
            : '${word[0]}${word.substring(1).toLowerCase()}',
      )
      .join(' ');

  Widget _tileImage(double size) {
    Widget fallback() => Container(
      color: const Color(0xffe9efff),
      alignment: Alignment.center,
      child: Icon(icon, color: wonderlaCobalt, size: size * .55),
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
    child: LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = (constraints.maxWidth * .22).clamp(34.0, 44.0);
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: const Color(0xfffbfdff), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x183a5069),
                blurRadius: 16,
                spreadRadius: 1,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Color(0x0c3a5069),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(23),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 6 : 12,
                  vertical: compact ? 6 : 12,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox.square(
                        dimension: imageSize,
                        child: _tileImage(imageSize),
                      ),
                    ),
                    SizedBox(width: compact ? 6 : 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleCase ? _titleCase(title) : title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _navy,
                              fontSize: compact ? 12 : 14,
                              height: 1.04,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _navy,
                      size: compact ? 22 : 25,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
