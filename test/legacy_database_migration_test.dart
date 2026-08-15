import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vidra/src/data/database/app_database.dart';

/// The bundle rename moves an existing macOS install's whole library, so this
/// is tested on the ways that can go wrong rather than on the happy path
/// alone: a partial move that strands the WAL, and a failed move that lets an
/// empty database take the real one's place.
void main() {
  late Directory root;
  late Directory legacy;
  late Directory current;
  late File target;

  setUp(() {
    root = Directory.systemTemp.createTempSync('vidra_migration');
    legacy = Directory(p.join(root.path, 'com.example.videoapp.video'))
      ..createSync();
    // path_provider creates this before handing it over, so every test starts
    // with it already present and empty.
    current = Directory(p.join(root.path, 'com.vidra.app'))..createSync();
    target = File(p.join(current.path, 'vidradb.sqlite'));
  });

  tearDown(() => root.deleteSync(recursive: true));

  File legacyFile(String name) => File(p.join(legacy.path, name));

  test('moves the whole library, database and sidecars together', () async {
    legacyFile('vidradb.sqlite').writeAsStringSync('main');
    legacyFile('vidradb.sqlite-wal').writeAsStringSync('wal');
    legacyFile('vidradb.sqlite-shm').writeAsStringSync('shm');
    legacyFile('libCachedImageData.db').writeAsStringSync('covers');
    Directory(p.join(legacy.path, 'thumbs')).createSync();

    final opened = await resolveDatabaseFile(
      legacyFolder: legacy,
      target: target,
    );

    expect(opened.path, target.path);
    expect(target.readAsStringSync(), 'main');
    expect(File('${target.path}-wal').readAsStringSync(), 'wal');
    expect(File('${target.path}-shm').readAsStringSync(), 'shm');
    expect(
      File(p.join(current.path, 'libCachedImageData.db')).readAsStringSync(),
      'covers',
    );
    expect(Directory(p.join(current.path, 'thumbs')).existsSync(), isTrue);
    expect(legacy.existsSync(), isFalse);
  });

  // The failure that would otherwise be permanent: drift creating an empty
  // database at the new path makes the already-migrated check true forever.
  test('a failed move opens the old library in place, untouched', () async {
    legacyFile('vidradb.sqlite').writeAsStringSync('main');
    legacyFile('vidradb.sqlite-wal').writeAsStringSync('wal');
    // Something else is already in the new directory, so it cannot be cleared
    // out of the way and the rename onto it fails.
    File(p.join(current.path, 'stray.txt')).writeAsStringSync('x');

    final opened = await resolveDatabaseFile(
      legacyFolder: legacy,
      target: target,
    );

    expect(opened.path, legacyFile('vidradb.sqlite').path);
    expect(opened.readAsStringSync(), 'main');
    // Nothing moved: the WAL is still beside the database it belongs to.
    expect(legacyFile('vidradb.sqlite-wal').existsSync(), isTrue);
    expect(target.existsSync(), isFalse);
  });

  test('never overwrites a database already in the new location', () async {
    target.writeAsStringSync('current');
    legacyFile('vidradb.sqlite').writeAsStringSync('stale');

    final opened = await resolveDatabaseFile(
      legacyFolder: legacy,
      target: target,
    );

    expect(opened.path, target.path);
    expect(target.readAsStringSync(), 'current');
    expect(legacyFile('vidradb.sqlite').existsSync(), isTrue);
  });

  test('a fresh install migrates nothing', () async {
    final opened = await resolveDatabaseFile(
      legacyFolder: legacy,
      target: target,
    );

    expect(opened.path, target.path);
    expect(target.existsSync(), isFalse);
  });

  test('an old directory without a database is left alone', () async {
    legacyFile('libCachedImageData.db').writeAsStringSync('covers');

    final opened = await resolveDatabaseFile(
      legacyFolder: legacy,
      target: target,
    );

    expect(opened.path, target.path);
    expect(legacyFile('libCachedImageData.db').existsSync(), isTrue);
  });

  test('a missing old directory is not an error', () async {
    legacy.deleteSync();

    final opened = await resolveDatabaseFile(
      legacyFolder: legacy,
      target: target,
    );

    expect(opened.path, target.path);
  });
}
