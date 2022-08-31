import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/country.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/utils/dropdown_labels.dart';

class CountryDropdown extends StatelessWidget {

  const CountryDropdown({
    Key? key, 
    required this.isModifiable,
  }) : super(key: key);

  final bool isModifiable;

  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    final profileChanges = profileProvider.profileChanges;
    
    return FutureBuilder<List<Country>>(
      future: profileProvider.countries,
      builder: (context, snapshot) {

        final countries = snapshot.data ?? [ Country.countryNotSpecified ];

        final profileCountryIdx = countries.indexOf(profileChanges.country);
        final dropdownValue = profileCountryIdx.isNegative ? 0 : profileCountryIdx;

        return DropdownButtonFormField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: localizations.country,
            helperText: ' ',
            hintText: localizations.select
          ),
          isExpanded: true,
          items: DropdownLabels.getCountryDropdownItems(context, countries),
          value: dropdownValue,
          onChanged: isModifiable && snapshot.hasData
            ? (int? newValue) {
                final valueInRange = min(newValue ?? 0, countries.length);
                profileChanges.country = countries[valueInRange];
              }
            : null,
        );
      }
    );
  }
}