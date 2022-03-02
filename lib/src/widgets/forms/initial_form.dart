import 'package:flutter/material.dart';
import 'package:hydrate_app/src/db/sqlite_db.dart';

import 'package:hydrate_app/src/models/medical_data.dart';
import 'package:hydrate_app/src/models/user_info.dart';

class InitialForm extends StatefulWidget {
  const InitialForm({ Key? key }) : super(key: key);

  @override
  _InitialFormState createState() => _InitialFormState();
}

class _InitialFormState extends State<InitialForm> {

  final _formKey = GlobalKey<FormState>();

  final UserInfo _userInfo = UserInfo();

  int? _selectedUserSex = 0;
  int? _selectedCountry = 0;
  int? _selectedOccupation = 0;
  int? _selectedMedicalCondition = 0;

  final birthDateController = TextEditingController();

  final _sexDropdownItems = UserSex.values
    .map((e) {

      const labels = <String>['Otro','Mujer','Hombre'];

      return DropdownMenuItem(
        value: e.index,
        child: Text(labels[e.index]),
      );
    }).toList();

  //TODO: Hacer esto en base a codigos de pais reales
  final _countryDropdownItems = UserCountry.values
    .map((e) {

      final labels = <String>['México','E.U.','Otro'];

      return DropdownMenuItem(
        value: e.index,
        child: Text(labels[e.index]),
      );
    }).toList();

  final _occupationDropdownItems = Occupation.values
    .map((e) {

      const labels = <String>[
        'Prefiero no especificar',
        'Estudiante',
        'Oficinista',
        'Trabajador Físico',
        'Padre o Madre',
        'Atleta',
        'Otro'
      ];

      return DropdownMenuItem(
        value: e.index,
        child: Text(labels[e.index]),
      );
    }).toList();

  final _conditionDropdownItems = MedicCondition.values
    .map((e) {

      const labels = <String>['Prefiero no especificar', 'Ninguna','Insuficiencia Renal','Síndrome Nefrótico','Otro'];

      return DropdownMenuItem(
        value: e.index,
        child: Text(labels[e.index]),
      );
    }).toList();

  /// Verifica cada campo del formulario. Si no hay errores, registra la nueva
  /// información del usuario en la DB y redirige a [redirectRoute]. 
  void _validateAndSave(BuildContext context, String? redirectRoute) async {
    if (_formKey.currentState!.validate()) {
      int resultado = await SQLiteDB.instance.insert(_userInfo);

      if (resultado >= 0) {
        Navigator.pushReplacementNamed(context, redirectRoute ?? '/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Card(
        margin: const EdgeInsets.only(top: 48.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Escribe sobre tí para conocerte mejor:', 
                  style: Theme.of(context).textTheme.bodyText1,
                ),

                const SizedBox( height: 16.0, ),

                TextFormField(
                  readOnly: true,
                  controller: birthDateController,
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

                    // newGoal.startDate = newStartDate;

                    // if (newStartDate != null) {
                    //   startDateController.text = newStartDate.toString().substring(0,10);
                    // }
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
                        items: _sexDropdownItems,
                        value: _selectedUserSex,
                        onChanged: (int? newValue) {
                          _userInfo.sex = UserSex.values[newValue ?? 0];
                          setState(() {
                            _selectedUserSex = newValue ?? 0;
                          });
                        },
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
                        items: _countryDropdownItems,
                        value: _selectedCountry,
                        onChanged: (int? newValue) {
                          // _userInfo.country = UserCountry.values[newValue ?? 0];
                          setState(() {
                            _selectedCountry = newValue ?? 0;
                          });
                        },
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
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Estatura (m)',
                          hintText: '1.70',
                          helperText: ' ',
                          suffixIcon: Icon(Icons.height),
                        ),
                        onChanged: (value) => _userInfo.height = double.tryParse(value) ?? 0,
                        validator: (value) => UserInfo.validateHeight(value),
                      ),
                    ),

                    const SizedBox( width: 16.0, ),

                    Expanded(
                      child: TextFormField(
                        autocorrect: false,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Peso (kg)',
                          hintText: '60.0',
                          helperText: ' ',
                          suffixIcon: Icon(Icons.monitor_weight_outlined)
                        ),
                        onChanged: (value) => _userInfo.weight = double.tryParse(value) ?? 0,
                        validator: (value) => UserInfo.validateWeight(value),
                      ),
                    ),
                  ],
                ),
              
                const SizedBox( height: 16.0, ),

                DropdownButtonFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Ocupación',
                    helperText: ' ',
                    hintText: 'Selecciona' 
                  ),
                  items: _occupationDropdownItems,
                  value: _selectedOccupation,
                  onChanged: (int? newValue) {
                    _userInfo.occupation = Occupation.values[newValue ?? 0];
                    setState(() {
                      _selectedOccupation = newValue ?? 0;
                    });
                  },
                ),

                const SizedBox( height: 16.0, ),

                DropdownButtonFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Condiciones Médicas',
                    helperText: ' ',
                    hintText: 'Padecimientos crónicos' 
                  ),
                  items: _conditionDropdownItems,
                  value: _selectedMedicalCondition,
                  onChanged: (int? newValue) {
                    _userInfo.medicCondition = MedicCondition.values[newValue ?? 0];
                    setState(() {
                      _selectedMedicalCondition = newValue ?? 0;
                    });
                  },
                ),
              
                Row(
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
                        onPressed: () => _validateAndSave(context, '/'),
                      ),
                    ),
                  ]
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }
}