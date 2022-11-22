import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/services/profile_service.dart';

class AddDataDialog extends StatelessWidget {

  const AddDataDialog({Key? key}) : super(key: key);

  VoidCallback? _getOptionOnPressed(BuildContext context, _AddDataNavOption option, UserProfile? profile) {

    if (profile == null) return null;

    switch (option.route) {
      case RouteNames.newActivity:
      case RouteNames.weeklyForm:
        return () => Navigator.popAndPushNamed(context, option.route);
      case RouteNames.medicalForm:
        if (profile.hasRenalInsufficiency || profile.hasNephroticSyndrome) {
          return () => Navigator.popAndPushNamed(context, option.route);
        } else {
          return null;
        }
      default: 
        return null;
    }
  }

  List<_AddDataNavOption> _getDataOptions(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return <_AddDataNavOption>[
      _AddDataNavOption( 
        title: localizations.addActivity, 
        icon: const Icon( Icons.directions_run ), 
        route: RouteNames.newActivity
      ),
      _AddDataNavOption( 
        title: localizations.summarizeWeek, 
        icon: const Icon( Icons.fact_check ), 
        route: RouteNames.weeklyForm
      ),
      _AddDataNavOption( 
        title: localizations.addMedicalResults, 
        icon: const Icon( Icons.monitor_heart ), 
        route: RouteNames.medicalForm
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;

    return Consumer<ProfileService>(
      builder: (context, profileService, __) {
        return FutureBuilder<UserProfile?>(
          future: profileService.profile,
          builder: (context, snapshot) {

            final profile = snapshot.data;
            final options = _getDataOptions(context);

            return AlertDialog(
              title: Text(localizations.addData),
              content: SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(localizations.addDataDetails),

                    const SizedBox(height: 8.0,),

                    ListView.builder(
                      shrinkWrap: true,
                      itemBuilder: (context, i) {
                  
                        final option = options[i];
                  
                        return ListTile(
                          minVerticalPadding: 8.0,
                          leading: option.icon,
                          title: Text(option.title),
                          contentPadding: const EdgeInsets.all( 16.0, ),
                          trailing: const Icon(
                            Icons.arrow_forward,
                            size: 24.0,
                          ),
                          onTap: _getOptionOnPressed(context, option, profile),
                        );
                      },
                      itemCount: options.length,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, null), 
                  child: Text(localizations.cancel),
                ),
              ],
            );
          }
        );
      }
    );
  }
}

class _AddDataNavOption {

  const _AddDataNavOption({
    required this.title, 
    required this.icon, 
    required this.route
  });

  final String title;
  final Icon icon;
  final String route;
}