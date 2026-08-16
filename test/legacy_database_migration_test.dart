import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vidra/src/data/database/app_database.dart';

/// The bundle rename moves an existing macOS install's whole library, so this
/// is tested on the ways that can go wrong rather than on the happy path
/// alone: a partial move that strands the WAL, and a failed move that lets an
/// empty database take the real one's place.
///
/// There are two old identifiers now, not one. 1.13.0 spent a single release
/// on `com.vidra.app` before that turned out to name an application bundle
/// rather than a folder, so an install can arrive from either.
void main() {
  late Directory root;
  late Directory placeholder;
  late Directory dotApp;
  late Directory current;
  late File target;

  setUp(() {
    root = Directory.systemTemp.createTempSync('vidra_migration');
    placeholder = Directory(p.join(root.path, 'com.example.videoapp.video'))
      ..createSync();
    dotApp = Directory(p.join(root.path, 'com.vidra.app'))..createSync();
    // path_provider creates this before handing it over, so every test starts
    // with it already present and empty.
    current = Directory(p.join(root.path, 'com.vidra.video'))..createSync();
    target = File(p.join(current.path, 'vidradb.sqlite'));
  });

  tearDown(() => root.deleteSync(recursive: true));

  /// Newest first, exactly as the app passes them.
  List<Directory> chain() => [dotApp, placeholder];

  File dbIn(Directory d) => File(p.join(d.path, 'vidradb.sqlite'));

  test('moves the whole library, database and sidecars together', () async {
    dbIn(placeholder).writeAsStringSync('main');
    File(p.join(placeholder.path, 'vidradb.sqlite-wal')).writeAsStringSync('w');
    File(p.join(placeholder.path, 'vidradb.sqlite-shm')).writeAsStringSync('s');
    File(p.join(placeholder.path, 'libCachedImageData.db')).writeAsStringSync(
      'covers',
    );
    Directory(p.join(placeholder.path, 'thumbs')).createSync();

    final opened = await resolveDatabaseFile(
      legacyFolders: chain(),
      target: target,
    );

    expect(opened.path, target.path);
    expect(target.readAsStringSync(), 'main');
    expect(File('${target.path}-wal').readAsStringSync(), 'w');
    expect(File('${target.path}-shm').readAsStringSync(), 's');
    expect(
      File(p.join(current.path, 'libCachedImageData.db')).readAsStringSync(),
      'covers',
    );
    expect(Directory(p.join(current.path, 'thumbs')).existsSync(), isTrue);
    expect(placeholder.existsSync(), isFalse);
  });

  test('an install coming from the one-release .app id migrates too', () async {
    dbIn(dotApp).writeAsStringSync('from 1.13.0');

    final opened = await resolveDatabaseFile(
      legacyFolders: chain(),
      target: target,
    );

    expect(opened.path, target.path);
    expect(target.readAsStringSync(), 'from 1.13.0');
    expect(dotApp.existsSync(), isFalse);
  });

  // A machine that ran 1.12.2, updated to 1.13.0, and is now updating again
  // has both directories on disk — the placeholder left behind by whatever
  // relaunched an old build after the first migration.
  test('with two old libraries the newer one wins', () async {
    dbIn(dotApp).writeAsStringSync('newer');
    dbIn(placeholder).writeAsStringSync('stale');

    final opened = await resolveDatabaseFile(
      legacyFolders: chain(),
      target: target,
    );

    expect(target.readAsStringSync(), 'newer');
    expect(opened.path, target.path);
    // The stale one is left alone rather than deleted; it is not ours to throw
    // away, and the next launch has nowhere to put it anyway.
    expect(dbIn(placeholder).readAsStringSync(), 'stale');
  });

  // The failure that would otherwise be permanent: drift creating an empty
  // database at the new path makes the already-migrated check true forever.
  test('a failed move opens the old library in place, untouched', () async {
    dbIn(placeholder).writeAsStringSync('main');
    File(p.join(placeholder.path, 'vidradb.sqlite-wal')).writeAsStringSync('w');
    // Something else is already in the new directory, so it cannot be cleared
    // out of the way and the rename onto it fails.
    File(p.join(current.path, 'stray.txt')).writeAsStringSync('x');

    final opened = await resolveDatabaseFile(
      legacyFolders: chain(),
      target: target,
    );

    expect(opened.path, dbIn(placeholder).path);
    expect(opened.readAsStringSync(), 'main');
    // Nothing moved: the WAL is still beside the database it belongs to.
    expect(
      File(p.join(placeholder.path, 'vidradb.sqlite-wal')).existsSync(),
      isTrue,
    );
    expect(target.existsSync(), isFalse);
  });

  test('never overwrites a database already in the new location', () async {
    target.writeAsStringSync('current');
    dbIn(dotApp).writeAsStringSync('stale');

    final opened = await resolveDatabaseFile(
      legacyFolders: chain(),
      target: target,
    );

    expect(opened.path, target.path);
    expect(target.readAsStringSync(), 'current');
    expect(dbIn(dotApp).existsSync(), isTrue);
  });

  test('a fresh install migrates nothing', () async {
    final opened = await resolveDatabaseFile(
      legacyFolders: chain(),
      target: target,
    );

    expect(opened.path, target.path);
    expect(target.existsSync(), isFalse);
  });

  test('an old directory without a database is skipped, not claimed', () async {
    File(p.join(dotApp.path, 'libCachedImageData.db')).writeAsStringSync('c');
    dbIn(placeholder).writeAsStringSync('main');

    final opened = await resolveDatabaseFile(
      legacyFolders: chain(),
      target: target,
    );

    // The .app directory has no database, so the placeholder is what moves.
    expect(opened.path, target.path);
    expect(target.readAsStringSync(), 'main');
  });

  test('missing old directories are not an error', () async {
    dotApp.deleteSync();
    placeholder.deleteSync();

    final opened = await resolveDatabaseFile(
      legacyFolders: chain(),
      target: target,
    );

    expect(opened.path, target.path);
  });
}
