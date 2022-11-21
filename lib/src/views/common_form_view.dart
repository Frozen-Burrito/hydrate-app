import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/api/api_client.dart';
import 'package:hydrate_app/src/utils/launch_url.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/forms/card_form_container.dart';
import 'package:hydrate_app/src/widgets/forms/create_goal_form.dart';
import 'package:hydrate_app/src/widgets/forms/medical_form.dart';
import 'package:hydrate_app/src/widgets/forms/new_activity_form.dart';
import 'package:hydrate_app/src/widgets/forms/profile_form.dart';
import 'package:hydrate_app/src/widgets/forms/weekly_form.dart';

class CommonFormView extends StatelessWidget {
  
  final Widget formWidget;

  final bool displayBackAction;

  final Color? backgroundColor;

  final Widget? shapeDecoration;

  const CommonFormView({ 
    required this.formWidget,
    this.displayBackAction = true,
    this.backgroundColor,
    this.shapeDecoration,
    Key? key, 
  }) : super(key: key);

  String _getLocalizedFormTitle(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (formWidget is CreateGoalForm) {
      return localizations.setGoalFormTitle;    
    } else if (formWidget is NewActivityForm) {
      return localizations.newActivityFormTitle;    
    } else if (formWidget is ProfileForm) {
      return localizations.initialFormTitle;    
    } else if (formWidget is WeeklyForm) {
      return localizations.weeklyFormTitle;      
    } else if (formWidget is MedicalForm) {
      return localizations.medicalFormTitle;      
    } else {
      throw UnsupportedError("Form title not supported");
    }
  }

  String _getLocalizedFormDetails(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (formWidget is CreateGoalForm) {
      return localizations.setGoalFormDetails;    
    } else if (formWidget is NewActivityForm) {
      return localizations.newActivityFormDetails;    
    } else if (formWidget is ProfileForm) {
      return localizations.initialFormDetails;    
    } else if (formWidget is WeeklyForm) {
      return localizations.weeklyFormDetails;      
    } else if (formWidget is MedicalForm) {
      return localizations.medicalFormDetails;      
    } else {
      throw UnsupportedError("Form title not supported");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: (backgroundColor == null )
        ? Theme.of(context).scaffoldBackgroundColor
        : backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          CustomSliverAppBar(
            title: _getLocalizedFormTitle(context),
            leading: (displayBackAction) 
              ? <Widget>[
                IconButton(
                  icon: const Icon(Icons.arrow_back), 
                  onPressed: () => Navigator.pop(context),
                )
              ] : null,
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.help),
                onPressed: () {
                  final url = ApiClient.urlForPage("guias-formularios");
                  UrlLauncher.launchUrlInBrowser(url);
                }, 
              ),
            ],
          ),

          SliverToBoxAdapter(
              child: Stack(
              children: <Widget> [
                (shapeDecoration != null) 
                ? shapeDecoration as Widget
                : const SizedBox(width: 0.0,),

                Center(
                  child: CardFormContainer(
                    formWidget,
                    formLabel: _getLocalizedFormDetails(context),
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}