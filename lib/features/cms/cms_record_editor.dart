part of 'cms_screen.dart';

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
  String? _coordinateError;

  bool get _isMapPlaceEditor =>
      widget.schema.any((field) => field.$1 == 'lat') &&
      widget.schema.any((field) => field.$1 == 'lng');

  Widget _coordinatesEditor() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F6FA),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE1E7EF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enable walking directions',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'In Google Maps, right-click the exact spot on desktop or long-press it on a phone, then copy the coordinate pair. Enter the first number as Latitude and the second as Longitude. Save this item, then save the map configuration.',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final fields = [
              ('lat', 'Latitude', 'e.g. 12.8343'),
              ('lng', 'Longitude', 'e.g. 77.4010'),
            ];
            final children = fields
                .map(
                  (field) => TextField(
                    controller: _controllers[field.$1],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    onChanged: (_) => setState(() => _coordinateError = null),
                    decoration: InputDecoration(
                      labelText: field.$2,
                      hintText: field.$3,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                )
                .toList();
            if (constraints.maxWidth < 420) {
              return Column(
                children: [
                  children[0],
                  const SizedBox(height: 10),
                  children[1],
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: children[0]),
                const SizedBox(width: 10),
                Expanded(child: children[1]),
              ],
            );
          },
        ),
        if (_coordinateError != null) ...[
          const SizedBox(height: 8),
          Text(
            _coordinateError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    ),
  );

  bool _validateCoordinates() {
    final latitudeText = _controllers['lat']?.text.trim() ?? '';
    final longitudeText = _controllers['lng']?.text.trim() ?? '';
    String? error;
    if (latitudeText.isEmpty != longitudeText.isEmpty) {
      error = 'Enter both latitude and longitude.';
    } else if (latitudeText.isNotEmpty) {
      final latitude = double.tryParse(latitudeText);
      final longitude = double.tryParse(longitudeText);
      if (latitude == null ||
          longitude == null ||
          !latitude.isFinite ||
          !longitude.isFinite) {
        error = 'Enter valid numeric coordinates.';
      } else if (latitude < -90 || latitude > 90) {
        error = 'Latitude must be between −90 and 90.';
      } else if (longitude < -180 || longitude > 180) {
        error = 'Longitude must be between −180 and 180.';
      }
    }
    setState(() => _coordinateError = error);
    return error == null;
  }

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
            if (_isMapPlaceEditor) _coordinatesEditor(),
            for (final (key, label) in widget.schema)
              if (_isMapPlaceEditor && (key == 'lat' || key == 'lng'))
                const SizedBox.shrink()
              else if (key == 'img' || key == 'avatarImage')
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
          if (_isMapPlaceEditor && !_validateCoordinates()) return;
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
