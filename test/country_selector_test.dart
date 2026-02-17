import 'package:flutter/material.dart';
import 'package:country_selector/country_selector.dart';
import 'package:country_selector/src/widgets/_no_result_view.dart';
import 'package:country_selector/src/widgets/_search_box.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  runTests(isPage: true);
  runTests(isPage: false);
}

void runTests({required bool isPage}) {
  group('CountrySelector', () {
    Widget buildSelector({
      List<IsoCode> countries = IsoCode.values,
      List<IsoCode> favorites = const [],
      bool addFavoritesSeparator = true,
      Function(IsoCode)? onCountrySelected,
    }) {
      return MaterialApp(
        locale: const Locale('en', ''),
        localizationsDelegates: const [
          ...GlobalMaterialLocalizations.delegates,
          CountrySelectorLocalization.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: Scaffold(
          body: isPage
              ? CountrySelector.page(
                  onCountrySelected: onCountrySelected ?? (c) {},
                  countries: countries,
                  favoriteCountries: favorites,
                  addFavoritesSeparator: addFavoritesSeparator,
                )
              : CountrySelector.sheet(
                  onCountrySelected: onCountrySelected ?? (c) {},
                  countries: countries,
                  favoriteCountries: favorites,
                  addFavoritesSeparator: addFavoritesSeparator,
                ),
        ),
      );
    }

    testWidgets('Should call callback when country is selected', (
      tester,
    ) async {
      bool called = false;
      await tester.pumpWidget(
        buildSelector(
          onCountrySelected: (c) {
            called = true;
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('Should filter with text', (tester) async {
      await tester.pumpWidget(buildSelector());
      await tester.pumpAndSettle();
      final txtFound = find.byType(SearchBox);
      expect(txtFound, findsOneWidget);
      await tester.enterText(txtFound, 'spa');
      await tester.pumpAndSettle();
      final tiles = find.byType(ListTile);
      expect(tiles, findsWidgets);
      expect(tester.widget<ListTile>(tiles.first).key, equals(const Key('ES')));
      // completely unrelated query should return no results
      await tester.enterText(txtFound, 'xyznotacountry');
      await tester.pumpAndSettle();
      expect(tiles, findsNothing);
      await tester.pumpAndSettle();
      // country codes
      await tester.enterText(txtFound, '33');
      await tester.pumpAndSettle();
      expect(tiles, findsWidgets);
      expect(tester.widget<ListTile>(tiles.first).key, equals(const Key('FR')));
    });

    testWidgets('should show a divider between favorites and all countries', (
      tester,
    ) async {
      await tester.pumpWidget(buildSelector(favorites: const [IsoCode.BE]));
      await tester.pumpAndSettle();
      final list = find.byType(ListView);
      expect(list, findsOneWidget);
      final allTiles = find.descendant(
        of: list,
        matching: find.byWidgetPredicate(
          (Widget widget) => widget is ListTile || widget is Divider,
        ),
      );

      expect(allTiles, findsWidgets);
      expect(
        tester.widget(allTiles.at(1)),
        isA<Divider>(),
        reason: 'separator should be visible after the favorites countries',
      );
    });

    testWidgets('should hide favorites when search has started', (
      tester,
    ) async {
      await tester.pumpWidget(buildSelector(favorites: const [IsoCode.BE]));
      await tester.pumpAndSettle();
      final searchBox = find.byType(SearchBox);
      expect(searchBox, findsOneWidget);
      // Search for "Belgium" - favorites section should be hidden
      await tester.enterText(searchBox, 'Belgium');
      await tester.pumpAndSettle();
      final tiles = find.byType(ListTile);
      // Should find results with Belgium first (favorites hidden during search)
      expect(tiles, findsWidgets);
      expect(tester.widget<ListTile>(tiles.first).key, equals(const Key('BE')));
    });

    testWidgets('should not duplicate favorite countries in main list', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSelector(
          countries: const [IsoCode.BE, IsoCode.FR],
          favorites: const [IsoCode.BE],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('BE')), findsOneWidget);
      expect(find.byKey(const Key('FR')), findsOneWidget);
    });

    testWidgets(
      'should not show divider when favorites separator is disabled',
      (tester) async {
        await tester.pumpWidget(
          buildSelector(
            favorites: const [IsoCode.BE],
            addFavoritesSeparator: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('countryListSeparator')),
          findsNothing,
        );
      },
    );

    testWidgets('should sort countries', (tester) async {
      await tester.pumpWidget(
        buildSelector(favorites: const [IsoCode.SE, IsoCode.SG]),
      );
      await tester.pumpAndSettle();
      final allTiles = find.byType(ListTile, skipOffstage: false);
      expect(allTiles, findsWidgets);
      expect(
        tester.widget<ListTile>(allTiles.at(0)).key,
        equals(Key(IsoCode.SG.name)),
      );
      expect(
        tester.widget<ListTile>(allTiles.at(1)).key,
        equals(Key(IsoCode.SE.name)),
      );
    });

    testWidgets('should display no result when there is no result', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CountrySelector.page(onCountrySelected: (c) {})),
        ),
      );

      final searchBox = find.byType(SearchBox);
      expect(searchBox, findsOneWidget);
      await tester.enterText(searchBox, 'fake search with no result');
      await tester.pumpAndSettle();

      // no listitem should be displayed when no result found
      final allTiles = find.byType(ListTile);
      expect(allTiles, findsNothing);

      final noResultWidget = find.byType(NoResultView);
      expect(noResultWidget, findsOneWidget);
    });

    testWidgets('search box should not submit on text change', (tester) async {
      var submitCalls = 0;
      var changedText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBox(
              autofocus: false,
              onChanged: (value) => changedText = value,
              onSubmitted: () => submitCalls++,
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Belgium');
      await tester.pump();

      expect(changedText, 'Belgium');
      expect(submitCalls, 0);

      await tester.showKeyboard(textField);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submitCalls, 1);
    });

    testWidgets(
      'controller should be disposed and recreated when dependencies change',
      (tester) async {
        Widget buildWithLocale(Locale locale) {
          return MaterialApp(
            locale: locale,
            localizationsDelegates: const [
              ...GlobalMaterialLocalizations.delegates,
              CountrySelectorLocalization.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ar')],
            home: Scaffold(
              body: isPage
                  ? CountrySelector.page(onCountrySelected: (_) {})
                  : CountrySelector.sheet(onCountrySelected: (_) {}),
            ),
          );
        }

        await tester.pumpWidget(buildWithLocale(const Locale('en')));
        await tester.pumpAndSettle();

        final selectorFinder = isPage
            ? find.byType(CountrySelectorPage)
            : find.byType(CountrySelectorSheet);
        final dynamic firstState = tester.state(selectorFinder);
        final ChangeNotifier firstController =
            firstState.controller as ChangeNotifier;

        await tester.pumpWidget(buildWithLocale(const Locale('ar')));
        await tester.pumpAndSettle();

        final dynamic secondState = tester.state(selectorFinder);
        final ChangeNotifier secondController =
            secondState.controller as ChangeNotifier;

        expect(secondController, isNot(same(firstController)));
        expect(
          () => firstController.addListener(() {}),
          throwsA(isA<FlutterError>()),
        );
      },
    );

    test('country names should be localized for all iso codes', () {
      final localization = CountrySelectorLocalizationEn();

      for (final isoCode in IsoCode.values) {
        final countryName = localization.countryName(isoCode);
        expect(
          countryName,
          isNotEmpty,
          reason: 'Missing localization mapping for ${isoCode.name}',
        );
      }
    });
  });
}
