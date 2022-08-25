import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/enums/occupation_type.dart';
import 'package:hydrate_app/src/models/enums/user_sex.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/provider/settings_provider.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';
import 'package:hydrate_app/src/utils/dropdown_labels.dart';
import 'package:hydrate_app/src/widgets/forms/country_dropdown.dart';

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
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      // Actualizar el perfil de usuario (ya sea recién creado o existente) con 
      // los cambios de este formulario.
      final savedProfileId = await profileProvider.saveNewProfile();

      if (savedProfileId >= 0) {
        // Si es el formulario inicial, configurar el ID del perfil activo por 
        // defecto en los ajustes.
        if (!widget.isModifyingExistingProfile) {
          // Configurar el ID del perfil por defecto para settings.
          final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
          settingsProvider.currentProfileId = savedProfileId;
        } 

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

  void _skipInitialForm(BuildContext context) async {

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    final newProfileId = await profileProvider.saveNewProfile(saveEmpty: true);
    settingsProvider.currentProfileId = newProfileId;

    Navigator.pushReplacementNamed(context, RouteNames.home);
  }

  void _pickBirthDate(BuildContext context) async {
    // Mostrar el selector de fechas.
    DateTime? newBirthDate = await showDatePicker(
      context: context, 
      initialDate: DateTime(DateTime.now().year - 10), 
      firstDate: DateTime(1900), 
      lastDate: DateTime(DateTime.now().year)
    );

    final profileChanges = Provider.of<ProfileProvider>(context, listen: false).profileChanges;

    profileChanges.birthDate = newBirthDate;

    if (profileChanges.birthDate != null) {
      birthDateController.text = profileChanges.birthDate.toString().substring(0,10);
    }
  }

  void _showProfileErrorSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        //TODO: agregar i18n para error creando perfil inicial.
        content: Text('Tu perfil no pudo ser creado'),
        duration: Duration(seconds: 3),
      )
    );
  }

  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileProvider>(context);

    final localizations = AppLocalizations.of(context)!;

    final profileChanges = profileProvider.profileChanges;

    birthDateController.text = profileChanges.birthDate?.toLocalizedDate ?? '';

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          
          (widget.isModifyingExistingProfile
            ? const SizedBox( height: 0)
            : _ProfileFormNameFields(
              isFormModifiable: widget.isFormModifiable,
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
              helperText: ' ', // Para evitar cambios en la altura del widget
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

          (widget.isModifyingExistingProfile
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
            )
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
                    onPressed: () => _validateAndSave(context)
                  ),
                ),
              ]
            ),
        ]
      ),
    );
  }
}

class _ProfileFormNameFields extends StatelessWidget {

  const _ProfileFormNameFields({
    Key? key, 
    this.isFormModifiable = false,
  }) : super(key: key);

  final bool isFormModifiable;

  String? _getTextInputCounter(String value, int maxLength) {
    // Build the string using a buffer.
    StringBuffer strBuf = StringBuffer(value.characters.length);

    strBuf.write("/");
    strBuf.write(UserProfile.maxFirstNameLength);

    return strBuf.toString();
  }

  @override
  Widget build(BuildContext context) {
    
    final profileChanges = Provider.of<ProfileProvider>(context).profileChanges;
    final localizations = AppLocalizations.of(context)!;

    return Column(
      children: [
        TextFormField(
          keyboardType: TextInputType.text,
          maxLength: 50,
          enabled: isFormModifiable,
          readOnly: !isFormModifiable,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: localizations.firstName,
            helperText: ' ',
            counterText:  _getTextInputCounter(
              profileChanges.firstName,
              UserProfile.maxFirstNameLength
            ),
          ),
          onChanged: (value) => profileChanges.firstName = value,
          validator: (value) => UserProfile.validateFirstName(value),
        ),

        const SizedBox( height: 16.0 ),

        TextFormField(
          keyboardType: TextInputType.text,
          maxLength: 50,
          enabled: isFormModifiable,
          readOnly: !isFormModifiable,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: localizations.lastName,
            helperText: ' ',
            counterText: _getTextInputCounter(
              profileChanges.lastName,
              UserProfile.maxLastNameLength
            ),
          ),
          onChanged: (value) => profileChanges.lastName = value,
          validator: (value) => UserProfile.validateLastName(value),
        ),
      ],
    );
  }
}
