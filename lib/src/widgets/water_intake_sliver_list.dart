import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/provider/hydration_record_provider.dart';
import 'package:hydrate_app/src/models/hydration_record.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';

class WaterIntakeSliverList extends StatelessWidget {
  const WaterIntakeSliverList({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(8.0),
      sliver: Consumer<HydrationRecordProvider>(
        builder: (_, provider, __) {
          String msg = '';
          IconData placeholderIcon = Icons.info;
    
          if (!provider.isLoading && provider.hydrationRecords.isEmpty) {
            msg = 'Aún no hay registros de hidratación. Toma agua y vuelve más tarde.';
            placeholderIcon = Icons.fact_check_rounded;
          }
    
          if (provider.isLoading || provider.hydrationRecords.isEmpty) {
            // Retornar un placeholder si los datos están cargando, o no hay datos aín.
            return SliverDataPlaceholder(
              isLoading: provider.isLoading,
              message: msg,
              icon: placeholderIcon,
            );

          } else {
            // Retornar la lista de registros de hidratacion del usuario.
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int i) {
                  return _HydrationCard(hydrationRecords: provider.dailyHidration.values.toList()[i],);
                },
                childCount: provider.dailyHidration.length,
              ),
            );
          }
        },
      )
    );
  }
}

class _HydrationCard extends StatelessWidget {

  final List<HydrationRecord> hydrationRecords;

  const _HydrationCard({ required this.hydrationRecords, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final totalIntake = hydrationRecords.isNotEmpty 
      ? hydrationRecords.map((e) => e.amount).reduce((total, v) => total + v)
      : 0;

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    String dateString = hydrationRecords[0].date.toString().substring(0,10);
    
    if (hydrationRecords[0].date.isAfter(today)) {
      dateString = 'Hoy';
    } else if (hydrationRecords[0].date.isAfter(today.subtract(const Duration(days: 1)))) {
      dateString = 'Ayer';
    }

    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ListTile(
            title: Text(
              hydrationRecords.isNotEmpty ? dateString : 'Sin fecha',
              style: Theme.of(context).textTheme.headline4?.copyWith(fontWeight: FontWeight.w500),
            ),
            trailing: Text(
              '${totalIntake}ml',
              style: Theme.of(context).textTheme.headline5?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w400
              ),
            ),
            minVerticalPadding: 0,
            visualDensity: VisualDensity.compact,
          ),

          SizedBox(
            height: 16.0 * hydrationRecords.length + 48.0,
            child:Padding(
              padding: const EdgeInsets.only( left: 16.0, right: 16.0, bottom: 16.0),
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 16.0),
                itemCount: hydrationRecords.length,
                itemBuilder: (context, i) {
                  return Row(
                    children: [
                      Container(
                        width: 16.0,
                        height: 16.0,
                        color: Theme.of(context).colorScheme.primaryVariant,
                        margin: const EdgeInsets.only(right: 4.0),
                      ),

                      Text(
                        '${hydrationRecords[i].date.toString().substring(11,16)} - ${hydrationRecords[i].amount} ml',
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}