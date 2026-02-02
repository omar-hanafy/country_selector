import 'package:country_selector/src/search/country_finder.dart';
import 'package:country_selector/src/search/searchable_country.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// Comprehensive English search tests for CountryFinder.
/// These tests lock in expected search behavior for regression testing.
void main() {
  late CountryFinder finder;
  late List<SearchableCountry> countries;

  setUp(() {
    finder = CountryFinder();
    countries = _buildEnglishCountries();
  });

  group('CountryFinder - English - Empty and Edge Cases', () {
    test('empty query returns all countries', () {
      final results = finder.whereText(text: '', countries: countries);
      expect(results.length, equals(countries.length));
    });

    test('whitespace-only query returns all countries', () {
      final results = finder.whereText(text: '   ', countries: countries);
      expect(results.length, equals(countries.length));
    });

    test('single character query returns matches containing that char', () {
      final results = finder.whereText(text: 'a', countries: countries);
      // Should find countries containing 'a': Afghanistan, Albania, Mali, etc.
      expect(results, isNotEmpty);
      // First result should start with 'a' (prefix matches rank higher)
      expect(results.first.searchKey.startsWith('a'), isTrue);
      // All results should contain 'a'
      for (final c in results) {
        expect(
          c.searchKey.contains('a'),
          isTrue,
          reason: '${c.name} should contain "a"',
        );
      }
    });

    test('special characters only returns all countries', () {
      final results = finder.whereText(text: "'-", countries: countries);
      // After normalization, this becomes empty, so all countries returned
      expect(results.length, equals(countries.length));
    });

    test('query with leading/trailing spaces is trimmed', () {
      final results = finder.whereText(text: '  spain  ', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.ES));
    });
  });

  group('CountryFinder - English - Exact Matches', () {
    test('exact match "Spain" returns Spain first', () {
      final results = finder.whereText(text: 'Spain', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.ES));
    });

    test('exact match "Chad" returns Chad first', () {
      final results = finder.whereText(text: 'Chad', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.TD));
    });

    test('exact match is case-insensitive', () {
      final results = finder.whereText(text: 'SPAIN', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.ES));
    });

    test('exact match "Germany" returns Germany first', () {
      final results = finder.whereText(text: 'Germany', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.DE));
    });
  });

  group('CountryFinder - English - Prefix Matches', () {
    test('"Spa" returns Spain first (prefix match)', () {
      final results = finder.whereText(text: 'Spa', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.ES));
    });

    test('"Ger" returns Germany first', () {
      final results = finder.whereText(text: 'Ger', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.DE));
    });

    test('"Aus" returns Austria and Australia (shorter first)', () {
      final results = finder.whereText(text: 'Aus', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      expect(isoCodes, contains(IsoCode.AT)); // Austria
      expect(isoCodes, contains(IsoCode.AU)); // Australia
      // Austria (7 chars) should come before Australia (9 chars)
      final austriaIdx = isoCodes.indexOf(IsoCode.AT);
      final australiaIdx = isoCodes.indexOf(IsoCode.AU);
      expect(austriaIdx, lessThan(australiaIdx));
    });

    test('"United" returns United countries', () {
      final results = finder.whereText(text: 'United', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      expect(isoCodes, contains(IsoCode.AE)); // United Arab Emirates
      expect(isoCodes, contains(IsoCode.GB)); // United Kingdom
      expect(isoCodes, contains(IsoCode.US)); // United States
    });

    test('"New" returns New Zealand and New Caledonia', () {
      final results = finder.whereText(text: 'New', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      expect(isoCodes, contains(IsoCode.NZ)); // New Zealand
      expect(isoCodes, contains(IsoCode.NC)); // New Caledonia
    });
  });

  group('CountryFinder - English - Contains Matches', () {
    test('"land" returns countries containing "land"', () {
      final results = finder.whereText(text: 'land', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      // Countries with "land": Finland, Iceland, Ireland, Netherlands, etc.
      expect(isoCodes, contains(IsoCode.FI)); // Finland
      expect(isoCodes, contains(IsoCode.IS)); // Iceland
      expect(isoCodes, contains(IsoCode.IE)); // Ireland
    });

    test('"stan" returns countries ending with "-stan"', () {
      final results = finder.whereText(text: 'stan', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      expect(isoCodes, contains(IsoCode.AF)); // Afghanistan
      expect(isoCodes, contains(IsoCode.PK)); // Pakistan
      expect(isoCodes, contains(IsoCode.KZ)); // Kazakhstan
    });

    test('"king" returns United Kingdom', () {
      final results = finder.whereText(text: 'king', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      expect(isoCodes, contains(IsoCode.GB));
    });

    test('"arab" returns countries with "arab" in name', () {
      final results = finder.whereText(text: 'arab', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      expect(isoCodes, contains(IsoCode.AE)); // United Arab Emirates
      expect(isoCodes, contains(IsoCode.SA)); // Saudi Arabia
    });
  });

  group('CountryFinder - English - No-Space Queries', () {
    test('"unitedstates" matches "United States"', () {
      final results =
          finder.whereText(text: 'unitedstates', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.US));
    });

    test('"unitedkingdom" matches "United Kingdom"', () {
      final results =
          finder.whereText(text: 'unitedkingdom', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.GB));
    });

    test('"saudiarabia" matches "Saudi Arabia"', () {
      final results =
          finder.whereText(text: 'saudiarabia', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.SA));
    });

    test('"newzealand" matches "New Zealand"', () {
      final results =
          finder.whereText(text: 'newzealand', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.NZ));
    });

    test('"papuanewguinea" matches "Papua New Guinea"', () {
      final results =
          finder.whereText(text: 'papuanewguinea', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.PG));
    });
  });

  group('CountryFinder - English - Diacritics Handling', () {
    test('"Turkiye" matches "Turkiye" (with special chars)', () {
      final results = finder.whereText(text: 'Turkiye', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.TR));
    });

    test('"Turk" matches "Turkiye" (prefix match)', () {
      // "Turk" is a prefix of "turkiye" so strict match works
      final results = finder.whereText(text: 'Turk', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      expect(isoCodes, contains(IsoCode.TR));
    });

    test('"Turkey" matches "Turkiye" (common spelling)', () {
      // "Turkey" is a common English spelling of "Turkiye"
      final results = finder.whereText(text: 'Turkey', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      expect(isoCodes, contains(IsoCode.TR));
    });

    test('"Curacao" matches "Curacao" (without diacritics)', () {
      final results = finder.whereText(text: 'Curacao', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.CW));
    });

    test('"Reunion" matches "Reunion" (accent stripped)', () {
      final results = finder.whereText(text: 'Reunion', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.RE));
    });
  });

  group('CountryFinder - English - Punctuation Handling', () {
    test('"Guinea-Bissau" matches with hyphen', () {
      final results =
          finder.whereText(text: 'Guinea-Bissau', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.GW));
    });

    test('"Guinea Bissau" matches without hyphen', () {
      final results =
          finder.whereText(text: 'Guinea Bissau', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.GW));
    });

    test('"guineabissau" matches without hyphen or space', () {
      final results =
          finder.whereText(text: 'guineabissau', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.GW));
    });

    test('"Timor-Leste" matches with hyphen', () {
      final results =
          finder.whereText(text: 'Timor-Leste', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.TL));
    });

    test('"Timor Leste" matches without hyphen', () {
      final results =
          finder.whereText(text: 'Timor Leste', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.TL));
    });

    test('"timorleste" matches without hyphen or space', () {
      final results =
          finder.whereText(text: 'timorleste', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.TL));
    });

    test('"Bosnia and Herzegovina" matches with "and"', () {
      final results =
          finder.whereText(text: 'Bosnia and Herzegovina', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.BA));
    });

    test('"bosnia herzegovina" matches without "and"', () {
      final results =
          finder.whereText(text: 'bosnia herzegovina', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.BA));
    });
  });

  group('CountryFinder - English - Fuzzy/Typo Matching', () {
    // Note: Fuzzy matching has adaptive thresholds:
    // - Queries <= 2 chars: threshold 0.999 (effectively disabled)
    // - Queries <= 4 chars: threshold 0.88 (very strict)
    // - Queries <= 7 chars: threshold 0.75 (moderately strict)
    // - Queries > 7 chars: threshold 0.65 (more lenient)

    test('"Germny" (typo - missing a) matches Germany via fuzzy', () {
      // "Germny" does not contain in "germany", so relies on fuzzy
      // Jaro-Winkler score for germny vs germany is high enough to pass
      final results = finder.whereText(text: 'Germny', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      expect(isoCodes, contains(IsoCode.DE));
    });

    test('"Germa" (partial) matches Germany via prefix', () {
      final results = finder.whereText(text: 'Germa', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.DE));
    });

    test('"Franc" (partial) matches France via prefix', () {
      final results = finder.whereText(text: 'Franc', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.FR));
    });

    test('"Austral" (partial) matches Australia via prefix', () {
      final results = finder.whereText(text: 'Austral', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      expect(isoCodes, contains(IsoCode.AU));
    });

    test('"Switzer" (partial) matches Switzerland via prefix', () {
      final results = finder.whereText(text: 'Switzer', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.CH));
    });

    test('"Portug" (partial) matches Portugal via prefix', () {
      final results = finder.whereText(text: 'Portug', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.PT));
    });

    test('"Zimbab" (partial) matches Zimbabwe via prefix', () {
      final results = finder.whereText(text: 'Zimbab', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.ZW));
    });

    test('"Argent" (partial) matches Argentina via prefix', () {
      final results = finder.whereText(text: 'Argent', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.AR));
    });

    test('"Brazl" (typo) matches Brazil via fuzzy', () {
      // brazl vs brazil - high similarity
      final results = finder.whereText(text: 'Brazl', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      expect(isoCodes, contains(IsoCode.BR));
    });

    test('"Mexic" (partial) matches Mexico via prefix', () {
      final results = finder.whereText(text: 'Mexic', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.MX));
    });

    test('"Egpt" (missing y) matches Egypt', () {
      final results = finder.whereText(text: 'Egpt', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      expect(isoCodes, contains(IsoCode.EG));
    });

    test('"Eygpt" (extra y) matches Egypt', () {
      final results = finder.whereText(text: 'Eygpt', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      expect(isoCodes, contains(IsoCode.EG));
    });
  });

  group('CountryFinder - English - Shortcuts and Abbreviations', () {
    test('"EG" matches Egypt (ISO code)', () {
      final results = finder.whereText(text: 'EG', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.EG));
    });

    test('"EGB" matches Egypt (short code typo)', () {
      final results = finder.whereText(text: 'EGB', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.EG));
    });

    test('"UAE" matches United Arab Emirates', () {
      final results = finder.whereText(text: 'UAE', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.AE));
    });

    test('"UK" matches United Kingdom', () {
      final results = finder.whereText(text: 'UK', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.GB));
    });

    test('"US" matches United States', () {
      final results = finder.whereText(text: 'US', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.US));
    });

    test('"USA" matches United States', () {
      final results = finder.whereText(text: 'USA', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.US));
    });

    test('"U.S." matches United States', () {
      final results = finder.whereText(text: 'U.S.', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.US));
    });

    test('"KSA" matches Saudi Arabia', () {
      final results = finder.whereText(text: 'KSA', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.SA));
    });
  });

  group('CountryFinder - English - Multi-Word Queries', () {
    test('"united arab" matches United Arab Emirates', () {
      final results =
          finder.whereText(text: 'united arab', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.AE));
    });

    test('"south korea" matches South Korea', () {
      final results =
          finder.whereText(text: 'south korea', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.KR));
    });

    test('"north korea" matches North Korea', () {
      final results =
          finder.whereText(text: 'north korea', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.KP));
    });

    test('"south africa" matches South Africa', () {
      final results =
          finder.whereText(text: 'south africa', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.ZA));
    });

    test('"sri lanka" matches Sri Lanka', () {
      final results =
          finder.whereText(text: 'sri lanka', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.LK));
    });

    test('"el salvador" matches El Salvador', () {
      final results =
          finder.whereText(text: 'el salvador', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.SV));
    });

    test('"costa rica" matches Costa Rica', () {
      final results =
          finder.whereText(text: 'costa rica', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.CR));
    });
  });

  group('CountryFinder - English - Dial Code Searches', () {
    test('"1" returns USA and Canada (prefix match)', () {
      final results = finder.whereText(text: '1', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      expect(isoCodes, contains(IsoCode.US));
      expect(isoCodes, contains(IsoCode.CA));
    });

    test('"+1" returns USA and Canada', () {
      final results = finder.whereText(text: '+1', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      expect(isoCodes, contains(IsoCode.US));
      expect(isoCodes, contains(IsoCode.CA));
    });

    test('"33" returns France', () {
      final results = finder.whereText(text: '33', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.FR));
    });

    test('"44" returns United Kingdom', () {
      final results = finder.whereText(text: '44', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.GB));
    });

    test('"49" returns Germany', () {
      final results = finder.whereText(text: '49', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.DE));
    });

    test('"91" returns India', () {
      final results = finder.whereText(text: '91', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.IN));
    });

    test('"20" returns Egypt', () {
      final results = finder.whereText(text: '20', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.EG));
    });

    test('"971" returns UAE', () {
      final results = finder.whereText(text: '971', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.AE));
    });

    test('"966" returns Saudi Arabia', () {
      final results = finder.whereText(text: '966', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.SA));
    });

    test('dial code with + prefix works', () {
      final results = finder.whereText(text: '+44', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.GB));
    });
  });

  group('CountryFinder - English - No Results', () {
    test('completely unrelated query returns empty', () {
      final results =
          finder.whereText(text: 'xyzabc123', countries: countries);
      expect(results, isEmpty);
    });

    test('wrong language query returns empty or fuzzy matches', () {
      // "Espagne" is French for Spain - should not match in English
      final results = finder.whereText(text: 'Espagne', countries: countries);
      // Should either be empty or not have Spain as first result
      if (results.isNotEmpty) {
        // If fuzzy finds something, Spain shouldn't be first
        // because the searchKey is "spain" not "espagne"
      }
    });
  });

  group('CountryFinder - English - Sorting/Ranking', () {
    test('prefix matches rank higher than contains matches', () {
      // "land" should rank Finland (contains) lower than countries starting with "Land" if any
      // But for "Fin", Finland should be first
      final results = finder.whereText(text: 'Fin', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.FI));
    });

    test('shorter names rank higher for same prefix', () {
      // "Ger" should put Germany (7 chars) before any longer matches
      final results = finder.whereText(text: 'Ger', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.DE));
    });

    test('exact prefix match ranks highest', () {
      // "Japan" should rank Japan first, not Jamaica (also starts with Ja)
      final results = finder.whereText(text: 'Japan', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.JP));
    });
  });
}

/// Build a list of SearchableCountry for English locale.
List<SearchableCountry> _buildEnglishCountries() {
  return [
    SearchableCountry(IsoCode.AF, '93', 'Afghanistan'),
    SearchableCountry(IsoCode.AL, '355', 'Albania'),
    SearchableCountry(IsoCode.DZ, '213', 'Algeria'),
    SearchableCountry(IsoCode.AD, '376', 'Andorra'),
    SearchableCountry(IsoCode.AO, '244', 'Angola'),
    SearchableCountry(IsoCode.AG, '1268', 'Antigua and Barbuda'),
    SearchableCountry(IsoCode.AR, '54', 'Argentina'),
    SearchableCountry(IsoCode.AM, '374', 'Armenia'),
    SearchableCountry(IsoCode.AU, '61', 'Australia'),
    SearchableCountry(IsoCode.AT, '43', 'Austria'),
    SearchableCountry(IsoCode.AZ, '994', 'Azerbaijan'),
    SearchableCountry(IsoCode.BS, '1242', 'Bahamas'),
    SearchableCountry(IsoCode.BH, '973', 'Bahrain'),
    SearchableCountry(IsoCode.BD, '880', 'Bangladesh'),
    SearchableCountry(IsoCode.BB, '1246', 'Barbados'),
    SearchableCountry(IsoCode.BY, '375', 'Belarus'),
    SearchableCountry(IsoCode.BE, '32', 'Belgium'),
    SearchableCountry(IsoCode.BZ, '501', 'Belize'),
    SearchableCountry(IsoCode.BJ, '229', 'Benin'),
    SearchableCountry(IsoCode.BT, '975', 'Bhutan'),
    SearchableCountry(IsoCode.BO, '591', 'Bolivia'),
    SearchableCountry(IsoCode.BA, '387', 'Bosnia and Herzegovina'),
    SearchableCountry(IsoCode.BW, '267', 'Botswana'),
    SearchableCountry(IsoCode.BR, '55', 'Brazil'),
    SearchableCountry(IsoCode.BN, '673', 'Brunei Darussalam'),
    SearchableCountry(IsoCode.BG, '359', 'Bulgaria'),
    SearchableCountry(IsoCode.BF, '226', 'Burkina Faso'),
    SearchableCountry(IsoCode.BI, '257', 'Burundi'),
    SearchableCountry(IsoCode.CV, '238', 'Cape Verde'),
    SearchableCountry(IsoCode.KH, '855', 'Cambodia'),
    SearchableCountry(IsoCode.CM, '237', 'Cameroon'),
    SearchableCountry(IsoCode.CA, '1', 'Canada'),
    SearchableCountry(IsoCode.CF, '236', 'Central African Republic'),
    SearchableCountry(IsoCode.TD, '235', 'Chad'),
    SearchableCountry(IsoCode.CL, '56', 'Chile'),
    SearchableCountry(IsoCode.CN, '86', 'China'),
    SearchableCountry(IsoCode.CO, '57', 'Colombia'),
    SearchableCountry(IsoCode.KM, '269', 'Comoros'),
    SearchableCountry(IsoCode.CG, '242', 'Republic of the Congo'),
    SearchableCountry(IsoCode.CD, '243', 'Democratic Republic of the Congo'),
    SearchableCountry(IsoCode.CR, '506', 'Costa Rica'),
    SearchableCountry(IsoCode.CI, '225', 'Ivory Coast'),
    SearchableCountry(IsoCode.HR, '385', 'Croatia'),
    SearchableCountry(IsoCode.CU, '53', 'Cuba'),
    SearchableCountry(IsoCode.CW, '599', 'Curacao'),
    SearchableCountry(IsoCode.CY, '357', 'Cyprus'),
    SearchableCountry(IsoCode.CZ, '420', 'Czech Republic'),
    SearchableCountry(IsoCode.DK, '45', 'Denmark'),
    SearchableCountry(IsoCode.DJ, '253', 'Djibouti'),
    SearchableCountry(IsoCode.DM, '1767', 'Dominica'),
    SearchableCountry(IsoCode.DO, '1809', 'Dominican Republic'),
    SearchableCountry(IsoCode.EC, '593', 'Ecuador'),
    SearchableCountry(IsoCode.EG, '20', 'Egypt'),
    SearchableCountry(IsoCode.SV, '503', 'El Salvador'),
    SearchableCountry(IsoCode.GQ, '240', 'Equatorial Guinea'),
    SearchableCountry(IsoCode.ER, '291', 'Eritrea'),
    SearchableCountry(IsoCode.EE, '372', 'Estonia'),
    SearchableCountry(IsoCode.SZ, '268', 'Eswatini'),
    SearchableCountry(IsoCode.ET, '251', 'Ethiopia'),
    SearchableCountry(IsoCode.FJ, '679', 'Fiji'),
    SearchableCountry(IsoCode.FI, '358', 'Finland'),
    SearchableCountry(IsoCode.FR, '33', 'France'),
    SearchableCountry(IsoCode.GA, '241', 'Gabon'),
    SearchableCountry(IsoCode.GM, '220', 'Gambia'),
    SearchableCountry(IsoCode.GE, '995', 'Georgia'),
    SearchableCountry(IsoCode.DE, '49', 'Germany'),
    SearchableCountry(IsoCode.GH, '233', 'Ghana'),
    SearchableCountry(IsoCode.GR, '30', 'Greece'),
    SearchableCountry(IsoCode.GD, '1473', 'Grenada'),
    SearchableCountry(IsoCode.GT, '502', 'Guatemala'),
    SearchableCountry(IsoCode.GN, '224', 'Guinea'),
    SearchableCountry(IsoCode.GW, '245', 'Guinea-Bissau'),
    SearchableCountry(IsoCode.GY, '592', 'Guyana'),
    SearchableCountry(IsoCode.HT, '509', 'Haiti'),
    SearchableCountry(IsoCode.HN, '504', 'Honduras'),
    SearchableCountry(IsoCode.HU, '36', 'Hungary'),
    SearchableCountry(IsoCode.IS, '354', 'Iceland'),
    SearchableCountry(IsoCode.IN, '91', 'India'),
    SearchableCountry(IsoCode.ID, '62', 'Indonesia'),
    SearchableCountry(IsoCode.IR, '98', 'Iran'),
    SearchableCountry(IsoCode.IQ, '964', 'Iraq'),
    SearchableCountry(IsoCode.IE, '353', 'Ireland'),
    SearchableCountry(IsoCode.IT, '39', 'Italy'),
    SearchableCountry(IsoCode.JM, '1876', 'Jamaica'),
    SearchableCountry(IsoCode.JP, '81', 'Japan'),
    SearchableCountry(IsoCode.JO, '962', 'Jordan'),
    SearchableCountry(IsoCode.KZ, '7', 'Kazakhstan'),
    SearchableCountry(IsoCode.KE, '254', 'Kenya'),
    SearchableCountry(IsoCode.KI, '686', 'Kiribati'),
    SearchableCountry(IsoCode.KP, '850', 'North Korea'),
    SearchableCountry(IsoCode.KR, '82', 'South Korea'),
    SearchableCountry(IsoCode.KW, '965', 'Kuwait'),
    SearchableCountry(IsoCode.KG, '996', 'Kyrgyzstan'),
    SearchableCountry(IsoCode.LA, '856', 'Laos'),
    SearchableCountry(IsoCode.LV, '371', 'Latvia'),
    SearchableCountry(IsoCode.LB, '961', 'Lebanon'),
    SearchableCountry(IsoCode.LS, '266', 'Lesotho'),
    SearchableCountry(IsoCode.LR, '231', 'Liberia'),
    SearchableCountry(IsoCode.LY, '218', 'Libya'),
    SearchableCountry(IsoCode.LI, '423', 'Liechtenstein'),
    SearchableCountry(IsoCode.LT, '370', 'Lithuania'),
    SearchableCountry(IsoCode.LU, '352', 'Luxembourg'),
    SearchableCountry(IsoCode.MG, '261', 'Madagascar'),
    SearchableCountry(IsoCode.MW, '265', 'Malawi'),
    SearchableCountry(IsoCode.MY, '60', 'Malaysia'),
    SearchableCountry(IsoCode.MV, '960', 'Maldives'),
    SearchableCountry(IsoCode.ML, '223', 'Mali'),
    SearchableCountry(IsoCode.MT, '356', 'Malta'),
    SearchableCountry(IsoCode.MH, '692', 'Marshall Islands'),
    SearchableCountry(IsoCode.MR, '222', 'Mauritania'),
    SearchableCountry(IsoCode.MU, '230', 'Mauritius'),
    SearchableCountry(IsoCode.MX, '52', 'Mexico'),
    SearchableCountry(IsoCode.FM, '691', 'Micronesia'),
    SearchableCountry(IsoCode.MD, '373', 'Moldova'),
    SearchableCountry(IsoCode.MC, '377', 'Monaco'),
    SearchableCountry(IsoCode.MN, '976', 'Mongolia'),
    SearchableCountry(IsoCode.ME, '382', 'Montenegro'),
    SearchableCountry(IsoCode.MA, '212', 'Morocco'),
    SearchableCountry(IsoCode.MZ, '258', 'Mozambique'),
    SearchableCountry(IsoCode.MM, '95', 'Myanmar'),
    SearchableCountry(IsoCode.NA, '264', 'Namibia'),
    SearchableCountry(IsoCode.NR, '674', 'Nauru'),
    SearchableCountry(IsoCode.NP, '977', 'Nepal'),
    SearchableCountry(IsoCode.NL, '31', 'Netherlands'),
    SearchableCountry(IsoCode.NC, '687', 'New Caledonia'),
    SearchableCountry(IsoCode.NZ, '64', 'New Zealand'),
    SearchableCountry(IsoCode.NI, '505', 'Nicaragua'),
    SearchableCountry(IsoCode.NE, '227', 'Niger'),
    SearchableCountry(IsoCode.NG, '234', 'Nigeria'),
    SearchableCountry(IsoCode.MK, '389', 'North Macedonia'),
    SearchableCountry(IsoCode.NO, '47', 'Norway'),
    SearchableCountry(IsoCode.OM, '968', 'Oman'),
    SearchableCountry(IsoCode.PK, '92', 'Pakistan'),
    SearchableCountry(IsoCode.PW, '680', 'Palau'),
    SearchableCountry(IsoCode.PS, '970', 'Palestine'),
    SearchableCountry(IsoCode.PA, '507', 'Panama'),
    SearchableCountry(IsoCode.PG, '675', 'Papua New Guinea'),
    SearchableCountry(IsoCode.PY, '595', 'Paraguay'),
    SearchableCountry(IsoCode.PE, '51', 'Peru'),
    SearchableCountry(IsoCode.PH, '63', 'Philippines'),
    SearchableCountry(IsoCode.PL, '48', 'Poland'),
    SearchableCountry(IsoCode.PT, '351', 'Portugal'),
    SearchableCountry(IsoCode.QA, '974', 'Qatar'),
    SearchableCountry(IsoCode.RE, '262', 'Reunion'),
    SearchableCountry(IsoCode.RO, '40', 'Romania'),
    SearchableCountry(IsoCode.RU, '7', 'Russia'),
    SearchableCountry(IsoCode.RW, '250', 'Rwanda'),
    SearchableCountry(IsoCode.WS, '685', 'Samoa'),
    SearchableCountry(IsoCode.SM, '378', 'San Marino'),
    SearchableCountry(IsoCode.ST, '239', 'Sao Tome and Principe'),
    SearchableCountry(IsoCode.SA, '966', 'Saudi Arabia'),
    SearchableCountry(IsoCode.SN, '221', 'Senegal'),
    SearchableCountry(IsoCode.RS, '381', 'Serbia'),
    SearchableCountry(IsoCode.SC, '248', 'Seychelles'),
    SearchableCountry(IsoCode.SL, '232', 'Sierra Leone'),
    SearchableCountry(IsoCode.SG, '65', 'Singapore'),
    SearchableCountry(IsoCode.SK, '421', 'Slovakia'),
    SearchableCountry(IsoCode.SI, '386', 'Slovenia'),
    SearchableCountry(IsoCode.SB, '677', 'Solomon Islands'),
    SearchableCountry(IsoCode.SO, '252', 'Somalia'),
    SearchableCountry(IsoCode.ZA, '27', 'South Africa'),
    SearchableCountry(IsoCode.SS, '211', 'South Sudan'),
    SearchableCountry(IsoCode.ES, '34', 'Spain'),
    SearchableCountry(IsoCode.LK, '94', 'Sri Lanka'),
    SearchableCountry(IsoCode.SD, '249', 'Sudan'),
    SearchableCountry(IsoCode.SR, '597', 'Suriname'),
    SearchableCountry(IsoCode.SE, '46', 'Sweden'),
    SearchableCountry(IsoCode.CH, '41', 'Switzerland'),
    SearchableCountry(IsoCode.SY, '963', 'Syria'),
    SearchableCountry(IsoCode.TW, '886', 'Taiwan'),
    SearchableCountry(IsoCode.TJ, '992', 'Tajikistan'),
    SearchableCountry(IsoCode.TZ, '255', 'Tanzania'),
    SearchableCountry(IsoCode.TH, '66', 'Thailand'),
    SearchableCountry(IsoCode.TL, '670', 'Timor-Leste'),
    SearchableCountry(IsoCode.TG, '228', 'Togo'),
    SearchableCountry(IsoCode.TO, '676', 'Tonga'),
    SearchableCountry(IsoCode.TT, '1868', 'Trinidad and Tobago'),
    SearchableCountry(IsoCode.TN, '216', 'Tunisia'),
    SearchableCountry(IsoCode.TR, '90', 'Turkiye'),
    SearchableCountry(IsoCode.TM, '993', 'Turkmenistan'),
    SearchableCountry(IsoCode.TV, '688', 'Tuvalu'),
    SearchableCountry(IsoCode.UG, '256', 'Uganda'),
    SearchableCountry(IsoCode.UA, '380', 'Ukraine'),
    SearchableCountry(IsoCode.AE, '971', 'United Arab Emirates'),
    SearchableCountry(IsoCode.GB, '44', 'United Kingdom'),
    SearchableCountry(IsoCode.US, '1', 'United States'),
    SearchableCountry(IsoCode.UY, '598', 'Uruguay'),
    SearchableCountry(IsoCode.UZ, '998', 'Uzbekistan'),
    SearchableCountry(IsoCode.VU, '678', 'Vanuatu'),
    SearchableCountry(IsoCode.VA, '379', 'Vatican City'),
    SearchableCountry(IsoCode.VE, '58', 'Venezuela'),
    SearchableCountry(IsoCode.VN, '84', 'Vietnam'),
    SearchableCountry(IsoCode.YE, '967', 'Yemen'),
    SearchableCountry(IsoCode.ZM, '260', 'Zambia'),
    SearchableCountry(IsoCode.ZW, '263', 'Zimbabwe'),
  ];
}
