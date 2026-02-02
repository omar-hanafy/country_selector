# country_selector

A highly customizable and localized country selector for Flutter, featuring fuzzy search, flag support, and flexible display options (full page or modal sheet).

## Features

*   **Flexible Display:** Use it as a full page or a modal bottom sheet.
*   **Powerful Search:**
    *   Search by country name, dial code, or ISO code.
    *   Fuzzy search algorithms (typo tolerance) handling localizations and diacritics.
    *   Smart sorting with exact matches and favorites prioritized.
*   **Localization:** Built-in localization support.
*   **Customization:** Fully customizable styles for text, search box, and flags.
*   **Favorites:** Pin favorite countries to the top of the list.
*   **Flag Support:** Displays country flags using `circle_flags`.

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  country_selector: ^1.0.0
  flutter_localizations:
    sdk: flutter
```

## Usage

### Basic Usage

You can use the `CountrySelector.page` or `CountrySelector.sheet` static methods to display the selector.

#### Full Page

```dart
import 'package:country_selector/country_selector.dart';
import 'package:flutter/material.dart';

void showCountryPage(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => CountrySelector.page(
        onCountrySelected: (IsoCode isoCode) {
          print('Selected country: ${isoCode.name}');
          Navigator.of(context).pop();
        },
      ),
    ),
  );
}
```

#### Modal Sheet

For the best experience in a modal sheet, use `DraggableScrollableSheet` and pass the scroll controller.

```dart
import 'package:country_selector/country_selector.dart';
import 'package:flutter/material.dart';

void showCountrySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return CountrySelector.sheet(
          onCountrySelected: (IsoCode isoCode) {
            print('Selected country: ${isoCode.name}');
            Navigator.of(context).pop();
          },
          scrollController: scrollController,
        );
      },
    ),
  );
}
```

### Localization

To enable localizations, add the delegates to your `MaterialApp`:

```dart
import 'package:country_selector/country_selector.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

MaterialApp(
  localizationsDelegates: [
    CountrySelectorLocalization.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: [
    Locale('en', ''),
    Locale('ar', ''),
    // ... other locales
  ],
  // ...
)
```

### Customization

Both `page` and `sheet` constructors allow extensive customization:

```dart
CountrySelector.page(
  onCountrySelected: (isoCode) {},
  favoriteCountries: [IsoCode.US, IsoCode.GB], // Pin favorites
  showDialCode: true, // Show +1, +44, etc.
  flagSize: 30,
  noResultMessage: "No country found",
  searchBoxDecoration: InputDecoration(
    labelText: "Search Country",
    border: OutlineInputBorder(),
  ),
  // ... and many more style properties
)
```

## Performance

The package includes a `preloadFlags` method (useful for web) to download flag assets into memory:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Optional: Preload flags for smoother web experience
  await CountrySelector.preloadFlags(); 
  runApp(MyApp());
}
```
