import 'package:country_selector/src/localization/localization.dart';
import 'package:flutter/material.dart';

class SearchBox extends StatefulWidget {
  final Function(String) onChanged;
  final Function() onSubmitted;
  final bool autofocus;
  final InputDecoration? decoration;
  final TextStyle? style;
  final Color? searchIconColor;

  const SearchBox({
    super.key,
    required this.onChanged,
    required this.onSubmitted,
    required this.autofocus,
    this.decoration,
    this.style,
    this.searchIconColor,
  });

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  void handleChange(String text) {
    widget.onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final baseDecoration =
        widget.decoration ??
        InputDecoration(
          prefixIcon: Icon(
            Icons.search,
            size: 24,
            color: widget.searchIconColor,
          ),
          filled: true,
          isDense: true,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(20),
          ),
          hintText:
              CountrySelectorLocalization.of(context)?.search ??
              CountrySelectorLocalizationEn().search,
        );

    final effectiveDecoration = widget.searchIconColor == null
        ? baseDecoration
        : baseDecoration.copyWith(prefixIconColor: widget.searchIconColor);

    return TextField(
      autofocus: widget.autofocus,
      onChanged: handleChange,
      onSubmitted: (_) => widget.onSubmitted(),
      cursorColor: widget.style?.color,
      style: widget.style ?? Theme.of(context).textTheme.titleLarge,
      autofillHints: const [AutofillHints.countryName],
      decoration: effectiveDecoration,
    );
  }
}
