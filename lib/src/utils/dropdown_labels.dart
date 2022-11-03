import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hydrate_app/src/models/enums/occupation_type.dart';

import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/models/enums/user_sex.dart';

class DropdownLabels {

  static  genderDropdownItems(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final genderLabels = <String>[
      localizations.genderWoman,
      localizations.genderMan,
      localizations.other,
    ];

    return UserSex.values
      .map((e) {

        return DropdownMenuItem(
          value: e.index,
          child: Text(genderLabels[e.index], overflow: TextOverflow.ellipsis,),
        );
      }).toList();
  }
    
  static List<DropdownMenuItem<int>> getCountryDropdownItems(BuildContext context, List<Country> countries) {

    final localizations = AppLocalizations.of(context)!;

    final labels = <String, String>{
      '--': localizations.preferNotToSay,
      'MX': localizations.countryMx,
      'EU': localizations.countryUs,
      'OT': localizations.other,
    };

    return countries.map((country) {
      return DropdownMenuItem(
        value: country.id - 1,
        child: Text(labels[country.code] ?? 'No especificado', overflow: TextOverflow.ellipsis,),
      );
    }).toList();
  }

  static List<IconLabel> activityLabels(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;

    return <IconLabel> [
      IconLabel(1, localizations.actTypeWalk, Icons.directions_walk),
      IconLabel(2, localizations.actTypeRun, Icons.directions_run),
      IconLabel(3, localizations.actTypeCycle, Icons.directions_bike),
      IconLabel(4, localizations.actTypeSwim, Icons.pool),
      IconLabel(5, localizations.actTypeSoccer, Icons.sports_soccer),
      IconLabel(6, localizations.actTypeBasketball, Icons.sports_basketball),
      IconLabel(7, localizations.actTypeVolleyball, Icons.sports_volleyball),
      IconLabel(8, localizations.actTypeDance, Icons.emoji_people),
      IconLabel(9, localizations.actTypeYoga, Icons.self_improvement),
    ];
  }

  static List<DropdownMenuItem<int>> activityTypes(BuildContext context, List<ActivityType> activityTypes) {

    final activityLabels = DropdownLabels.activityLabels(context);

    return activityTypes.map((activityType) {
      
      final int activityTypeIndex = activityLabels.indexWhere(
        (activityLabel) => activityLabel.activityTypeId == activityType.id);

      final IconLabel labelForActivityType = activityTypeIndex >= 0 
        ? activityLabels[activityTypeIndex] 
        : const IconLabel.unknownItem();

      return DropdownMenuItem(
        value: activityType.id,
        child: Row(
          children: [
            
            Icon(labelForActivityType.icon),

            const SizedBox( width: 4.0,),

            Text(
              labelForActivityType.label, 
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }).toList();
  }

  static occupationLabels(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return <String>[
      localizations.preferNotToSay,
      localizations.student,
      localizations.officeWorker,
      localizations.manualWorker,
      localizations.parent,
      localizations.athlete,
      localizations.other,
    ];
  }
   
  static occupationDropdownItems(BuildContext context) {

    final occupationLabels = DropdownLabels.occupationLabels(context);

    return Occupation.values
    .map((e) {
      return DropdownMenuItem(
        value: e.index,
        child: Text(occupationLabels[e.index], overflow: TextOverflow.ellipsis,),
      );
    }).toList();
  }

  static conditionDropdownItems(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final labels = <String>[
      localizations.preferNotToSay, 
      localizations.condNone,
      localizations.condRenalInsuf,
      localizations.condNephriticSynd,
      localizations.other
    ];

    return MedicalCondition.values
      .map((e) {
        return DropdownMenuItem(
          value: e.index,
          child: Text(labels[e.index], overflow: TextOverflow.ellipsis,),
        );
      }).toList();
  }
}

class IconLabel {

  final int activityTypeId;
  final String label;
  final IconData icon;

  const IconLabel(this.activityTypeId, this.label, this.icon);

  const IconLabel.unknownItem() : this(-1, "Unknown item", Icons.question_answer);
}
