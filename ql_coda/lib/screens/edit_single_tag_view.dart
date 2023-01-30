import 'dart:ui';

import 'package:coda/models/clipboard_model.dart';
import 'package:coda/models/edited_tags_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';
import '../models/tags_model.dart';
import 'package:logger/logger.dart';
import 'package:coda/logger.dart';

Logger _logger = getLogger('edit_single_tag_view', Level.debug);

class EditSingleTagView extends ConsumerStatefulWidget {
  // tagIndex non-null refers to tag's place in the parent's list of tags
  // a null value means a new tag is to be added to the clipboad
  // TODO if this need to be used from more callers, get the parent provider from a provider
  //
  final int? tagIndex;

  EditSingleTagView({super.key, this.tagIndex}) {
    _logger.d('EditSingleTagView constructor, tagIndex: $tagIndex');
  }

  @override
  ConsumerState<EditSingleTagView> createState() => _EditSingleTagViewState();
}

class _EditSingleTagViewState extends ConsumerState<EditSingleTagView> {
  final tagValueController = TextEditingController();
  final tagNameController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String? newTagName;
  String? newTagValue;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    //tagValueController.dispose();
    //tagValueController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isClipboardTag = widget.tagIndex == null;
    List<EditTag> editTags = ref.read(editedTagsProvider);
    if ((!isClipboardTag) && (widget.tagIndex != -1)){
      tagNameController.text = editTags[widget.tagIndex!].name;
      tagValueController.text = editTags[widget.tagIndex!].value;
    }
    return Card(
      margin:const EdgeInsets.symmetric(vertical: 100.0, horizontal: 200.0),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildTagName(),
              const SizedBox(height: 16),
              buildTagValue(),
              const SizedBox(height: 12),
              buildSubmit(context)
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTagName() => TypeAheadFormField<String?>(
        textFieldConfiguration: TextFieldConfiguration(
          controller: tagNameController,
          decoration: const InputDecoration(
            labelText: 'Tag name',
            border: OutlineInputBorder(),
          ),
        ),
        suggestionsCallback: TagNameSuggestions.getSuggestions,
        itemBuilder: (context, String? suggestion) => ListTile(
          title: Text(suggestion!),
        ),
        onSuggestionSelected: (String? suggestion) =>
            tagNameController.text = suggestion!,
        validator: (value) =>
            value != null && value.isEmpty ? 'Please provide a tag name' : null,
        onSaved: (value) => newTagName = value,
      );

  Widget buildTagValue() => TypeAheadFormField<String?>(
        textFieldConfiguration: TextFieldConfiguration(
          controller: tagValueController,
          decoration: const InputDecoration(
            labelText: 'Value',
            border: OutlineInputBorder(),
          ),
        ),
        suggestionsCallback: tagValueSuggestions,
        itemBuilder: (context, String? suggestion) => ListTile(
          title: Text(suggestion!),
        ),
        onSuggestionSelected: (String? suggestion) =>
            tagValueController.text = suggestion!,
        validator: (value) => value != null && value.isEmpty
            ? 'Please provide a the tag value'
            : null,
        onSaved: (value) => newTagValue = value,
      );

  List<String> tagValueSuggestions(String query) {
    List<String> valueNameSuggestions =
        TagCache().valuesFor(tagNameController.text);
    if (valueNameSuggestions.isEmpty) {
      return [];
    } else {
      return List.of(valueNameSuggestions).where((tag) {
        final tagLower = tag.toLowerCase();
        final queryLower = query.toLowerCase();

        return tagLower.contains(queryLower);
      }).toList();
    }
  }

  Widget buildSubmit(BuildContext context) => Builder(
    builder: (context) {
      bool isClipboardTag = (widget.tagIndex == null);
      return ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Add', style: TextStyle(fontSize: 20)),
            onPressed: () {
              final form = formKey.currentState!;

              if (form.validate()) {
                form.save();

                if (isClipboardTag) {
                  ref.read(clipboardProvider.notifier).add(Tag(name: newTagName!, value: newTagValue!));
                }
                else {
                  ref.read(editedTagsProvider.notifier).replace(
                      widget.tagIndex!, Tag(name: newTagName!, value: newTagValue!));
                }

              }
              GoRouter.of(context).pop();
            },
          );
    }
  );
}

class ButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback onClicked;

  const ButtonWidget({
    Key? key,
    required this.text,
    required this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
        ),
        onPressed: onClicked,
        child: Text(text, style: const TextStyle(fontSize: 20)),
      );
}

const List<String> tagNameSuggestions = [
  'album',
  'artist',
  'composer',
  'date',
  'discnumber',
  'discsubtitle',
  'genre',
  'grouping',
  'labelid',
  'mood',
  'performer:',
  'style',
  'title',
  'tracknumber',
  'version'
];

class TagNameSuggestions {
  static List<String> getSuggestions(String query) =>
      List.of(tagNameSuggestions).where((tag) {
        final tagLower = tag.toLowerCase();
        final queryLower = query.toLowerCase();

        return tagLower.contains(queryLower);
      }).toList();
}

class EditSingleTagPopup extends PopupRoute {
  EditSingleTagPopup({required this.tagIndex});
  final int tagIndex;

  @override
  // TODO: implement barrierColor
  Color? get barrierColor => const Color(0);

  @override
  // TODO: implement barrierDismissible
  bool get barrierDismissible => true;

  @override
  // TODO: implement barrierLabel
  String? get barrierLabel => '';

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return EditSingleTag(tagIndex: tagIndex);
  }

  @override
  // TODO: implement transitionDuration
  Duration get transitionDuration => const Duration(milliseconds: 400);

}

class EditSingleTag extends StatefulWidget {
  final int? tagIndex;

  EditSingleTag({super.key, this.tagIndex}) {
    _logger.d('EditSingleTag constructor');
  }
  @override
  State<EditSingleTag> createState() => _EditSingleTagState();
}

class _EditSingleTagState extends State<EditSingleTag> {
  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: EditSingleTagView(tagIndex: widget.tagIndex));
  }
}
