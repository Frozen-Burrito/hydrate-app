import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/enums/occupation_type.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/utils/dropdown_labels.dart';
import 'package:hydrate_app/src/widgets/activity_time_brief.dart';
import 'package:hydrate_app/src/widgets/coin_display.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/dialogs/environment_select_dialog.dart';
import 'package:hydrate_app/src/widgets/forms/profile_form.dart';
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

      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

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

    final profileProvider = Provider.of<ProfileProvider>(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        CustomSliverAppBar(
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

            const AuthOptionsMenu()
          ],
        ),

        
  
        SliverToBoxAdapter(
          child: FutureBuilder<UserProfile?>(
            future: profileProvider.profile,
            builder: (context, snapshot) {

              if (snapshot.hasData) {

                final profile = snapshot.data;

                if (profile != null) {
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
                              child: Image( 
                                image: AssetImage(profile.selectedEnvironment.imagePath),
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
              }

              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          ),
        ),
  
        SliverToBoxAdapter(
          child: Column(
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
                child: const _IdealHydrationLabel(2.54),
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

  String? _getTextInputCounter(String value, int maxLength) {
    // Build the string using a buffer.
    StringBuffer strBuf = StringBuffer(value.characters.length);

    strBuf.write("/");
    strBuf.write(UserProfile.maxFirstNameLength);

    return strBuf.toString();
  }

  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    return FutureBuilder<UserProfile?>(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget> [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: TextFormField(
                          keyboardType: TextInputType.text,
                          maxLength: UserProfile.maxFirstNameLength,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: localizations.firstName,
                            helperText: ' ',
                            counterText: _getTextInputCounter(
                              profileChanges.firstName,
                              UserProfile.maxFirstNameLength
                            ),
                          ),
                          //TODO: Agregar i18n para mostrar nombre de usuario anónimo.
                          initialValue: profile.firstName,
                          onChanged: (value) => profileChanges.firstName = value,
                          validator: (value) => UserProfile.validateFirstName(value),
                        ),
                      ),

                      const SizedBox( width: 8.0, ),

                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: TextFormField(
                          keyboardType: TextInputType.text,
                          maxLength: UserProfile.maxLastNameLength,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: localizations.lastName,
                            helperText: ' ',
                            counterText: _getTextInputCounter(
                              profileChanges.lastName,
                              UserProfile.maxLastNameLength
                            ),
                          ),
                          initialValue: profile.lastName,
                          onChanged: (value) => profileChanges.lastName = value,
                          validator: (value) => UserProfile.validateLastName(value),
                        ),
                      )
                    ],
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
    ); 
  }
}

class _IdealHydrationLabel extends StatelessWidget {

  final double idealHydration;

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
          '${idealHydration.toStringAsFixed(2)} L',
          style: Theme.of(context).textTheme.headline6!.copyWith(
            color: Theme.of(context).colorScheme.primary
          )
        ),
      ],
    );
  }
}