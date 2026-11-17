import 'dart:typed_data';

import 'qr_download_stub.dart'
    if (dart.library.html) 'qr_download_web.dart'
    as platform;

Future<void> downloadQrPng(Uint8List bytes, String filename) =>
    platform.downloadQrPng(bytes, filename);
