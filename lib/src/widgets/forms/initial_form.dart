import 'package:flutter/material.dart';
import 'package:hydrate_app/src/widgets/forms/country_dropdown.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/utils/datetime_extensions.dart';
import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/provider/settings_provider.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/utils/dropdown_labels.dart';

class InitialForm extends StatefulWidget {

  const InitialForm({ 
    this.isFormEditing = false, 
    this.isFormModifiable = true, 
    Key? key 
  }) : super(key: key);
  
  final bool isFormEditing;
  final bool isFormModifiable;

  @override
  State<InitialForm> createState() => _InitialFormState();
}

class _InitialFormState extends State<InitialForm> {
  final _formKey = GlobalKey<FormState>();

  final birthDateController = TextEditingController();

  /// Verifica cada campo del formulario. Si no hay errores, registra la nueva
  /// información del usuario en la DB y redirige a [redirectRoute]. 
  void _validateAndSave(BuildContext context, UserProfile changes, {String? redirectRoute}) async {

    // Revisar si el form está en un estado válido.
    if (_formKey.currentState!.validate()) {
      // Obtener proveedor de perfiles.
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      // Actualizar el perfil si el formulario es de edición, de lo contrario
      // crear un nuevo perfil.
      if (widget.isFormEditing) {
        await profileProvider.saveProfileChanges();
      } else {
        // Crear el nuevo perfil de usuario.
        int newProfileId = await profileProvider.saveNewProfile();
        // Configurar el ID del perfil por defecto para settings.
        Provider.of<SettingsProvider>(context, listen: false).currentProfileId = newProfileId;
      }

      if (redirectRoute != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(redirectRoute, (route) => false);
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    final localizations = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: FutureBuilder<UserProfile?>(
        future: profileProvider.profile,
        builder: (context, snapshot) {

          if (snapshot.hasData) {

            final activeProfile = snapshot.data;
            final profileChanges = profileProvider.profileChanges;

            if (activeProfile != null && profileChanges != null) {

              birthDateController.text = activeProfile.birthDate?.toLocalizedDate ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  
                  (widget.isFormEditing)
                  ? const SizedBox( height: 0.0 )
                  : TextFormField(
                      keyboardType: TextInputType.text,
                      maxLength: 50,
                      enabled: widget.isFormModifiable,
                      readOnly: !widget.isFormModifiable,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: localizations.firstName,
                        helperText: ' ',
                        counterText: '${profileChanges.firstName.length.toString()}/50'
                      ),
                      onChanged: (value) => profileChanges.firstName = value,
                      validator: (value) => UserProfile.validateFirstName(value),
                    ),
                  
                  SizedBox( height: (widget.isFormEditing ? 0.0 : 16.0 )),

                  (widget.isFormEditing)
                  ? const SizedBox( height: 0.0 )
                  : TextFormField(
                      keyboardType: TextInputType.text,
                      maxLength: 50,
                      enabled: widget.isFormModifiable,
                      readOnly: !widget.isFormModifiable,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: localizations.lastName,
                        helperText: ' ',
                        counterText: '${profileChanges.lastName.length.toString()}/50'
                      ),
                      onChanged: (value) => profileChanges.lastName = value,
                      validator: (value) => UserProfile.validateLastName(value),
                    ),
                  
                  SizedBox( height: (widget.isFormEditing ? 0.0 : 16.0 )),

                  TextFormField(
                    readOnly: true,
                    controller: birthDateController,
                    enabled: widget.isFormModifiable,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: localizations.dateOfBirth,
                      helperText: ' ', // Para evitar cambios en la altura del widget
                      suffixIcon: const Icon(Icons.event_rounded)
                    ),
                    onTap: () async {
                      DateTime? newBirthDate = await showDatePicker(
                        context: context, 
                        initialDate: DateTime(DateTime.now().year - 10), 
                        firstDate: DateTime(1900), 
                        lastDate: DateTime(DateTime.now().year)
                      );

                      profileChanges.birthDate = newBirthDate;

                      if (profileChanges.birthDate != null) {
                        birthDateController.text = profileChanges.birthDate.toString().substring(0,10);
                      }
                    },
                  ),                

                  const SizedBox( height: 16.0, ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:  <Widget>[
                      Expanded(
                        child: DropdownButtonFormField(
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: localizations.gender,
                            helperText: ' ',
                            hintText: localizations.select
                          ),
                          isExpanded: true,
                          items: DropdownLabels.genderDropdownItems(context),
                          value: profileChanges.sex.index,
                          onChanged: (widget.isFormModifiable) 
                            ? (int? newValue) {
                                profileChanges.sex = UserSex.values[newValue ?? 0];
                              }
                            : null,
                        ),
                      ),

                      const SizedBox( width: 16.0 ,),

                      Expanded(
                        child: CountryDropdown(
                          isUnmodifiable: !widget.isFormEditing
                        ),
                      ),
                    ]
                  ),
                
                  const SizedBox( height: 16.0, ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:  <Widget>[
                      Expanded(
                        child: TextFormField(
                          // autocorrect: false,
                          keyboardType: TextInputType.number,
                          enabled: widget.isFormModifiable,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: '${localizations.height} (m)',
                            hintText: '1.70',
                            helperText: ' ',
                            suffixIcon: const Icon(Icons.height),
                          ),
                          initialValue: profileChanges.height.toStringAsFixed(2),
                          onChanged: (value) => profileChanges.height = double.tryParse(value) ?? 0,
                          validator: (value) => UserProfile.validateHeight(value),
                        ),
                      ),

                      const SizedBox( width: 16.0, ),

                      Expanded(
                        child: TextFormField(
                          autocorrect: false,
                          keyboardType: TextInputType.number,
                          enabled: widget.isFormModifiable,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: '${localizations.weight} (kg)',
                            hintText: '60.0',
                            helperText: ' ',
                            suffixIcon: const Icon(Icons.monitor_weight_outlined)
                          ),
                          initialValue: profileChanges.weight.toString(),
                          onChanged: (value) => profileChanges.weight = double.tryParse(value) ?? 0,
                          validator: (value) => UserProfile.validateWeight(value),
                        ),
                      ),
                    ],
                  ),
                
                  const SizedBox( height: 16.0, ),

                  (widget.isFormEditing)
                  ? const SizedBox( height: 0.0, )
                  : DropdownButtonFormField(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: localizations.occupation,
                        helperText: ' ',
                        hintText: localizations.select
                      ),
                      items: DropdownLabels.occupationDropdownItems(context),
                      value: profileChanges.occupation.index,
                      onChanged: (widget.isFormModifiable) 
                        ? (int? newValue) {
                            profileChanges.occupation = Occupation.values[newValue ?? 0];
                          }
                        : null,
                    ),

                  const SizedBox( height: 16.0, ),

                  DropdownButtonFormField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: localizations.medicalCondition,
                      helperText: ' ',
                    ),
                    items: DropdownLabels.conditionDropdownItems(context),
                    value: profileChanges.medicalCondition.index,
                    onChanged: (widget.isFormModifiable) 
                      ? (int? newValue) {
                          profileChanges.medicalCondition = MedicalCondition.values[newValue ?? 0];
                        }
                      : null,
                  ),
                
                  (widget.isFormEditing) 
                    ? const SizedBox( height: 48.0 )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: ElevatedButton(
                            child: Text(localizations.skip),
                            style: ElevatedButton.styleFrom(
                              primary: Colors.grey.shade700,
                            ),
                            onPressed: () async {
                              int newProfileId = await profileProvider.newDefaultProfile();
                              settingsProvider.currentProfileId = newProfileId;

                              Navigator.pushReplacementNamed(context, RouteNames.home);
                            },
                          ),
                        ),
                  
                        const SizedBox( width: 16.0, ),
                  
                        Expanded(
                          child: ElevatedButton(
                            child: Text(localizations.continueAction),
                            style: ElevatedButton.styleFrom(
                              primary: Colors.blue,
                            ),
                            onPressed: () => _validateAndSave(context, profileChanges)
                          ),
                        ),
                      ]
                    ),
                ]
              );
            }
          } 

          return const SizedBox(
            height: 248.0,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      ),
    );
  }
}
