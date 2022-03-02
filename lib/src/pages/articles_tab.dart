import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';

import 'package:provider/provider.dart';

import 'package:hydrate_app/src/provider/article_provider.dart';
import 'package:hydrate_app/src/widgets/article_sliver_list.dart';
import 'package:hydrate_app/src/widgets/opt_popup_menu.dart';

class ArticlesTab extends StatelessWidget {
  
  const ArticlesTab({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ArticleProvider(),
      child: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget> [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: CustomSliverAppBar(
                  title: 'Artículos',
                  bottom: TabBar(
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: <Tab> [
                      Tab(child: Text('Descubrir', style: Theme.of(context).textTheme.bodyText1, )),
                      Tab(child: Text('Marcados', style: Theme.of(context).textTheme.bodyText1, )),
                    ],
                  ),
                  actions: <Widget>[
                    OptionsPopupMenu(
                      options: <MenuItem> [
                        MenuItem(
                          icon: Icons.account_circle_rounded, 
                          label: 'Iniciar Sesión',
                          onSelected: () => print('Iniciando sesion...'),
                        ),
                        MenuItem(
                          icon: Icons.settings, 
                          label: 'Ajustes',
                          onSelected: () => Navigator.pushNamed(context, '/config'),
                        ),
                      ]
                    ),
                  ],
                ),
              ),
            ];
          },
          body: Consumer<ArticleProvider>(
            builder: (_, articleProvider, __) {
              return TabBarView(
                physics: const BouncingScrollPhysics(),
                children: <Widget> [
                  ArticleSliverList(articles: articleProvider.articles),
                  ArticleSliverList(articles: articleProvider.bookmarks),
                ]
              );
            },
          ),
        ),
      ),
    );
  }
}
