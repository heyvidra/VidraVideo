import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/cast/presentation/cast_button.dart';
import 'package:vidra_cast/vidra_cast.dart';

CastDevice _tv(String address, {String id = 'tv'}) =>
    CastDevice(id: id, name: 'TV', address: address);

void main() {
  // The picker shows remembered televisions before anything has confirmed
  // them, which is what makes it appear instantly — and is how a set from
  // another network offers a cast that can only fail.
  group('which televisions the picker may offer', () {
    test('one on this machine\'s own subnet is offered', () {
      final devices = [_tv('http://192.168.1.12:1416')];
      expect(CastButton.devicesOn('192.168.1.24', devices), devices);
    });

    test('one from another network is not', () {
      // The flat before this one, the office, a hotel: still in the cache,
      // still unreachable.
      expect(
        CastButton.devicesOn('192.168.1.24', [_tv('http://10.0.0.5:1416')]),
        isEmpty,
      );
    });

    test('a port that moved is still the same subnet, so still offered', () {
      // An LG hands out a new UPnP port on every reboot. The address goes
      // stale; the network it is on does not.
      expect(
        CastButton.devicesOn('192.168.1.24', [_tv('http://192.168.1.12:1905')]),
        hasLength(1),
      );
    });

    test('no address of our own means nothing is reachable', () {
      expect(
        CastButton.devicesOn(null, [_tv('http://192.168.1.12:1416')]),
        isEmpty,
      );
    });

    test('an address that is not four octets is not a subnet', () {
      expect(
        CastButton.devicesOn('192.168.1.24', [_tv('http://tv.local:1416')]),
        isEmpty,
      );
    });

    test('the ones that qualify come back in the order they arrived', () {
      final near1 = _tv('http://192.168.1.12:1416', id: 'a');
      final far = _tv('http://172.16.4.9:1416', id: 'b');
      final near2 = _tv('http://192.168.1.30:8060', id: 'c');
      expect(CastButton.devicesOn('192.168.1.24', [near1, far, near2]), [
        near1,
        near2,
      ]);
    });
  });
}
