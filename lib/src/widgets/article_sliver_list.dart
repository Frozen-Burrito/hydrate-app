import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/article.dart';
import 'package:hydrate_app/src/provider/article_provider.dart';
import 'package:hydrate_app/src/utils/launch_url.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';

class ArticleSliverList extends StatelessWidget {

  final Future<List<Article>?> articles;

  final ScrollController? scrollController;

  final ArticleSource articleSource;

  const ArticleSliverList({ 
    required this.articles, 
    required this.articleSource,
    this.scrollController,
    Key? key 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      bottom: false,
      child: Builder(
        builder: (context) {
          return CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: <Widget> [
              SliverOverlapInjector(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(8.0),
                sliver: FutureBuilder<List<Article>?>(
                  future: articles,
                  builder: (context, snapshot) {

                    if (snapshot.hasData) {
                      // El Future tiene datos.
                      if (snapshot.data!.isNotEmpty) {
                        // Retornar lista de articulos, si los hay.
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int i) {
                              return _ArticleCard(article: snapshot.data![i]);
                            },
                            childCount: snapshot.data!.length
                          ),
                        );
                      } else {
                        // Mostrar contenido placeholder cuando no hay articulos.
                        return SliverDataPlaceholder(
                          message: articleSource == ArticleSource.bookmarks 
                            ? localizations.noBookmarks
                            : localizations.resourcesUnavailable,
                          icon: Icons.inbox,
                        );
                      }
                    } else if (snapshot.hasError) {
                      // Mostrar contenido placeholder de error.
                      return SliverDataPlaceholder(
                        message: localizations.resourcesErr,
                        icon: (articleSource == ArticleSource.bookmarks) 
                          ? Icons.folder_open 
                          : Icons.cloud_off_rounded,
                      );
                    }

                    return const SliverDataPlaceholder(
                      isLoading: true,
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

    final localizations = AppLocalizations.of(context)!;

    if (article.isBookmarked) {
      // Si está marcado, quitar marca.
      bool wasBookmarkRemoved = await provider.removeBookmark(article);
      snackMsg = wasBookmarkRemoved 
        ? localizations.resourceRemoved 
        : localizations.resourceNotRemoved;

    } else {
      // Si no está marcado, marcar y guardar el recurso informativo.
      final wasBookmarkCreated = await provider.bookmarkArticle(article);
      snackMsg = wasBookmarkCreated 
        ? localizations.resourceAdded 
        : localizations.resourceNotAdded;
    }

    return SnackBar(
      content: Text(snackMsg)
    );
  }

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;

    final rawPublishDateStr = article.publishDate.toString();

    final articleDateStr = (article.publishDate != null)
      ? rawPublishDateStr.substring(0, min(article.publishDate.toString().length, 10))
      : localizations.noDate;

    return Card(
      child: Column(
        children: [
          ListTile(
            visualDensity: VisualDensity.comfortable,
            minVerticalPadding: 16.0,
            title: GestureDetector(
              onTap: article.url != null
                ? () => UrlLauncher.launchUrlInBrowser(article.url!)
                : null,
              child: Text(
                article.title, 
                style: Theme.of(context).textTheme.headline5,
              ),
            ),
            subtitle: Container(
              margin: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${localizations.published}: $articleDateStr',
                style: Theme.of(context).textTheme.bodyText1?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface
                )
              ),
            ),
            trailing: Consumer<ArticleProvider>(
              builder: (_, articleProvider, __) {
                return IconButton(
                  icon: Icon(article.isBookmarked ? Icons.bookmark_added: Icons.bookmark_border_outlined), 
                  color: article.isBookmarked ? Colors.blue : Colors.grey,
                  onPressed: () async {
                    final snackBar = await addOrRemoveBookmark(context, articleProvider);
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  },
                );
              }
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
