import 'package:country_selector/src/localization/localization.dart';
import 'package:country_selector/src/search/country_finder.dart';
import 'package:country_selector/src/search/searchable_country.dart';
import 'package:flutter/material.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class CountrySelectorController with ChangeNotifier {
  final _finder = CountryFinder();
  List<SearchableCountry> _allCountries = [];
  List<SearchableCountry> _countries = [];
  List<SearchableCountry> _filteredCountries = [];
  List<SearchableCountry> _favoriteCountries = [];
  List<SearchableCountry> _filteredFavoriteCountries = [];

  List<SearchableCountry> get filteredCountries => _filteredCountries;
  List<SearchableCountry> get filteredFavorites => _filteredFavoriteCountries;

  CountrySelectorController(
    BuildContext context,
    List<IsoCode> countriesIsoCode,
    List<IsoCode> favoriteCountriesIsoCode,
  ) {
    final filteredFavorites = favoriteCountriesIsoCode
        .where((c) => c != IsoCode.IL)
        .toList();
    final filteredCountries = countriesIsoCode
        .where((c) => c != IsoCode.IL)
        .toList();

    _allCountries = _buildLocalizedCountryList(context, filteredCountries);
    _favoriteCountries = _buildLocalizedCountryList(context, filteredFavorites);
    final favoriteSet = filteredFavorites.toSet();
    _countries = _allCountries
        .where((country) => !favoriteSet.contains(country.isoCode))
        .toList(growable: false);
    _filteredCountries = _countries;
    _filteredFavoriteCountries = _favoriteCountries;
  }

  void search(String searchedText) {
    if (searchedText.isEmpty) {
      _filteredCountries = _countries;
      _filteredFavoriteCountries = _favoriteCountries;
    } else {
      _filteredCountries = _finder.whereText(
        text: searchedText,
        countries: _allCountries,
      );
      _filteredFavoriteCountries = [];
    }
    notifyListeners();
  }

  SearchableCountry? findFirst() {
    return _filteredFavoriteCountries.firstOrNull ??
        _filteredCountries.firstOrNull;
  }

  List<SearchableCountry> _buildLocalizedCountryList(
    BuildContext context,
    List<IsoCode> isoCodes,
  ) {
    // we need the localized names in order to search
    final localization =
        CountrySelectorLocalization.of(context) ??
        CountrySelectorLocalizationEn();
    return isoCodes
        .map(
          (isoCode) => SearchableCountry(
            isoCode,
            localization.countryDialCode(isoCode),
            localization.countryName(isoCode),
          ),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
