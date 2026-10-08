// Rebuilds the azkar library from the scraped file:
//
//     dart run tool/generate_library.dart
//
// Reads tool/data/zekrel_scraped.json, cleans it (see tool/library_builder.dart)
// and writes lib/features/library/data/dhikr_library_data.dart. Prints what it
// did, including any merged entries whose sources disagreed, so a new scrape
// can be checked before it is committed.
import 'dart:io';

import 'library_builder.dart';

const _input = 'tool/data/zekrel_scraped.json';
const _output = 'lib/features/library/data/dhikr_library_data.dart';

void main() {
  final source = File(_input).readAsStringSync();
  final report = buildLibrary(parseScraped(source));

  File(_output).writeAsStringSync(emitDart(report.items));

  stdout
    ..writeln('Read ${report.rawCount} entries from $_input.')
    ..writeln('Folded ${report.merged} repeats of the same dhikr into one '
        'entry each, leaving ${report.items.length}.')
    ..writeln('Wrote $_output.');

  if (report.conflicts.isNotEmpty) {
    stdout.writeln('\n${report.conflicts.length} fields differed between the '
        'copies of a merged entry (the first was kept):');
    report.conflicts.forEach(stdout.writeln);
  }
}
