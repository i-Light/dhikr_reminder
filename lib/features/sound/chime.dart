import 'dart:math' as math;
import 'dart:typed_data';

/// The soft chime played when a dhikr is finished (if the person turned sound
/// on), made here out of two sine tones so there is no recording, no licence
/// and no asset to ship. Mono, 16-bit, [sampleRate] Hz, about 0.7 seconds.
///
/// Gentle on purpose: a short attack so it does not click, a quick fall so it
/// does not linger, and a peak well under full scale so it never startles.
Uint8List buildChimeWav({int sampleRate = 22050}) {
  const seconds = 0.7;
  final frames = (sampleRate * seconds).round();
  final pcm = Int16List(frames);

  // A fifth apart, the second tone a moment later: a rising "ting-ting".
  const tones = [
    _Tone(frequency: 880, start: 0.0, peak: 0.22),
    _Tone(frequency: 1318.5, start: 0.11, peak: 0.18),
  ];
  for (var i = 0; i < frames; i++) {
    final t = i / sampleRate;
    var sample = 0.0;
    for (final tone in tones) {
      final local = t - tone.start;
      if (local < 0) continue;
      // 8 ms to fade in, then an exponential fall.
      final attack = math.min(1.0, local / 0.008);
      final fall = math.exp(-local * 7.5);
      sample += math.sin(2 * math.pi * tone.frequency * local) *
          tone.peak *
          attack *
          fall;
    }
    // The last 30 ms fade to exact silence, so the end cannot click.
    final tail = math.min(1.0, (seconds - t) / 0.03);
    pcm[i] = (sample * tail * 32767).round().clamp(-32768, 32767);
  }

  final dataBytes = pcm.lengthInBytes;
  final out = ByteData(44 + dataBytes);
  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      out.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  out.setUint32(4, 36 + dataBytes, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  out.setUint32(16, 16, Endian.little); // size of the fmt block
  out.setUint16(20, 1, Endian.little); // PCM
  out.setUint16(22, 1, Endian.little); // mono
  out.setUint32(24, sampleRate, Endian.little);
  out.setUint32(28, sampleRate * 2, Endian.little); // bytes per second
  out.setUint16(32, 2, Endian.little); // bytes per frame
  out.setUint16(34, 16, Endian.little); // bits per sample
  ascii(36, 'data');
  out.setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < frames; i++) {
    out.setInt16(44 + i * 2, pcm[i], Endian.little);
  }
  return out.buffer.asUint8List();
}

class _Tone {
  const _Tone({
    required this.frequency,
    required this.start,
    required this.peak,
  });

  final double frequency;
  final double start;
  final double peak;
}
