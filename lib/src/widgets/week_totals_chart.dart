import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeekTotalsChart extends StatelessWidget {

  final bool isLoading;

  final List<int> dailyTotals;

  final String? encabezado;

  final String yUnit;

  WeekTotalsChart({ 
    required this.dailyTotals, 
    this.isLoading = false, 
    this.encabezado,
    this.yUnit = '',
    Key? key 
  }) : super(key: key);

  final int currentDay = DateTime.now().weekday;

  final weekdayLabels = ['lun.', 'mar.', 'mie.', 'jue.', 'vie.', 'sab.', 'dom.'];
  
  final xRange = Iterable<int>.generate(7).toList();

  @override
  Widget build(BuildContext context) {

    final consumptionAverage = dailyTotals.reduce((total, valor) => total + valor) / 7;

    print('Average: ${consumptionAverage.toInt()}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        (encabezado != null) 
        ? Container(
          margin: const EdgeInsets.symmetric( vertical: 24.0, horizontal: 24.0 ),
          child: Text(
            encabezado ?? '', 
            style: Theme.of(context).textTheme.headline5,
            textAlign: TextAlign.start,
          ),
        )
        : const SizedBox(),

        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 240.0,
          child: isLoading 
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : BarChart(
              BarChartData(
                maxY: 3000, // Maximo 3000 de yUnit.
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: SideTitles(showTitles: false),
                  topTitles: SideTitles(showTitles: false),
                  rightTitles: SideTitles(showTitles: false),
                  bottomTitles: SideTitles(
                    showTitles: true,
                    getTextStyles: (context,  value) => Theme.of(context).textTheme.bodyText2?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.82),
                    ),
                    margin: 20.0,
                    getTitles: (double value) {
                      int intValue = value.toInt();

                      if (intValue < 0 || intValue > 6) return '';

                      int dayNumber = currentDay + value.toInt();

                      int dayIndex = dayNumber > 6 ? dayNumber - 7 : dayNumber;

                      return weekdayLabels[dayIndex];
                    }
                  )
                ),
                borderData: FlBorderData( show: false, ),
                alignment: BarChartAlignment.spaceAround,
                barGroups: xRange.map((index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      y: dailyTotals[index].toDouble(),
                      colors: [ Colors.greenAccent ],
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
                        rod.y.round().toString() + ' $yUnit',
                        Theme.of(context).textTheme.bodyText1 ?? const TextStyle(color: Colors.black),
                      );
                    },
                  ),
                ),
              )
            ),
        ),

        const Divider( thickness: 1.0 ),
      ],
    );
  }
}