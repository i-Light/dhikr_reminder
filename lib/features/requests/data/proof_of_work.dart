import 'dart:convert';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

/// Whether [counter] solves the puzzle: the SHA-256 of
/// `<challenge>:<install>:<counter>` starts with at least [bits] zero bits.
/// The service checks exactly this (server/src/core.mjs, `powHolds`).
bool proofHolds(String challenge, String install, int counter, int bits) {
  final digest = sha256.convert(utf8.encode('$challenge:$install:$counter'));
  return _leadingZeroBits(digest.bytes) >= bits;
}

int _leadingZeroBits(List<int> bytes) {
  var bits = 0;
  for (final byte in bytes) {
    if (byte == 0) {
      bits += 8;
      continue;
    }
    bits += 8 - byte.bitLength;
    break;
  }
  return bits;
}

/// Finds a counter that solves the puzzle, in a separate isolate so the screen
/// keeps moving. At 16 bits that is about 65,000 hashes on average, well under
/// a second on a phone.
Future<int> solveProofOfWork({
  required String challenge,
  required String install,
  required int bits,
}) {
  return Isolate.run(() {
    var counter = 0;
    while (!proofHolds(challenge, install, counter, bits)) {
      counter++;
    }
    return counter;
  });
}
