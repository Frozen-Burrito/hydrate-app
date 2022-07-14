import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeekTotalsChart extends StatelessWidget {

  final Future<List<int>> dailyTotals;

  final String? encabezado;

  final String yUnit;

  const WeekTotalsChart({ 
    required this.dailyTotals, 
    this.encabezado,
    this.yUnit = "",
    Key? key 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        (encabezado != null) 
        ? Container(
          margin: const EdgeInsets.symmetric( vertical: 24.0, horizontal: 24.0 ),
          child: Text(
            encabezado ?? "", 
            style: Theme.of(context).textTheme.headline5,
            textAlign: TextAlign.start,
          ),
        )
        : const SizedBox(),

        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 240.0,
          child: FutureBuilder<List<int>>(
            future: dailyTotals,
            builder: (context, snapshot) {

              if (snapshot.hasData) {

                final dataPoints = snapshot.data;

                if (dataPoints != null && dataPoints.isNotEmpty) {
                  // Hay datos para la grafica de barras.
                  return _BarChart(
                    yUnitsLabel: yUnit,
                    dataPoints: dataPoints
                  );
                } else {
                  return const Center(
                    child: Text("No hay datos disponibles."),
                  );
                }

              } else if (snapshot.hasError) {
                // Ocurrió un error al intentar obtener los datos.
                return const Center(
                  child: Text("Hubo un error inesperado al obtener los datos."),
                );
              } else {
                // Los datos para la grafica todavia estan cargando.
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            }
          ),
        ),

        const Divider( thickness: 1.0 ),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {

  const _BarChart({
    Key? key,
    required this.dataPoints,
    this.yUnitsLabel = '',
  }) : super(key: key);

  final List<int> dataPoints;

  final String yUnitsLabel;

  //TODO: Agregar i18n para abreviaciones de dias.
  static const weekdayLabels = ["lun.", "mar.", "mie.", "jue.", "vie.", "sab.", "dom."];

  @override
  Widget build(BuildContext context) {

    final int currentDay = DateTime.now().weekday;

    if (dataPoints.isEmpty) {
      dataPoints.addAll(Iterable<int>.generate(7));
    }

    final xRange = Iterable<int>.generate(dataPoints.length).toList();

    final consumptionAverage = dataPoints.reduce((total, valor) => total + valor) / 7;

    print("Average: ${consumptionAverage.toInt()}");

    return BarChart(
      BarChartData(
        maxY: 3000, // Maximo 3000 de yUnit.
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles( showTitles: false )
          ),
          topTitles:AxisTitles(
            sideTitles: SideTitles( showTitles: false )
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles( showTitles: false )
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              // interval: 4,
              getTitlesWidget: (double value, TitleMeta? _) {
                int intValue = value.toInt();

                String contenidoTitulo = '';

                if (intValue >= 0 && intValue <= 6) {

                  int dayNumber = currentDay + value.toInt();

                  int dayIndex = dayNumber > 6 ? dayNumber - 7 : dayNumber;

                  contenidoTitulo = weekdayLabels[dayIndex];
                }

                return Text(
                  contenidoTitulo, 
                  style: Theme.of(context).textTheme.bodyText2?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.82),
                  ), 
                );
              }
            ),
          )
        ),
        borderData: FlBorderData( show: false, ),
        alignment: BarChartAlignment.spaceAround,
        barGroups: xRange.map((index) => BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: dataPoints[index].toDouble(),
              color: Colors.greenAccent,
            )
          ]
        )).toList(),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: 100,
          drawVerticalLine: false,
          checkToShowHorizontalLine: (x) => (x.toInt() - consumptionAverage.toInt()).abs() < 50,
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.transparent,
            tooltipPadding: const EdgeInsets.all(0),
            tooltipMargin: 8,
            getTooltipItem: (
              BarChartGroupData group,
              int groupIndex,
              BarChartRodData rod,
              int rodIndex,
            ) {
              return BarTooltipItem(
                rod.toY.round().toString() + " $yUnitsLabel",
                Theme.of(context).textTheme.bodyText1 ?? const TextStyle(color: Colors.black),
              );
            },
          ),
        ),
      )
    );
  }
}