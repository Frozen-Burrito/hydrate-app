import 'dart:math';

import 'package:flutter/material.dart';

import 'package:hydrate_app/src/models/article.dart';
import 'package:hydrate_app/src/provider/article_provider.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';
import 'package:provider/provider.dart';

class ArticleSliverList extends StatelessWidget {

  final List<Article> articles;

  final bool isBookmarks;
  final bool hasError;
  final bool isLoading;

  const ArticleSliverList({ 
    required this.articles, 
    this.isBookmarks = false,
    this.isLoading = false, 
    this.hasError = false,
    Key? key 
    }) : super(key: key);

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
                sliver: Builder(
                  builder: (context) {

                    String msg = '';
                    IconData placeholderIcon = Icons.error;

                    if (hasError) {
                      msg = 'Hubo un error obteniendo los recursos informativos';
                      placeholderIcon = isBookmarks ? Icons.folder_open : Icons.cloud_off_rounded;

                    } else if (!isLoading && articles.isEmpty) {
                      msg = isBookmarks 
                        ? 'Aún no has guardado recursos informativos.' 
                        : 'No hay recursos informativos disponibles. Intenta más tarde.';
                      placeholderIcon = Icons.inbox;
                    }

                    if (isLoading || hasError || articles.isEmpty) {
                      return SliverDataPlaceholder(
                        isLoading: isLoading,
                        message: msg,
                        icon: placeholderIcon,
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int i) {
                          return _ArticleCard(article: articles[i]);
                        },
                        childCount: articles.length
                      ),
                    );
                  }
                )
              ),
            ]
          );
        }
      ),
    );
  }
}

/// Muestra los datos de un [Article] en una [Card].
class _ArticleCard extends StatelessWidget {

  /// EL [Article] de la tarjeta.
  final Article article;

  const _ArticleCard({ required this.article, Key? key }) : super(key: key);

  /// Activa o desactiva una marca de leer más tarde de un [Artículo]
  /// 
  /// Si el [Article] no está marcado, guarda el artículo en la base de datos
  /// usando [ArticleProvider.bookmarkArticle()]. 
  ///  
  /// Si el [Article] ya está marcado, remueve el artículo en la base de datos
  /// usando [ArticleProvider.removeArticle()].  
  /// 
  /// Retorna un SnackBar con un mensaje de confirmación.
  Future<SnackBar> addOrRemoveBookmark(BuildContext context, ArticleProvider provider) async {
    // El mensaje para confirmar la marca/eliminación.
    String snackMsg = '';

    if (article.isBookmarked) {
      // Si está marcado, quitar marca.
      int id = await provider.removeArticle(article.id);
      snackMsg = id > -1 ? 'Artículo removido' : 'No se pudo remover el artículo.';

    } else {
      // Si no está marcado, marcar y guardar el recurso informativo.
      final id = await provider.bookmarkArticle(article);
      snackMsg = id > -1 ? 'Artículo marcado.' : 'No se pudo marcar el artículo.';
    }

    return SnackBar(
      content: Text(snackMsg)
    );
  }

  @override
  Widget build(BuildContext context) {

    final articleProvider = Provider.of<ArticleProvider>(context);

    final rawPublishDateStr = article.publishDate.toString();

    final articleDateStr = (article.publishDate != null)
      ? rawPublishDateStr.substring(0, min(article.publishDate.toString().length, 10))
      : 'Sin fecha';

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(
              article.title, 
              style: Theme.of(context).textTheme.headline6,
            ),
            subtitle: Text(
              'Publicación: $articleDateStr',
              style: Theme.of(context).textTheme.bodyText1
            ),
            trailing: IconButton(
              icon: Icon(article.isBookmarked ? Icons.bookmark_added: Icons.bookmark_border_outlined), 
              color: article.isBookmarked ? Colors.blue : Colors.grey,
              onPressed: () async {
                final snackBar = await addOrRemoveBookmark(context, articleProvider);
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.only( left: 16.0, right: 16.0, bottom: 16.0),
            child: Text(
              article.description ?? '', 
              style: Theme.of(context).textTheme.bodyText2,
              textAlign: TextAlign.start, 
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}
