import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/widgets/shapes.dart';
import 'package:provider/provider.dart';

class CoinDisplay extends StatelessWidget {
  const CoinDisplay({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CoinShape(radius: 14.0,),
            ),
  
            const SizedBox( width: 4.0,),
  
            Consumer<ProfileProvider>(
              builder: (_, profileProvider, __) {
                return FutureBuilder<UserProfile?>(
                  future: profileProvider.profile,
                  builder: (context, snapshot) {

                    if (snapshot.hasData && snapshot.data != null) {
                      return Text(
                        snapshot.data!.coins.toString(),
                        style: Theme.of(context).textTheme.bodyText2,
                        textAlign: TextAlign.right,
                      );
                    } else {
                      return Text(
                        '0',
                        style: Theme.of(context).textTheme.bodyText2,
                        textAlign: TextAlign.right,
                      );
                    }
                  }
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}