import 'package:coda/models/tags_model.dart';
import 'package:coda/screens/common_scaffold.dart';
import 'package:flutter/material.dart';

class CachePage extends StatefulWidget {
  const CachePage({super.key});

  @override
  CachePageState createState() {
    return CachePageState();
  }
}

class CachePageState extends State<CachePage> {
  static String viewCache = 'artist';
  static List<String> cacheNames = [];
  final TagCache tagCache = TagCache();
  final itemExtent = 30.0;
  ScrollController scrollController = ScrollController();
  static bool requireRebuild = true;

  @override
  void initState() {
    //print('init CachePageState');
    super.initState();
    requireRebuild = tagCache.tagCache.isEmpty;
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  build(BuildContext context) {
    return CommonScaffold(
      title: 'Tags suggestions cache',
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              // dropdown to select which cache
              requireRebuild
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: DropdownButton<String>(
                        value: viewCache,
                        icon: const Icon(Icons.arrow_downward),
                        iconSize: 24,
                        elevation: 16,
                        style: const TextStyle(color: Colors.deepPurple),
                        underline: Container(
                          height: 2,
                          color: Colors.deepPurpleAccent,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            viewCache = newValue!;
                          });
                        },
                        items: tagCache.cacheNames
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
              // scrollable ist of cached tag values
              Builder(
                builder: (BuildContext context) {
                  return TextButton.icon(
                    icon: const Icon(Icons.build),
                    label: const Text('Rebuild'),
                    //shape: RoundedRectangleBorder(),
                    onPressed: () {
                      requireRebuild = true;
                      cacheNames = [];
                      tagCache.rebuildFromQl().then((_) {
                        setState(() {
                          requireRebuild = false;
                        });
                        for (var k in TagCache.cache.keys) {
                          cacheNames.add(k.toString());
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Rebuilding tag caches...."),
                        ),
                      );
                    },
                  );
                },
              ),
              /*FlatButton.icon(
                icon: Icon(Icons.build),
                label: Text('check'),
                shape: RoundedRectangleBorder(),
                onPressed: () {
                  print('cache keys: ${TagCache.cache.keys.toList()}');
                  print('cache keys type: ${TagCache.cache.keys.runtimeType}');
                  print('$cacheNames');
                },
              ),*/
            ],
          ),
          requireRebuild
              ? Container()
              : Expanded(
                  child: ListView(
                    controller: scrollController,
                    itemExtent: itemExtent,
                    children: viewCacheItems(),
                  ),
                ),
        ],
      ),
    );
  }

  List<Widget> viewCacheItems() {
    List<Widget> items = [];
    tagCache.tagCache[viewCache].forEach((item) {
      items.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(child: Text(item)),
      ));
    });
    return items;
  }
}
