import 'dart:convert';
import 'package:crypto/crypto.dart';

class VideoSignatureHelper {
  // he: Character -> 6-bit binary string
  static String _he(int c) {
    // Dart's toRadixString(2) doesn't support padding directly for byte to bits
    // 'c' is a byte value (0-255). We want 8 bits, then take the last 6?
    // Wait, Go: fmt.Sprintf("%06b", c) on a byte.
    // Go's %b prints binary. If c is byte, it prints the bits.
    // The Go code: `he(t[i])` where `t` is string timestamp. `t[i]` is a byte (uint8).
    // The timestamp string characters (digits 0-9) are ascii 48-57.
    // Ascii '0' (48) in binary: 00110000.
    // Go's %06b would take the value 48 and print it as binary, padded to 6 chars.
    // 48 in binary is 110000. So it fits.
    // If we had larger byte, it might truncate? No, Printf just pads.
    // But since input is timestamp digits, it's always small enough to fit in 8 bits.
    // We just need the value of the char, converted to binary string, padded to 6 digits.

    String binary = c.toRadixString(2);
    while (binary.length < 6) {
      binary = '0$binary';
    }
    return binary;
  }

  // D: MD5 Hash
  static String _d(String s) {
    var bytes = utf8.encode(s);
    var digest = md5.convert(bytes);
    return digest.toString();
  }

  // fe: Core signing algorithm
  static String _fe(int ts) {
    String t = ts.toString();
    List<String> r = ["", "", "", ""];

    // Distribute bits of the timestamp string characters
    for (int i = 0; i < t.length; i++) {
      String bits = _he(t.codeUnitAt(i));
      // bits is at least 6 chars long
      // Go: r[0] += bits[2:3] -> 3rd char (index 2)
      // Go slice [2:3] is length 1.
      // Dart substring(2, 3)
      if (bits.length >= 6) {
        // We use the LAST 6 bits if it were longer, but for digits it's 00xxxx.
        // Let's stick to the 6 char logic.
        r[0] += bits.substring(2, 3);
        r[1] += bits.substring(3, 4);
        r[2] += bits.substring(4, 5);
        r[3] += bits.substring(5);
      }
    }

    List<String> a = List.filled(4, "");
    for (int i = 0; i < 4; i++) {
      // Parse binary string to int
      // Dart: int.parse(str, radix: 2)
      // Go: strconv.ParseInt(r[i], 2, 64)
      if (r[i].isEmpty) {
        a[i] = "000";
        continue;
      }

      int v = int.parse(r[i], radix: 2);
      // Format as hex
      String h = v.toRadixString(16);
      while (h.length < 3) {
        h = "0$h";
      }
      a[i] = h;
    }

    String n = _d(t);

    // Assembly
    // Go: n[0:3] + a[0] + n[6:11] + a[1] + n[14:19] + a[2] + n[22:27] + a[3] + n[30:]
    if (n.length < 30) {
      // MD5 hex is 32 chars. Should be safe.
      return "";
    }

    return n.substring(0, 3) +
        a[0] +
        n.substring(6, 11) +
        a[1] +
        n.substring(14, 19) +
        a[2] +
        n.substring(22, 27) +
        a[3] +
        n.substring(30);
  }

  static String generate() {
    return _fe(DateTime.now().millisecondsSinceEpoch ~/ 1000); // Unix seconds
  }
}
