import 'dart:convert';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> downloadQrPng(Uint8List bytes, String filename) async {
  final data = 'data:image/png;base64,${base64Encode(bytes)}';
  web.HTMLAnchorElement()
    ..href = data
    ..download = filename
    ..click();
}
