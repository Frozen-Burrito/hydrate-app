import 'package:flutter/material.dart';
import 'package:hydrate_app/src/bloc/auth_form_bloc.dart';

class FormStateProvider extends InheritedWidget {
  
  const FormStateProvider({
    Key? key, 
    required this.model,
    required Widget child
  }) : super(key: key, child: child);

  final AuthFormBloc model;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) 
    => oldWidget is FormStateProvider && model == oldWidget.model;

  static FormStateProvider of(BuildContext context) {
    final FormStateProvider? result = context.dependOnInheritedWidgetOfExactType<FormStateProvider>();
    assert(result != null, 'A FormStateProvider widget was not found for this context');
    return result!;
  }
}