import 'package:country_selector/country_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const CountrySelectorExampleApp());
}

class CountrySelectorExampleApp extends StatelessWidget {
  const CountrySelectorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Country Selector Example',
      theme: ThemeData.light(),
      localizationsDelegates: const [
        ...GlobalMaterialLocalizations.delegates,
        CountrySelectorLocalization.delegate,
      ],
      supportedLocales: const [Locale('ar')],
      home: const CountrySelectorHome(),
    );
  }
}

class CountrySelectorHome extends StatefulWidget {
  const CountrySelectorHome({super.key});

  @override
  State<CountrySelectorHome> createState() => _CountrySelectorHomeState();
}

class _CountrySelectorHomeState extends State<CountrySelectorHome> {
  static const List<IsoCode> _favorites = [IsoCode.EG, IsoCode.SA, IsoCode.AE];

  IsoCode? _selected;
  bool _showDialCode = true;

  CountrySelectorLocalization _localization(BuildContext context) {
    return CountrySelectorLocalization.of(context) ??
        CountrySelectorLocalizationEn();
  }

  void _setSelected(IsoCode isoCode) {
    setState(() {
      _selected = isoCode;
    });
  }

  Future<void> _openSelectorSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: CountrySelector.sheet(
            favoriteCountries: _favorites,
            showDialCode: _showDialCode,
            onCountrySelected: (isoCode) {
              _setSelected(isoCode);
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  Future<void> _openSelectorPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: const Text('Select a country')),
            body: CountrySelector.page(
              favoriteCountries: _favorites,
              showDialCode: _showDialCode,
              onCountrySelected: (isoCode) {
                _setSelected(isoCode);
                Navigator.of(context).pop();
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = _localization(context);
    final selectedName = _selected == null
        ? 'None'
        : localization.countryName(_selected!);
    final selectedDialCode = _selected == null
        ? '-'
        : localization.countryDialCode(_selected!);

    return Scaffold(
      appBar: AppBar(title: const Text('Country Selector Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                title: Text(selectedName),
                subtitle: Text('Dial code: $selectedDialCode'),
                trailing: _selected == null ? null : Text(_selected!.name),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Show dial code'),
              value: _showDialCode,
              onChanged: (value) {
                setState(() {
                  _showDialCode = value;
                });
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _openSelectorSheet,
              child: const Text('Open selector sheet'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _openSelectorPage,
              child: const Text('Open selector page'),
            ),
          ],
        ),
      ),
    );
  }
}
