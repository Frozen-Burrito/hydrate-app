import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/services/goals_service.dart';
import 'package:hydrate_app/src/services/nav_provider.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/services/settings_service.dart';
import 'package:hydrate_app/src/views/articles_tab.dart';
import 'package:hydrate_app/src/views/history_tab.dart';
import 'package:hydrate_app/src/views/home_tab.dart';
import 'package:hydrate_app/src/views/profile_tab.dart';
import 'package:hydrate_app/src/widgets/dialogs/guides_dialog.dart';
import 'package:hydrate_app/src/widgets/dialogs/report_available_dialog.dart';
import 'package:hydrate_app/src/widgets/bottom_nav_bar.dart';
import 'package:hydrate_app/src/widgets/tab_page_view.dart';

class MainView extends StatelessWidget {

  const MainView({ Key? key }) : super(key: key);

  /// Muestra un [GuidesDialog] si la app ha sido abierta menos de 
  /// [SettingsService.appStartupsToShowGuides] veces.
  Future<void> _showGuidesDialog(BuildContext context) async {

    // Incrementar la cuenta del número de veces que ha sido abierta la app.
    final settingsProvider = Provider.of<SettingsService>(context, listen: false);

    // Determinar si es adecuado mostrar el dialog con el link a las guías 
    // de usuario.
    if (settingsProvider.appStartups <= SettingsService.appStartupsToShowGuides) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => const GuidesDialog(),
      );

      // Si el usuario especifica que no quiere volver a ver GuidesDialog, 
      // incrementar el número de inicios de la app para que la condición 
      // anterior no se cumpla.
      if (result != null && !result) {
        settingsProvider.appStartups += SettingsService.appStartupsToShowGuides;
      }
    }
  } 

  /// Muestra un [ReportAvailableDialog], si es que hay un reporte semanal o 
  /// médico que puede ser respondido por el usuario.
  Future<void> _showDialogIfReportAvailable(BuildContext context) async {
    // Obtener una referencia al provider de metas y datos de hidratacion.
    final goalsProvider = Provider.of<GoalsService>(context, listen: false);

    // final isWeeklyReportAvailable = await goalsProvider.isWeeklyReportAvailable;
    final isWeeklyReportAvailable = false;
    // final isMedicalReportAvailable = await goalsProvider.isMedicalReportAvailable;
    final isMedicalReportAvailable = true;

    // Mostrar Dialog 
    if (isWeeklyReportAvailable) {

      final settings = Provider.of<SettingsService>(context, listen: false);

      if (settings.areWeeklyFormsEnabled) {
        final result = await showDialog<bool>(
          context: context, 
          builder: (context) =>  const ReportAvailableDialog.weekly(),
        );

        if (result != null) {
          goalsProvider.appAskedForPeriodicalData();
        }
      }
    } else if (isMedicalReportAvailable) {

      final profile = await Provider.of<ProfileService>(context, listen: false).profile;

      final hasRenalInsufficiency = profile?.hasRenalInsufficiency ?? false;
      final hasNephroticSyndrome = profile?.hasNephroticSyndrome ?? false;

      // if (hasRenalInsufficiency || hasNephroticSyndrome) {
        final medicalResult = await showDialog<bool>(
          context: context, 
          builder: (context) =>  const ReportAvailableDialog.medical(),
        );

        if (medicalResult != null) {
          goalsProvider.appAskedForMedicalData();
        }
      // }
    }
  }

  @override
  Widget build(BuildContext context) {

    Future.delayed(const Duration(seconds: 1), () {
      _showGuidesDialog(context);
      _showDialogIfReportAvailable(context);
    });

    return ChangeNotifierProvider(
      create: (_) => NavigationProvider(1),
      child: Scaffold(
        body: const TabPageView(
          tabs: <Widget>[
            ArticlesTab(),
            HomeTab(),
            HistoryTab(),
            ProfileTab(),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.directions_run),
          //TODO: agregar i18n.
          tooltip: 'Registrar actividad',
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () => Navigator.pushNamed(context, RouteNames.newActivity)
        ),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }
}