import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hydrate_app/src/models/article.dart';
import 'package:hydrate_app/src/widgets/custom_toolbar.dart';
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
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget> [
    
          SliverPersistentHeader(
            floating: true,
            delegate: _SliverCustomHeaderDelegate(
              minHeight: 168,
              maxHeight: 168,
              child: CustomToolbar(
                title: 'Artículos',
                endActions: [
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
                  )
                ],
                child: const TabBar(
                  tabs: <Tab> [
                    Tab(child: Text('Descubrir', style: TextStyle(color: Colors.black),), ),
                    Tab(child: Text('Marcados', style: TextStyle(color: Colors.black),),),
                  ],
                ),
              ),
            )
          ),
    
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int i) {
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(items[i].title,),
                        subtitle: Text(items[i].publishDate.toString()),
                        //TODO: Cambiar el ícono del botón dependiendo de si el 
                        // recurso informativo fue guardado
                        trailing: IconButton(
                          icon: const Icon(Icons.bookmark_border_outlined), 
                          //TODO: Agregar/Remover marcador del artículo en onPressed
                          onPressed: () {},
                        ),
                      ),
          
                      Padding(
                        padding: const EdgeInsets.only( left: 16.0, right: 16.0, bottom: 16.0),
                        child: Text(items[i].description ?? '', textAlign: TextAlign.start),
                      ),
                    ],
                  ),
                );
              },
              childCount: items.length 
            )
          ),
        ],
      ),
    );
  }
}

class _SliverCustomHeaderDelegate extends SliverPersistentHeaderDelegate {

  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverCustomHeaderDelegate({
    required this.minHeight, 
    required this.maxHeight, 
    required this.child
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: child,
    );
  }

  @override
  double get maxExtent => max(minHeight, maxHeight);

  @override
  double get minExtent => min(minHeight, maxHeight);

  @override
  bool shouldRebuild(covariant _SliverCustomHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || 
           minHeight != oldDelegate.minHeight ||
           child != oldDelegate.child;
  }
}
