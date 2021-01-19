import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:git_touch/models/gitee.dart';
import 'package:git_touch/scaffolds/refresh_stateful.dart';
import 'package:git_touch/utils/utils.dart';
import 'package:git_touch/widgets/action_entry.dart';
import 'package:git_touch/widgets/app_bar_title.dart';
import 'package:git_touch/models/auth.dart';
import 'package:git_touch/widgets/entry_item.dart';
import 'package:git_touch/widgets/repository_item.dart';
import 'package:git_touch/widgets/table_view.dart';
import 'package:git_touch/widgets/user_header.dart';
import 'package:provider/provider.dart';
import 'package:git_touch/widgets/action_button.dart';
import 'package:tuple/tuple.dart';
import 'package:timeago/timeago.dart' as timeago;

class GeUserScreen extends StatelessWidget {
  final String login;
  final bool isViewer;
  GeUserScreen(this.login, {this.isViewer = false});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthModel>(context);
    return RefreshStatefulScaffold<Tuple2<GiteeUser, List<GiteeRepo>>>(
      fetch: () async {
        final res = await Future.wait([
          auth.fetchGitee('/users/$login'),
          auth.fetchGitee('/users/$login/repos?per_page=6'),
        ]);
        return Tuple2(
          GiteeUser.fromJson(res[0]),
          [for (var v in res[1]) GiteeRepo.fromJson(v)],
        );
      },
      title: AppBarTitle(isViewer ? 'Me' : login),
      action: isViewer
          ? ActionEntry(
              iconData: Icons.settings,
              url: '/settings',
            )
          : null,
      actionBuilder: isViewer
          ? null
          : (p, setState) {
              return ActionButton(
                title: 'User Actions',
                items: [...ActionItem.getUrlActions(p.item1.htmlUrl)],
              );
            },
      bodyBuilder: (p, setState) {
        final user = p.item1;
        final repos = p.item2;

        return Column(
          children: <Widget>[
            UserHeader(
              login: user.login,
              avatarUrl: user.avatarUrl,
              name: user.name,
              createdAt: user.createdAt,
              isViewer: isViewer,
              bio: user.bio,
            ),
            CommonStyle.border,
            Row(children: [
              EntryItem(
                count: user.publicRepos,
                text: 'Repositories',
                url: '/gitee/$login?tab=repositories',
              ),
              EntryItem(
                count: user.stared,
                text: 'Stars',
                url: '/gitee/$login?tab=stars',
              ),
              EntryItem(
                count: user.followers,
                text: 'Followers',
                url: '/gitee/$login?tab=followers',
              ),
              EntryItem(
                count: user.following,
                text: 'Following',
                url: '/gitee/$login?tab=following',
              ),
            ]),
            // TableView(
            //   hasIcon: true,
            //   items: [
            //     TableViewItem(
            //       leftIconData: Octicons.home,
            //       text: Text('Organizations'),
            //       url: '/gitee/$login?tab=organizations',
            //     ),
            //   ],
            // ),
            CommonStyle.border,
            Column(
              children: <Widget>[
                for (var v in repos)
                  RepositoryItem(
                    owner: v.namespace.path,
                    avatarUrl: v.owner.avatarUrl,
                    name: v.path,
                    description: v.description,
                    starCount: v.stargazersCount,
                    forkCount: v.forksCount,
                    note: 'Updated ${timeago.format(v.updatedAt)}',
                    url: '/gitee/${v.namespace.path}/${v.path}',
                    avatarLink: '/gitee/${v.namespace.path}',
                    // iconData: , TODO:
                  )
              ],
            ),
          ],
        );
      },
    );
  }
}
