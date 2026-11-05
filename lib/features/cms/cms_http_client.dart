import 'package:http/http.dart' as http;

import 'cms_http_client_stub.dart'
    if (dart.library.html) 'cms_http_client_web.dart'
    as platform;

http.Client createCmsHttpClient() => platform.createCmsHttpClient();
