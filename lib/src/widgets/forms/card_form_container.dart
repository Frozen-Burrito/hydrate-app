import 'package:flutter/material.dart';

class CardFormContainer extends StatelessWidget {

  final String formLabel; 

  final Widget formWidget;

  const CardFormContainer (this.formWidget, { this.formLabel = '',  Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 48.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                formLabel, 
                style: Theme.of(context).textTheme.bodyText1,
              ),

              const SizedBox( height: 16.0, ),

              formWidget,
            ],
          ),
        ),
      ),
    );
  }
}
