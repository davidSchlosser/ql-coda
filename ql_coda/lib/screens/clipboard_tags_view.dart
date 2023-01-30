import 'dart:ui';
import 'package:coda/models/clipboard_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:coda/logger.dart';

import 'edit_single_tag_view.dart';

Logger _logger = getLogger('clipboard_tags', Level.debug);

class ClipboardView extends ConsumerWidget {
  final String title;
  final Function onDone;
  final List<String> nameSuggestions = [
    'artist',
    'composer',
    'genre',
    'mood',
    'performer:',
    'style',
  ];

  ClipboardView({super.key, required this.title, required this.onDone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Clipping> clipboard = ref.watch(clipboardProvider);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Padding(
        padding: MediaQuery.of(context).viewInsets +
            const EdgeInsets.symmetric(vertical: 60.0, horizontal: 30.0),
        child: Card(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Text(
                  title,
                  textScaleFactor: 1.5,
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    Wrap(
                      spacing: 4.0, // gap between adjacent chips
                      runSpacing: 4.0, // gap between lines
                      children: clipboard.map((clipping) {
                        return RawChip(
                          avatar: Icon(clipping.op ? Icons.add : Icons.close),
                          backgroundColor: clipping.op
                              ? Colors.blue.shade100
                              : Colors.pink.shade100,
                          label: Text(
                              '${clipping.tag.name}: ${clipping.tag.value}'),
                          onDeleted: () {
                            ref
                                .read(clipboardProvider.notifier)
                                .remove(clipping.tag);
                          },
                          onPressed: () {
                            ref
                                .read(clipboardProvider.notifier)
                                .toggle(clipping.tag);
                          },
                        );
                      }).toList(),
                    ),
                    EditSingleTagView(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        (!ref.read(clipboardProvider.notifier).isEmpty())
                            ? ElevatedButton(
                                onPressed: () {
                                  ref.read(clipboardProvider.notifier).clear();
                                },
                                child: const Text('Clear'),
                              )
                            : Container(),
                        ElevatedButton(
                          onPressed: () {
                            onDone(clipboard);
                            Navigator.of(context).pop(false);
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
