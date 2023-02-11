import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:coda/models/query_model.dart';
import 'package:logger/logger.dart';
import 'package:coda/logger.dart';
import '../models/albums_model.dart';
import '../models/clipboard_model.dart';
import 'assemble_route.dart';
import 'clipboard_tags_view.dart';

Logger _logger = getLogger('queries_view', Level.info);

String previousQueryText = '';

class QueriesView extends ConsumerWidget {
  final String title;
  final Function applyQuery;

  //final _scrollController = ScrollController();
  //final SavedQueriesModel sqm = SavedQueriesModel();

  QueriesView({super.key, this.title = 'Saved filters', this.applyQuery = applyQueryOnPlayer}){
    SavedQueriesModel();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //SavedQueriesModel();
    _logger.d('queries: ${SavedQueriesModel.queries}');
    TextEditingController? queryTextController = QueryModel().textController;
    queryTextController!.text = previousQueryText;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 100.0, horizontal: 200.0),
        child: Scaffold(
            appBar: AppBar(title: Text(title)),
            body: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ListTile(
                    //leading: IconButton(icon:Icon(Icons.directions_run)),
                    title: TextField(
                        controller: queryTextController,
                        decoration: InputDecoration(
                          prefixIcon: //Icon(Icons.search),
                              IconButton(
                            icon: const Icon(Icons.save),
                            tooltip: 'Save this as',
                            onPressed: () {
                              showDialog<void>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(content:

                                        TextField(
                                        decoration: const InputDecoration(labelText: 'name the filter'),
                                        onSubmitted: (name) {
                                          _logger.d('saved query text name: $name text: ${queryTextController.text}');
                                          SavedQueriesModel.save(name, queryTextController.text);
                                          //Navigator.of(context).pop();
                                        },
                                      )
                                    );
                                  });
                            },
                          ),
                          suffixIcon: IconButton(
                              onPressed: () {
                                _logger.d('clear query text field');
                                queryTextController.text = '';
                              },
                              icon: const Icon(Icons.clear)),
                          border: const OutlineInputBorder(),
                          labelText: 'Search music using filter',
                        ),
                        maxLines: null,
                        onChanged: (qText) {
                          //query.text = qText;
                        }),
                    trailing: IconButton(
                        onPressed: () {
                          _logger.d('entered applyFilter');
                          applyQuery(queryTextController.text);
                          _logger.d('returned from applyFilter');
                          ref.read(queryProvider.notifier).state = queryTextController.text;
                          previousQueryText = queryTextController.text;
                          context.pop();
                          //Navigator.of(context).popUntil(ModalRoute.withName('/'));
                        },
                        icon: const Icon(Icons.search)),
                  ),
                ),
                Expanded(
                  child: Builder(
                      builder: (BuildContext context) {
                        List<Widget> kids = [];
                        SavedQueriesModel.queries.forEach((key, value) {
                          kids.add(buildItem(key, value, queryTextController, applyQuery, ref, context));
                        });
                        return ListView(
                          //controller: _scrollController,
                          shrinkWrap: true,
                          children: kids,
                        );
                      },
                    ),
                ),
              ],
            ),
            floatingActionButton: FilterFAB(queryTextController)),
      ),
    );
  }
}

//
// when an item is clicked, its text will get pasted into the query text input field
// swipe left or right to delete, with option to undo
// click search icon to apply the query to the back-end
//
Widget buildItem(String name, String filter,
    TextEditingController queryTextController, Function? applyQuery, WidgetRef ref, BuildContext context) {
  //_logger.d('buildItem key: ${name}');
  return Dismissible(
      key: Key(name),
      background: Container(
        color: Colors.amberAccent,
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Icon(Icons.delete_sweep),
        ),
      ),
      secondaryBackground: Container(
        color: Colors.amberAccent,
        child: const Align(
          alignment: Alignment.centerRight,
          child: Icon(Icons.delete_sweep),
        ),
      ),
      onDismissed: (direction) {
        //SavedQueriesModel savedQueries = SavedQueriesModel();
        String? queryText = SavedQueriesModel.queries[name];
        SavedQueriesModel.unSave(name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("$name search removed"),
              action: SnackBarAction(
                label: "UNDO",
                onPressed: () {
                  SavedQueriesModel.save(name, queryText!);
                },
              )),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
        child: ListTile(
          title: Text(name),
          onTap: () {
            queryTextController.text = filter; //_searchTextController.text = filter;
          },
          subtitle: Text(filter),
          trailing: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              if (applyQuery != null) {
                applyQuery(filter);
                ref.read(queryProvider.notifier).state = filter;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Filtering player on $filter"),
                  ),
                );
                _logger.d('returned from applyFilter');
              }
              previousQueryText = queryTextController.text;
              context.pop();
              //Navigator.of(context).popUntil(ModalRoute.withName('/'));
            },
          ),
        ),
      ));
}

class FilterFAB extends StatelessWidget {
  final TextEditingController queryTextController;
  const FilterFAB(this.queryTextController, {super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      List<Clipping> clipboard = ref.watch(clipboardProvider);
      return FloatingActionButton(
          child: const FaIcon(FontAwesomeIcons.tags),
          onPressed: () {
            Navigator.push(context, AssembleRoute(builder: (context) {
              return ClipboardView(
                  title: 'Clipboard - add tags to include or exclude in filter',
                  onDone: (List<Clipping> clipboard) {
                    queryTextController.text = filter(clipboard);
                  });
            }));
          });
    });
  }

  //String filter(Map<Tag, bool> clippings) {
  String filter(List<Clipping> clippings) {
    //
    // construct Quodlibet filter query based on the clipboard contents. Tags in the clipboard are to included or excluded in the filter
    //
    final Map<String, Set<String>> include = {};
    final Map<String, Set<String>> exclude = {};
    late Map<String, Set<String>> clude;

    for (Clipping clipping in clippings) {

      clude = (clipping.op) ? include : exclude;

      if (clude[clipping.tag.name] == null) {
        clude[clipping.tag.name] = <String>{};
      }
      //clude[tag.name]!.add('\\"${tag.value}\\"');
      clude[clipping.tag.name]!.add('/${clipping.tag.value}/');
    }

    List filters = [];
    include.forEach((tagName, values) {
      filters.add('$tagName=|(${values.join(",")})');
    });
    exclude.forEach((tagName, values) {
      filters.add('!$tagName=|(${values.join(",")})');
    });

    // construct the query
    // it'll look like '&(genre=|(Classical),mood=|(moderate,mild))'
    //
    String query = '';
    for (String filter in filters) {
      query = query.isEmpty ? '&($filter' : '$query,$filter';
    }
    if (query.isNotEmpty) {
      query += ')';
    }
    _logger.d('tag query: $query');
    return query;
  }
}

class QueriesPopup extends PopupRoute {
  final WidgetRef ref;
  QueriesPopup(this.ref);

  @override
  Color? get barrierColor => const Color(0);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => '';

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return QueriesView(applyQuery: (String filter) {
      fetchAlbumsMatchingQuery(filter, ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Filtering player on $filter"),
        ),
      );
    });
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);
}
