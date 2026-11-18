part of 'visitor_home.dart';

class VisitorSectionScreen extends StatefulWidget {
  const VisitorSectionScreen({
    super.key,
    required this.title,
    required this.config,
    required this.api,
    this.initialTab,
  });
  final String title;
  final Map<String, dynamic> config;
  final CmsApi api;
  final String? initialTab;
  @override
  State<VisitorSectionScreen> createState() => _VisitorSectionScreenState();
}

class _VisitorSectionScreenState extends State<VisitorSectionScreen> {
  late Map<String, dynamic> _config;
  bool _loading = false;
  String? _error;
  late String _rideTab;
  String _menuFilter = 'All';
  @override
  void initState() {
    super.initState();
    _config = Map<String, dynamic>.from(widget.config);
    _rideTab = widget.initialTab ?? 'Rides';
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
      backgroundColor: wonderlaWhite,
      foregroundColor: wonderlaNavy,
      surfaceTintColor: wonderlaWhite,
      toolbarHeight: 68,
      title: Text(
        widget.title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
      ),
      actions:
          ['RIDES & WATER ACTIVITIES', 'MAINTENANCE LOG'].contains(widget.title)
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
          ..._content(),
        ],
      ),
    ),
  );

  List<Widget> _content() => switch (widget.title) {
    'RIDES & WATER ACTIVITIES' => _ridesEvents(),
    'EVENTS' => _events(),
    'DINING & MENU' => _dining(),
    'RIDE GUIDELINES' => _guidelines(),
    'SAFETY & HYGIENE' => _safety(),
    'MAINTENANCE LOG' => _maintenance(),
    _ => [const SizedBox.shrink()],
  };

  List<Widget> _ridesEvents() {
    final rides = _list('rides');
    final tabLabels = ['Rides', 'Water activities', 'Live wait time'];
    final tabs = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tab in tabLabels)
          ChoiceChip(
            label: Text(tab),
            selected: _rideTab == tab,
            showCheckmark: false,
            selectedColor: _navy,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: _rideTab == tab ? Colors.white : wonderlaNavy,
              fontWeight: FontWeight.w700,
            ),
            onSelected: (_) => setState(() => _rideTab = tab),
          ),
      ],
    );
    return [
      tabs,
      const SizedBox(height: 14),
      if (_rideTab == 'Live wait time') ..._waitTimes(),
      if (_rideTab == 'Water activities') ..._wave(),
      if (_rideTab == 'Rides' && rides.isEmpty) _empty('Rides'),
      if (_rideTab == 'Rides')
        for (final item in rides) _mediaCard(item),
    ];
  }

  List<Widget> _events() => [
    if (_list('events').isEmpty) _empty('Events'),
    for (final item in _list('events')) _mediaCard(item, event: true),
  ];

  List<Widget> _dining() {
    final outlets = _list('dining');
    return [
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [wonderlaNavy, wonderlaCobalt],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.restaurant_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A GOOD DAY NEEDS GOOD FOOD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .35,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${outlets.length} ${outlets.length == 1 ? 'place' : 'places'} to eat around the park',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .82),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (outlets.isEmpty) _empty('Dining options'),
      for (final outlet in outlets)
        Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 13),
          clipBehavior: Clip.antiAlias,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: wonderlaBorder),
          ),
          child: InkWell(
            onTap: () => _diningDetail(outlet),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 112,
                      height: 124,
                      child: outlet['img']?.toString().isNotEmpty == true
                          ? Image.network(
                              _url(outlet['img']?.toString()),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _diningImageFallback(),
                            )
                          : _diningImageFallback(),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((outlet['cuisine']?.toString() ?? '').isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: wonderlaWhite,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              outlet['cuisine'].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: wonderlaNavy,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          outlet['name']?.toString() ?? 'Dining',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          outlet['description']?.toString() ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: wonderlaNavy,
                            height: 1.3,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Text(
                              'VIEW MENU',
                              style: TextStyle(
                                color: wonderlaCobalt,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .6,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: wonderlaCobalt,
                              size: 15,
                            ),
                          ],
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
  }

  Widget _diningImageFallback() => Container(
    color: wonderlaWhite,
    alignment: Alignment.center,
    child: const Icon(
      Icons.restaurant_rounded,
      color: wonderlaCobalt,
      size: 32,
    ),
  );
  Future<void> _diningDetail(Map<String, dynamic> outlet) async {
    _menuFilter = 'All';
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
                heightFactor: .94,
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
                      'MENU',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 20,
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
                            showCheckmark: false,
                            selectedColor: wonderlaNavy,
                            labelStyle: TextStyle(
                              color: _menuFilter == f
                                  ? Colors.white
                                  : wonderlaNavy,
                              fontWeight: FontWeight.w700,
                            ),
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
                              margin: const EdgeInsets.only(bottom: 9),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                                side: const BorderSide(color: wonderlaBorder),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 4,
                                ),
                                minLeadingWidth: 54,
                                leading: _thumb(
                                  item['img']?.toString(),
                                  size: 58,
                                ),
                                title: Text(
                                  item['name']?.toString() ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _navy,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  item['veg'] == true
                                      ? 'Vegetarian'
                                      : 'Non-vegetarian',
                                  style: const TextStyle(
                                    color: wonderlaNavy,
                                    fontSize: 12,
                                  ),
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
    if (_list('waveRainDance').isEmpty) _empty('Water activities'),
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
  List<Widget> _maintenance() {
    final entries = _list('maintenanceLog');
    if (entries.isEmpty) return [_empty('Maintenance log')];
    return [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Service records',
              style: TextStyle(
                color: _navy,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Chip(
            label: Text(
              '${entries.length} ${entries.length == 1 ? 'record' : 'records'}',
            ),
            backgroundColor: Colors.white,
          ),
        ],
      ),
      const SizedBox(height: 10),
      for (final item in entries) _maintenanceRow(item),
    ];
  }

  Widget _maintenanceRow(Map<String, dynamic> item) {
    final ride = item['ride']?.toString() ?? '';
    final service = item['lastService']?.toString() ?? '';
    final checks = item['checks']?.toString() ?? '';
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: wonderlaBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: wonderlaWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.build_outlined, color: _navy),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    ride.isEmpty ? 'Park equipment' : ride,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 22,
              runSpacing: 12,
              children: [
                _maintenanceInfo(
                  Icons.event_available_outlined,
                  'Last service',
                  service,
                ),
                _maintenanceInfo(
                  Icons.checklist_rounded,
                  'Work completed',
                  checks,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _maintenanceInfo(IconData icon, String label, String value) =>
      SizedBox(
        width: 220,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: wonderlaNavy),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: wonderlaNavy,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value.isEmpty ? 'Not recorded' : value,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

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
