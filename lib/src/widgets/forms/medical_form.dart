import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/medical_data.dart';

class MedicalForm extends StatefulWidget {

  const MedicalForm({ Key? key }) : super(key: key);

  @override
  _MedicalFormState createState() => _MedicalFormState();
}

class _MedicalFormState extends State<MedicalForm> {

  final _formKey = GlobalKey<FormState>();

  final MedicalData _userMedicalData = MedicalData();

  final nextAppointmentController = TextEditingController();

  /// Verifica cada campo del formulario. Si no hay errores, registra la nueva
  /// información del usuario en la DB y redirige a [redirectRoute]. 
  void _validateAndSave(BuildContext context, String? redirectRoute) async {
    if (_formKey.currentState!.validate()) {
      int resultado = await SQLiteDB.instance.insert(_userMedicalData);

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
                const Text(
                  'Introduce los siguientes datos con apoyo de tu nefrólogo:', 
                  style: TextStyle(fontSize: 16.0, color: Colors.black),
                ),

                const SizedBox( width: 16.0, ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:  <Widget>[
                    Expanded(
                      child: TextFormField(
                        autocorrect: false,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Hipervolemia',
                          helperText: ' ',
                        ),
                        onChanged: (value) => _userMedicalData.hypervolemia = double.tryParse(value) ?? 0,
                      ),
                    ),

                    const SizedBox( width: 16.0, ),

                    Expanded(
                      child: TextFormField(
                        autocorrect: false,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Peso post-diálisis',
                          helperText: ' ',
                        ),
                        onChanged: (value) => _userMedicalData.postDialysisWeight = double.tryParse(value) ?? 0,
                      ),
                    ),
                  ],
                ),

                const SizedBox( width: 16.0, ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:  <Widget>[
                    Expanded(
                      child: TextFormField(
                        autocorrect: false,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Agua extracelular',
                          helperText: ' ',
                        ),
                        onChanged: (value) => _userMedicalData.extracellularWater = double.tryParse(value) ?? 0,
                      ),
                    ),

                    const SizedBox( width: 16.0, ),

                    Expanded(
                      child: TextFormField(
                        autocorrect: false,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Normovolemia',
                          helperText: ' ',
                        ),
                        onChanged: (value) => _userMedicalData.normovolemia = double.tryParse(value) ?? 0,
                      ),
                    ),
                  ],
                ),

                const SizedBox( width: 16.0, ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:  <Widget>[
                    Expanded(
                      child: TextFormField(
                        autocorrect: false,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Ganancia interdialítica recomendada',
                          helperText: ' ',
                        ),
                        onChanged: (value) => _userMedicalData.recommendedGain = double.tryParse(value) ?? 0,
                      ),
                    ),

                    const SizedBox( width: 16.0, ),

                    Expanded(
                      child: TextFormField(
                        autocorrect: false,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Ganancia interdialítica registrada',
                          helperText: ' ',
                        ),
                        onChanged: (value) => _userMedicalData.actualGain = double.tryParse(value) ?? 0,
                      ),
                    ),
                  ],
                ),

                const SizedBox( width: 16.0, ),

                TextFormField(
                  readOnly: true,
                  controller: nextAppointmentController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Siguiente cita',
                    helperText: ' ', // Para evitar cambios en la altura del widget
                    suffixIcon: Icon(Icons.event),
                  ),
                  onTap: () async {
                    DateTime? nextAppointmentDate = await showDatePicker(
                      context: context, 
                      initialDate: DateTime.now(), 
                      firstDate: DateTime(DateTime.now().year), 
                      lastDate: DateTime(2100)
                    );

                    _userMedicalData.nextAppointment = nextAppointmentDate;

                    if (nextAppointmentDate != null) {
                      nextAppointmentController.text = nextAppointmentDate.toString().substring(0,10);
                    }
                  },
                ), 

                const SizedBox( width: 16.0, ),

                Center(
                  child: SizedBox( 
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: ElevatedButton(
                      child: const Text('Continuar'),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue,
                      ),
                      onPressed: () => _validateAndSave(context, '/'),
                    ),
                  ),
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }
}