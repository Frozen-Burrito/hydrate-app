import 'dart:async';

import 'package:flutter/widgets.dart';

enum FormFieldsState {
  empty,
  incomplete,
  canSubmit,
  loading,
  error,
  success,
}

typedef OnFormSuccessCallback = Future Function(Map<String, Object?> values);

typedef OnFormValidationErrorCallback = Function(Map<String, String?> errors);

class FormControlBloc {

  FormControlBloc({
    required Map<String, Object?> fields,
    required Map<String, Object?> defaultFieldValues,
    Set<String> requiredFields = const <String>{},
    OnFormSuccessCallback? onFormSuccess,
    OnFormValidationErrorCallback? onFormValidationError,
    this.validateOnChange = true,
  }) 
    : _formFields = fields,
      _defaultFieldValues = Map.from(defaultFieldValues),
      _formFieldStreams = Map.from(fields.map((name, value) => MapEntry(name, StreamController<Object?>.broadcast()))),
      _requiredFields = requiredFields,
      _onFormSuccess = onFormSuccess,
      _onFormError = onFormValidationError,
      _errorMessages = Map.fromEntries(fields.keys.map((name) => MapEntry(name, ""))) {
    
    _onChangeController.stream.listen(_handleFormValueChange);
    _formStateController.sink.add(FormFieldsState.empty);
  }

  final formKey = GlobalKey<FormState>();

  final bool validateOnChange;

  Stream<FormFieldsState> get formState => _formStateController.stream;

  final Map<String, Object?> _formFields;
  final Map<String, Object?> _defaultFieldValues;
  final Map<String, StreamController<dynamic>?> _formFieldStreams;

  final Map<String, String?> _errorMessages;

  final Set<String> _requiredFields;

  late final Sink<MapEntry<String, Object?>> _onValueChangeSink = _onChangeController.sink;

  final OnFormSuccessCallback? _onFormSuccess;
  final OnFormValidationErrorCallback? _onFormError;

  final StreamController<FormFieldsState> _formStateController = StreamController.broadcast();
  final StreamController<MapEntry<String, Object?>> _onChangeController = StreamController();

  void submitForm({ bool validateFields = true }) async {

    _formStateController.sink.add(FormFieldsState.loading);

    if (validateFields) {

      final isFormInInvalidSate = !(formKey.currentState?.validate() ?? false);

      // Si el formulario no está en un estado válido, interrumpir el submit
      // inmediatamente.
      if (isFormInInvalidSate) {
        // Especificar errores en formulario.
        if (_onFormError != null) _onFormError!(_errorMessages);
        _formStateController.sink.add(FormFieldsState.error);
        return;
      }
    }

    if (_onFormSuccess != null) {
      try {
        await _onFormSuccess!(_formFields);
        _formStateController.sink.add(FormFieldsState.success);
      } on Exception catch (ex) {
        debugPrint("Exception on form submit: $ex");
        _formStateController.sink.add(FormFieldsState.error);
        rethrow;
      }
    }
  }

  void validateField(BuildContext context, String field, Object? value) {

  }

  Stream<T> getFieldValueStream<T>(String field) {
    return _formFieldStreams[field]!.stream.cast<T>();
  }

  void changeFieldValue(String field, Object? value) {
    _onValueChangeSink.add(MapEntry<String, Object?>(field, value));
  }

  void _handleFormValueChange(MapEntry<String, Object?> changedValue) {

    if (_formFields.containsKey(changedValue.key)) {
      _formFieldStreams[changedValue.key]!.sink.add(changedValue.value);
      _formFields[changedValue.key] = changedValue.value;
    }

    if (validateOnChange) {
      bool isFormIncomplete = false;

      for (final field in _formFields.entries) {

        final bool isFieldRequired = _requiredFields.contains(field.key);
        final bool fieldIsUnchanged = _defaultFieldValues[field.key] == field.value;

        isFormIncomplete = isFieldRequired && fieldIsUnchanged;

        if (isFormIncomplete) break;
      }

      if (isFormIncomplete) {
        // Faltan campos obligatorios
        _formStateController.sink.add(FormFieldsState.incomplete);
        return;
      } else {
        _formStateController.sink.add(FormFieldsState.canSubmit);
      }
    }
  }
}