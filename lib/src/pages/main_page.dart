import 'package:flutter/material.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/pages/articles_tab.dart';
import 'package:hydrate_app/src/pages/history_tab.dart';
import 'package:hydrate_app/src/pages/home_tab.dart';
import 'package:hydrate_app/src/pages/profile_tab.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/provider/nav_provider.dart';
import 'package:hydrate_app/src/provider/goals_provider.dart';
import 'package:hydrate_app/src/provider/settings_provider.dart';
import 'package:hydrate_app/src/widgets/dialogs/guides_dialog.dart';
import 'package:hydrate_app/src/widgets/dialogs/report_available_dialog.dart';
import 'package:hydrate_app/src/widgets/bottom_nav_bar.dart';
import 'package:hydrate_app/src/widgets/tab_page_view.dart';

class MainPage extends StatelessWidget {

  const MainPage({ Key? key }) : super(key: key);

    void checkNumOfAppStartups(BuildContext context) async {

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    settingsProvider.appStartups++;

    if (settingsProvider.appStartups < 5) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => const GuidesDialog(),
      );

      if (result != null && !result) {
        settingsProvider.appStartups += 5;
      }
    }
  } 

  /// Muestra un [ReportAvailableDialog], si es que hay un reporte semanal o 
  /// médico que puede ser respondido por el usuario.
  Future<void> _showDialogIfReportAvailable(BuildContext context) async {
    // Obtener una referencia al provider de metas y datos de hidratacion.
    final goalsProvider = Provider.of<GoalProvider>(context, listen: false);

    final isWeeklyReportAvailable = await goalsProvider.isWeeklyReportAvailable;
    final isMedicalReportAvailable = await goalsProvider.isMedicalReportAvailable;

    // Mostrar Dialog 
    if (isWeeklyReportAvailable) {

      final settings = Provider.of<SettingsProvider>(context, listen: false);

      if (settings.areWeeklyFormsEnabled) {
        showDialog(
          context: context, 
          builder: (context) =>  const ReportAvailableDialog.weekly(),
        );
      }
    } else if (isMedicalReportAvailable) {

      final profile = await Provider.of<ProfileProvider>(context, listen: false).profile;

      final hasRenalInsufficiency = profile?.hasRenalInsufficiency ?? false;
      final hasNephroticSyndrome = profile?.hasNephroticSyndrome ?? false;

      if (hasRenalInsufficiency || hasNephroticSyndrome) {
        showDialog(
          context: context, 
          builder: (context) =>  const ReportAvailableDialog.medical(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    Future.delayed(const Duration(seconds: 1), () {
      checkNumOfAppStartups(context);
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