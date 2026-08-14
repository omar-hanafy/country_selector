import 'package:country_selector/country_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Locks the exclusion in place: the selector must never surface an excluded
/// country, no matter what the caller passes in.
void main() {
  Widget buildSheet({
    List<IsoCode> countries = IsoCode.values,
    List<IsoCode> favorites = const [],
  }) {
    return MaterialApp(
      locale: const Locale('en', ''),
      localizationsDelegates: const [
        ...GlobalMaterialLocalizations.delegates,
        CountrySelectorLocalization.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      home: Scaffold(
        body: CountrySelector.sheet(
          onCountrySelected: (_) {},
          countries: countries,
          favoriteCountries: favorites,
        ),
      ),
    );
  }

  group('excluded countries', () {
    testWidgets('are dropped even when passed explicitly', (tester) async {
      await tester.pumpWidget(
        buildSheet(countries: const [IsoCode.IL, IsoCode.EG]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Egypt'), findsOneWidget);
      expect(find.text('Israel'), findsNothing);
    });

    testWidgets('are dropped when passed as favorites', (tester) async {
      await tester.pumpWidget(
        buildSheet(
          countries: const [IsoCode.EG],
          favorites: const [IsoCode.IL],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Israel'), findsNothing);
    });

    testWidgets('cannot be surfaced by a name search', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'israel');
      await tester.pumpAndSettle();

      expect(find.text('Israel'), findsNothing);
    });

    testWidgets('cannot be surfaced by a dial-code search', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '972');
      await tester.pumpAndSettle();

      expect(find.text('Israel'), findsNothing);
    });
  });
}
