part of 'cms_screen.dart';

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
            Text(_message!, style: const TextStyle(color: wonderlaNavy)),
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
