import 'package:country_selector/src/search/country_finder.dart';
import 'package:country_selector/src/search/searchable_country.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// Comprehensive Arabic search tests for CountryFinder.
/// These tests lock in expected search behavior for regression testing.
///
/// Note: Arabic text is right-to-left but the search algorithm treats
/// it as a sequence of Unicode characters, which works correctly.
void main() {
  late CountryFinder finder;
  late List<SearchableCountry> countries;

  setUp(() {
    finder = CountryFinder();
    countries = _buildArabicCountries();
  });

  group('CountryFinder - Arabic - Empty and Edge Cases', () {
    test('empty query returns all countries', () {
      final results = finder.whereText(text: '', countries: countries);
      expect(results.length, equals(countries.length));
    });

    test('whitespace-only query returns all countries', () {
      final results = finder.whereText(text: '   ', countries: countries);
      expect(results.length, equals(countries.length));
    });

    test('single Arabic character query returns prefix matches', () {
      // "م" (meem) - should match countries starting with this letter
      final results = finder.whereText(text: 'م', countries: countries);
      expect(results, isNotEmpty);
      // Should match: مصر (Egypt), المغرب (Morocco), etc.
    });
  });

  group('CountryFinder - Arabic - Exact Matches', () {
    test('exact match "مصر" returns Egypt first', () {
      final results = finder.whereText(text: 'مصر', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.EG));
    });

    test('exact match "فرنسا" returns France first', () {
      final results = finder.whereText(text: 'فرنسا', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.FR));
    });

    test('exact match "ألمانيا" returns Germany first', () {
      final results = finder.whereText(text: 'ألمانيا', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.DE));
    });

    test('exact match "اليابان" returns Japan first', () {
      final results = finder.whereText(text: 'اليابان', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.JP));
    });

    test('exact match "الصين" returns China first', () {
      final results = finder.whereText(text: 'الصين', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.CN));
    });

    test('exact match "إسبانيا" returns Spain first', () {
      final results = finder.whereText(text: 'إسبانيا', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.ES));
    });
  });

  group('CountryFinder - Arabic - Prefix Matches', () {
    test('"الإ" returns countries starting with "الإ"', () {
      final results = finder.whereText(text: 'الإ', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      // Should match: الإمارات (UAE), الإكوادور (Ecuador)
      expect(isoCodes, contains(IsoCode.AE));
      expect(isoCodes, contains(IsoCode.EC));
    });

    test('"سو" returns countries starting with "سو"', () {
      final results = finder.whereText(text: 'سو', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      // Should match: سوريا (Syria), سويسرا (Switzerland), السودان (Sudan)
      expect(isoCodes, contains(IsoCode.SY));
      expect(isoCodes, contains(IsoCode.CH));
    });

    test('"كو" returns countries starting with "كو"', () {
      final results = finder.whereText(text: 'كو', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      // Should match: كوبا (Cuba), كولومبيا (Colombia), كوريا (Korea)
      expect(isoCodes, contains(IsoCode.CU));
      expect(isoCodes, contains(IsoCode.CO));
    });

    test('"ال" returns countries with definite article', () {
      final results = finder.whereText(text: 'ال', countries: countries);
      // Many Arabic country names start with "ال" (the definite article)
      expect(results.length, greaterThan(10));
    });
  });

  group('CountryFinder - Arabic - Contains Matches', () {
    test('"عربية" returns countries containing "عربية"', () {
      final results = finder.whereText(text: 'عربية', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      // Should match: الإمارات العربية المتحدة, المملكة العربية السعودية
      expect(isoCodes, contains(IsoCode.AE));
      expect(isoCodes, contains(IsoCode.SA));
    });

    test('"جمهورية" returns countries containing "جمهورية"', () {
      final results = finder.whereText(text: 'جمهورية', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      // Should match various republics
      expect(isoCodes, contains(IsoCode.CF)); // جمهورية أفريقيا الوسطى
      expect(isoCodes, contains(IsoCode.CG)); // جمهورية الكونغو
    });

    test('"جزر" returns countries containing "جزر" (islands)', () {
      final results = finder.whereText(text: 'جزر', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      // Should match island nations
      expect(isoCodes, contains(IsoCode.MV)); // جزر المالديف
      expect(isoCodes, contains(IsoCode.MH)); // جزر مارشال
    });

    test('"غينيا" returns countries containing "غينيا"', () {
      final results = finder.whereText(text: 'غينيا', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      // Should match: غينيا, غينيا بيساو, غينيا الاستوائية, بابوا غينيا الجديدة
      expect(isoCodes, contains(IsoCode.GN));
      expect(isoCodes, contains(IsoCode.GW));
      expect(isoCodes, contains(IsoCode.GQ));
      expect(isoCodes, contains(IsoCode.PG));
    });
  });

  group('CountryFinder - Arabic - No-Space Queries', () {
    test('"الإماراتالعربيةالمتحدة" matches UAE', () {
      final results = finder.whereText(
        text: 'الإماراتالعربيةالمتحدة',
        countries: countries,
      );
      expect(results.first.isoCode, equals(IsoCode.AE));
    });

    test('"المملكةالمتحدة" matches United Kingdom', () {
      final results = finder.whereText(
        text: 'المملكةالمتحدة',
        countries: countries,
      );
      expect(results.first.isoCode, equals(IsoCode.GB));
    });

    test('"الولاياتالمتحدة" matches United States', () {
      final results = finder.whereText(
        text: 'الولاياتالمتحدة',
        countries: countries,
      );
      expect(results.first.isoCode, equals(IsoCode.US));
    });

    test('"جنوبأفريقيا" matches South Africa', () {
      final results = finder.whereText(
        text: 'جنوبأفريقيا',
        countries: countries,
      );
      expect(results.first.isoCode, equals(IsoCode.ZA));
    });

    test('"كورياالجنوبية" matches South Korea', () {
      final results = finder.whereText(
        text: 'كورياالجنوبية',
        countries: countries,
      );
      expect(results.first.isoCode, equals(IsoCode.KR));
    });
  });

  group('CountryFinder - Arabic - Diacritics/Tashkeel Handling', () {
    // Arabic diacritics (harakat) should be handled correctly
    test('"عُمان" with damma matches Oman', () {
      final results = finder.whereText(text: 'عُمان', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.OM));
    });

    test('"عمان" without damma also matches Oman', () {
      final results = finder.whereText(text: 'عمان', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.OM));
    });
  });

  group('CountryFinder - Arabic - Multi-Word Queries', () {
    test('"الإمارات العربية" matches UAE', () {
      final results = finder.whereText(
        text: 'الإمارات العربية',
        countries: countries,
      );
      expect(results.first.isoCode, equals(IsoCode.AE));
    });

    test('"المملكة العربية السعودية" matches Saudi Arabia', () {
      final results = finder.whereText(
        text: 'المملكة العربية السعودية',
        countries: countries,
      );
      expect(results.first.isoCode, equals(IsoCode.SA));
    });

    test('"كوريا الجنوبية" matches South Korea', () {
      final results = finder.whereText(
        text: 'كوريا الجنوبية',
        countries: countries,
      );
      expect(results.first.isoCode, equals(IsoCode.KR));
    });

    test('"كوريا الشمالية" matches North Korea', () {
      final results = finder.whereText(
        text: 'كوريا الشمالية',
        countries: countries,
      );
      expect(results.first.isoCode, equals(IsoCode.KP));
    });

    test('"جنوب أفريقيا" matches South Africa', () {
      final results = finder.whereText(
        text: 'جنوب أفريقيا',
        countries: countries,
      );
      expect(results.first.isoCode, equals(IsoCode.ZA));
    });

    test('"ساحل العاج" matches Ivory Coast', () {
      final results = finder.whereText(
        text: 'ساحل العاج',
        countries: countries,
      );
      expect(results.first.isoCode, equals(IsoCode.CI));
    });
  });

  group('CountryFinder - Arabic - Common Alternate Spellings', () {
    // Test common variations in Arabic spelling
    test('"امارات" (without hamza) still matches UAE', () {
      final results = finder.whereText(text: 'امارات', countries: countries);
      final isoCodes = results.map((c) => c.isoCode).toList();
      // May or may not match depending on fuzzy threshold
      // The normalized form should handle this
      expect(isoCodes, contains(IsoCode.AE));
    });

    test('"سعوديه" (with taa marbuta as haa) fuzzy matches', () {
      // This tests robustness - "ة" vs "ه" is a common typo
      final results = finder.whereText(text: 'سعوديه', countries: countries);
      // Should either match Saudi Arabia or be close enough for fuzzy
      final isoCodes = results.map((c) => c.isoCode).toList();
      expect(isoCodes, contains(IsoCode.SA));
    });
  });

  group('CountryFinder - Arabic - Dial Code Searches', () {
    test('"20" returns Egypt (مصر)', () {
      final results = finder.whereText(text: '20', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.EG));
    });

    test('"966" returns Saudi Arabia', () {
      final results = finder.whereText(text: '966', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.SA));
    });

    test('"971" returns UAE', () {
      final results = finder.whereText(text: '971', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.AE));
    });

    test('"962" returns Jordan (الأردن)', () {
      final results = finder.whereText(text: '962', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.JO));
    });

    test('"961" returns Lebanon (لبنان)', () {
      final results = finder.whereText(text: '961', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.LB));
    });

    test('"965" returns Kuwait (الكويت)', () {
      final results = finder.whereText(text: '965', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.KW));
    });

    test('"974" returns Qatar (قطر)', () {
      final results = finder.whereText(text: '974', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.QA));
    });

    test('"213" returns Algeria (الجزائر)', () {
      final results = finder.whereText(text: '213', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.DZ));
    });

    test('"212" returns Morocco (المغرب)', () {
      final results = finder.whereText(text: '212', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.MA));
    });

    test('"+20" with plus prefix returns Egypt', () {
      final results = finder.whereText(text: '+20', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.EG));
    });
  });

  group('CountryFinder - Arabic - Gulf Countries', () {
    test('"الخليج" related searches find Gulf countries', () {
      // Test that major Gulf countries are findable
      final uaeResults =
          finder.whereText(text: 'الإمارات', countries: countries);
      expect(uaeResults.first.isoCode, equals(IsoCode.AE));

      final saudiResults =
          finder.whereText(text: 'السعودية', countries: countries);
      expect(saudiResults.first.isoCode, equals(IsoCode.SA));

      final kuwaitResults =
          finder.whereText(text: 'الكويت', countries: countries);
      expect(kuwaitResults.first.isoCode, equals(IsoCode.KW));

      final qatarResults = finder.whereText(text: 'قطر', countries: countries);
      expect(qatarResults.first.isoCode, equals(IsoCode.QA));

      final bahrainResults =
          finder.whereText(text: 'البحرين', countries: countries);
      expect(bahrainResults.first.isoCode, equals(IsoCode.BH));

      final omanResults = finder.whereText(text: 'عمان', countries: countries);
      expect(omanResults.first.isoCode, equals(IsoCode.OM));
    });
  });

  group('CountryFinder - Arabic - Levant Countries', () {
    test('Levant countries are findable', () {
      final jordanResults =
          finder.whereText(text: 'الأردن', countries: countries);
      expect(jordanResults.first.isoCode, equals(IsoCode.JO));

      final lebanonResults =
          finder.whereText(text: 'لبنان', countries: countries);
      expect(lebanonResults.first.isoCode, equals(IsoCode.LB));

      final syriaResults =
          finder.whereText(text: 'سوريا', countries: countries);
      expect(syriaResults.first.isoCode, equals(IsoCode.SY));

      final palestineResults =
          finder.whereText(text: 'فلسطين', countries: countries);
      expect(palestineResults.first.isoCode, equals(IsoCode.PS));

      final iraqResults = finder.whereText(text: 'العراق', countries: countries);
      expect(iraqResults.first.isoCode, equals(IsoCode.IQ));
    });
  });

  group('CountryFinder - Arabic - North Africa Countries', () {
    test('North African countries are findable', () {
      final egyptResults = finder.whereText(text: 'مصر', countries: countries);
      expect(egyptResults.first.isoCode, equals(IsoCode.EG));

      final algeriaResults =
          finder.whereText(text: 'الجزائر', countries: countries);
      expect(algeriaResults.first.isoCode, equals(IsoCode.DZ));

      final moroccoResults =
          finder.whereText(text: 'المغرب', countries: countries);
      expect(moroccoResults.first.isoCode, equals(IsoCode.MA));

      final tunisiaResults =
          finder.whereText(text: 'تونس', countries: countries);
      expect(tunisiaResults.first.isoCode, equals(IsoCode.TN));

      final libyaResults = finder.whereText(text: 'ليبيا', countries: countries);
      expect(libyaResults.first.isoCode, equals(IsoCode.LY));

      final sudanResults =
          finder.whereText(text: 'السودان', countries: countries);
      expect(sudanResults.first.isoCode, equals(IsoCode.SD));
    });
  });

  group('CountryFinder - Arabic - No Results', () {
    test('completely unrelated query returns empty', () {
      final results =
          finder.whereText(text: 'xyzاختبار123', countries: countries);
      expect(results, isEmpty);
    });

    test('English query returns empty for Arabic list', () {
      // Searching "Spain" in Arabic country names should not match
      final results = finder.whereText(text: 'Spain', countries: countries);
      // Should be empty since Arabic names don't contain "Spain"
      expect(results, isEmpty);
    });
  });

  group('CountryFinder - Arabic - Sorting/Ranking', () {
    test('prefix matches rank higher than contains matches', () {
      // "مصر" should put Egypt first, not other countries containing these letters
      final results = finder.whereText(text: 'مصر', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.EG));
    });

    test('exact match ranks highest', () {
      // "قطر" should rank Qatar first
      final results = finder.whereText(text: 'قطر', countries: countries);
      expect(results.first.isoCode, equals(IsoCode.QA));
    });
  });
}

/// Build a list of SearchableCountry for Arabic locale.
List<SearchableCountry> _buildArabicCountries() {
  return [
    SearchableCountry(IsoCode.AF, '93', 'أفغانستان'),
    SearchableCountry(IsoCode.AL, '355', 'ألبانيا'),
    SearchableCountry(IsoCode.DZ, '213', 'الجزائر'),
    SearchableCountry(IsoCode.AD, '376', 'أندورا'),
    SearchableCountry(IsoCode.AO, '244', 'أنغولا'),
    SearchableCountry(IsoCode.AG, '1268', 'أنتيغوا وبربودا'),
    SearchableCountry(IsoCode.AR, '54', 'الأرجنتين'),
    SearchableCountry(IsoCode.AM, '374', 'أرمينيا'),
    SearchableCountry(IsoCode.AU, '61', 'أستراليا'),
    SearchableCountry(IsoCode.AT, '43', 'النمسا'),
    SearchableCountry(IsoCode.AZ, '994', 'أذربيجان'),
    SearchableCountry(IsoCode.BS, '1242', 'جزر البهاما'),
    SearchableCountry(IsoCode.BH, '973', 'البحرين'),
    SearchableCountry(IsoCode.BD, '880', 'بنغلاديش'),
    SearchableCountry(IsoCode.BB, '1246', 'باربادوس'),
    SearchableCountry(IsoCode.BY, '375', 'بيلاروسيا'),
    SearchableCountry(IsoCode.BE, '32', 'بلجيكا'),
    SearchableCountry(IsoCode.BZ, '501', 'بليز'),
    SearchableCountry(IsoCode.BJ, '229', 'بنين'),
    SearchableCountry(IsoCode.BT, '975', 'بوتان'),
    SearchableCountry(IsoCode.BO, '591', 'بوليفيا'),
    SearchableCountry(IsoCode.BA, '387', 'البوسنة والهرسك'),
    SearchableCountry(IsoCode.BW, '267', 'بوتسوانا'),
    SearchableCountry(IsoCode.BR, '55', 'البرازيل'),
    SearchableCountry(IsoCode.BN, '673', 'بروناي'),
    SearchableCountry(IsoCode.BG, '359', 'بلغاريا'),
    SearchableCountry(IsoCode.BF, '226', 'بوركينا فاسو'),
    SearchableCountry(IsoCode.BI, '257', 'بوروندي'),
    SearchableCountry(IsoCode.CV, '238', 'الرأس الأخضر'),
    SearchableCountry(IsoCode.KH, '855', 'كمبوديا'),
    SearchableCountry(IsoCode.CM, '237', 'الكاميرون'),
    SearchableCountry(IsoCode.CA, '1', 'كندا'),
    SearchableCountry(IsoCode.CF, '236', 'جمهورية أفريقيا الوسطى'),
    SearchableCountry(IsoCode.TD, '235', 'تشاد'),
    SearchableCountry(IsoCode.CL, '56', 'تشيلي'),
    SearchableCountry(IsoCode.CN, '86', 'الصين'),
    SearchableCountry(IsoCode.CO, '57', 'كولومبيا'),
    SearchableCountry(IsoCode.KM, '269', 'جزر القمر'),
    SearchableCountry(IsoCode.CG, '242', 'جمهورية الكونغو'),
    SearchableCountry(IsoCode.CD, '243', 'جمهورية الكونغو الديمقراطية'),
    SearchableCountry(IsoCode.CR, '506', 'كوستاريكا'),
    SearchableCountry(IsoCode.CI, '225', 'ساحل العاج'),
    SearchableCountry(IsoCode.HR, '385', 'كرواتيا'),
    SearchableCountry(IsoCode.CU, '53', 'كوبا'),
    SearchableCountry(IsoCode.CW, '599', 'كوراساو'),
    SearchableCountry(IsoCode.CY, '357', 'قبرص'),
    SearchableCountry(IsoCode.CZ, '420', 'التشيك'),
    SearchableCountry(IsoCode.DK, '45', 'الدنمارك'),
    SearchableCountry(IsoCode.DJ, '253', 'جيبوتي'),
    SearchableCountry(IsoCode.DM, '1767', 'دومينيكا'),
    SearchableCountry(IsoCode.DO, '1809', 'جمهورية الدومينيكان'),
    SearchableCountry(IsoCode.EC, '593', 'الإكوادور'),
    SearchableCountry(IsoCode.EG, '20', 'مصر'),
    SearchableCountry(IsoCode.SV, '503', 'السلفادور'),
    SearchableCountry(IsoCode.GQ, '240', 'غينيا الاستوائية'),
    SearchableCountry(IsoCode.ER, '291', 'إريتريا'),
    SearchableCountry(IsoCode.EE, '372', 'إستونيا'),
    SearchableCountry(IsoCode.SZ, '268', 'إسواتيني'),
    SearchableCountry(IsoCode.ET, '251', 'إثيوبيا'),
    SearchableCountry(IsoCode.FJ, '679', 'فيجي'),
    SearchableCountry(IsoCode.FI, '358', 'فنلندا'),
    SearchableCountry(IsoCode.FR, '33', 'فرنسا'),
    SearchableCountry(IsoCode.GA, '241', 'الغابون'),
    SearchableCountry(IsoCode.GM, '220', 'غامبيا'),
    SearchableCountry(IsoCode.GE, '995', 'جورجيا'),
    SearchableCountry(IsoCode.DE, '49', 'ألمانيا'),
    SearchableCountry(IsoCode.GH, '233', 'غانا'),
    SearchableCountry(IsoCode.GR, '30', 'اليونان'),
    SearchableCountry(IsoCode.GD, '1473', 'غرينادا'),
    SearchableCountry(IsoCode.GT, '502', 'غواتيمالا'),
    SearchableCountry(IsoCode.GN, '224', 'غينيا'),
    SearchableCountry(IsoCode.GW, '245', 'غينيا بيساو'),
    SearchableCountry(IsoCode.GY, '592', 'غيانا'),
    SearchableCountry(IsoCode.HT, '509', 'هايتي'),
    SearchableCountry(IsoCode.HN, '504', 'هندوراس'),
    SearchableCountry(IsoCode.HU, '36', 'المجر'),
    SearchableCountry(IsoCode.IS, '354', 'آيسلندا'),
    SearchableCountry(IsoCode.IN, '91', 'الهند'),
    SearchableCountry(IsoCode.ID, '62', 'إندونيسيا'),
    SearchableCountry(IsoCode.IR, '98', 'إيران'),
    SearchableCountry(IsoCode.IQ, '964', 'العراق'),
    SearchableCountry(IsoCode.IE, '353', 'أيرلندا'),
    SearchableCountry(IsoCode.IT, '39', 'إيطاليا'),
    SearchableCountry(IsoCode.JM, '1876', 'جامايكا'),
    SearchableCountry(IsoCode.JP, '81', 'اليابان'),
    SearchableCountry(IsoCode.JO, '962', 'الأردن'),
    SearchableCountry(IsoCode.KZ, '7', 'كازاخستان'),
    SearchableCountry(IsoCode.KE, '254', 'كينيا'),
    SearchableCountry(IsoCode.KI, '686', 'كيريباتي'),
    SearchableCountry(IsoCode.KP, '850', 'كوريا الشمالية'),
    SearchableCountry(IsoCode.KR, '82', 'كوريا الجنوبية'),
    SearchableCountry(IsoCode.KW, '965', 'الكويت'),
    SearchableCountry(IsoCode.KG, '996', 'قيرغيزستان'),
    SearchableCountry(IsoCode.LA, '856', 'لاوس'),
    SearchableCountry(IsoCode.LV, '371', 'لاتفيا'),
    SearchableCountry(IsoCode.LB, '961', 'لبنان'),
    SearchableCountry(IsoCode.LS, '266', 'ليسوتو'),
    SearchableCountry(IsoCode.LR, '231', 'ليبيريا'),
    SearchableCountry(IsoCode.LY, '218', 'ليبيا'),
    SearchableCountry(IsoCode.LI, '423', 'ليختنشتاين'),
    SearchableCountry(IsoCode.LT, '370', 'ليتوانيا'),
    SearchableCountry(IsoCode.LU, '352', 'لوكسمبورغ'),
    SearchableCountry(IsoCode.MG, '261', 'مدغشقر'),
    SearchableCountry(IsoCode.MW, '265', 'ملاوي'),
    SearchableCountry(IsoCode.MY, '60', 'ماليزيا'),
    SearchableCountry(IsoCode.MV, '960', 'جزر المالديف'),
    SearchableCountry(IsoCode.ML, '223', 'مالي'),
    SearchableCountry(IsoCode.MT, '356', 'مالطا'),
    SearchableCountry(IsoCode.MH, '692', 'جزر مارشال'),
    SearchableCountry(IsoCode.MR, '222', 'موريتانيا'),
    SearchableCountry(IsoCode.MU, '230', 'موريشيوس'),
    SearchableCountry(IsoCode.MX, '52', 'المكسيك'),
    SearchableCountry(IsoCode.FM, '691', 'ميكرونيزيا'),
    SearchableCountry(IsoCode.MD, '373', 'مولدوفا'),
    SearchableCountry(IsoCode.MC, '377', 'موناكو'),
    SearchableCountry(IsoCode.MN, '976', 'منغوليا'),
    SearchableCountry(IsoCode.ME, '382', 'الجبل الأسود'),
    SearchableCountry(IsoCode.MA, '212', 'المغرب'),
    SearchableCountry(IsoCode.MZ, '258', 'موزمبيق'),
    SearchableCountry(IsoCode.MM, '95', 'ميانمار'),
    SearchableCountry(IsoCode.NA, '264', 'ناميبيا'),
    SearchableCountry(IsoCode.NR, '674', 'ناورو'),
    SearchableCountry(IsoCode.NP, '977', 'نيبال'),
    SearchableCountry(IsoCode.NL, '31', 'هولندا'),
    SearchableCountry(IsoCode.NC, '687', 'كاليدونيا الجديدة'),
    SearchableCountry(IsoCode.NZ, '64', 'نيوزيلندا'),
    SearchableCountry(IsoCode.NI, '505', 'نيكاراغوا'),
    SearchableCountry(IsoCode.NE, '227', 'النيجر'),
    SearchableCountry(IsoCode.NG, '234', 'نيجيريا'),
    SearchableCountry(IsoCode.MK, '389', 'مقدونيا الشمالية'),
    SearchableCountry(IsoCode.NO, '47', 'النرويج'),
    SearchableCountry(IsoCode.OM, '968', 'عُمان'),
    SearchableCountry(IsoCode.PK, '92', 'باكستان'),
    SearchableCountry(IsoCode.PW, '680', 'بالاو'),
    SearchableCountry(IsoCode.PS, '970', 'فلسطين'),
    SearchableCountry(IsoCode.PA, '507', 'بنما'),
    SearchableCountry(IsoCode.PG, '675', 'بابوا غينيا الجديدة'),
    SearchableCountry(IsoCode.PY, '595', 'باراغواي'),
    SearchableCountry(IsoCode.PE, '51', 'بيرو'),
    SearchableCountry(IsoCode.PH, '63', 'الفلبين'),
    SearchableCountry(IsoCode.PL, '48', 'بولندا'),
    SearchableCountry(IsoCode.PT, '351', 'البرتغال'),
    SearchableCountry(IsoCode.QA, '974', 'قطر'),
    SearchableCountry(IsoCode.RE, '262', 'ريونيون'),
    SearchableCountry(IsoCode.RO, '40', 'رومانيا'),
    SearchableCountry(IsoCode.RU, '7', 'روسيا'),
    SearchableCountry(IsoCode.RW, '250', 'رواندا'),
    SearchableCountry(IsoCode.WS, '685', 'ساموا'),
    SearchableCountry(IsoCode.SM, '378', 'سان مارينو'),
    SearchableCountry(IsoCode.ST, '239', 'ساو تومي وبرينسيبي'),
    SearchableCountry(IsoCode.SA, '966', 'المملكة العربية السعودية'),
    SearchableCountry(IsoCode.SN, '221', 'السنغال'),
    SearchableCountry(IsoCode.RS, '381', 'صربيا'),
    SearchableCountry(IsoCode.SC, '248', 'سيشل'),
    SearchableCountry(IsoCode.SL, '232', 'سيراليون'),
    SearchableCountry(IsoCode.SG, '65', 'سنغافورة'),
    SearchableCountry(IsoCode.SK, '421', 'سلوفاكيا'),
    SearchableCountry(IsoCode.SI, '386', 'سلوفينيا'),
    SearchableCountry(IsoCode.SB, '677', 'جزر سليمان'),
    SearchableCountry(IsoCode.SO, '252', 'الصومال'),
    SearchableCountry(IsoCode.ZA, '27', 'جنوب أفريقيا'),
    SearchableCountry(IsoCode.SS, '211', 'جنوب السودان'),
    SearchableCountry(IsoCode.ES, '34', 'إسبانيا'),
    SearchableCountry(IsoCode.LK, '94', 'سريلانكا'),
    SearchableCountry(IsoCode.SD, '249', 'السودان'),
    SearchableCountry(IsoCode.SR, '597', 'سورينام'),
    SearchableCountry(IsoCode.SE, '46', 'السويد'),
    SearchableCountry(IsoCode.CH, '41', 'سويسرا'),
    SearchableCountry(IsoCode.SY, '963', 'سوريا'),
    SearchableCountry(IsoCode.TW, '886', 'تايوان'),
    SearchableCountry(IsoCode.TJ, '992', 'طاجيكستان'),
    SearchableCountry(IsoCode.TZ, '255', 'تنزانيا'),
    SearchableCountry(IsoCode.TH, '66', 'تايلاند'),
    SearchableCountry(IsoCode.TL, '670', 'تيمور الشرقية'),
    SearchableCountry(IsoCode.TG, '228', 'توغو'),
    SearchableCountry(IsoCode.TO, '676', 'تونغا'),
    SearchableCountry(IsoCode.TT, '1868', 'ترينيداد وتوباغو'),
    SearchableCountry(IsoCode.TN, '216', 'تونس'),
    SearchableCountry(IsoCode.TR, '90', 'تركيا'),
    SearchableCountry(IsoCode.TM, '993', 'تركمانستان'),
    SearchableCountry(IsoCode.TV, '688', 'توفالو'),
    SearchableCountry(IsoCode.UG, '256', 'أوغندا'),
    SearchableCountry(IsoCode.UA, '380', 'أوكرانيا'),
    SearchableCountry(IsoCode.AE, '971', 'الإمارات العربية المتحدة'),
    SearchableCountry(IsoCode.GB, '44', 'المملكة المتحدة'),
    SearchableCountry(IsoCode.US, '1', 'الولايات المتحدة'),
    SearchableCountry(IsoCode.UY, '598', 'أوروغواي'),
    SearchableCountry(IsoCode.UZ, '998', 'أوزبكستان'),
    SearchableCountry(IsoCode.VU, '678', 'فانواتو'),
    SearchableCountry(IsoCode.VA, '379', 'الفاتيكان'),
    SearchableCountry(IsoCode.VE, '58', 'فنزويلا'),
    SearchableCountry(IsoCode.VN, '84', 'فيتنام'),
    SearchableCountry(IsoCode.YE, '967', 'اليمن'),
    SearchableCountry(IsoCode.ZM, '260', 'زامبيا'),
    SearchableCountry(IsoCode.ZW, '263', 'زيمبابوي'),
  ];
}
