import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/provider/article_provider.dart';
import 'package:hydrate_app/src/widgets/article_sliver_list.dart';
import 'package:hydrate_app/src/widgets/opt_popup_menu.dart';

class ArticlesTab extends StatelessWidget {
  
  const ArticlesTab({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;

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
                  title: localizations.resources,
                  bottom: TabBar(
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: <Tab> [
                      Tab(
                        child: Text(localizations.discover, 
                        style: Theme.of(context).textTheme.bodyText1, )
                      ),
                      Tab(
                        child: Text(localizations.bookmarks, 
                        style: Theme.of(context).textTheme.bodyText1, )
                      ),
                    ],
                  ),
                  actions: const <Widget>[
                    AuthOptionsMenu(),
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
                  ArticleSliverList(
                    articles: Future.value(articleProvider.allArticles),
                    scrollController: articleProvider.scrollController,
                    articleSource: ArticleSource.network,
                  ),
                  ArticleSliverList(
                    articles: articleProvider.bookmarks, 
                    articleSource: ArticleSource.bookmarks,
                  ),
                ]
              );
            },
          ),
        ),
      ),
    );
  }
}
