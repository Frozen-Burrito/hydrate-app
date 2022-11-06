import 'package:flutter/material.dart';
import 'package:hydrate_app/src/services/activity_service.dart';
import 'package:hydrate_app/src/services/goals_service.dart';
import 'package:hydrate_app/src/services/hydration_record_service.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';
import 'package:hydrate_app/src/utils/water_intake_calculator.dart';
import 'package:hydrate_app/src/widgets/count_text.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/enums/occupation_type.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/utils/dropdown_labels.dart';
import 'package:hydrate_app/src/widgets/asset_fade_in_image.dart';
import 'package:hydrate_app/src/widgets/activity_time_brief.dart';
import 'package:hydrate_app/src/widgets/coin_display.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/dialogs/environment_select_dialog.dart';
import 'package:hydrate_app/src/widgets/forms/profile_form.dart';
import 'package:hydrate_app/src/widgets/full_name_input.dart';
import 'package:hydrate_app/src/widgets/opt_popup_menu.dart';
import 'package:hydrate_app/src/widgets/shapes.dart';

class ProfileTab extends StatefulWidget {

  const ProfileTab({ Key? key }) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {

  bool isEditModeActive = false;
  bool isSaving = false;

  Future<void> _toggleEditMode(BuildContext context) async {

    if (isEditModeActive) {

      setState(() { isSaving = true; });

      final profileProvider = Provider.of<ProfileService>(context, listen: false);

      final saveResult = await profileProvider.saveProfileChanges();

      if (saveResult != SaveProfileResult.noChanges) {
        _showSaveResultSnackbar(context, saveResult);
      }

      switch(saveResult) {
        case SaveProfileResult.changesSaved:
        case SaveProfileResult.noChanges:
          isEditModeActive = false;
          break;
        default:
          isEditModeActive = true; 
          break;
      }
    } else {
      isEditModeActive = true;
    }

    isSaving = false;

    setState(() {});
  }

  void _showSaveResultSnackbar(BuildContext context, SaveProfileResult result) {
    //TODO: agregar i18 a los mensajes de snackbar para cambios de perfil
    String message = "Something went wrong with message display.";

    switch(result) {
      case SaveProfileResult.changesSaved:
        message = "Profile changes saved.";
        break;
      case SaveProfileResult.reachedChangeLimit:
        message = "You have reached the limit of yearly profile modifications";
        break;
      default: 
        message = "An error occurred while saving changes. Please try again.";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      )
    );
  }

  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileService>(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        CustomSliverAppBar(
          //TODO: agregar i18n.
          title: 'Perfil',
          leading: const <Widget>[
            CoinDisplay(),
          ],
          actions: <Widget>[

            Builder(
              builder: (context) {
                if (isSaving) {
                  return const Center(
                    child: SizedBox(
                      height: 16.0,
                      width: 16.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        //TODO: agregar i18n
                        semanticsLabel: 'Saving profile changes',
                      ),
                    ),
                  );
                } else {
                  return IconButton(
                    icon: Icon( isEditModeActive ? Icons.check : Icons.edit ),
                    color: isEditModeActive
                      ? Colors.green.shade400
                      : Theme.of(context).colorScheme.onBackground,
                    onPressed: () {
                      _toggleEditMode(context);
                    }, 
                  );
                }
              }
            ),

            IconButton(
              onPressed: () async {

                  profileProvider.profileChanges.addCoins(100);
                  await profileProvider.saveProfileChanges();
              },
              icon: const Icon(Icons.add),
            )

            // const AuthOptionsMenu()
          ],
        ),
  
        SliverToBoxAdapter(
          child: FutureBuilder<UserProfile?>(
            future: profileProvider.profile,
            builder: (context, snapshot) {

              if (snapshot.hasData) {

                final profile = snapshot.data!;

                return Stack(
                  children: <Widget>[
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: GestureDetector(
                        onTap:  isEditModeActive 
                          ? () => showDialog(
                              context: context, 
                              builder: (context) => const EnvironmentSelectDialog(), 
                            )
                          : null,
                          child: ClipPath(
                          clipper: WaveImageClipper(),
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: AssetFadeInImage(
                              image: isEditModeActive 
                                ? profile.selectedEnvironment.baseImagePath
                                : profileProvider.profileChanges.selectedEnvironment.baseImagePath,
                              duration: const Duration(milliseconds: 500),
                            ),
                          ),
                        ), 
                      ),
                    ),
                    
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.10,
                      left: MediaQuery.of(context).size.width * 0.5 - 50.0,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        radius: 64.0,
                        child: Text(
                          profile.initials,
                          style: Theme.of(context).textTheme.headline3!.copyWith(
                            fontSize: 48.0,
                            color: Theme.of(context).colorScheme.onSecondary
                          ),
                        ),
                      ),
                    )
                  ]
                );
              }

              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          ),
        ),
  
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only( bottom: 32.0 ),
                child: _FullnameDisplay(isEditing: isEditModeActive)
              ),

              Container(
                margin: const EdgeInsets.only( bottom: 32.0 ),
                child: const ActivityTimeBrief(),
              ),

              Container(
                margin: const EdgeInsets.only( bottom: 16.0 ),
                child: Consumer<ActivityService>(
                  builder: (_, activityService, __) {

                    final goalsService = Provider.of<GoalsService>(context);
                    final hydrationService = Provider.of<HydrationRecordService>(context);

                    return FutureBuilder<int>(
                      future: Future.microtask(() async {

                        final DateTime aWeekAgo = DateTime.now().onlyDate
                          .subtract(const Duration( days: 6 ));

                        final userProfile = await profileProvider.profile;
                        final activityDuringPastWeek = (await activityService.routineActivities)
                          .activitiesWithRoutines
                          .where((record) => record.date.isAfter(aWeekAgo))
                          .toList();

                        final pastWeekTotals = await hydrationService.pastWeekMlTotals;
                        final latestPeriodicReport = await goalsService.lastPeriodicReport; 

                        final int recommendedHydration;

                        if (userProfile != null) {

                          final latestMedicalReport = (userProfile.hasNephroticSyndrome || userProfile.hasRenalInsufficiency)
                            ? await goalsService.lastMedicalReport
                            : null; 

                          recommendedHydration = IdealHydrationCalculator.aproximateIdealHydration(
                            userProfile, 
                            activityDuringPastWeek, 
                            pastWeekTotals, 
                            mostRecentWeeklyReport: latestPeriodicReport,
                            mostRecentMedicalReport: latestMedicalReport,
                          );

                        } else {
                          recommendedHydration = 0;
                        }

                        return recommendedHydration;
                      }),
                      builder: (context, snapshot) {
                        final recommendedHydration = snapshot.data ?? 0;
                        return _IdealHydrationLabel(recommendedHydration);
                      }
                    );
                  }
                ),
              ),
              
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ProfileForm(
                    isModifyingExistingProfile: true,
                    isFormModifiable: isEditModeActive
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

class _FullnameDisplay extends StatelessWidget {

  final bool isEditing;

  const _FullnameDisplay({ this.isEditing = false, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileService>(context);
    final localizations = AppLocalizations.of(context)!;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: FutureBuilder<UserProfile?>(
        future: profileProvider.profile,
        builder: (context, snapshot) {

          if (snapshot.hasData) {
            // Obtener datos de perfil.
            final profile = snapshot.data;
            final profileChanges = profileProvider.profileChanges;

            if (profile != null) {
              if (isEditing) {

                return Column(
                  children: <Widget>[
                    FullNameInput.horizontal(
                      isEnabled: isEditing, 
                      firstNameValidator: UserProfile.validateFirstName,
                      lastNameValidator: UserProfile.validateLastName,
                      maxFirstNameLength: UserProfile.maxFirstNameLength,
                      maxLastNameLength: UserProfile.maxLastNameLength,
                      initialFirstName: profileChanges.firstName,
                      initialLastName: profileChanges.lastName,
                      onFirstNameChanged: (value) => profileChanges.firstName = value, 
                      onLastNameChanged: (value) => profileChanges.lastName = value,
                    ),
                  
                    const SizedBox( height: 16.0 ,),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 48.0),
                      child: DropdownButtonFormField(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: localizations.occupation,
                          helperText: ' ',
                          hintText: 'Selecciona' 
                        ),
                        items: DropdownLabels.occupationDropdownItems(context),
                        value: profileChanges.occupation.index,
                        onChanged: (int? value) => profileChanges.occupation = Occupation.values[value ?? 0],
                      ),
                    ),
                  ],
                );
              } else {

                return Column(
                  children: <Widget>[
                    Text(
                      (profile.fullName.trim().isNotEmpty) 
                        ? profile.fullName
                        : 'Perfil Anónimo',
                      style: Theme.of(context).textTheme.headline4,
                    ),

                    const SizedBox( height: 16.0 ,),

                    Text(
                      DropdownLabels.occupationLabels(context)[profile.occupation.index],
                      style: Theme.of(context).textTheme.headline6,
                    ),
                  ]
                );
              }
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

class _IdealHydrationLabel extends StatelessWidget {
  /// La hidratación ideal, en mililitros por día.
  final int idealHydration;

  const _IdealHydrationLabel(
    this.idealHydration,
    { Key? key, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          AppLocalizations.of(context)!.idealHydration,
          style: Theme.of(context).textTheme.headline6
        ),

        Icon(
          Icons.opacity,
          size: 24.0,
          color: Theme.of(context).colorScheme.primary,
        ),

        Text(
          '${(idealHydration / 1000.0).toStringAsFixed(2)} L',
          style: Theme.of(context).textTheme.headline6!.copyWith(
            color: Theme.of(context).colorScheme.primary
          )
        ),
      ],
    );
  }
}