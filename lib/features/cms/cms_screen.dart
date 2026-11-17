import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'cms_api.dart';
import 'qr_download.dart';
import '../../shared/scroll_reveal.dart';
import '../../shared/wonderla_palette.dart';

part 'cms_login_screen.dart';
part 'cms_admin_dashboard.dart';
part 'cms_record_editor.dart';
part 'cms_image_picker_field.dart';
part 'cms_api_key_card.dart';
part 'cms_users_manager.dart';

const _brandNavy = wonderlaCobalt;
const _ink = wonderlaNavy;

bool _hasValidMapCoordinates(Map<String, dynamic> place) {
  final latitude = double.tryParse('${place['lat']}');
  final longitude = double.tryParse('${place['lng']}');
  return latitude != null &&
      longitude != null &&
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

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
        body: Center(child: CircularProgressIndicator(color: _brandNavy)),
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
          const Icon(Icons.inbox_outlined, size: 38, color: _brandNavy),
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
