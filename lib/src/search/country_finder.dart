// responsible of searching through the country list

import 'package:country_selector/src/search/searchable_country.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:string_search_algorithms/string_search_algorithms.dart';

class CountryFinder {
  CountryFinder({
    this.strictAlgorithm = SearchAlgorithm.boyerMoore,
    this.maxResults = 50,
  });

  final SearchAlgorithm strictAlgorithm;
  final int maxResults;

  final StringSearchEngine _search = const StringSearchEngine();

  // Use an engine instance so you can tune behavior.
  // We disable normalization because we're already feeding normalized keys.
  final StringSimilarityEngine _sim = StringSimilarityEngine(
    options: const SimilarityOptions(
      normalization: NormalizationOptions(enabled: false),
      cache: CacheOptions(
        enabled: true,
        normalizedCapacity: 256,
        bigramCapacity: 512,
        ngramCapacity: 512,
      ),
      algorithms: AlgorithmOptions(
        ngramSize: 3,
      ),
    ),
  );

  String _normalizeQuery(String input) {
    return SearchableCountry.buildSearchKey(input);
  }

  List<SearchableCountry> whereText({
    required String text,
    required List<SearchableCountry> countries,
  }) {
    if (text.startsWith('+')) {
      text = text.substring(1);
    }

    if (text.isEmpty) return countries;

    final asInt = int.tryParse(text);
    if (asInt != null) {
      return _filterByCountryCallingCode(
        countryCallingCode: text,
        countries: countries,
      );
    }

    return _filterByName(searchText: text, countries: countries);
  }

  List<SearchableCountry> _filterByCountryCallingCode({
    required String countryCallingCode,
    required List<SearchableCountry> countries,
  }) {
    int computeSortScore(SearchableCountry c) =>
        c.dialCode.startsWith(countryCallingCode) ? 0 : 1;

    final out = countries
        .where((c) => c.dialCode.contains(countryCallingCode))
        .toList()
      ..sort((a, b) => computeSortScore(a) - computeSortScore(b));

    return out.length > maxResults ? out.sublist(0, maxResults) : out;
  }

  SimilarityAlgorithm _chooseFuzzyAlgorithm(String q) {
    // Multi-word queries: token similarity is more meaningful.
    if (q.contains(' ')) return SimilarityAlgorithm.cosine;

    // Short names / prefixes / minor typos: Jaro-Winkler is excellent.
    if (q.length <= 7) return SimilarityAlgorithm.jaroWinkler;

    // Longer tokens: n-grams tend to be stable.
    return SimilarityAlgorithm.ngram;
  }

  double _adaptiveThreshold(String q, SimilarityAlgorithm algo) {
    // Tuned for typo tolerance in country names.
    // Lower thresholds = more typo tolerance but potentially more noise.
    if (q.length <= 2) return 0.999; // disable fuzzy for 1-2 chars (too noisy)
    if (algo == SimilarityAlgorithm.cosine) return 0.55; // multi-word queries
    if (q.length <= 4) return 0.75; // short names: allow 1 typo
    if (q.length <= 7) return 0.65; // medium names: allow 1-2 typos
    return 0.55; // long names: allow 2-3 typos
  }

  double _shortKeyThreshold(int length) {
    if (length <= 2) return 1.0; // exact only
    return 0.85;
  }

  List<SearchableCountry> _matchShortKeys({
    required String query,
    required List<SearchableCountry> countries,
  }) {
    if (query.isEmpty || query.length > 3) return const <SearchableCountry>[];

    final allowFuzzy = query.length == 3;
    final threshold = _shortKeyThreshold(query.length);
    final matches = <({SearchableCountry country, double score})>[];

    for (final c in countries) {
      var best = -1.0;
      for (final key in c.shortKeys) {
        if (key.isEmpty) continue;
        if (key == query) {
          best = 1.0;
          break;
        }
        if (!allowFuzzy || key.length != 2) continue;

        final score = _sim.compare(
          query,
          key,
          algorithm: SimilarityAlgorithm.jaroWinkler,
        );
        if (score > best) best = score;
      }
      if (best >= threshold) {
        matches.add((country: c, score: best));
      }
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches.map((e) => e.country).toList(growable: false);
  }

  List<SearchableCountry> _filterByName({
    required String searchText,
    required List<SearchableCountry> countries,
  }) {
    final q = _normalizeQuery(searchText);
    if (q.isEmpty) return countries;

    final qNoSpaces = q.replaceAll(' ', '');

    // ---- 1) STRICT MATCH (compile once, scan many) ----
    final compiled = _search.compile(q, algorithm: strictAlgorithm);

    // If the query has no spaces, reuse the same compiled pattern
    // against the no-space keys (so "unitedstates" matches "united states").
    final compiledNoSpaces = qNoSpaces.isEmpty
        ? null
        : (qNoSpaces == q
            ? compiled
            : _search.compile(qNoSpaces, algorithm: strictAlgorithm));

    final strict = <({SearchableCountry country, int index, bool prefix})>[];

    for (final c in countries) {
      final idx1 = compiled.indexOfIn(c.searchKey);
      final idx2 = compiledNoSpaces?.indexOfIn(c.searchKeyNoSpaces) ?? -1;

      var best = idx1;
      if (best < 0 || (idx2 >= 0 && idx2 < best)) best = idx2;

      if (best >= 0) {
        strict.add((country: c, index: best, prefix: best == 0));
      }
    }

    strict.sort((a, b) {
      if (a.prefix && !b.prefix) return -1;
      if (!a.prefix && b.prefix) return 1;

      final byIndex = a.index.compareTo(b.index);
      if (byIndex != 0) return byIndex;

      return a.country.searchKey.length.compareTo(b.country.searchKey.length);
    });

    final strictCountries =
        strict.map((e) => e.country).toList(growable: false);

    final results = <SearchableCountry>[];
    final seen = <IsoCode>{};

    void addUnique(List<SearchableCountry> list) {
      for (final c in list) {
        if (seen.add(c.isoCode)) {
          results.add(c);
        }
      }
    }

    List<SearchableCountry> shortKeyMatches = const <SearchableCountry>[];
    if (qNoSpaces.isNotEmpty && qNoSpaces.length <= 3) {
      shortKeyMatches = _matchShortKeys(query: qNoSpaces, countries: countries);
    }

    if (qNoSpaces.length <= 2) {
      addUnique(shortKeyMatches);
    }

    addUnique(strictCountries);

    if (qNoSpaces.length == 3) {
      addUnique(shortKeyMatches);
    }

    // If strict results are good enough, stop.
    if (results.length >= 8 || q.length <= 2) {
      return results.length > maxResults
          ? results.sublist(0, maxResults)
          : results;
    }

    // ---- 2) FUZZY FILL (typos, near matches) ----
    final algo = _chooseFuzzyAlgorithm(q);
    final threshold = _adaptiveThreshold(q, algo);

    final fuzzy = <({SearchableCountry country, double score})>[];
    for (final c in countries) {
      if (seen.contains(c.isoCode)) continue;

      final s1 = _sim.compare(q, c.searchKey, algorithm: algo);
      final s2 = qNoSpaces.isEmpty
          ? 0.0
          : _sim.compare(qNoSpaces, c.searchKeyNoSpaces, algorithm: algo);

      final score = s1 > s2 ? s1 : s2;

      if (score >= threshold) {
        fuzzy.add((country: c, score: score));
      }
    }

    fuzzy.sort((a, b) => b.score.compareTo(a.score));

    results.addAll(fuzzy.map((e) => e.country));

    return results.length > maxResults
        ? results.sublist(0, maxResults)
        : results;
  }
}
