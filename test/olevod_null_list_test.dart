import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/video/data/demo_olevod/olevod_data_source.dart';

/// Serves what api.olelive.com actually returns for a filter combination with
/// no matches (seen live with 综艺+英国): code 0, but "list" is null rather
/// than an empty array.
class _NullListAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"code":0,"data":{"list":null,"total":0,"page":1}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('an empty filter result ("list": null) is an empty page, not a crash',
      () async {
    final dio = Dio()..httpClientAdapter = _NullListAdapter();

    final response = await OlevodDataSource(dio).fetchVideos(
      categoryId: 3, // 综艺
      area: '英国',
    );

    expect(response.list, isEmpty);
    expect(response.total, 0);
    expect(response.page, 1);
  });
}
