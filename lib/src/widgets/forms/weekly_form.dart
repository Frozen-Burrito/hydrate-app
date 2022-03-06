import 'package:flutter/material.dart';
import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/models/habits.dart';

class WeeklyForm extends StatefulWidget {
  const WeeklyForm({ Key? key }) : super(key: key);

  @override
  _WeeklyFormState createState() => _WeeklyFormState();
}

class _WeeklyFormState extends State<WeeklyForm> {

  final _formKey = GlobalKey<FormState>();

  final Habits _userHabits = Habits( date: DateTime.now() );

  final List<int> _hourTotals = <int>[0,0,0];
  
  /// Verifica cada campo del formulario. Si no hay errores, registra la nueva
  /// información del usuario en la DB y redirige a [redirectRoute]. 
  void _validateAndSave(BuildContext context, {String? redirectRoute}) async {
    if (_formKey.currentState!.validate()) {
      int resultado = await SQLiteDB.instance.insert(_userHabits);

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
                  '¿Cómo ha estado tu semana?', 
                  style: Theme.of(context).textTheme.bodyText1,
                ),

                const SizedBox( height: 16.0, ),

                Text(
                  'Escribe la cantidad de horas diarias promedio que dedicaste a cada una de las siguientes actividades durante esta semana.', 
                  style: TextStyle(fontSize: 14.0, color: Colors.grey.shade700),
                ),

                const SizedBox( height: 16.0, ),

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
                    _userHabits.hoursOfSleep = int.tryParse(value) ?? 0;

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
                    _userHabits.hoursOfActivity = int.tryParse(value) ?? 0;

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
                    _userHabits.hoursOfOccupation = int.tryParse(value) ?? 0;

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
                  onChanged: (value) => _userHabits.maxTemperature = int.tryParse(value) ?? 0,
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
                      onPressed: () => _validateAndSave(context),
                    ),
                  ),
                )
              ]
            ),
          ),
        ),
      ),
    );
  }
}