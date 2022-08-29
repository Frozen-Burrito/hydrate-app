import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/hydration_record.dart';
import 'package:hydrate_app/src/provider/hydration_record_provider.dart';
import 'package:hydrate_app/src/provider/settings_provider.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/settings_items.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget> [
            CustomSliverAppBar(
              title: localizations.settings,
              leading: <Widget> [
                IconButton(
                  icon: const Icon(Icons.arrow_back), 
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    Navigator.pop(context);
                  }
                ),
              ],
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.phonelink_ring),
                  onPressed: () => Navigator.pushNamed(context, RouteNames.bleConnection),
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
                          localizations.batteryHeading, 
                          style: Theme.of(context).textTheme.headline5,
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                  ),
            
                  const _BatteryUsageChart(),
                ]
              )
            ),

            Consumer<HydrationRecordProvider>(
              builder: (_, hydrationProvider, __) {
                return FutureBuilder<List<HydrationRecord>?>(
                  future: hydrationProvider.recordsInPast24h,
                  initialData: const [],
                  builder: (context, snapshot) {

                    String lastBatteryUpdate = 'Nunca'; //TODO: Agregar i18n de 'nunca'

                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      // Determinar actualización más reciente de nivel de batería.
                      lastBatteryUpdate = snapshot.data!.first.date
                          .toString()
                          .substring(0,16);
                    } 

                    return SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.only( top: 8.0, left: 24.0 ),
                        child: Text(
                          '${localizations.lastUpdate}: $lastBatteryUpdate', 
                          style: Theme.of(context).textTheme.bodyText2,
                        ),
                      ),
                    );
                  }
                );
              }
            ),

            SliverToBoxAdapter(
              child: Consumer<SettingsProvider>(
                builder: (_, settingsProvider, __) {
                  return SettingsItems(
                    currentSettings: settingsProvider.currentSettings,
                  );
                }
              )
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

  const _BatteryUsageChart({ Key? key, }) : super(key: key);

  List<FlSpot> _getBatteryUsageSpots(List<BatteryRecord> batteryUsage) {

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Transforma la lista de registros de consumo en una lista de puntos para la gráfica.
    // - Convierte registros a puntos, donde x es la hora y y es el nivel de batería.
    final batterySpots = batteryUsage
        .map((r) {
            // El primer registro de uso puede ser uno agregado solo para indicar que
          // hay registros previos. 
          final isRecordBeforeYesterday = r == batteryUsage.last && r.date.isBefore(yesterday);
          if (isRecordBeforeYesterday) return FlSpot(0.0, r.level.toDouble());

          final dateDiff = now.difference(r.date);

          assert(dateDiff.inSeconds > 0, "por algun motivo, r.date sucede después que now");
          assert(dateDiff.inMinutes < (24 * 60), "la diferencia de fechas es mayor a un día");

          final howMuchTimeAgo = dateDiff.inMinutes.toDouble() / 60.0;

          return FlSpot(
            24.0 - howMuchTimeAgo, r.level.toDouble()
          );
        }).toList();

    // Insertar puntos en extremos de la gráfica para conseguir una linea horizontal
    // completa.
    if (batterySpots.isNotEmpty) {
      batterySpots.insert(0, FlSpot(24.0, batterySpots.first.y));
    }

    return batterySpots;
  }

  String _getLabelForValue(double value) {
    final strBuf = StringBuffer();

    if (value > 0.0 && value < 24.0) {

      final now = DateTime.now();
      DateTime labelDate = now.subtract(Duration(hours: (24 - value).toInt()));

      strBuf.writeAll([ 
        labelDate.toString().substring(11,14),
        "00"
      ]);
    }

    return strBuf.toString();
  }

  @override
  Widget build(BuildContext context) {

    final hydrationProvider = Provider.of<HydrationRecordProvider>(context);

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 300.0,
      child: FutureBuilder<List<BatteryRecord>>(
        future: hydrationProvider.last24hBatteryUsage,
        initialData: List.unmodifiable(<BatteryRecord>[]),
        builder: (context, snapshot) {

          final records = snapshot.data ?? List.unmodifiable(<BatteryRecord>[]);

          return LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: _getBatteryUsageSpots(records),
                  color: Colors.yellow.shade300,
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
                topTitles: AxisTitles(
                  sideTitles: SideTitles( showTitles: false )
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles( showTitles: false )
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles( showTitles: false )
                ),
                bottomTitles: AxisTitles( 
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 4,
                    reservedSize: 30,
                    getTitlesWidget: (double value, TitleMeta? _) {

                      final label = _getLabelForValue(value);

                      return Text(
                        label,
                        style: Theme.of(context).textTheme.bodyText2,
                      );
                    }
                  ),
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
          );
        },
      )
    );
  }
}
