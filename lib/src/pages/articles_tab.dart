import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
                sliver:  SliverAppBar(
                  title: const Text('Artículos'),
                  titleTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 24),
                  centerTitle: true,
                  backgroundColor: Colors.white,
                  floating: true,
                  bottom: const TabBar(
                    indicatorColor: Colors.blue,
                    tabs: <Tab> [
                      Tab(child: Text('Descubrir', style: TextStyle(color: Colors.black),), ),
                      Tab(child: Text('Marcados', style: TextStyle(color: Colors.black),),),
                    ],
                  ),
                  actionsIconTheme: const IconThemeData(color: Colors.black),
                  actions: [
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
              )
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
