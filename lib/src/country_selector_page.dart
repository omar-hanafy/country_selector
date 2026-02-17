import 'package:country_selector/src/country_selector_base.dart';
import 'package:country_selector/src/localization/localization.dart';
import 'package:country_selector/src/widgets/_country_list_view.dart';
import 'package:country_selector/src/widgets/_search_box.dart';
import 'package:flutter/material.dart';

/// Same as [CountrySelectorSheet] but designed as a full page
class CountrySelectorPage extends CountrySelectorBase {
  const CountrySelectorPage({
    super.key,
    required super.onCountrySelected,
    super.scrollController,
    super.scrollPhysics,
    super.addFavoritesSeparator,
    super.showDialCode,
    super.noResultMessage,
    super.favoriteCountries,
    super.countries,
    super.searchAutofocus,
    super.subtitleStyle,
    super.titleStyle,
    super.searchBoxDecoration,
    super.searchBoxTextStyle,
    super.searchBoxIconColor,
    super.flagSize,
  });

  @override
  CountrySelectorPageState createState() => CountrySelectorPageState();
}

class CountrySelectorPageState
    extends CountrySelectorBaseState<CountrySelectorPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shadowColor: Theme.of(context).colorScheme.shadow,
        title: SearchBox(
          autofocus: widget.searchAutofocus,
          onChanged: onSearch,
          onSubmitted: onSubmitted,
          decoration:
              widget.searchBoxDecoration ??
              InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search,
                  size: 24,
                  color: widget.searchBoxIconColor,
                ),
                hintText:
                    CountrySelectorLocalization.of(context)?.search ??
                    CountrySelectorLocalizationEn().search,
              ),
          style: widget.searchBoxTextStyle,
          searchIconColor: widget.searchBoxIconColor,
        ),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return CountryListView(
            countries: controller.filteredCountries,
            favorites: controller.filteredFavorites,
            addFavoritesSeparator: widget.addFavoritesSeparator,
            showDialCode: widget.showDialCode,
            onTap: (country) => widget.onCountrySelected(country.isoCode),
            flagSize: widget.flagSize,
            scrollController: widget.scrollController,
            scrollPhysics: widget.scrollPhysics,
            noResultMessage: widget.noResultMessage,
            titleStyle: widget.titleStyle,
            subtitleStyle: widget.subtitleStyle,
          );
        },
      ),
    );
  }
}
