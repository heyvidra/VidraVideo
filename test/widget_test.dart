import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra/src/routing/app_router.dart';

void main() {
  test('router provider creates app router with home as initial location', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    addTearDown(router.dispose);

    expect(router.routeInformationProvider.value.uri.path, '/');
  });
}
