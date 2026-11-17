part of 'cms_screen.dart';

class _ImagePickerField extends StatefulWidget {
  const _ImagePickerField({
    required this.api,
    required this.parkSlug,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onUploaded,
  });
  final CmsApi api;
  final String parkSlug;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final Future<void> Function(String url)? onUploaded;
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
      await widget.onUploaded?.call(url);
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
          border: Border.all(color: wonderlaNavy),
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
                      color: _brandNavy,
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
                    style: const TextStyle(color: wonderlaNavy, fontSize: 11),
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
