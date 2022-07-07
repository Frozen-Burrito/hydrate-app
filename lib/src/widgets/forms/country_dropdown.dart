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
    required this.isUnmodifiable,
  }) : super(key: key);

  final bool isUnmodifiable;

  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileProvider>(context);
    final localizations = AppLocalizations.of(context)!;
    
    return FutureBuilder<List<Country>?>(
      future: profileProvider.countries,
      builder: (context, snapshot) {

        if (snapshot.hasData) {

          final countries = snapshot.data;
          final profileChanges = profileProvider.profileChanges;

          if (countries != null && profileChanges != null) {

            return DropdownButtonFormField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: localizations.country,
                helperText: ' ',
                hintText: localizations.select
              ),
              isExpanded: true,
              items: DropdownLabels.getCountryDropdownItems(context, countries),
              value: countries.indexOf(profileChanges.country),
              onChanged: isUnmodifiable
                ? null
                : (int? newValue) {
                    profileChanges.country = countries[min(newValue ?? 0, countries.length)];
                  },
            );
          }
        }

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.05,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
    );
  }
}