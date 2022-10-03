import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/widgets/count_text.dart';
import 'package:hydrate_app/src/widgets/shapes.dart';

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
  
            Consumer<ProfileService>(
              builder: (_, profileService, __) {
                return FutureBuilder<UserProfile?>(
                  future: profileService.profile,
                  builder: (context, snapshot) {

                    final int coinCount = snapshot.data?.coins ?? 0;

                    return CountText(
                      value: coinCount,
                      style: Theme.of(context).textTheme.bodyText2,
                      textAlign: TextAlign.right,
                    );
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
