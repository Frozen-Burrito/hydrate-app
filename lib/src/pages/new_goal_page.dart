import 'package:flutter/material.dart';
import 'package:hydrate_app/src/db/sqlite_db.dart';

import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/widgets/shapes.dart';

class NewGoalPage extends StatelessWidget {
  const NewGoalPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            title: const Padding(
              padding: EdgeInsets.symmetric( vertical: 10.0 ),
              child: Text('Nueva Meta'),
            ),
            titleTextStyle: Theme.of(context).textTheme.headline4,
            centerTitle: true,
            backgroundColor: Colors.white,
            floating: true,
            leading: IconButton(
              color: Colors.black, 
              icon: const Icon(Icons.arrow_back), 
              onPressed: () => Navigator.pop(context)
            ),
            actionsIconTheme: const IconThemeData(color: Colors.black),
            actions: <Widget> [
              IconButton(
                icon: const Icon(Icons.help),
                onPressed: (){}, 
              ),
            ],
          ),
        
          //TODO: Agregar tarjeta con el formulario para nueva meta.
          SliverToBoxAdapter(
            child: Stack(
              children: const <Widget> [
                WaveShape(),

                Center(
                  child: _ObjectiveForm()
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectiveForm extends StatefulWidget {

  const _ObjectiveForm({ Key? key, }) : super(key: key);

  @override
  State<_ObjectiveForm> createState() => _ObjectiveFormState();
}

class _ObjectiveFormState extends State<_ObjectiveForm> {

  final _formKey = GlobalKey<FormState>();

  final Goal newGoal = Goal(term: GoalTerm.daily, id: 0, endDate: DateTime.now());

  bool isLoading = false;

  int tagsLength = 0;
  int notesLength = 0;

  int? selectedTerm;

  final termDropdownItems = GoalTerm.values
    .map((e) {

      const termLabels = <String>['Diario','Semanal','Mensual'];

      return DropdownMenuItem(
        value: e.index,
        child: Text(termLabels[e.index]),
      );
    }).toList();

  

  @override
  Widget build(BuildContext context) {

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.always,
      child: Card(
        margin: const EdgeInsets.only( top: 48.0 ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Escribe los detalles de tu nueva meta:', 
                  style: TextStyle(fontSize: 16.0, color: Colors.black),
                ),
    
                const SizedBox( height: 16.0, ),
          
                DropdownButtonFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '¿Cuál es el plazo de tu meta?' 
                  ),
                  items: termDropdownItems,
                  value: selectedTerm,
                  onChanged: (int? newValue) {
                    newGoal.term = GoalTerm.values[newValue ?? 0];
                    setState(() {
                      selectedTerm = newValue ?? 0;
                    });
                  },
                  // validator: (int? value) => Goal.validateTerm(value),
                ),
    
                const SizedBox( height: 16.0, ),
    
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:  <Widget>[
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Inicio',
                          suffixIcon: Icon(Icons.event_rounded)
                        ),
                        onTap: () async {
                          DateTime? startDate = await showDatePicker(
                            context: context, 
                            initialDate: DateTime.now(), 
                            firstDate: DateTime(2000), 
                            lastDate: DateTime(2100)
                          );

                          newGoal.startDate = startDate;
                        },
                      ),
                    ),
    
                    const SizedBox( width: 16.0 ,),
    
                    Expanded(
                      child: TextField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Término',
                          suffixIcon: Icon(Icons.event_rounded)
                        ),
                        onTap: () async {
                          DateTime? endDate = await showDatePicker(
                            context: context, 
                            initialDate: DateTime.now().add(const Duration( days: 30)), 
                            firstDate: DateTime(2000), 
                            lastDate: DateTime(2100)
                          );

                          // newGoal.endDate = endDate;
                        },
                      ),
                    ),
                  ],
                ),
              
                const SizedBox( height: 16.0, ),
    
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        autocorrect: false,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Recompensa',
                          hintText: '20',
                          suffixIcon: Icon(Icons.monetization_on)
                        ),
                        onChanged: (value) => newGoal.reward = int.tryParse(value) ?? 0,
                        validator: (value) => Goal.validateReward(value),
                      ),
                    ),
    
                    const SizedBox( width: 16.0, ),
    
                    Expanded(
                      child: TextFormField(
                        autocorrect: false,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Cantidad (ml)',
                          hintText: '100ml'
                        ),
                        onChanged: (value) => newGoal.quantity = int.tryParse(value) ?? 0,
                        validator: (value) => Goal.validateWaterQuantity(value),
                      ),
                    ),
                  ]
                ),
    
                const SizedBox( height: 16.0, ),
    
                TextFormField(
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Etiquetas',
                    counterText: '${tagsLength.toString()}/3'
                  ),
                  onChanged: (value) => setState(() {
                    tagsLength = newGoal.parseTags(value);
                  }),
                  validator: (value) => Goal.validateTags(value),
                ),
    
                const SizedBox( height: 16.0, ),
    
                TextFormField(
                  keyboardType: TextInputType.multiline,
                  maxLength: 100,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Anotaciones',
                    hintText: 'Debo recordar tomar agua antes de...',
                    counterText: '${notesLength.toString()}/100'
                  ),
                  onChanged: (value) => setState(() {
                    newGoal.notes = value;
                    notesLength = newGoal.notes?.length ?? 0;
                  }),
                  validator: (value) => Goal.validateNotes(value),
                ),
    
                const SizedBox( height: 16.0, ),
    
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        child: const Text('Cancelar'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.grey.shade700,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
    
                    const SizedBox( width: 16.0, ),
    
                    Expanded(
                      child: ElevatedButton(
                        child: const Text('Crear'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blue,
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            int resultado = await SQLiteDB.db.insert(newGoal);

                            if (resultado > 0) {
                              Navigator.pushReplacementNamed(context, '/');
                            }
                          }
                        },
                      ),
                    ),
                  ]
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}