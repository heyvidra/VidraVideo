// The demo sources ban IPs under request storms, so plain navigation must
// not map one-to-one onto network fetches. These tests pin the three cache
// layers added for that: list responses, search responses, and the detail
// freshness window that guards the forceRefresh path (on dbku one detail
// fetch fans out into a play-page request per episode).

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/core/utils/ttl_cache.dart';
import 'package:vidra/src/data/database/app_database.dart' hide Video;
import 'package:vidra/src/features/video/data/demo_dbku/dbku_data_source.dart';
import 'package:vidra/src/features/video/data/video_data_source.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/features/video/domain/category.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';

class CountingSource implements VideoDataSource {
  int listCalls = 0;
  int detailCalls = 0;
  int searchCalls = 0;

  @override
  String get id => 'counting';
  @override
  String get name => 'Counting';

  @override
  Future<List<Category>> getCategories() async => const [];

  @override
  Future<VideoResponse> fetchVideos({
    required int categoryId,
    int? subTypeId,
    String? area,
    String? year,
    int page = 1,
  }) async {
    listCalls++;
    return VideoResponse(
      list: [
        Video(apiId: 1, sourceId: id, title: 'A', coverUrl: '', rating: 0),
      ],
      total: 1,
      page: page,
    );
  }

  @override
  Future<Video?> getVideoDetail(int id, {String? sourceKey}) async {
    detailCalls++;
    return Video(
      apiId: id,
      sourceId: this.id,
      title: 'A',
      coverUrl: '',
      rating: 0,
      urls: const [
        VideoEpisode(
          index: 0,
          title: 'E1',
          qualities: [VideoQuality(name: 'hd', url: 'http://x/1.m3u8')],
        ),
      ],
    );
  }

  @override
  Future<List<Video>> searchVideos(String keyword) async {
    searchCalls++;
    return [
      Video(apiId: 2, sourceId: id, title: keyword, coverUrl: '', rating: 0),
    ];
  }

  @override
  Future<String?> resolveEpisodeUrl(String url) async => url;

  @override
  String? get pingHost => null;

  @override
  Map<String, String>? get streamHeaders => null;

  @override
  String resolveUrl(String url) => url;

  @override
  Future<String?> getDownloadUrl(Video video, {VideoEpisode? episode}) async =>
      null;
}

/// A catalog that gains episodes between visits, and never volunteers a `new`
/// flag of its own — dbku's shape, which is the case the source field could not
/// serve.
class GrowingSource extends CountingSource {
  int episodes = 1;

  @override
  Future<Video?> getVideoDetail(int id, {String? sourceKey}) async {
    detailCalls++;
    return Video(
      apiId: id,
      sourceId: this.id,
      title: 'A',
      coverUrl: '',
      rating: 0,
      urls: [
        for (var n = 1; n <= episodes; n++)
          VideoEpisode(
            index: n - 1,
            title: '第$n集',
            qualities: [VideoQuality(name: 'hd', url: 'http://x/$n.m3u8')],
          ),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TtlCache', () {
    test('expires by ttl and evicts oldest at the cap', () {
      var now = DateTime(2026, 8, 1);
      final cache = TtlCache<String, int>(
        ttl: const Duration(minutes: 10),
        maxEntries: 2,
        clock: () => now,
      );
      cache.set('a', 1);
      expect(cache.get('a'), 1);

      now = now.add(const Duration(minutes: 11));
      expect(cache.get('a'), isNull, reason: 'past ttl');

      cache.set('a', 1);
      now = now.add(const Duration(minutes: 1));
      cache.set('b', 2);
      cache.set('c', 3); // over cap: 'a' is oldest and must go
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), 2);
      expect(cache.get('c'), 3);
    });
  });

  group('VideoRepository request caching', () {
    late CountingSource source;
    late AppDatabase database;
    late VideoRepository repo;

    setUp(() {
      source = CountingSource();
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repo = VideoRepository(source, [source], database);
    });

    tearDown(() => database.close());

    test(
      'an identical list query within the window is served from cache',
      () async {
        await repo.fetchVideos(categoryId: 1);
        await repo.fetchVideos(categoryId: 1);
        expect(source.listCalls, 1);

        // A different tuple is a different key.
        await repo.fetchVideos(categoryId: 1, page: 2);
        expect(source.listCalls, 2);

        // And the escape hatch still reaches the network.
        await repo.fetchVideos(categoryId: 1, forceRefresh: true);
        expect(source.listCalls, 3);
      },
    );

    test('a repeated search is served from cache', () async {
      await repo.searchVideosAllSources('foo');
      await repo.searchVideosAllSources('foo');
      expect(source.searchCalls, 1);
      await repo.searchVideosAllSources('bar');
      expect(source.searchCalls, 2);
    });

    test(
      'forceRefresh within the freshness window becomes a cache read',
      () async {
        // First visit: network (and the row lands in drift with episodes).
        await repo.getVideo(7, forceRefresh: true);
        expect(source.detailCalls, 1);

        // Re-entering the detail seconds later must NOT refetch — on dbku
        // this is the difference between 0 requests and one per episode.
        final v = await repo.getVideo(7, forceRefresh: true);
        expect(source.detailCalls, 1);
        expect(v?.urls, isNotEmpty, reason: 'served from the drift cache');
      },
    );
  });

  group('新 badge is computed, not taken from the source', () {
    // olevod ships a `new` field and dbku ships none, so the same show wore
    // orange dots on one catalog's page and none on the other's. The badge is
    // now our own diff against the previous snapshot — the same rule for every
    // catalog, and a better answer than the field, which marked 第14集 new to a
    // viewer who had already watched it on the other source.
    late GrowingSource source;
    late AppDatabase database;

    setUp(() {
      source = GrowingSource();
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() => database.close());

    // A fresh repository over the SAME database is the honest way to express
    // "later, after the show updated": the detail freshness window deliberately
    // downgrades a forceRefresh minutes after the last fetch, so re-asking the
    // same instance is a cache read by design and would never reach the diff.
    Future<Video?> visit() => VideoRepository(source, [
      source,
    ], database).getVideo(1, forceRefresh: true);

    test('a first sighting marks nothing, then only what appeared', () async {
      source.episodes = 3;
      final first = await visit();
      expect(
        first!.urls!.every((e) => e.isNew != true),
        isTrue,
        reason: 'no previous snapshot for anything to have appeared since',
      );

      source.episodes = 5;
      final second = await visit();
      expect(
        second!.urls!.map((e) => e.isNew == true).toList(),
        [false, false, false, true, true],
        reason: 'only 第4集 and 第5集 were absent last time',
      );

      // The badge means "appeared since you last looked", not "recently
      // aired", so a visit that finds nothing added clears it.
      final third = await visit();
      expect(third!.urls!.every((e) => e.isNew != true), isTrue);
    });
  });

  group('dbku session resolution cache', () {
    const detail2 =
        '<h1 class="title">T</h1>'
        '<a class="btn btn-default" href="/vodplay/9-1-1.html">第1集</a>'
        '<a class="btn btn-default" href="/vodplay/9-1-2.html">第2集</a>';
    const detail3 =
        '<h1 class="title">T</h1>'
        '<a class="btn btn-default" href="/vodplay/9-1-1.html">第1集</a>'
        '<a class="btn btn-default" href="/vodplay/9-1-2.html">第2集</a>'
        '<a class="btn btn-default" href="/vodplay/9-1-3.html">第3集</a>';
    String play(int n) =>
        '<script>player_aaaa = {"url":"http://cdn/e$n.m3u8","encrypt":0}</script>';

    test(
      'a repeat detail fetch only resolves episodes it has never seen',
      () async {
        final pages = {
          '/voddetail/9.html': detail2,
          '/vodplay/9-1-1.html': play(1),
          '/vodplay/9-1-2.html': play(2),
          '/vodplay/9-1-3.html': play(3),
        };
        final adapter = _FakePages(pages);
        final dio = Dio()..httpClientAdapter = adapter;
        final ds = DbkuDataSource(dio);

        final v1 = await ds.getVideoDetail(9);
        expect(v1?.urls, hasLength(2));
        expect(adapter.requests.where((p) => p.contains('vodplay')).length, 2);

        // The show gained one episode; the run must not be re-resolved.
        pages['/voddetail/9.html'] = detail3;
        final v2 = await ds.getVideoDetail(9);
        expect(v2?.urls, hasLength(3));
        expect(
          adapter.requests.where((p) => p.contains('vodplay')).length,
          3,
          reason: 'only the NEW episode pays a play-page request',
        );
        expect(v2!.urls![0].qualities!.single.url, 'http://cdn/e1.m3u8');
        expect(v2.urls![2].qualities!.single.url, 'http://cdn/e3.m3u8');
      },
    );
  });
}

// --- dbku session resolution cache -----------------------------------------

class _FakePages implements HttpClientAdapter {
  _FakePages(this.pages);
  final Map<String, String> pages;
  final requests = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri.path);
    return ResponseBody.fromString(
      pages[options.uri.path] ?? '',
      200,
      headers: {
        Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
