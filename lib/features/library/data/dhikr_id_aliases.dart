/// Old library ids that now mean another entry: `old id -> current id`.
///
/// An entry's id is made from its words (see `tool/library_builder.dart`), so
/// correcting a typo in a dhikr changes its id, and every reminder saved with
/// the old one would stop being tied to the library. Whenever the generator
/// changes an id, the old one is added here, and a saved reminder follows it.
/// Nothing is ever removed from this map.
const Map<String, String> dhikrIdAliases = <String, String>{};
