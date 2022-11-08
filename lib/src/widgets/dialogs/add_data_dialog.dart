import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:provider/provider.dart';

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

  static const List<_AddDataNavOption> options = <_AddDataNavOption>[
    _AddDataNavOption( 
      title: "Registra una actividad físcia", 
      icon: Icon( Icons.directions_run ), 
      route: RouteNames.newActivity
    ),
    _AddDataNavOption( 
      title: "Resume tu semana", 
      icon: Icon( Icons.fact_check ), 
      route: RouteNames.weeklyForm
    ),
    _AddDataNavOption( 
      title: "Agrega resultados médicos", 
      icon: Icon( Icons.monitor_heart ), 
      route: RouteNames.medicalForm
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileService>(
      builder: (context, profileService, __) {
        return FutureBuilder<UserProfile?>(
          future: profileService.profile,
          builder: (context, snapshot) {

            final profile = snapshot.data;

            return AlertDialog(
              title: const Text("Agrega datos"),
              content: SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Registra datos sobre tu actividad, estilo de vida, o salud:"),

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
                  child: const Text('Cancelar'),
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