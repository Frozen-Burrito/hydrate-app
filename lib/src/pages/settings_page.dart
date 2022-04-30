import 'package:flutter/material.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:hydrate_app/src/provider/hydration_record_provider.dart';
import 'package:hydrate_app/src/provider/settings_provider.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/settings_items.dart';

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
              child: SettingsItems(settingsProvider)
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
