import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:hydrate_app/src/provider/hydration_record_provider.dart';
import 'package:hydrate_app/src/provider/settings_provider.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final settingsProvider = Provider.of<SettingsProvider>(context);
    final hydrationRecords = Provider.of<HydrationRecordProvider>(context).hydrationRecords;

    final lastBatteryUpdate = hydrationRecords.isNotEmpty ? hydrationRecords.first.date : null;

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget> [
            CustomSliverAppBar(
              title: 'Ajustes',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back), 
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  Navigator.pop(context);
                }
              ),
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.phonelink_ring),
                  onPressed: () => Navigator.pushNamed(context, '/ble-pair'),
                )
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.symmetric( vertical: 24.0, horizontal: 24.0 ),
                    child: Row(
                      children: [
                        Text(
                          'Batería de la Botella', 
                          style: Theme.of(context).textTheme.headline5,
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                  ),

                  const _BatteryUsageChart(),

                  Container(
                    margin: const EdgeInsets.only( top: 8.0, left: 24.0 ),
                    child: Text(
                      'Última actualización: ${lastBatteryUpdate != null ? lastBatteryUpdate.toString().substring(0,16) : 'Nunca'}', 
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ),
                ],
              )
            ),

            SliverToBoxAdapter(
              child: _SettingsControl(settingsProvider)
            ),
          ], 
        ),
      ),
    );
  }
}

/// Un [LineChart] que visualiza el nivel de batería registrado a lo largo de las
/// últimas 24 horas.
/// 
/// Para cada punto [FlSpot], el valor 'x' es dado por la hora registrada y el valor
/// 'y' es el porcentaje de carga en la batería de la botella, en ese instante. 
/// 
/// Usa el [HydrationRecordProvider] para obtener sus valores. Asume que la lista 
/// de registros de hidratación está ordenada cronológicamente. 
class _BatteryUsageChart extends StatelessWidget {

  const _BatteryUsageChart({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final hydrationProvider = Provider.of<HydrationRecordProvider>(context);

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final hydrationRecords = hydrationProvider.hydrationRecords;

    // Transforma la lista de registros de consumo en una lista de puntos para la gráfica.
    // - Filtra los datos para obtener los registros de las últimas 24 hrs.
    // - Convierte registros a puntos, donde x es la hora y y es el nivel de batería.
    final batteryData = hydrationRecords
        .where((r) => r.date.isAfter(yesterday) && r.date.isBefore(now))
        .map((r) {
          // Representa la hora y minuto, donde las horas son enteros y los 
          // minutos se representan como centesimas.
          double decimalTime = r.date.day == now.day 
              ? 24 - ((r.date.hour - now.hour).abs()).toDouble() 
              : ((24 - now.hour) - (24 - r.date.hour)).abs().toDouble();

          decimalTime += r.date.minute / 60;

          return FlSpot(
            decimalTime, r.batteryPercentage.toDouble()
          );
        }).toList();

    // Condición para insertar puntos en extremos de la línea de la gráfica.
    final isBatteryDataAvailable = hydrationRecords.isNotEmpty && hydrationRecords.length > batteryData.length; 

    final prevBatteryLvl = isBatteryDataAvailable
        ? hydrationRecords[hydrationRecords.length - batteryData.length -1].batteryPercentage.toDouble()
        : batteryData.isNotEmpty ? batteryData.last.y : 0.0;

    // Insertar puntos en extremos de la gráfica para conseguir una linea horizontal
    // completa.
    if (batteryData.isNotEmpty) {
      batteryData.insert(0, FlSpot(24.0, batteryData.first.y));
    }

    batteryData.add(FlSpot(0.0, prevBatteryLvl));

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 300.0,
      child: hydrationProvider.isLoading 
      ? const Center(
        child: CircularProgressIndicator(),
      )
      : LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: batteryData,
              colors: [
                Colors.yellow.shade300,
              ],
              isCurved: false,
              barWidth: 2,
              belowBarData: BarAreaData(
                show: false,
              ),
              dotData: FlDotData(show: false)
            )
          ],
          minY: 0.0,
          maxY: 100.0,
          minX: 0.0,
          maxX: 24.0,
          titlesData: FlTitlesData(
            topTitles: SideTitles( showTitles: false),
            rightTitles: SideTitles( showTitles: false),
            leftTitles: SideTitles( showTitles: false,),
            bottomTitles: SideTitles( 
              showTitles: true,
              reservedSize: 30,
              interval: 4,
              getTextStyles: (context, value) => Theme.of(context).textTheme.bodyText2,
              getTitles: (value) {
                if (value <= 0.0 || value >= 24.0) return '';

                DateTime labelDate = now.subtract(Duration(hours: (24 - value).toInt()));

                // String yesterdayLabel = labelDate.day < now.day ? 'Ayer, ' : '';

                return '${labelDate.toString().substring(11,14)}00';
              }
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: true,
            horizontalInterval: 4,
            verticalInterval: 10,
            checkToShowHorizontalLine: (x) => x.toInt() % 10 == 0,
            checkToShowVerticalLine: (y) => y.toInt() == 0,
          ),
          borderData: FlBorderData( show: false, ),
        )
      ),
    );
  }
}

class _SettingsControl extends StatefulWidget {

  final SettingsProvider settingsProvider;

  const _SettingsControl(this.settingsProvider, {
    Key? key,
  }) : super(key: key);

  @override
  State<_SettingsControl> createState() => _SettingsControlState();
}

class _SettingsControlState extends State<_SettingsControl> {

  ThemeMode _selectedThemeMode = ThemeMode.system;
  ThemeMode _originalThemeMode = ThemeMode.system;

  NotificationSettings _selectedNotifications = NotificationSettings.disabled;
  NotificationSettings _originalNotifications = NotificationSettings.disabled;

  bool _contributeData = false; 
  bool _originalContributeData = false; 

  bool _weeklyForms = false; 
  bool _originalWeeklyForms = false; 

  bool _isSnackbarActive = false;

  static final _themeLabels = <String>['Sistema','Claro','Oscuro'];

  static final _notifLabels = <String>['Ninguna','Metas','Batería','Todas'];

  final _themeDropdownItems = ThemeMode.values
      .map((option) => DropdownMenuItem(
          value: option.index,
          child: Text(_themeLabels[option.index]),
        ),
      ).toList();

  final _notifDropdownItems = NotificationSettings.values
      .map((option) => DropdownMenuItem(
          value: option.index,
          child: Text(_notifLabels[option.index]),
        ),
      ).toList();

  @override
  void initState() {
    super.initState();

    _originalThemeMode = widget.settingsProvider.appThemeMode;
    _originalContributeData = widget.settingsProvider.isSharingData;
    _originalNotifications = widget.settingsProvider.notificationSettings;
    _originalWeeklyForms = widget.settingsProvider.areWeeklyFormsEnabled;

    _selectedThemeMode = _originalThemeMode;
    _contributeData = _originalContributeData;
    _selectedNotifications = _originalNotifications;
    _weeklyForms = _originalWeeklyForms;
  }

  /// Compara los valores originales con los ajustes modificados. Si son diferentes,
  /// muestra un [SnackBar] para confirmar los cambios.
  void compareChanges(BuildContext context) {
    
    bool hasThemeChanged = _originalThemeMode != _selectedThemeMode;
    bool hasDataContributionChanged = _originalContributeData != _contributeData;
    bool hasNotificationsChanged = _originalNotifications != _selectedNotifications;
    bool hasWeeklyFormsChanged = _originalWeeklyForms != _originalWeeklyForms;

    bool settingsChanged = hasThemeChanged || hasDataContributionChanged || hasNotificationsChanged || hasWeeklyFormsChanged;

    if (!_isSnackbarActive && settingsChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tienes ajustes modificados sin guardar'),
          duration: const Duration(minutes: 30),
          action: SnackBarAction(
            label: 'Guardar', 
            onPressed: () {
              saveChanges();
              _isSnackbarActive = false;
            },
          ),
        )
      );

      _isSnackbarActive = true;
    }
  }

  /// Guarda los cambios de ajustes en SharedPreferences usando [SettingsProvider].
  /// 
  /// Solo guarda las modificaciones necesarias.
  void saveChanges() {

    bool hasThemeChanged = _originalThemeMode != _selectedThemeMode;
    bool hasDataContributionChanged = _originalContributeData != _contributeData;
    bool hasNotificationsChanged = _originalNotifications != _selectedNotifications;
    bool hasWeeklyFormsChanged = _originalWeeklyForms != _originalWeeklyForms;


    if (hasThemeChanged) {
      print('Theme was modified: de $_originalThemeMode a $_selectedThemeMode');
      widget.settingsProvider.appThemeMode = _selectedThemeMode;
      _originalThemeMode = _selectedThemeMode;
    }

    if (hasDataContributionChanged) {
      widget.settingsProvider.isSharingData = _contributeData;
      _originalContributeData = _contributeData;
    }

    if (hasNotificationsChanged) {
      widget.settingsProvider.notificationSettings = _selectedNotifications;
      _originalNotifications = _selectedNotifications;
    }

    if (hasWeeklyFormsChanged) {
      widget.settingsProvider.areWeeklyFormsEnabled = _weeklyForms;
      _originalWeeklyForms = _weeklyForms;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTileTheme(
      iconColor: Theme.of(context).colorScheme.onBackground,
      textColor: Theme.of(context).colorScheme.onBackground,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        children: <Widget> [
          const SizedBox( height: 24.0, ),
    
          const Divider( height: 1.0, ),
          Padding(
            padding: const EdgeInsets.symmetric( vertical: 16.0, ),
            child: ListTile(
              leading: const Icon(
                Icons.colorize, 
                size: 24.0, 
              ),
              title: const Text('Tema de color'),
              trailing: SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedThemeMode.index,
                  items: _themeDropdownItems,
                  onChanged: (int? newValue) {
                    _selectedThemeMode = ThemeMode.values[newValue ?? 0];
                    compareChanges(context);
                  },
                ),
              ),
            ),
          ),
    
          const Divider( height: 1.0, ),
          Padding(
            padding: const EdgeInsets.symmetric( vertical: 16.0, ),
            child: SwitchListTile(
              secondary: const Icon(
                Icons.bar_chart, 
                size: 24.0, 
              ),
              title: const Text('Contribuir a datos abiertos'),
              value: _contributeData,
              onChanged: (bool value) {
                setState(() {
                  _contributeData = value;
                  compareChanges(context);
                });
              },
            ),
          ),
    
          const Divider( height: 1.0, ),
          Padding(
            padding: const EdgeInsets.symmetric( vertical: 16.0, ),
            child: ListTile(
              leading: const Icon(
                Icons.notifications, 
                size: 24.0,
              ),
              title: const Text('Notificaciones'),
              trailing: SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedNotifications.index,
                  items: _notifDropdownItems,
                  onChanged: (int? newValue) {
                    _selectedNotifications = NotificationSettings.values[newValue ?? 0];
                    compareChanges(context);
                  },
                ),
              ),
            ),
          ),

          const Divider( height: 1.0, ),
          Padding(
            padding: const EdgeInsets.symmetric( vertical: 16.0, ),
            child: SwitchListTile(
              secondary: const Icon(
                Icons.event_note, 
                size: 24.0, 
              ),
              title: const Text('Formularios semanales'),
              value: _weeklyForms,
              onChanged: (bool value) {
                setState(() {
                  _weeklyForms = value;
                  compareChanges(context);
                });
              },
            ),
          ),

          const Divider( height: 1.0, ),
          ListTile(
            minVerticalPadding: 24.0,
            leading: const Icon(
              Icons.question_answer, 
              size: 24.0, 
            ),
            title: const Text('Enviar comentarios'),
            trailing: const Icon(
              Icons.arrow_forward,
              size: 24.0,
            ),
            onTap: () {
              print('Enviando comentarios...');
            },
          ),
    
          const Divider( height: 1.0, ),
          ListTile(
            minVerticalPadding: 24.0,
            leading: const Icon(
              Icons.lightbulb,
              size: 24.0, 
            ),
            title: const Text('Guías de usuario'),
            trailing: const Icon(
              Icons.arrow_forward,
              size: 24.0,
            ),
            onTap: () {
              print('Redireccionando a guias de usuario...');
            },
          ),
    
          const Padding(
            padding: EdgeInsets.symmetric( horizontal: 24.0, vertical: 8.0,),
            child: Text(
              'Versión: 0.0.4+3',
              style: TextStyle(color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }
}
