import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/utils/dropdown_labels.dart';

class InitialForm extends StatelessWidget {

  InitialForm({ 
    this.isFormEditing = false, 
    this.isFormModifiable = true, 
    Key? key 
  }) : super(key: key);
  
  final bool isFormEditing;
  final bool isFormModifiable;

  final _formKey = GlobalKey<FormState>();

  final birthDateController = TextEditingController();

  /// Verifica cada campo del formulario. Si no hay errores, registra la nueva
  /// información del usuario en la DB y redirige a [redirectRoute]. 
  void _validateAndSave(BuildContext context, UserProfile changes, {String? redirectRoute}) async {
    if (_formKey.currentState!.validate()) {
      // Actualizar el perfil si el formulario es de edición, de lo contrario
      // crear un nuevo perfil.
      int resultado = isFormEditing 
        ? await SQLiteDB.instance.update(changes)
        : await SQLiteDB.instance.insert(changes);

      if (resultado >= 0) {
        if (redirectRoute != null) {
          Navigator.of(context).pushNamedAndRemoveUntil(redirectRoute, (route) => false);
        } else {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileProvider>(context);

    final profileChanges = profileProvider.profileChanges;

    birthDateController.text = profileProvider.profile.birthDate
      ?.toString().substring(0, 10) ?? '';

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          
          (isFormEditing)
          ? const SizedBox( height: 0.0 )
          : TextFormField(
              keyboardType: TextInputType.text,
              maxLength: 50,
              enabled: isFormModifiable,
              readOnly: !isFormModifiable,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Nombre(s)',
                helperText: ' ',
                counterText: '${profileChanges.firstName.length.toString()}/50'
              ),
              onChanged: (value) => profileProvider.firstName = value,
              validator: (value) => UserProfile.validateFirstName(value),
            ),
          
          SizedBox( height: (isFormEditing ? 0.0 : 16.0 )),

          (isFormEditing)
          ? const SizedBox( height: 0.0 )
          : TextFormField(
              keyboardType: TextInputType.text,
              maxLength: 50,
              enabled: isFormModifiable,
              readOnly: !isFormModifiable,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Appellido(s)',
                helperText: ' ',
                counterText: '${profileChanges.lastName.length.toString()}/50'
              ),
              onChanged: (value) => profileProvider.lastName = value,
              validator: (value) => UserProfile.validateLastName(value),
            ),
          
          SizedBox( height: (isFormEditing ? 0.0 : 16.0 )),

          TextFormField(
            readOnly: true,
            controller: birthDateController,
            enabled: isFormModifiable,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Fecha de Nacimiento',
              helperText: ' ', // Para evitar cambios en la altura del widget
              suffixIcon: Icon(Icons.event_rounded)
            ),
            onTap: () async {
              DateTime? newBirthDate = await showDatePicker(
                context: context, 
                initialDate: DateTime(DateTime.now().year - 10), 
                firstDate: DateTime(1900), 
                lastDate: DateTime(DateTime.now().year)
              );

              profileProvider.dateOfBirth = newBirthDate;

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
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Sexo',
                    helperText: ' ',
                    hintText: 'Selecciona' 
                  ),
                  items: DropdownLabels.sexDropdownItems,
                  value: profileChanges.sex.index,
                  onChanged: (isFormModifiable) 
                    ? (int? newValue) {
                        profileProvider.userSex = UserSex.values[newValue ?? 0];
                      }
                    : null,
                ),
              ),

              const SizedBox( width: 16.0 ,),

              Expanded(
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'País',
                    helperText: ' ',
                    hintText: 'Selecciona' 
                  ),
                  items: DropdownLabels.countryDropdownItems,
                  value: profileProvider.indexOfCountry(profileChanges.country),
                  onChanged: (isFormModifiable)
                    ? (int? newValue) {
                        profileChanges.country = profileProvider.countries[newValue ?? 0];
                      }
                    : null,
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
                  autocorrect: false,
                  keyboardType: TextInputType.number,
                  enabled: isFormModifiable,
                  readOnly: !isFormModifiable,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Estatura (m)',
                    hintText: '1.70',
                    helperText: ' ',
                    suffixIcon: Icon(Icons.height),
                  ),
                  initialValue: profileChanges.height.toString(),
                  onChanged: (value) => profileProvider.height = double.tryParse(value) ?? 0,
                  validator: (value) => UserProfile.validateHeight(value),
                ),
              ),

              const SizedBox( width: 16.0, ),

              Expanded(
                child: TextFormField(
                  autocorrect: false,
                  keyboardType: TextInputType.number,
                  enabled: isFormModifiable,
                  readOnly: !isFormModifiable,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Peso (kg)',
                    hintText: '60.0',
                    helperText: ' ',
                    suffixIcon: Icon(Icons.monitor_weight_outlined)
                  ),
                  initialValue: profileChanges.weight.toString(),
                  onChanged: (value) => profileProvider.weight = double.tryParse(value) ?? 0,
                  validator: (value) => UserProfile.validateWeight(value),
                ),
              ),
            ],
          ),
        
          const SizedBox( height: 16.0, ),

          (isFormEditing)
          ? const SizedBox( height: 0.0, )
          : DropdownButtonFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Ocupación',
                helperText: ' ',
                hintText: 'Selecciona' 
              ),
              items: DropdownLabels.occupationDropdownItems,
              value: profileChanges.occupation.index,
              onChanged: (isFormModifiable) 
                ? (int? newValue) {
                    profileProvider.occupation = Occupation.values[newValue ?? 0];
                  }
                : null,
            ),

          const SizedBox( height: 16.0, ),

          DropdownButtonFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Condiciones Médicas',
              helperText: ' ',
              hintText: 'Padecimientos crónicos' 
            ),
            items: DropdownLabels.conditionDropdownItems,
            value: profileChanges.medicalCondition.index,
            onChanged: (isFormModifiable) 
              ? (int? newValue) {
                  profileProvider.medicalCondition = MedicalCondition.values[newValue ?? 0];
                }
              : null,
          ),
        
          (isFormEditing) 
            ? const SizedBox( height: 120.0 )
            : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    child: const Text('Omitir'),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.grey.shade700,
                    ),
                    onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                  ),
                ),

                const SizedBox( width: 16.0, ),

                Expanded(
                  child: ElevatedButton(
                    child: const Text('Continuar'),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                    ),
                    onPressed: () => _validateAndSave(context, profileProvider.profileChanges)
                  ),
                ),
              ]
            ),
        ]
      ),
    );
  }
}