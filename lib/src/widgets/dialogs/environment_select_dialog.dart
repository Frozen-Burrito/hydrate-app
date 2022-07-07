import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/environment.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/widgets/shapes.dart';
import 'package:provider/provider.dart';

class EnvironmentSelectDialog extends StatelessWidget {

  const EnvironmentSelectDialog({Key? key}) : super(key: key);

  bool confirmEnvChoice({
    required UserProfile profile,
    required void Function(Environment) onSet,
    required Future<bool> Function(Environment) onPurchase,
  }) {

    final selectedEnv = profile.selectedEnvironment;

    final hasToPurchaseEnv = profile.hasUnlockedEnv(selectedEnv.id);

    if (hasToPurchaseEnv) {
      onPurchase(selectedEnv);
    }

    onSet(selectedEnv);

    return true;
  }

  //TODO: Agregar localizaciones.
  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileProvider>(context);
    
    return FutureBuilder<UserProfile?>(
      future: profileProvider.profile,
      builder: (context, snapshot) {

        if (snapshot.hasData) {

          final activeProfile = snapshot.data;
          final profileChanges = profileProvider.profileChanges;

          if (activeProfile != null && profileChanges != null) {

            final hasToPurchaseEnv = activeProfile
                .hasUnlockedEnv(profileChanges.selectedEnvId);

            return AlertDialog(
              title: const Text('Selecciona un Entorno', textAlign: TextAlign.center,),
              titleTextStyle: Theme.of(context).textTheme.headline4,
              content: _EnvGridView(
                activeProfile: activeProfile,
                onItemSelected: (newSelectedEnv) {
                  profileProvider.changeSelectedEnv(newSelectedEnv);
                }
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actionsPadding: const EdgeInsets.symmetric( horizontal: 16.0 ),
              actions: [
                ElevatedButton(
                  child: const Text('Cancelar'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.grey.shade700,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),

                ElevatedButton(
                  child: hasToPurchaseEnv
                    ? const Text('Confirmar')
                    : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Comprar por ${(profileChanges.selectedEnvironment.price).toString()}'),
                        
                        const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: CoinShape(radius: 8.0,),
                        ),
                      ],
                    ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                  ),
                  onPressed: activeProfile.selectedEnvId != profileChanges.selectedEnvId 
                  ? () async {
                      final result = confirmEnvChoice(
                        profile: profileChanges,
                        onSet: profileProvider.changeSelectedEnv,
                        onPurchase: profileProvider.purchaseEnvironment
                      );

                      if (result) Navigator.pop(context);
                    } 
                  : null,
                ),
              ],
            );
          }
        }

        return AlertDialog(
          title: const Text('Cargando Entornos', textAlign: TextAlign.center,),
          titleTextStyle: Theme.of(context).textTheme.headline4,
          content: SizedBox(
            height: MediaQuery.of(context).size.height * 0.1,
            child: const Center(
              child: CircularProgressIndicator(), 
            ),
          )
        );
      }
    );
  }
}

class _EnvGridView extends StatelessWidget {

  const _EnvGridView({
    Key? key, 
    required this.activeProfile, 
    required this.onItemSelected,
  }) : super(key: key);

  final UserProfile activeProfile;

  final void Function(Environment) onItemSelected;

  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileProvider>(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      width: double.maxFinite,
      child: FutureBuilder<List<Environment>?>(
        future: profileProvider.environments,
        builder: (context, snapshot) {

          if (snapshot.hasData) { 

            final environments = snapshot.data;

            if (environments != null) {

              return GridView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: environments.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 124.0,
                  childAspectRatio: 1.0,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0
                ), 
                itemBuilder: (context, i) {
                  
                  final environment = environments[i];
                  final isEnvUnlocked = activeProfile.hasUnlockedEnv(environment.id); 

                  return GestureDetector(
                    onTap: isEnvUnlocked 
                    ? () {
                        print('Environment selected: $i');
                        onItemSelected(environment);
                      }
                    : null,
                    child: Container(
                      alignment: Alignment.center,
                      clipBehavior: Clip.hardEdge,
                      child: isEnvUnlocked
                        ? null
                        : Container(
                            color: Colors.black.withOpacity(0.4),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                              child: const Center(
                                child: Icon(Icons.lock),
                              ),
                            ),
                          ),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(environment.imagePath),
                          fit: BoxFit.cover,
                        ),
                        color: Theme.of(context).colorScheme.surface,
                        border: profileProvider.profileChanges?.selectedEnvId == environment.id
                          ? Border.all(
                            width: 2.0,
                            color: Theme.of(context).colorScheme.primary
                          )
                          : null,
                        borderRadius: BorderRadius.circular( 5.0 )
                      ),
                    ),
                  );
                }
              );
            }
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      ),
    );
  }
}