import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:hydrate_app/src/models/article.dart';
import 'package:hydrate_app/src/widgets/article_sliver_list.dart';
import 'package:hydrate_app/src/widgets/opt_popup_menu.dart';

class ArticlesTab extends StatelessWidget {
  
  ArticlesTab({ Key? key }) : super(key: key);

  //TODO: Obtener recursos informativos reales por medio de la API web.
  final items = [ 
    Article(id: 0, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 1, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 2, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 3, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 4, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 5, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 6, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 7, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 8, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 9, title: 'Un articulo de prueba', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
  ];

  final bookmarkedItems = [ 
    Article(id: 0, title: 'Un articulo guardado', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 1, title: 'Un articulo guardado', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 2, title: 'Un articulo guardado', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
    Article(id: 3, title: 'Un articulo guardado', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', url: 'http://url.com', publishDate: DateTime.now()),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
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
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: <Widget> [
            ArticleSliverList(articles: items),
            ArticleSliverList(articles: bookmarkedItems),
          ]
        ),
      ),
    );
  }
}
