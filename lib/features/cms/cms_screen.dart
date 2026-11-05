import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'cms_api.dart';
import '../../shared/scroll_reveal.dart';
import '../../shared/wonderla_palette.dart';

const _brandBlue = wonderlaCobalt;
const _ink = wonderlaNavy;

class CmsScreen extends StatefulWidget {
  const CmsScreen({super.key});
  @override
  State<CmsScreen> createState() => _CmsScreenState();
}

class _CmsScreenState extends State<CmsScreen> {
  final _api = CmsApi();
  Map<String, dynamic>? _user;
  bool _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    if (!_api.isConfigured) {
      setState(() => _checking = false);
      return;
    }
    try {
      final result = await _api.session();
      if (result['authenticated'] == true) {
        _user = Map<String, dynamic>.from(result['user'] as Map);
      }
    } catch (_) {}
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _brandBlue)),
      );
    }
    if (_user == null) {
      return _LoginPage(
        api: _api,
        onLogin: (u) => setState(() {
          _user = u;
          _error = null;
        }),
        initialError: _error,
      );
    }
    return _AdminDashboard(
      api: _api,
      user: _user!,
      onLogout: () async {
        try {
          await _api.logout();
        } catch (_) {}
        if (mounted) setState(() => _user = null);
      },
    );
  }
}

class _LoginPage extends StatefulWidget {
  const _LoginPage({
    required this.api,
    required this.onLogin,
    this.initialError,
  });
  final CmsApi api;
  final ValueChanged<Map<String, dynamic>> onLogin;
  final String? initialError;
  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _baseUrl = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _baseUrl.text = widget.api.baseUrl;
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _baseUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      widget.api.baseUrl = _baseUrl.text;
      final user = await widget.api.login(
        _username.text.trim(),
        _password.text,
      );
      widget.onLogin(user);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: wonderlaWhite,
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Card(
            color: Colors.white,
            elevation: 4,
            shadowColor: const Color(0x25071a3d),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/wonderla_logo.webp',
                        width: 230,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Content management',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Sign in to manage your park guide',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: wonderlaNavy),
                    ),
                    const SizedBox(height: 26),
                    TextFormField(
                      controller: _baseUrl,
                      decoration: const InputDecoration(
                        labelText: 'Backend website URL',
                        hintText: 'https://your-domain.com',
                        prefixIcon: Icon(Icons.language),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || Uri.tryParse(v)?.hasAuthority != true)
                          ? 'Enter the website URL that hosts the CMS API.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _username,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter your username.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: !_showPassword,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter your password.'
                          : null,
                    ),
                    if (_error != null || widget.initialError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error ?? widget.initialError!,
                        style: const TextStyle(color: wonderlaNavy),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _brandBlue,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Use your existing React CMS admin account. The backend URL is public configuration; never put server secrets here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: wonderlaNavy,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

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

  @override
  void initState() {
    super.initState();
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
    if (_config == null) return;
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
    return Scaffold(
      backgroundColor: wonderlaWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          children: [
            Image.asset(
              'assets/images/wonderla_logo.webp',
              width: 118,
              height: 42,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text(
              'Admin',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          if (_config != null &&
              _section != 'Users' &&
              _section != 'Google Maps settings' &&
              _section != 'Site URL & QR codes')
            TextButton.icon(
              onPressed: _saving ? null : _savePark,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving…' : 'Save changes'),
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
                  color: _brandBlue,
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
                    !{
                      'Parks',
                      'Users',
                      'Google Maps settings',
                      'Site URL & QR codes',
                    }.contains(name))
                  _navItem(name, icon),
            ],
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: wonderlaWhite,
            child: Icon(Icons.person_outline, color: _brandBlue),
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

  Widget _navItem(String title, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: ListTile(
      selected: _section == title,
      selectedColor: wonderlaWhite,
      selectedTileColor: _brandBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, size: 20),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      onTap: () {
        _changeSection(title);
        if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
      },
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
              !{
                'Parks',
                'Users',
                'Google Maps settings',
                'Site URL & QR codes',
              }.contains(title))
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
                selectedColor: _brandBlue,
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
      return const Center(child: CircularProgressIndicator(color: _brandBlue));
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
        if (_section == 'Park overview') ScrollReveal(child: _overview()),
        if (_section == 'Parks') ScrollReveal(child: _parksPage()),
        if (_listKeys.containsKey(_section))
          ScrollReveal(child: _collectionPage()),
        if (_section == 'Park map & places') ScrollReveal(child: _mapPage()),
        if (_section == 'Google Maps settings')
          ScrollReveal(child: _googleMapSettings()),
        if (_section == 'Users') ScrollReveal(child: _usersPage()),
        if (_section == 'Site URL & QR codes')
          ScrollReveal(child: _siteUrlPage()),
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
                    const Icon(Icons.edit_note, color: _brandBlue),
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
              leading: Icon(_iconFor(entry.key), color: _brandBlue),
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
              child: const Icon(Icons.park_outlined, color: _brandBlue),
            ),
            title: Text(p['name']?.toString() ?? ''),
            subtitle: Text('${p['location'] ?? ''} · /qr-code/${p['slug']}'),
            trailing: Wrap(
              spacing: 4,
              children: [
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
                    icon: const Icon(Icons.edit_outlined, color: _brandBlue),
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
          'Add visitor destinations with percent position and optional coordinates.',
          () => _editMapPlace(map, null),
        ),
        for (var i = 0; i < places.length; i++)
          Card(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.place_outlined, color: _brandBlue),
              title: Text(places[i]['name']?.toString() ?? 'Untitled place'),
              subtitle: Text(
                '${places[i]['category'] ?? 'Place'} · x ${places[i]['x'] ?? 0}% · y ${places[i]['y'] ?? 0}%',
              ),
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
                color: _brandBlue,
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
          ('lat', 'Latitude (optional)'),
          ('lng', 'Longitude (optional)'),
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
                    style: const TextStyle(
                      color: wonderlaNavy,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: add,
              icon: const Icon(Icons.add_circle_outline, color: _brandBlue),
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
        color: active ? wonderlaCobalt : wonderlaNavy,
        fontWeight: FontWeight.w700,
      ),
    ),
    backgroundColor: active ? wonderlaCobalt : wonderlaWhite,
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
        ? const Icon(Icons.image_outlined, color: _brandBlue)
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
              color: error ? wonderlaNavy : wonderlaCobalt,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: error ? wonderlaNavy : wonderlaCobalt,
                ),
              ),
            ),
            if (retry != null)
              TextButton(onPressed: retry, child: const Text('Retry')),
          ],
        ),
      );
}

class _RecordEditor extends StatefulWidget {
  const _RecordEditor({
    required this.title,
    required this.values,
    required this.schema,
    required this.api,
    required this.parkSlug,
    this.manageMenu = false,
  });
  final String title;
  final Map<String, dynamic> values;
  final List<(String, String)> schema;
  final CmsApi api;
  final String parkSlug;
  final bool manageMenu;
  @override
  State<_RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<_RecordEditor> {
  late final Map<String, dynamic> _values = Map<String, dynamic>.from(
    widget.values,
  );
  final _controllers = <String, TextEditingController>{};
  @override
  void initState() {
    super.initState();
    for (final (key, _) in widget.schema) {
      if (key == 'img' ||
          key == 'avatarImage' ||
          _values[key] is bool ||
          key == 'veg') {
        continue;
      }
      final v = _values[key];
      _controllers[key] = TextEditingController(
        text: v is List ? v.join(', ') : v?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (key, label) in widget.schema)
              if (key == 'img' || key == 'avatarImage')
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ImagePickerField(
                    api: widget.api,
                    parkSlug: widget.parkSlug,
                    label: label,
                    value: _values[key]?.toString() ?? '',
                    onChanged: (v) => setState(() => _values[key] = v),
                  ),
                )
              else if (_values[key] is bool ||
                  key == 'kioskBookingEnabled' ||
                  key == 'veg')
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(label),
                  value: _values[key] == true,
                  onChanged: (v) => setState(() => _values[key] = v),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: TextField(
                    controller: _controllers[key],
                    keyboardType:
                        {
                          'time',
                          'rideDuration',
                          'x',
                          'y',
                          'lat',
                          'lng',
                        }.contains(key)
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.multiline,
                    maxLines: {'description', 'checks'}.contains(key) ? 3 : 1,
                    decoration: InputDecoration(
                      labelText: label,
                      hintText: key == 'tags' || key == 'timeSlot'
                          ? 'Separate entries with commas'
                          : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
            if (widget.manageMenu) _menuItemsEditor(),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          for (final (key, _) in widget.schema) {
            final c = _controllers[key];
            if (c == null) continue;
            final raw = c.text.trim();
            if (key == 'tags' || key == 'timeSlot') {
              _values[key] = raw.isEmpty
                  ? <String>[]
                  : raw
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
            } else if ({
              'time',
              'rideDuration',
              'x',
              'y',
              'lat',
              'lng',
            }.contains(key)) {
              if (raw.isNotEmpty) {
                _values[key] = num.tryParse(raw) ?? raw;
              } else if (key == 'lat' || key == 'lng') {
                _values.remove(key);
              }
            } else {
              _values[key] = raw;
            }
          }
          Navigator.pop(context, _values);
        },
        child: const Text('Save item'),
      ),
    ],
  );

  Widget _menuItemsEditor() {
    final items = List<Map<String, dynamic>>.from(
      (_values['items'] as List? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 24),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Menu items',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        for (var i = 0; i < items.length; i++)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${items[i]['name'] ?? 'Dish'} · ${items[i]['price'] ?? ''}',
            ),
            subtitle: Text(
              items[i]['veg'] == true ? 'Vegetarian' : 'Non vegetarian',
            ),
            trailing: IconButton(
              onPressed: () => setState(() {
                items.removeAt(i);
                _values['items'] = items;
              }),
              icon: const Icon(Icons.delete_outline),
            ),
            onTap: () => _editDish(i, items),
          ),
        OutlinedButton.icon(
          onPressed: () => _editDish(null, items),
          icon: const Icon(Icons.add),
          label: const Text('Add menu item'),
        ),
      ],
    );
  }

  Future<void> _editDish(int? index, List<Map<String, dynamic>> items) async {
    final initial = index == null
        ? <String, dynamic>{'name': '', 'price': '', 'veg': false, 'img': ''}
        : Map<String, dynamic>.from(items[index]);
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _RecordEditor(
        title: index == null ? 'Add dish' : 'Edit dish',
        values: initial,
        schema: const [
          ('name', 'Dish name'),
          ('price', 'Price'),
          ('veg', 'Vegetarian'),
          ('img', 'Dish image'),
        ],
        api: widget.api,
        parkSlug: widget.parkSlug,
      ),
    );
    if (values == null) return;
    setState(() {
      if (index == null) {
        items.add(values);
      } else {
        items[index] = values;
      }
      _values['items'] = items;
    });
  }
}

class _ImagePickerField extends StatefulWidget {
  const _ImagePickerField({
    required this.api,
    required this.parkSlug,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final CmsApi api;
  final String parkSlug;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  @override
  State<_ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<_ImagePickerField> {
  bool _uploading = false;
  String? _error;
  Uint8List? _preview;
  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw const CmsApiException('Choose an image under 5 MB.');
      }
      final url = await widget.api.uploadImage(widget.parkSlug, file);
      if (mounted) setState(() => _preview = bytes);
      widget.onChanged(url);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _absolute(String path) => Uri.tryParse(path)?.hasScheme == true
      ? path
      : '${widget.api.baseUrl}${path.startsWith('/') ? '' : '/'}$path';
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.label,
        style: const TextStyle(
          fontSize: 12,
          color: wonderlaNavy,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: wonderlaWhite,
          border: Border.all(color: wonderlaCobalt),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: wonderlaWhite,
                borderRadius: BorderRadius.circular(11),
              ),
              clipBehavior: Clip.antiAlias,
              child: _preview != null
                  ? Image.memory(_preview!, fit: BoxFit.cover)
                  : widget.value.isEmpty
                  ? const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: _brandBlue,
                      size: 28,
                    )
                  : Image.network(
                      _absolute(widget.value),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: wonderlaNavy,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.value.isEmpty ? 'No image selected' : 'Image ready',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.value.isEmpty
                        ? 'Upload PNG, JPG, WebP or GIF. Maximum 5 MB.'
                        : widget.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: wonderlaNavy,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _pick,
                    icon: _uploading
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_outlined, size: 17),
                    label: Text(
                      _uploading
                          ? 'Uploading…'
                          : widget.value.isEmpty
                          ? 'Choose image'
                          : 'Replace image',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            _error!,
            style: const TextStyle(color: wonderlaNavy, fontSize: 12),
          ),
        ),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: widget.value,
        onChanged: widget.onChanged,
        decoration: const InputDecoration(
          labelText: 'Or paste an image URL',
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    ],
  );
}

class _ApiKeyCard extends StatefulWidget {
  const _ApiKeyCard({
    required this.api,
    required this.configured,
    required this.onSaved,
  });
  final CmsApi api;
  final bool configured;
  final VoidCallback onSaved;
  @override
  State<_ApiKeyCard> createState() => _ApiKeyCardState();
}

class _ApiKeyCardState extends State<_ApiKeyCard> {
  final _controller = TextEditingController();
  bool _configured = false;
  bool _saving = false;
  String? _error;
  String? _message;
  @override
  void initState() {
    super.initState();
    _configured = widget.configured;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _message = null;
    });
    try {
      await widget.api.saveMapSettings(_controller.text.trim());
      setState(() {
        _configured = _controller.text.trim().isNotEmpty;
        _message = 'Map API key saved.';
        _controller.clear();
      });
      widget.onSaved();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Google Maps API key',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 8),
          const Text(
            'The existing React map reads this key from the admin API. Key is hidden after save; enter a new value to replace it or submit an empty value only if the backend permits clearing.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: true,
            decoration: InputDecoration(
              labelText: _configured
                  ? 'A key is configured · paste replacement'
                  : 'Paste your browser API key',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.key_outlined),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving || _controller.text.trim().isEmpty
                ? null
                : _save,
            child: Text(_saving ? 'Saving…' : 'Save key'),
          ),
          if (_message != null)
            Text(_message!, style: const TextStyle(color: wonderlaCobalt)),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: wonderlaNavy)),
          const SizedBox(height: 12),
          const Text(
            'Restrict this browser key to the required Google Maps APIs and your web domains. This key is public to visitors; do not enter server credentials.',
            style: TextStyle(fontSize: 12, color: wonderlaNavy),
          ),
        ],
      ),
    ),
  );
}

class _UsersManager extends StatefulWidget {
  const _UsersManager({
    required this.api,
    required this.users,
    required this.parks,
    required this.currentUsername,
    required this.reload,
  });
  final CmsApi api;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> parks;
  final String currentUsername;
  final Future<void> Function() reload;
  @override
  State<_UsersManager> createState() => _UsersManagerState();
}

class _UsersManagerState extends State<_UsersManager> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  String _role = 'park';
  String? _park;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    if (widget.parks.isNotEmpty) _park = widget.parks.first['slug'] as String;
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.createUser({
        'username': _username.text.trim(),
        'password': _password.text,
        'role': _role,
        if (_role == 'park') 'parkSlug': _park,
      });
      _username.clear();
      _password.clear();
      await widget.reload();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _delete(String username) async {
    if (username == widget.currentUsername) return;
    final yes =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete user?'),
            content: Text('Remove $username access?'),
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
    if (!yes) return;
    try {
      await widget.api.deleteUser(username);
      await widget.reload();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Card(
        color: Colors.white,
        child: Column(
          children: [
            for (final u in widget.users)
              ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    u['role'] == 'superadmin'
                        ? Icons.admin_panel_settings
                        : Icons.person_outline,
                  ),
                ),
                title: Text(u['username']?.toString() ?? ''),
                subtitle: Text(
                  '${u['role']} · ${u['parkSlug'] ?? 'All parks'}',
                ),
                trailing: u['username'] == widget.currentUsername
                    ? const Chip(label: Text('You'))
                    : IconButton(
                        onPressed: () => _delete(u['username'] as String),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: wonderlaNavy,
                        ),
                      ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add admin user',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _username,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password · at least 6 characters',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'park', child: Text('Park editor')),
                  DropdownMenuItem(
                    value: 'superadmin',
                    child: Text('Superadmin'),
                  ),
                ],
                onChanged: (v) => setState(() => _role = v ?? 'park'),
              ),
              if (_role == 'park' && widget.parks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: _park,
                    decoration: const InputDecoration(
                      labelText: 'Assigned park',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final p in widget.parks)
                        DropdownMenuItem(
                          value: p['slug'] as String,
                          child: Text(p['name'] as String),
                        ),
                    ],
                    onChanged: (v) => setState(() => _park = v),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: wonderlaNavy),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed:
                    _busy ||
                        _username.text.trim().isEmpty ||
                        _password.text.length < 6
                    ? null
                    : _create,
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(_busy ? 'Creating…' : 'Create user'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.title, this.subtitle);
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 38, color: _brandBlue),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: wonderlaNavy),
          ),
        ],
      ),
    ),
  );
}
