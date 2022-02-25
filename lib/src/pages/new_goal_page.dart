import 'package:flutter/material.dart';
import 'package:hydrate_app/src/utils/validators.dart';

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
          titleTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 24),
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
                  child: _ObjectiveForm(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectiveForm extends StatelessWidget {
  const _ObjectiveForm({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidateMode: AutovalidateMode.onUserInteraction,
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
          
                const TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '¿Cuál es el plazo de tu meta?'
                  ),
                ),
    
                const SizedBox( height: 16.0, ),
    
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:  <Widget>[
                    Expanded(
                      child: TextField(
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
                        },
                      ),
                    ),
                  ],
                ),
              
                const SizedBox( height: 16.0, ),
    
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Recompensa',
                          hintText: '20',
                          suffixIcon: Icon(Icons.monetization_on)
                        ),
                      ),
                    ),
    
                    const SizedBox( width: 16.0, ),
    
                    Expanded(
                      child: TextFormField(
                        autocorrect: false,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Cantidad',
                          hintText: '100ml'
                        ),
                        validator: (value) => Validators.validateWaterAmount(value),
                      ),
                    ),
                  ]
                ),
    
                const SizedBox( height: 16.0, ),
    
                const TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Etiquetas',
                    counterText: '0/3'
                  ),
                ),
    
                const SizedBox( height: 16.0, ),
    
                const TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Anotaciones',
                    hintText: 'Debo recordar tomar agua antes de...',
                    counterText: '0/100'
                  ),
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
                        onPressed: () {},
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