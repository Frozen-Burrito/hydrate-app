import 'package:flutter/material.dart';

import 'package:hydrate_app/src/models/article.dart';
import 'package:hydrate_app/src/provider/article_provider.dart';
import 'package:provider/provider.dart';

class ArticleSliverList extends StatelessWidget {

  final List<Article> articles;

  const ArticleSliverList({ required this.articles, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Builder(
        builder: (context) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget> [
              SliverOverlapInjector(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(8.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int i) {
                      return _ArticleCard(article: articles[i]);
                    },
                    childCount: articles.length
                  ),
                )
              ),
            ]
          );
        }
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {

  final Article article;

  const _ArticleCard({ required this.article, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final articleProvider = Provider.of<ArticleProvider>(context);

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(article.title,),
            subtitle: Text(article.publishDate.toString()),
            //TODO: Cambiar el ícono del botón dependiendo de si el 
            // recurso informativo fue guardado
            trailing: IconButton(
              icon: Icon(article.isBookmarked ? Icons.bookmark_added: Icons.bookmark_border_outlined), 
              color: article.isBookmarked ? Colors.blue : Colors.grey,
              //TODO: Agregar/Remover marcador del artículo en onPressed
              onPressed: () async {
                final id = await articleProvider.bookmarkArticle(article);
                final snackBar = SnackBar(
                  content: Text((id > -1) ? 'Artículo marcado' : 'No se pudo marcar el artículo')
                );

                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              } 
            ),
          ),

          Padding(
            padding: const EdgeInsets.only( left: 16.0, right: 16.0, bottom: 16.0),
            child: Text(article.description ?? '', textAlign: TextAlign.start),
          ),
        ],
      ),
    );
  }
}