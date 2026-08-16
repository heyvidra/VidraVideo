import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'browser_headers.dart';

/// Shared Dio instance. Error mapping to ApiException happens at the data
/// source layer (see olevod_data_source) so callers get typed failures.
///
/// The [BrowserHeaders] interceptor is what every catalog request inherits its
/// identity from. It covers this instance only — which is three call sites in
/// two data sources — so anything reaching the network another way attaches the
/// same headers itself; see [BrowserHeaders.apply].
final dioProvider = Provider<Dio>((ref) {
  return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    )
    ..interceptors.add(const BrowserHeaders());
});
