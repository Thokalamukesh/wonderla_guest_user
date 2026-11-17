part of 'cms_screen.dart';

class _AdminDashboard extends StatefulWidget {
  const _AdminDashboard({
    required this.api,
    required this.user,
    required this.onLogout,
  });
  final CmsApi api;
  final Map<String, dynamic> user;
  final VoidCallback onLogout;
  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  final _sections = const [
    ('Park overview', LucideIcons.chartNoAxesCombined),
    ('Parks', LucideIcons.building2),
    ('Rides', LucideIcons.ferrisWheel),
    ('Events', LucideIcons.calendarDays),
    ('Dining & menus', LucideIcons.utensils),
    ('Live wait times', LucideIcons.timer),
    ('Wave pool & rain dance', LucideIcons.waves),
    ('Safety & hygiene', LucideIcons.shieldCheck),
    ('Maintenance log', LucideIcons.wrench),
    ('Ride guidelines', LucideIcons.ruler),
    ('Park map & places', LucideIcons.mapPinned),
    ('Google Maps settings', LucideIcons.map),
    ('Users', LucideIcons.users),
    ('Site URL & QR codes', LucideIcons.qrCode),
  ];
  final _listKeys = const {
    'Rides': 'rides',
    'Events': 'events',
    'Dining & menus': 'dining',
    'Live wait times': 'liveWaitTimes',
    'Wave pool & rain dance': 'waveRainDance',
    'Safety & hygiene': 'safetyHygiene',
    'Maintenance log': 'maintenanceLog',
    'Ride guidelines': 'rideGuidelines',
  };
  final _schemas = const <String, List<(String, String)>>{
    'Rides': [
      ('title', 'Ride name'),
      ('description', 'Description'),
      ('img', 'Ride image'),
      ('tags', 'Tags (comma separated)'),
      ('kioskBookingEnabled', 'Enable kiosk booking'),
    ],
    'Events': [
      ('title', 'Event name'),
      ('time', 'Time'),
      ('description', 'Description'),
      ('img', 'Event image'),
      ('tags', 'Tags (comma separated)'),
    ],
    'Dining & menus': [
      ('name', 'Outlet name'),
      ('cuisine', 'Cuisine'),
      ('description', 'Description'),
      ('img', 'Outlet image'),
      ('directionsUrl', 'Directions URL'),
      ('tags', 'Tags (comma separated)'),
    ],
    'Live wait times': [
      ('title', 'Ride name'),
      ('time', 'Wait time in minutes'),
      ('description', 'Description'),
      ('img', 'Ride image'),
    ],
    'Wave pool & rain dance': [
      ('title', 'Attraction name'),
      ('timeSlot', 'Session times (comma separated)'),
      ('rideDuration', 'Duration in minutes'),
      ('img', 'Image'),
    ],
    'Safety & hygiene': [
      ('title', 'Information title'),
      ('description', 'Description'),
      ('img', 'Image'),
    ],
    'Maintenance log': [
      ('ride', 'Ride'),
      ('lastService', 'Last service date (dd/mm/yyyy)'),
      ('checks', 'Checks performed'),
    ],
    'Ride guidelines': [
      ('title', 'Guideline title'),
      ('description', 'Description'),
      ('minHeight', 'Minimum height'),
    ],
  };
  List<Map<String, dynamic>> _parks = [];
  Map<String, dynamic>? _config;
  Map<String, dynamic>? _mapSettings;
  List<Map<String, dynamic>> _users = [];
  String? _selectedSlug;
  String _section = 'Park overview';
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _notice;

  bool get _super => widget.user['role'] == 'superadmin';
  List<String> get _permissions => List<String>.from(
    widget.user['permissions'] as List? ?? const <String>[],
  );
  bool _canAccess(String section) =>
      _super ||
      widget.user['permissions'] == null ||
      _permissions.contains('all') ||
      _permissions.contains(section);
  bool get _canSave =>
      _config != null &&
      _canAccess(_section) &&
      _section != 'Users' &&
      _section != 'Google Maps settings' &&
      _section != 'Site URL & QR codes';

  @override
  void initState() {
    super.initState();
    if (!_super &&
        widget.user['permissions'] != null &&
        !_canAccess(_section)) {
      _section = _sections
          .map((section) => section.$1)
          .firstWhere(_canAccess, orElse: () => 'Park overview');
    }
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _parks = await widget.api.parks();
      if (_super) {
        final slug =
            _selectedSlug ??
            (_parks.isNotEmpty ? _parks.first['slug'] as String : null);
        if (slug != null) await _loadPark(slug);
      } else {
        final slug = widget.user['parkSlug'] as String?;
        if (slug != null) await _loadPark(slug);
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadPark(String slug) async {
    final config = await widget.api.park(slug);
    if (mounted) {
      setState(() {
        _config = config;
        _selectedSlug = slug;
      });
    }
  }

  Future<void> _loadUsers() async {
    _users = await widget.api.users();
    if (mounted) setState(() {});
  }

  Future<void> _savePark() async {
    if (_config == null || !_canAccess(_section)) return;
    setState(() {
      _saving = true;
      _error = null;
      _notice = null;
    });
    try {
      _config = await widget.api.savePark(_selectedSlug!, _config!);
      _parks = await widget.api.parks();
      _notice = 'Park content saved successfully.';
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _changeSection(String value) async {
    if (!_canAccess(value)) return;
    setState(() {
      _section = value;
      _error = null;
      _notice = null;
    });
    if (value == 'Google Maps settings') await _loadMapSettings();
    if (value == 'Users') await _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final compact = MediaQuery.sizeOf(context).width < 720;
    final narrow = MediaQuery.sizeOf(context).width < 390;
    return Scaffold(
      backgroundColor: wonderlaCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        toolbarHeight: 64,
        title: Row(
          children: [
            Image.asset(
              'assets/images/wonderla_logo.webp',
              width: narrow ? 96 : 118,
              height: 42,
              fit: BoxFit.contain,
            ),
            if (!narrow) ...[
              const SizedBox(width: 10),
              const Text(
                'Admin',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
        actions: [
          if (_canSave && !compact)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: FilledButton.icon(
                onPressed: _saving ? null : _savePark,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving…' : 'Save changes'),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (_) => widget.onLogout(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'logout',
                child: Text('Sign out · ${widget.user['username']}'),
              ),
            ],
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
        bottom: _canSave && compact
            ? PreferredSize(
                preferredSize: const Size.fromHeight(68),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _savePark,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving…' : 'Save changes'),
                    ),
                  ),
                ),
              )
            : null,
      ),
      drawer: wide ? null : Drawer(child: _nav()),
      body: Row(
        children: [
          if (wide) SizedBox(width: 255, child: _nav()),
          Expanded(
            child: Column(
              children: [
                if (!wide) _mobileSectionPicker(),
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nav() => Container(
    color: Colors.white,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: wonderlaWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dashboard_customize_outlined,
                  color: _brandNavy,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PARK CMS',
                      style: TextStyle(
                        fontSize: 11,
                        color: wonderlaNavy,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _super ? 'Superadmin' : 'Park editor',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_super) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _parkDropDown(),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MANAGE CONTENT',
                style: TextStyle(
                  fontSize: 10,
                  color: wonderlaNavy,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            children: [
              for (final (name, icon) in _sections)
                if (_super ||
                    (_canAccess(name) &&
                        !{
                          'Parks',
                          'Users',
                          'Google Maps settings',
                          'Site URL & QR codes',
                        }.contains(name)))
                  _navItem(name, icon),
            ],
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: wonderlaWhite,
            child: Icon(Icons.person_outline, color: _brandNavy),
          ),
          title: Text(
            '${widget.user['username']}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('${widget.user['role']}'),
          trailing: IconButton(
            tooltip: 'Sign out',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ),
      ],
    ),
  );

  Widget _parkDropDown() => DropdownButtonFormField<String>(
    initialValue: _selectedSlug,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: 'Selected park',
      filled: true,
      fillColor: wonderlaWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
    ),
    items: [
      for (final p in _parks)
        DropdownMenuItem(
          value: p['slug'] as String,
          child: Text(p['name'] as String, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: (slug) async {
      if (slug != null) {
        setState(() => _loading = true);
        try {
          await _loadPark(slug);
        } catch (e) {
          setState(() => _error = e.toString());
        }
        if (mounted) setState(() => _loading = false);
      }
    },
  );

  Widget _navItem(String title, IconData icon) => Builder(
    builder: (tileContext) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          selected: _section == title,
          selectedColor: wonderlaWhite,
          selectedTileColor: _brandNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(icon, size: 20),
          title: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          onTap: () {
            _changeSection(title);
            final scaffold = Scaffold.maybeOf(tileContext);
            if (scaffold?.isDrawerOpen ?? false) scaffold?.closeDrawer();
          },
        ),
      ),
    ),
  );

  Widget _mobileSectionPicker() => SizedBox(
    height: 58,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      children: [
        for (final (title, icon) in _sections)
          if (_super ||
              (_canAccess(title) &&
                  !{
                    'Parks',
                    'Users',
                    'Google Maps settings',
                    'Site URL & QR codes',
                  }.contains(title)))
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: ChoiceChip(
                avatar: Icon(
                  icon,
                  size: 17,
                  color: _section == title ? wonderlaWhite : _ink,
                ),
                label: Text(
                  title,
                  style: TextStyle(
                    color: _section == title ? wonderlaWhite : _ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                selected: _section == title,
                selectedColor: _brandNavy,
                backgroundColor: wonderlaWhite,
                side: const BorderSide(color: _ink),
                onSelected: (_) => _changeSection(title),
              ),
            ),
      ],
    ),
  );

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _brandNavy));
    }
    if (_error != null) return _feedback(_error!, error: true, retry: _loadAll);
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _section,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _sectionSubtitle,
                    style: const TextStyle(color: wonderlaNavy),
                  ),
                ],
              ),
            ),
            if (_section == 'Parks' && _super)
              FilledButton.icon(
                onPressed: _addPark,
                icon: const Icon(Icons.add),
                label: const Text('New park'),
              ),
          ],
        ),
        if (_notice != null) _feedback(_notice!),
        const SizedBox(height: 18),
        if (_section == 'Park overview' && _canAccess('Park overview'))
          ScrollReveal(child: _overview()),
        if (_section == 'Parks') ScrollReveal(child: _parksPage()),
        if (_listKeys.containsKey(_section) && _canAccess(_section))
          ScrollReveal(child: _collectionPage()),
        if (_section == 'Park map & places' && _canAccess(_section))
          ScrollReveal(child: _mapPage()),
        if (_section == 'Google Maps settings')
          ScrollReveal(child: _googleMapSettings()),
        if (_section == 'Users') ScrollReveal(child: _usersPage()),
        if (_section == 'Site URL & QR codes' &&
            (_super || _permissions.isEmpty))
          ScrollReveal(child: _siteUrlPage()),
        if (!_canAccess(_section))
          const _EmptyCard(
            'No access assigned',
            'Ask an administrator to assign at least one section.',
          ),
      ],
    );
  }

  String get _sectionSubtitle => switch (_section) {
    'Park overview' =>
      'Update park identity, brand images and publishing status.',
    'Parks' =>
      'Create parks and control which parks appear in the visitor directory.',
    'Park map & places' =>
      'Manage map artwork and the map places list for this park.',
    'Google Maps settings' =>
      'Manage the Google Maps browser key used by the website map.',
    'Users' => 'Create park editors or full access administrators.',
    'Site URL & QR codes' =>
      'Preview the QR address visitors use to open this park guide.',
    _ => 'Edit the content visitors see in this section.',
  };

  Widget _overview() {
    if (_config == null) {
      return const _EmptyCard(
        'No park selected',
        'Create a park to start managing visitor content.',
      );
    }
    final cfg = _config!;
    return Column(
      children: [
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_note, color: _brandNavy),
                    const SizedBox(width: 8),
                    const Text(
                      'Park details',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const Spacer(),
                    _statusBadge(cfg['active'] == true),
                  ],
                ),
                const SizedBox(height: 18),
                _textField(
                  'Park display name',
                  cfg['name']?.toString() ?? '',
                  (v) => cfg['name'] = v,
                ),
                const SizedBox(height: 14),
                _textField(
                  'Location',
                  cfg['location']?.toString() ?? '',
                  (v) => cfg['location'] = v,
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Brand and landing images',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                _ImagePickerField(
                  api: widget.api,
                  parkSlug: _selectedSlug!,
                  label: 'Park logo',
                  value: cfg['logoUrl']?.toString() ?? '',
                  onChanged: (v) => setState(() => cfg['logoUrl'] = v),
                ),
                const SizedBox(height: 12),
                _ImagePickerField(
                  api: widget.api,
                  parkSlug: _selectedSlug!,
                  label: 'Welcome banner image',
                  value: cfg['heroImageUrl']?.toString() ?? '',
                  onChanged: (v) => setState(() => cfg['heroImageUrl'] = v),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Explore the Park card images',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Upload a photo for each home screen card. Card images save automatically for this park.',
                    style: TextStyle(color: wonderlaNavy, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 10),
                for (final (key, label) in const <(String, String)>[
                  ('exploreParkMapImageUrl', 'Park map'),
                  ('exploreRidesImageUrl', 'Rides & events'),
                  ('exploreDiningImageUrl', 'Dining & menu'),
                  ('exploreWaitTimesImageUrl', 'Live wait times'),
                  ('exploreGuidelinesImageUrl', 'Ride guidelines'),
                  ('exploreWaveImageUrl', 'Wave pool & rain dance'),
                  ('exploreSafetyImageUrl', 'Safety & hygiene'),
                  ('exploreMaintenanceImageUrl', 'Maintenance log'),
                ]) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ImagePickerField(
                      api: widget.api,
                      parkSlug: _selectedSlug!,
                      label: label,
                      value: cfg[key]?.toString() ?? '',
                      onChanged: (v) => setState(() => cfg[key] = v),
                      onUploaded: (_) => _savePark(),
                    ),
                  ),
                ],
                if (_super)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Published in visitor park directory'),
                    subtitle: const Text(
                      'Inactive parks stay editable in CMS but are hidden from visitors.',
                    ),
                    value: cfg['active'] == true,
                    onChanged: (v) => setState(() => cfg['active'] = v),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _contentSummary(),
      ],
    );
  }

  Widget _contentSummary() => Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content at a glance',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          for (final entry in _listKeys.entries)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(_iconFor(entry.key), color: _brandNavy),
              title: Text(entry.key),
              trailing: Text(
                '${(_config![entry.value] as List?)?.length ?? 0} items',
                style: const TextStyle(color: wonderlaNavy),
              ),
              onTap: () => _changeSection(entry.key),
            ),
        ],
      ),
    ),
  );

  Widget _parksPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_super)
        FilledButton.icon(
          onPressed: _addPark,
          icon: const Icon(Icons.add),
          label: const Text('Create a park'),
        ),
      const SizedBox(height: 8),
      for (final p in _parks)
        Card(
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: wonderlaWhite,
              child: const Icon(Icons.park_outlined, color: _brandNavy),
            ),
            title: Text(p['name']?.toString() ?? ''),
            subtitle: Text('${p['location'] ?? ''} · /qr-code/${p['slug']}'),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: 'Show and download QR code',
                  onPressed: () => _showParkQr(p),
                  icon: const Icon(Icons.qr_code_2, color: _brandNavy),
                ),
                if (_super)
                  IconButton(
                    tooltip: 'Delete park',
                    onPressed: () => _deletePark(p),
                    icon: const Icon(Icons.delete_outline, color: wonderlaNavy),
                  ),
                _statusBadge(p['active'] == true),
              ],
            ),
            onTap: () async {
              final slug = p['slug'] as String;
              await _loadPark(slug);
              await _changeSection('Park overview');
            },
          ),
        ),
    ],
  );

  Widget _collectionPage() {
    if (_config == null) {
      return const _EmptyCard(
        'Choose a park',
        'Select a park to edit its content.',
      );
    }
    final key = _listKeys[_section]!;
    final items = List<Map<String, dynamic>>.from(
      (_config![key] as List? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _editItem(key, null),
            icon: const Icon(Icons.add),
            label: Text('Add ${_section.toLowerCase()} item'),
          ),
        ),
        if (items.isEmpty)
          const _EmptyCard(
            'Nothing here yet',
            'Add the first item. Visitors will see these details in the park guide.',
          ),
        for (var i = 0; i < items.length; i++)
          Card(
            color: Colors.white,
            child: ListTile(
              leading: _thumbnail(items[i]['img']?.toString()),
              title: Text(_itemTitle(items[i])),
              subtitle: Text(
                _itemSubtitle(items[i]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => _editItem(key, i),
                    icon: const Icon(Icons.edit_outlined, color: _brandNavy),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () =>
                        setState(() => (_config![key] as List).removeAt(i)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        if (_section == 'Dining & menus' && items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Menu dishes, prices and veg markers are managed inside each outlet’s edit form.',
              style: TextStyle(color: wonderlaNavy),
            ),
          ),
      ],
    );
  }

  Widget _mapPage() {
    if (_config == null) {
      return const _EmptyCard(
        'Choose a park',
        'Select a park before managing its map.',
      );
    }
    final map = Map<String, dynamic>.from(_config!['parkMap'] as Map);
    final places = List<Map<String, dynamic>>.from(
      (map['places'] as List? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );
    final zones = List<Map<String, dynamic>>.from(
      (map['zones'] as List? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Park map artwork',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        'Park latitude',
                        map['centerLat']?.toString() ?? '',
                        (v) => setState(() {
                          map['centerLat'] = double.tryParse(v) ?? v;
                          _config!['parkMap'] = map;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _textField(
                        'Park longitude',
                        map['centerLng']?.toString() ?? '',
                        (v) => setState(() {
                          map['centerLng'] = double.tryParse(v) ?? v;
                          _config!['parkMap'] = map;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ImagePickerField(
                  api: widget.api,
                  parkSlug: _selectedSlug!,
                  label: 'Map image',
                  value: map['img']?.toString() ?? '',
                  onChanged: (v) => setState(() {
                    map['img'] = v;
                    _config!['parkMap'] = map;
                  }),
                ),
                const SizedBox(height: 10),
                _textField(
                  'Map description',
                  map['description']?.toString() ?? '',
                  (v) => setState(() {
                    map['description'] = v;
                    _config!['parkMap'] = map;
                  }),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        _subsectionHeader(
          'Map places',
          'Pin destinations on the map. Add GPS coordinates to enable walking directions from a visitor’s live location.',
          () => _editMapPlace(map, null),
        ),
        for (var i = 0; i < places.length; i++)
          Card(
            color: Colors.white,
            child: ListTile(
              leading: Icon(
                _hasValidMapCoordinates(places[i])
                    ? Icons.directions_walk
                    : Icons.place_outlined,
                color: _hasValidMapCoordinates(places[i])
                    ? Colors.green.shade700
                    : _brandNavy,
              ),
              title: Text(places[i]['name']?.toString() ?? 'Untitled place'),
              subtitle: Text(
                '${places[i]['category'] ?? 'Place'} · x ${places[i]['x'] ?? 0}% · y ${places[i]['y'] ?? 0}%\n${_hasValidMapCoordinates(places[i]) ? 'Walking directions ready' : 'Add latitude and longitude for directions'}',
              ),
              isThreeLine: true,
              trailing: Wrap(
                children: [
                  IconButton(
                    onPressed: () => _editMapPlace(map, i),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      places.removeAt(i);
                      map['places'] = places;
                      _config!['parkMap'] = map;
                    }),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        _subsectionHeader(
          'Map zones',
          'Optional zones and visitor descriptions.',
          () => _editMapZone(map, null),
        ),
        for (var i = 0; i < zones.length; i++)
          Card(
            color: Colors.white,
            child: ListTile(
              title: Text(zones[i]['name']?.toString() ?? ''),
              subtitle: Text(zones[i]['description']?.toString() ?? ''),
              trailing: Wrap(
                children: [
                  IconButton(
                    onPressed: () => _editMapZone(map, i),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      zones.removeAt(i);
                      map['zones'] = zones;
                      _config!['parkMap'] = map;
                    }),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            map['places'] = places;
            map['zones'] = zones;
            _config!['parkMap'] = map;
            _savePark();
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save map configuration'),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'This updates the selected park’s visitor map and pins. The existing Bengaluru walking map remains available separately.',
            style: TextStyle(color: wonderlaNavy, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _loadMapSettings() async {
    try {
      _mapSettings = await widget.api.mapSettings();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Widget _googleMapSettings() => _ApiKeyCard(
    api: widget.api,
    configured: (_mapSettings?['apiKey']?.toString() ?? '').isNotEmpty,
    onSaved: () async {
      await _loadMapSettings();
    },
  );

  Widget _usersPage() => _UsersManager(
    api: widget.api,
    users: _users,
    parks: _parks,
    currentUsername: widget.user['username']?.toString() ?? '',
    reload: _loadUsers,
  );

  Widget _siteUrlPage() {
    final origin = widget.api.baseUrl;
    final slug = _selectedSlug ?? '';
    final url = '$origin/qr-code/$slug';
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Park QR destination',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'The existing React backend serves this route for web visitors. Its site URL is derived from the deployed website domain.',
            ),
            const SizedBox(height: 16),
            SelectableText(
              url,
              style: const TextStyle(
                color: _brandNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await _loadSiteOrigin();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh deployed site URL'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Keep this web fallback URL on printed QR codes. Configure Android App Links and iOS Universal Links on the same domain if you want installed apps to open the QR directly.',
              style: TextStyle(color: wonderlaNavy, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showParkQr(Map<String, dynamic> park) async {
    final slug = park['slug']?.toString() ?? '';
    final url = '${widget.api.baseUrl}/qr-code/$slug';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${park['name'] ?? 'Park'} QR code'),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(data: url, version: QrVersions.auto, size: 220),
              const SizedBox(height: 8),
              SelectableText(url, textAlign: TextAlign.center),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final data = await QrPainter(
                data: url,
                version: QrVersions.auto,
              ).toImageData(1024, format: ImageByteFormat.png);
              if (data == null) return;
              await downloadQrPng(
                data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
                'wonderla-$slug-qr.png',
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            icon: const Icon(Icons.download),
            label: const Text('Download PNG'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSiteOrigin() async {
    try {
      final value = await widget.api.siteUrl();
      setState(() => _notice = 'Backend site origin: ${value['origin']}');
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _addPark() async {
    final values = await _simpleForm('Create park', [
      ('name', 'Park name'),
      ('location', 'Location'),
    ]);
    if (values == null || values['name']!.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final result = await widget.api.createPark(
        values['name']!.trim(),
        values['location']!.trim(),
      );
      _parks = await widget.api.parks();
      await _loadPark(result['slug'] as String);
      setState(() {
        _section = 'Park overview';
        _notice =
            'Park created. Add the content and images, then save changes.';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deletePark(Map<String, dynamic> p) async {
    final yes = await _confirm(
      'Delete ${p['name']}?',
      'This permanently deletes this park and its visitor content.',
    );
    if (!yes) return;
    try {
      await widget.api.deletePark(p['slug'] as String);
      _parks = await widget.api.parks();
      _config = null;
      _selectedSlug = null;
      if (_parks.isNotEmpty) await _loadPark(_parks.first['slug'] as String);
      setState(() => _notice = 'Park deleted.');
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _editItem(String configKey, int? index) async {
    final list = _config![configKey] as List;
    final existing = index == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(list[index] as Map);
    final schema =
        _schemas[_section] ??
        const [('title', 'Title'), ('description', 'Description')];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _RecordEditor(
        title: index == null ? 'Add $_section item' : 'Edit $_section item',
        values: existing,
        schema: schema,
        api: widget.api,
        parkSlug: _selectedSlug!,
        manageMenu: _section == 'Dining & menus',
      ),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        list.add(result);
      } else {
        list[index] = result;
      }
    });
  }

  Future<void> _editMapPlace(Map<String, dynamic> map, int? index) async {
    final values = List<Map<String, dynamic>>.from(
      (map['places'] as List? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _RecordEditor(
        title: index == null ? 'Add map place' : 'Edit map place',
        values: index == null ? {} : values[index],
        schema: const [
          ('name', 'Place name'),
          ('category', 'Category'),
          ('x', 'Horizontal position %'),
          ('y', 'Vertical position %'),
          ('lat', 'Latitude'),
          ('lng', 'Longitude'),
          ('avatarImage', 'Place icon image'),
        ],
        api: widget.api,
        parkSlug: _selectedSlug!,
      ),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        values.add(result);
      } else {
        values[index] = result;
      }
      map['places'] = values;
      _config!['parkMap'] = map;
    });
  }

  Future<void> _editMapZone(Map<String, dynamic> map, int? index) async {
    final values = List<Map<String, dynamic>>.from(
      (map['zones'] as List? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _RecordEditor(
        title: index == null ? 'Add map zone' : 'Edit map zone',
        values: index == null ? {} : values[index],
        schema: const [('name', 'Zone name'), ('description', 'Description')],
        api: widget.api,
        parkSlug: _selectedSlug!,
      ),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        values.add(result);
      } else {
        values[index] = result;
      }
      map['zones'] = values;
      _config!['parkMap'] = map;
    });
  }

  Future<Map<String, String>?> _simpleForm(
    String title,
    List<(String, String)> schema,
  ) async {
    final controllers = {
      for (final (key, _) in schema) key: TextEditingController(),
    };
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (key, label) in schema)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: controllers[key],
                    decoration: InputDecoration(
                      labelText: label,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, {
              for (final key in controllers.keys) key: controllers[key]!.text,
            }),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    for (final c in controllers.values) {
      c.dispose();
    }
    return result;
  }

  Future<bool> _confirm(String title, String content) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  Widget _subsectionHeader(String title, String subtitle, VoidCallback add) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 20, 2, 5),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: wonderlaNavy, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: add,
              icon: const Icon(Icons.add_circle_outline, color: _brandNavy),
            ),
          ],
        ),
      );
  Widget _textField(
    String label,
    String value,
    ValueChanged<String> changed, {
    int maxLines = 1,
  }) => TextFormField(
    initialValue: value,
    maxLines: maxLines,
    onChanged: changed,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
  );
  Widget _statusBadge(bool active) => Chip(
    label: Text(
      active ? 'Active' : 'Inactive',
      style: TextStyle(
        fontSize: 11,
        color: active ? wonderlaNavy : wonderlaNavy,
        fontWeight: FontWeight.w700,
      ),
    ),
    backgroundColor: active ? wonderlaNavy : wonderlaWhite,
    side: const BorderSide(color: wonderlaNavy),
    visualDensity: VisualDensity.compact,
  );
  Widget _thumbnail(String? url) => Container(
    width: 54,
    height: 54,
    decoration: BoxDecoration(
      color: wonderlaWhite,
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: url == null || url.isEmpty
        ? const Icon(Icons.image_outlined, color: _brandNavy)
        : Image.network(
            _absoluteImage(url),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
          ),
  );
  String _absoluteImage(String path) => Uri.tryParse(path)?.hasScheme == true
      ? path
      : '${widget.api.baseUrl}${path.startsWith('/') ? '' : '/'}$path';
  String _itemTitle(Map<String, dynamic> item) =>
      (item['title'] ?? item['name'] ?? item['ride'] ?? 'Untitled').toString();
  String _itemSubtitle(Map<String, dynamic> item) => [
    item['description'],
    item['time'] is num ? '${item['time']} min wait' : item['time'],
    item['cuisine'],
    item['checks'],
  ].where((e) => e != null && e.toString().isNotEmpty).join(' · ');
  IconData _iconFor(String key) => switch (key) {
    'Rides' => Icons.attractions_outlined,
    'Events' => Icons.event_outlined,
    'Dining & menus' => Icons.restaurant_outlined,
    'Live wait times' => Icons.timer_outlined,
    'Wave pool & rain dance' => Icons.waves_outlined,
    'Safety & hygiene' => Icons.health_and_safety_outlined,
    'Maintenance log' => Icons.build_outlined,
    'Ride guidelines' => Icons.straighten_outlined,
    _ => Icons.list_alt,
  };
  Widget _feedback(String message, {bool error = false, VoidCallback? retry}) =>
      Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: error ? wonderlaWhite : wonderlaWhite,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              color: error ? wonderlaFlagRed : wonderlaNavy,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: error ? wonderlaFlagRed : wonderlaNavy),
              ),
            ),
            if (retry != null)
              TextButton(onPressed: retry, child: const Text('Retry')),
          ],
        ),
      );
}
