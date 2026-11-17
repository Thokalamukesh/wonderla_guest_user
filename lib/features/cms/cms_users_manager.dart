part of 'cms_screen.dart';

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
  bool _allAccess = true;
  final Set<String> _selectedAccess = {};
  static const _accessSections = [
    'Park overview',
    'Rides',
    'Events',
    'Dining & menus',
    'Live wait times',
    'Wave pool & rain dance',
    'Safety & hygiene',
    'Maintenance log',
    'Ride guidelines',
    'Park map & places',
  ];
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
        if (_role == 'park')
          'permissions': _allAccess ? ['all'] : _selectedAccess.toList(),
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

  Future<void> _editAccess(Map<String, dynamic> user) async {
    if (user['role'] != 'park' || user['username'] == widget.currentUsername) return;
    final current = List<String>.from(user['permissions'] as List? ?? const ['all']);
    var all = current.contains('all');
    final selected = <String>{if (!all) ...current};
    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => AlertDialog(
        title: Text('Access for ${user['username']}'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          SwitchListTile(title: const Text('All sections'), value: all, onChanged: (v) => refresh(() => all = v)),
          if (!all) ..._accessSections.map((section) => CheckboxListTile(
            dense: true, title: Text(section), value: selected.contains(section),
            onChanged: (v) => refresh(() => v == true ? selected.add(section) : selected.remove(section)),
          )),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: !all && selected.isEmpty ? null : () => Navigator.pop(ctx, all ? ['all'] : selected.toList()), child: const Text('Save access'))],
      )),
    );
    if (result == null) return;
    try {
      await widget.api.updateUserPermissions(user['username'] as String, result);
      await widget.reload();
    } catch (e) { setState(() => _error = e.toString()); }
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
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (u['role'] == 'park') IconButton(tooltip: 'Edit section access', onPressed: () => _editAccess(u), icon: const Icon(Icons.tune_rounded)),
                      IconButton(
                        onPressed: () => _delete(u['username'] as String),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: wonderlaNavy,
                        ),
                      ),
                    ]),
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
              if (_role == 'park') ...[
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Access to all sections'),
                  subtitle: const Text('Turn off to choose specific sections.'),
                  value: _allAccess,
                  onChanged: (value) => setState(() => _allAccess = value),
                ),
                if (!_allAccess)
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      for (final section in _accessSections)
                        FilterChip(
                          label: Text(section),
                          selected: _selectedAccess.contains(section),
                          onSelected: (selected) => setState(() {
                            selected
                                ? _selectedAccess.add(section)
                                : _selectedAccess.remove(section);
                          }),
                        ),
                    ],
                  ),
              ],
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
                        _password.text.length < 6 ||
                        (_role == 'park' &&
                            !_allAccess &&
                            _selectedAccess.isEmpty)
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
