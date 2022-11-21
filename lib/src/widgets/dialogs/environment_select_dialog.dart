import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/environment.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/widgets/shapes.dart';

class EnvironmentSelectDialog extends StatelessWidget {

  const EnvironmentSelectDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileService>(context);
    final localizations = AppLocalizations.of(context)!;
    
    return FutureBuilder<UserProfile?>(
      future: profileProvider.profile,
      builder: (context, snapshot) {

        if (snapshot.hasData) {

          final activeProfile = snapshot.data!;

          return AlertDialog(
            title: Text(
              localizations.chooseEnvironment, 
              textAlign: TextAlign.center,
            ),
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
                child: Text(localizations.cancel),
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey.shade700,
                ),
                onPressed: () {
                  profileProvider.changeSelectedEnv(activeProfile.selectedEnvironment);
                  Navigator.pop(context);
                },
              ),

              _ConfirmOrPurchaseButton(
                activeProfile: activeProfile
              ),
            ],
          );
        }

        return AlertDialog(
          title: Text(
            localizations.loadingEnvironments, 
            textAlign: TextAlign.center,
          ),
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

class _ConfirmOrPurchaseButton extends StatelessWidget {

  const _ConfirmOrPurchaseButton({
    Key? key,
    required this.activeProfile,
  }) : super(key: key);

  final UserProfile activeProfile;

  String _getTooltipMessage(
    BuildContext context, 
    bool isEnvDifferentFromCurrent,
    bool hasUnlockedEnv, 
    bool canPurchaseEnv,
  ) {
    final localizations = AppLocalizations.of(context)!;

    if (isEnvDifferentFromCurrent) {
      if (!hasUnlockedEnv) {
        if (canPurchaseEnv) {
          return localizations.canPurchaseEnvTooltip;
        } else {
          return localizations.notEnoughCoins;
        }
      } 
    } else {
      return localizations.cannotChooseSameEnv;
    }

    return "";
  }

  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileService>(context);

    final selectedEnvironment = profileProvider.profileChanges.selectedEnvironment;

    final isSelectedDifferentFromCurrent = activeProfile.selectedEnvironment.id != 
        selectedEnvironment.id; 

    final hasUnlockedEnvironment = activeProfile.hasUnlockedEnv(selectedEnvironment.id);

    final int environmentPrice = selectedEnvironment.price;

    final canPurchaseEnv = activeProfile.coins >= environmentPrice;

    final bool isEnabled = isSelectedDifferentFromCurrent && (hasUnlockedEnvironment || canPurchaseEnv);

    final localizations = AppLocalizations.of(context)!;

    return Tooltip(
      message: _getTooltipMessage(
        context, 
        isSelectedDifferentFromCurrent, 
        hasUnlockedEnvironment, 
        canPurchaseEnv
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.blue,
        ),
        onPressed: isEnabled
        ? () async {
            final bool environmentChanged = await profileProvider.confirmEnvironment();
    
            if (environmentChanged) Navigator.pop(context);
          } 
        : null,
        
        child: hasUnlockedEnvironment
          ? Text(localizations.confirmAction)
          : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${localizations.purchaseFor} ${environmentPrice.toString()}"),
              
              const Padding(
                padding: EdgeInsets.all(4.0),
                child: CoinShape(radius: 8.0,),
              ),
            ],
          ),
      ),
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

    final profileProvider = Provider.of<ProfileService>(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      width: double.maxFinite,
      child: FutureBuilder<List<Environment>?>(
        future: profileProvider.environments,
        builder: (context, snapshot) {

          if (snapshot.hasData) { 

            final environments = snapshot.data!;

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
                  onTap: () => onItemSelected(environment),
                  child: Container(
                    alignment: Alignment.center,
                    clipBehavior: Clip.hardEdge,
                    child: isEnvUnlocked
                      ? null
                      : Container(
                          color: Colors.black.withOpacity(0.4),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
                            child: const Center(
                              child: Icon(Icons.lock),
                            ),
                          ),
                        ),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: AssetImage(environment.baseImagePath),
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      border: profileProvider.profileChanges.selectedEnvironment.id == environment.id
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

          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      ),
    );
  }
}