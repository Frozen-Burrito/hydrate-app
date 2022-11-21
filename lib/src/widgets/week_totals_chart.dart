import 'dart:collection';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeekTotalsChart extends StatelessWidget {

  const WeekTotalsChart({ 
    required this.dailyTotals, 
    this.encabezado,
    this.yUnit = "",
    this.maxYValue,
    Key? key 
  }) : super(key: key);

  final Future<List<int>> dailyTotals;

  final String? encabezado;

  final double? maxYValue;
  final String yUnit;

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
            initialData: UnmodifiableListView(List.generate(7, (_) => 130)),
            builder: (context, snapshot) {

              if (snapshot.hasError) {

                // Ocurrió un error al intentar obtener los datos. Mostrar un 
                // placeholder.
                return const Center(
                  child: Text("Hubo un error inesperado al obtener los datos."),
                );

              } else {
                // Este future builder maneja de esta forma el posible valor nulo
                // o vacío de su snapshot.data porque asume que dailyTotals siempre
                // será una lista no nula con al menos un elemento. Si el Future 
                // todavía no tiene data, simplemente muestra la gráfica con puntos en
                // 0, para mostrar la animación implícita de la gráfica.

                final dataPoints = snapshot.data;

                assert(dataPoints != null, 'el futuro de dailyTotals nunca debe resultar en una lista nula');
                assert(dataPoints!.isNotEmpty, 'siempre debe haber datos en dailyTotals, aunque sean por default');

                return _BarChart(
                  yUnitsLabel: yUnit,
                  maxY: maxYValue,
                  dataPoints: dataPoints!
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
    this.maxY = 1000,
  }) : super(key: key);

  final List<int> dataPoints;

  final double? maxY;
  final String yUnitsLabel;

  List<String> _getWeekdayLabels(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;
    final List<String> weekdays = <String>[
      localizations.monday,
      localizations.tuesday,
      localizations.wednesday,
      localizations.thursday,
      localizations.friday,
      localizations.saturday,
      localizations.sunday,
    ];

    final List<String> abbreviations = weekdays.map((day) => day.substring(0, 3)).toList();

    assert(abbreviations.length == 7);

    return abbreviations;
  }

  @override
  Widget build(BuildContext context) {

    final int currentDay = DateTime.now().weekday;

    if (dataPoints.isEmpty) {
      dataPoints.addAll(Iterable<int>.generate(7));
    }

    final xRange = Iterable<int>.generate(dataPoints.length).toList();

    final consumptionAverage = dataPoints.reduce((total, value) => total + value) / 7;

    final weekdayLabels = _getWeekdayLabels(context);

    return BarChart(
      BarChartData(
        maxY: maxY,
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