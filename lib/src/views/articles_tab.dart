import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/services/article_service.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/article_sliver_list.dart';
import 'package:hydrate_app/src/widgets/opt_popup_menu.dart';

class ArticlesTab extends StatelessWidget {
  
  const ArticlesTab({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;

    return ChangeNotifierProvider(
      create: (_) => ArticleService(),
      child: DefaultTabController(
        length: ArticleService.articleTabsLength,
        child: Consumer<ArticleService>(
          builder: (innerContext, articleProvider, __) {

            final tabController = DefaultTabController.of(innerContext)!;

            tabController.addListener(() {
              if (!tabController.indexIsChanging) {
                print("Tab index changed to: ${tabController.index}");
                articleProvider.currentTabIndex = tabController.index;
              }
            });

            return NestedScrollView(
              physics: const BouncingScrollPhysics(),
              controller: articleProvider.scrollController,
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
              body: const TabBarView(
                physics: BouncingScrollPhysics(),
                children: <Widget> [
                  ArticleSliverList(
                    articleSource: ArticleSource.network,
                  ),
                  ArticleSliverList(
                    articleSource: ArticleSource.bookmarks,
                  ),
                ]
              ),
            );
          }
        ),
      ),
    );
  }
}
