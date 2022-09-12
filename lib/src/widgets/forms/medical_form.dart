import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/medical_data.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/services/goals_service.dart';

class MedicalForm extends StatefulWidget {

  const MedicalForm({ Key? key }) : super(key: key);

  @override
  _MedicalFormState createState() => _MedicalFormState();
}

class _MedicalFormState extends State<MedicalForm> {

  final _formKey = GlobalKey<FormState>();

  final MedicalData _userMedicalData = MedicalData.uncommitted();

  final nextAppointmentController = TextEditingController();

  /// Verifica cada campo del formulario. Si no hay errores, registra la nueva
  /// información del usuario en la DB y redirige a [redirectRoute]. 
  void _validateAndSave(BuildContext context, {String? redirectRoute}) async {
    // Asegurar que el Form está en un estado válido.
    if (_formKey.currentState!.validate()) {

      final saveReport = Provider.of<GoalsService>(context).saveMedicalReport;
      // Guardar el reporte medico.
      int resultado = await saveReport(_userMedicalData);

      if (resultado >= 0) {
        if (redirectRoute != null) {
          Navigator.of(context).pushNamedAndRemoveUntil(redirectRoute, (route) => false);
        } else {
          Navigator.of(context).pop();
        }
      } else {
        // Si el reporte no fue guardado, mantener la app en la vista actual y 
        // notificar al usuario.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No fue posible guardar el reporte.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          
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

              if (nextAppointmentDate != null) {
                _userMedicalData.nextAppointment = nextAppointmentDate;
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
                onPressed: () => _validateAndSave(context, redirectRoute: RouteNames.home),
              ),
            ),
          ),
        ]
      ),
    );
  }
}