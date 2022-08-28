import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/article.dart';
import 'package:hydrate_app/src/provider/article_provider.dart';
import 'package:hydrate_app/src/utils/launch_url.dart';
import 'package:hydrate_app/src/widgets/floating_progress_indicator.dart';

class ArticleSliverList extends StatelessWidget {

  const ArticleSliverList({ 
    required this.articleSource,
    Key? key 
  }) : super(key: key);

  /// Define la fuente de los artículos mostrados en esta lista. Puede tener
  /// los siguientes valores:
  /// 
  /// - [ArticleSource.bookmarks] Los artículos mostrados son aquellos 
  /// marcados y guardados localmente.
  /// - [ArticleSource.network] Los artículos mostrados son los obtenidos
  /// desde la API web de recursos informativos.
  final ArticleSource articleSource;

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      bottom: false,
      child: Consumer<ArticleProvider>(
        builder: (_, articleProvider, __) {

          final articles = articleSource == ArticleSource.network
            ? articleProvider.allArticles
            : articleProvider.bookmarks;

          final isLoading = articleSource == ArticleSource.network
            ? articleProvider.isFetchingAllArticles
            : articleProvider.isFetchingBookmarks;

          final hasError = articleSource == ArticleSource.network
            ? articleProvider.hasErrorForAllArticles
            : articleProvider.hasErrorForBookmarks;

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: <Widget> [
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: hasError 
                      // Mostrar un placeholder de error.
                      ? SliverToBoxAdapter(
                          child: DataPlaceholder(
                            message: localizations.resourcesErr,
                            icon: articleSource == ArticleSource.bookmarks
                              ? Icons.folder_open 
                              : Icons.cloud_off_rounded,
                          ),
                        )
                      : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int i) {
                            return _ArticleCard(
                              article: articles[i],
                              source: articleSource,
                            );
                          },
                          childCount: articles.length
                        )
                      ),
                  )
                ]
              ),

              if (isLoading) 
              Positioned(
                bottom: 32.0,
                left: MediaQuery.of(context).size.width * 0.5 - 16.0,
                child: const FloatingProgressIndicator(
                  width: 32.0,
                  height: 32.0,
                ),
              ),
            ],
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

  final ArticleSource source;

  const _ArticleCard({ 
    Key? key,
    required this.article, 
    required this.source,
  }) : super(key: key);

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

    if (article.id == Article.invalidArticleId) {
      return DataPlaceholder(
        //TODO: revisar y actualizar i18n si es necesario.
        message: source == ArticleSource.bookmarks
          ? localizations.noBookmarks
          : localizations.resourcesUnavailable,
        icon: Icons.inbox,
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              overflow: TextOverflow.ellipsis, 
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}
