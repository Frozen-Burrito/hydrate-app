import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hydrate_app/src/models/enums/error_types.dart';
import 'package:hydrate_app/src/models/validators/validation_message_builder.dart';

class FullNameInput extends StatefulWidget {

  const FullNameInput.vertical({
    Key? key, 
    this.isEnabled = false,
    this.maxFirstNameLength = 16,
    this.maxLastNameLength = 16,
    this.firstNameValidator,
    this.lastNameValidator,
    this.initialFirstName = "", 
    this.initialLastName = "", 
    required this.onFirstNameChanged, 
    required this.onLastNameChanged,
  }) : useHorizontalOrientation = false, super(key: key);

  const FullNameInput.horizontal({
    Key? key, 
    this.isEnabled = false,
    this.maxFirstNameLength = 16,
    this.maxLastNameLength = 16,
    this.firstNameValidator,
    this.lastNameValidator, 
    this.initialFirstName = "", 
    this.initialLastName = "", 
    required this.onFirstNameChanged, 
    required this.onLastNameChanged,
  }) : useHorizontalOrientation = true, super(key: key);

  final bool isEnabled;

  final int maxFirstNameLength;

  final int maxLastNameLength;

  final bool useHorizontalOrientation;

  final String initialFirstName;

  final String initialLastName;

  final void Function(String) onFirstNameChanged;

  final void Function(String) onLastNameChanged;

  final TextLengthError Function(String? input)? firstNameValidator;

  final TextLengthError Function(String? input)? lastNameValidator;

  @override
  State<FullNameInput> createState() => _FullNameInputState();
}

class _FullNameInputState extends State<FullNameInput> {

  String firstName = "";
  String lastName = "";

  @override
  void initState() {
    super.initState();
    firstName = widget.initialFirstName;
    lastName = widget.initialLastName;
  }

  String? _getTextInputCounter(String value, int maxLength) {
    // Build the string using a buffer.
    StringBuffer strBuf = StringBuffer(value.characters.length);

    strBuf.write("/");
    strBuf.write(maxLength);

    return strBuf.toString();
  }

  String? _validateFirstName(ValidationMessageBuilder messageBuilder, String? input) {
    if (widget.firstNameValidator != null) {
      final firstNameError = widget.firstNameValidator!(input);
      return messageBuilder.forFirstName(firstNameError);
    } else {
      return null;
    }
  }

  String? _validateLastName(ValidationMessageBuilder messageBuilder, String? input) {
    if (widget.lastNameValidator != null) {
      final lastNameError = widget.lastNameValidator!(input);
      return messageBuilder.forLastName(lastNameError);
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final localizations = AppLocalizations.of(context)!;
    final validationMessageBuilder = ValidationMessageBuilder.of(context);

    final List<Widget> fields = [
      SizedBox(
        width: widget.useHorizontalOrientation
          ? MediaQuery.of(context).size.width * 0.4
          : double.infinity,
        child: TextFormField(
          keyboardType: TextInputType.text,
          maxLength: widget.maxFirstNameLength,
          enabled: widget.isEnabled,
          readOnly: !widget.isEnabled,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: localizations.firstName,
            helperText: ' ',
            counterText:  _getTextInputCounter(
              firstName,
              widget.maxFirstNameLength
            ),
          ),
          initialValue: widget.initialFirstName,
          onChanged: (value) {
            widget.onFirstNameChanged(value);
            setState(() {
              firstName = value;
            });
          },
          validator: (inputValue) => _validateFirstName(validationMessageBuilder, inputValue),
        ),
      ),

      (widget.useHorizontalOrientation
        ? const SizedBox( width: 8.0 )
        : const SizedBox( height: 16.0 )
      ),

      SizedBox(
        width: widget.useHorizontalOrientation
          ? MediaQuery.of(context).size.width * 0.4
          : double.infinity,
        child: TextFormField(
          keyboardType: TextInputType.text,
          maxLength: widget.maxLastNameLength,
          enabled: widget.isEnabled,
          readOnly: !widget.isEnabled,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: localizations.lastName,
            helperText: ' ',
            counterText: _getTextInputCounter(
              lastName,
              widget.maxLastNameLength
            ),
          ),
          initialValue: widget.initialLastName,
          onChanged: (value) {
            widget.onLastNameChanged(value);
            setState(() {
              lastName = value;
            });
          },
          validator: (inputValue) => _validateLastName(validationMessageBuilder, inputValue),
        ),
      ),
    ];

    if (widget.useHorizontalOrientation) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: fields,
      );
    } else {
      return Column(
        children: fields,
      );
    }
  }
}
