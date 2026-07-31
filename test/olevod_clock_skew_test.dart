import 'dart:io' show HttpDate;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/video/data/demo_olevod/olevod_data_source.dart';
import 'package:vidra/src/features/video/data/demo_olevod/video_signature_helper.dart';

/// Answers 401 until it sees a `_vv` signed within an hour of [serverTime],
/// the way api.olelive.com does, and reports [serverTime] in the `Date` header.
class _SkewedClockAdapter implements HttpClientAdapter {
  _SkewedClockAdapter(this.serverTime);

  final DateTime serverTime;
  final List<String> signatures = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final sign = options.queryParameters['_vv'] as String;
    signatures.add(sign);
    final date = {
      'date': [HttpDate.format(serverTime)],
    };

    // Brute-force the second the signature was made for; anything more than an
    // hour from the server's clock is rejected.
    final base = serverTime.millisecondsSinceEpoch ~/ 1000;
    final accepted = List.generate(7201, (i) => base - 3600 + i)
        .any((s) => VideoSignatureHelper.generate(
              DateTime.fromMillisecondsSinceEpoch(s * 1000),
            ) == sign);

    if (!accepted) {
      // text/plain, like the real API — the body is not JSON.
      return ResponseBody.fromString('用户签名非法', 401, headers: date);
    }
    return ResponseBody.fromString(
      '{"code":0,"data":{"list":[],"total":0,"page":1}}',
      200,
      headers: {
        ...date,
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('a device whose clock is 8h off still loads the list', () async {
    // What a wrong time zone looks like: local time reads fine, UTC does not.
    final adapter = _SkewedClockAdapter(
      DateTime.now().subtract(const Duration(hours: 8)),
    );
    final dio = Dio()..httpClientAdapter = adapter;

    final response = await OlevodDataSource(dio).fetchVideos(categoryId: 1);

    expect(response.list, isEmpty); // the stub serves an empty page
    expect(adapter.signatures, hasLength(2)); // rejected once, then corrected
    expect(adapter.signatures.first, isNot(adapter.signatures.last));
  });

  test('a correct clock costs no extra request', () async {
    final adapter = _SkewedClockAdapter(DateTime.now());
    final dio = Dio()..httpClientAdapter = adapter;

    await OlevodDataSource(dio).fetchVideos(categoryId: 1);

    expect(adapter.signatures, hasLength(1));
  });
}
