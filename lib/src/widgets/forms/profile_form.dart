import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/validators/profile_validator.dart';
import 'package:hydrate_app/src/models/validators/validation_message_builder.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/enums/occupation_type.dart';
import 'package:hydrate_app/src/models/enums/user_sex.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';
import 'package:hydrate_app/src/utils/dropdown_labels.dart';
import 'package:hydrate_app/src/widgets/forms/country_dropdown.dart';
import 'package:hydrate_app/src/widgets/full_name_input.dart';

class ProfileForm extends StatefulWidget {

  const ProfileForm({ 
    this.isModifyingExistingProfile = false, 
    this.isFormModifiable = true, 
    Key? key 
  }) : super(key: key);
  
  final bool isModifyingExistingProfile;
  final bool isFormModifiable;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {

  final _formKey = GlobalKey<FormState>();

  final birthDateController = TextEditingController();

  /// Verifica cada campo del formulario. Si no hay errores, registra la nueva
  /// información del usuario en la DB y redirige a [redirectRoute]. 
  void _validateAndSave(BuildContext context, {String? redirectRoute}) async {

    // Revisar si el form está en un estado válido.
    final isFormValid = _formKey.currentState!.validate();

    if (isFormValid) {
      // Obtener proveedor de perfiles.
      final profileProvider = Provider.of<ProfileService>(context, listen: false);

      // Actualizar el perfil de usuario (ya sea recién creado o existente) con 
      // los cambios de este formulario.
      final saveResult = await profileProvider.saveProfileChanges();

      if (saveResult == SaveProfileResult.changesSaved) {
        if (redirectRoute != null) {
          Navigator.of(context).pushNamedAndRemoveUntil(redirectRoute, (route) => false);
        } else {
          Navigator.of(context).pop();
        }

      } else {
        _showProfileErrorSnackbar(context);
      }
    }
  }

  void _skipInitialForm(BuildContext context) 
      => Navigator.pushReplacementNamed(context, RouteNames.home);

  void _pickBirthDate(BuildContext context) async {

    final profileChanges = Provider.of<ProfileService>(context, listen: false).profileChanges;

    final int currentYear = DateTime.now().year;
    final DateTime initialDate;
    final DateTime lastDate = DateTime(currentYear);
    
    if (profileChanges.dateOfBirth != null && profileChanges.dateOfBirth!.isBefore(lastDate)) {
      initialDate = profileChanges.dateOfBirth!;
    } else {
      initialDate = DateTime(currentYear - 20);
    }

    // Mostrar el selector de fechas.
    DateTime? newBirthDate = await showDatePicker(
      context: context, 
      initialDate: initialDate, 
      firstDate: DateTime(1900), 
      lastDate: lastDate,
    );

    profileChanges.dateOfBirth = newBirthDate;

    if (profileChanges.dateOfBirth != null) {
      birthDateController.text = profileChanges.dateOfBirth.toString().substring(0,10);
    }
  }

  void _showProfileErrorSnackbar(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${localizations.profileCreationError}."),
        duration: const Duration(seconds: 3),
      )
    );
  }

  String? _validateHeight(ValidationMessageBuilder messageBuilder, String? input) {
    final heightError = UserProfile.validator.validateHeight(input);
    return messageBuilder.forHeight(heightError);
  }

  String? _validateWeight(ValidationMessageBuilder messageBuilder, String? input) {
    final weightError = UserProfile.validator.validateWeight(input);
    return messageBuilder.forWeight(weightError);
  }

  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileService>(context);

    final localizations = AppLocalizations.of(context)!;
    final validationMessageBuilder = ValidationMessageBuilder.of(context);

    final profileChanges = profileProvider.profileChanges;
    
    birthDateController.text = profileChanges.dateOfBirth?.toLocalizedDate(context) ?? "";

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          
          (widget.isModifyingExistingProfile
            ? const SizedBox( height: 0)
            : FullNameInput.vertical(
              isEnabled: widget.isFormModifiable, 
              firstNameValidator: UserProfile.validator.validateFirstName,
              lastNameValidator: UserProfile.validator.validateLastName,
              maxFirstNameLength: ProfileValidator.firstNameLengthRange.max.toInt(),
              maxLastNameLength: ProfileValidator.lastNameLengthRange.min.toInt(),
              initialFirstName: profileChanges.firstName,
              initialLastName: profileChanges.lastName,
              onFirstNameChanged: (value) => profileChanges.firstName = value, 
              onLastNameChanged: (value) => profileChanges.lastName = value,
            )
          ), 

          const SizedBox( height: 16.0, ),

          TextFormField(
            readOnly: true,
            controller: birthDateController,
            enabled: widget.isFormModifiable,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: localizations.dateOfBirth,
              helperText: " ", // Para evitar cambios en la altura del widget
              suffixIcon: const Icon(Icons.event_rounded)
            ),
            onTap: () => _pickBirthDate(context),
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
                    helperText: " ",
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
                  isModifiable: widget.isFormModifiable
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
                    labelText: "${localizations.height} (${localizations.metersAbbreviated})",
                    hintText: localizations.heightHint,
                    helperText: " ",
                    suffixIcon: const Icon(Icons.height),
                  ),
                  initialValue: profileChanges.height.toStringAsFixed(2),
                  onChanged: (value) => profileChanges.height = double.tryParse(value) ?? 0.0,
                  validator: (value) => _validateHeight(validationMessageBuilder, value),
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
                    labelText: "${localizations.weight} (${localizations.kilogramsAbbreviated})",
                    hintText: localizations.weightHint,
                    helperText: " ",
                    suffixIcon: const Icon(Icons.monitor_weight_outlined)
                  ),
                  initialValue: profileChanges.weight.toString(),
                  onChanged: (value) => profileChanges.weight = double.tryParse(value) ?? 0,
                  validator: (value) => _validateWeight(validationMessageBuilder, value),
                ),
              ),
            ],
          ),
        
          const SizedBox( height: 16.0, ),

          if (!widget.isModifyingExistingProfile)
          DropdownButtonFormField(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: localizations.occupation,
              helperText: " ",
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
              helperText: " ",
            ),
            items: DropdownLabels.conditionDropdownItems(context),
            value: profileChanges.medicalCondition.index,
            onChanged: (widget.isFormModifiable) 
              ? (int? newValue) {
                  profileChanges.medicalCondition = MedicalCondition.values[newValue ?? 0];
                }
              : null,
          ),
        
          (widget.isModifyingExistingProfile) 
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
                    onPressed: () => _skipInitialForm(context),
                  ),
                ),
          
                const SizedBox( width: 16.0, ),
          
                Expanded(
                  child: ElevatedButton(
                    child: Text(localizations.continueAction),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                    ),
                    onPressed: () => _validateAndSave(
                      context, 
                      redirectRoute: RouteNames.home
                    ),
                  ),
                ),
              ]
            ),
        ]
      ),
    );
  }
}
