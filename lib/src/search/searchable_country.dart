import 'package:diacritic/diacritic.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// [SearchableCountry] regroups informations for searching
/// a country by some of its properties. It is not meant
/// to be exported outside this pacakge, as we would like people
/// to use CountrySelectorLocalization.of(context).countryName()
/// to find the country name instead, which would prevent country.name
/// to be out of sync if the search happened before a language change.
class SearchableCountry {
  /// Country alpha-2 iso code
  final IsoCode isoCode;

  /// localized name of the country
  final String name;

  /// country dialing code to call them internationally
  final String dialCode;

  /// Best general-purpose key for searching:
  /// - diacritics removed
  /// - lowercased
  /// - punctuation removed
  /// - whitespace collapsed
  final String searchKey;

  /// Same as [searchKey] but with spaces removed.
  /// Helps queries like "cotedivoire" or "unitedstates".
  final String searchKeyNoSpaces;

  /// Short keys for quick matching like ISO codes or initials.
  final List<String> shortKeys;

  /// returns "+ [dialCode]"
  String get formattedCountryDialingCode => '+ $dialCode';

  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _specialChars =
      RegExp(r'[^\p{L}\p{N}\s]', unicode: true);
  static final RegExp _arabicDiacritics = RegExp(
    r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]',
  );

  static const Map<IsoCode, List<String>> _extraShortKeys =
      <IsoCode, List<String>>{
    IsoCode.US: <String>['usa'],
    IsoCode.SA: <String>['ksa'],
  };

  SearchableCountry._(
    this.isoCode,
    this.dialCode,
    this.name,
    this.searchKey,
    this.searchKeyNoSpaces,
    this.shortKeys,
  );

  factory SearchableCountry(IsoCode isoCode, String dialCode, String name) {
    final key = buildSearchKey(name);
    return SearchableCountry._(
      isoCode,
      dialCode,
      name,
      key,
      key.replaceAll(' ', ''),
      _buildShortKeys(key, isoCode),
    );
  }

  static String buildSearchKey(String input) {
    var s = removeDiacritics(input).toLowerCase();
    s = _normalizeArabic(s);
    s = s.replaceAll(_specialChars, ' ');
    s = s.replaceAll(_whitespace, ' ').trim();
    return s;
  }

  static String _normalizeArabic(String input) {
    var s = input.replaceAll(_arabicDiacritics, '');
    s = s.replaceAll(RegExp(r'[\u0622\u0623\u0625\u0671]'), '\u0627');
    s = s.replaceAll('\u0649', '\u064A');
    s = s.replaceAll('\u0629', '\u0647');
    s = s.replaceAll('\u0624', '\u0648');
    s = s.replaceAll('\u0626', '\u064A');
    return s;
  }

  static List<String> _buildShortKeys(String key, IsoCode isoCode) {
    final keys = <String>{};
    final isoKey = isoCode.name.toLowerCase();
    if (isoKey.isNotEmpty) {
      keys.add(isoKey);
    }

    final tokens =
        key.split(' ').where((token) => token.isNotEmpty).toList();
    if (tokens.length >= 2) {
      final initials = tokens.map((token) => token[0]).join();
      if (initials.length >= 2) {
        keys.add(initials);
      }
    }

    final extra = _extraShortKeys[isoCode];
    if (extra != null) {
      keys.addAll(extra);
    }

    return keys.toList(growable: false);
  }

  @override
  String toString() {
    return '$runtimeType(isoCode: $isoCode, dialCode: $dialCode, name: $name)';
  }
}
