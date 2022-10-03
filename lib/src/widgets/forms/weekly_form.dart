import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/habits.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/services/goals_service.dart';

class WeeklyForm extends StatefulWidget {
  const WeeklyForm({ Key? key }) : super(key: key);

  @override
  _WeeklyFormState createState() => _WeeklyFormState();
}

class _WeeklyFormState extends State<WeeklyForm> {

  final _formKey = GlobalKey<FormState>();

  final Habits _userHabits = Habits.uncommitted();

  final List<double> _hourTotals = <double>[0.0,0.0,0.0];
  
  /// Verifica cada campo del formulario. Si no hay errores, registra la nueva
  /// información del usuario en la DB y redirige a [redirectRoute]. 
  void _validateAndSave(BuildContext context, {String? redirectRoute}) async {
    // Asegurar que el Form está en un estado válido.
    if (_formKey.currentState!.validate()) {

      final saveReport = Provider.of<GoalsService>(context, listen: false).saveWeeklyReport;

      int resultado = await saveReport(_userHabits);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[

          TextFormField(
            autocorrect: false,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Horas de sueño',
              hintText: '8',
              helperText: ' ',
              suffixIcon: Icon(Icons.bedtime)
            ),
            onChanged: (value) {
              _userHabits.hoursOfSleep = double.tryParse(value) ?? 0.0;

              setState(() {
                _hourTotals[0] = _userHabits.hoursOfSleep;
              });
            },
            validator: (value) => Habits.validateHourTotal(_hourTotals),
          ),

          const SizedBox( height: 16.0, ),

          TextFormField(
            autocorrect: false,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Horas de actividad física',
              hintText: '2',
              helperText: ' ',
              suffixIcon: Icon(Icons.directions_run)
            ),
            onChanged: (value) {
              _userHabits.hoursOfActivity = double.tryParse(value) ?? 0.0;

              setState(() {
                _hourTotals[2] = _userHabits.hoursOfActivity;
              });
            },
            validator: (value) => Habits.validateHourTotal(_hourTotals),
          ),

          const SizedBox( height: 16.0, ),

          TextFormField(
            autocorrect: false,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Horas de ocupación',
              hintText: '6',
              helperText: ' ',
              suffixIcon: Icon(Icons.work)
            ),
            onChanged: (value) {
              _userHabits.hoursOfOccupation = double.tryParse(value) ?? 0.0;

              setState(() {
                _hourTotals[0] = _userHabits.hoursOfOccupation;
              });
            },
            validator: (value) => Habits.validateHourTotal(_hourTotals),
          ),

          const SizedBox( height: 16.0, ),

          Text(
            'La temperatura máxima de la semana pasada:', 
            style: TextStyle(fontSize: 14.0, color: Colors.grey.shade700),
          ),

          const SizedBox( height: 16.0, ),

          TextFormField(
            autocorrect: false,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Temperatura máxima',
              hintText: '23 °C',
              helperText: ' ',
              suffixIcon: Icon(Icons.thermostat)
            ),
            onChanged: (value) => _userHabits.maxTemperature = double.tryParse(value) ?? 0.0,
            validator: (value) => Habits.validateTemperature(value),
          ),
          
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
          )
        ]
      ),
    );
  }
}