import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/utils/dropdown_labels.dart';
import 'package:hydrate_app/src/widgets/activity_time_brief.dart';
import 'package:hydrate_app/src/widgets/coin_display.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/opt_popup_menu.dart';
import 'package:hydrate_app/src/widgets/forms/initial_form.dart';
import 'package:hydrate_app/src/widgets/shapes.dart';

class ProfileTab extends StatefulWidget {

  const ProfileTab({ Key? key }) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {

  bool isEditModeActive = false;

  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileProvider>(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        CustomSliverAppBar(
          title: '',
          leading: const <Widget>[
            CoinDisplay(),
          ],
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditModeActive = !isEditModeActive;
                });
              }, 
            ),

            const AuthOptionsMenu()
          ],
        ),
  
        SliverToBoxAdapter(
          child: Stack(
            children: <Widget>[
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.3,
                child: GestureDetector(
                  //TODO: Dialog para editar el entorno.
                  onTap: isEditModeActive ? () => print('Editando entorno') : null,
                    child: ClipPath(
                    clipper: WaveImageClipper(),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: Image( 
                        image: AssetImage(profileProvider.profile.selectedEnvironment.imagePath),
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
                    profileProvider.profile.initials,
                    style: Theme.of(context).textTheme.headline3!.copyWith(
                      fontSize: 48.0,
                      color: Theme.of(context).colorScheme.onSecondary
                    ),
                  ),
                ),
              )
            ]
          ),
        ),
  
        SliverToBoxAdapter(
          child: Column(
            children: <Widget>[
              _FullnameDisplay(isEditing: isEditModeActive),
  
              const SizedBox( height: 32.0 ,),
  
              ActivityTimeBrief(profileProvider.profile.id),
  
              const SizedBox( height: 32.0 ,),
  
              const _IdealHydrationLabel(2.54),
  
              const SizedBox( height: 16.0 ,),
              
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: InitialForm(
                    isFormEditing: true,
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

    final localizations = AppLocalizations.of(context)!;

    return Consumer<ProfileProvider>(
      builder: (_, provider, __) {

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
                      maxLength: 50,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: localizations.firstName,
                        helperText: ' ',
                        counterText: '${provider.profileChanges.firstName.length.toString()}/50'
                      ),
                      initialValue: provider.profile.firstName,
                      onChanged: (value) => provider.firstName = value,
                      validator: (value) => UserProfile.validateFirstName(value),
                    ),
                  ),

                  const SizedBox( width: 8.0, ),

                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: TextFormField(
                      keyboardType: TextInputType.text,
                      maxLength: 50,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: localizations.lastName,
                        helperText: ' ',
                        counterText: '${provider.profileChanges.lastName.length.toString()}/50'
                      ),
                      initialValue: provider.profile.lastName,
                      onChanged: (value) => provider.lastName = value,
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
                  value: provider.profileChanges.occupation.index,
                  onChanged: (int? value) => provider.occupation = Occupation.values[value ?? 0],
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: <Widget>[
              Text(
                provider.profile.fullName,
                style: Theme.of(context).textTheme.headline4,
              ),

              const SizedBox( height: 16.0 ,),

              Text(
                DropdownLabels.occupationLabels(context)[provider.profile.occupation.index],
                style: Theme.of(context).textTheme.headline6,
              ),
            ]
          );
        }
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