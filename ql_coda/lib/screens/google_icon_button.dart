import 'package:coda/logger.dart';
import 'package:coda/models/tags_model.dart';
//import 'package:coda/screens/google_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:logger/logger.dart';
import 'package:coda/models/edited_tags_model.dart';

Logger _logger = getLogger('GoogleIconButton', Level.debug);

class GoogleIconButton extends ConsumerWidget {

  GoogleIconButton({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Tag> tags = ref.read(editedTagsProvider);
    return ElevatedButton.icon(
      label: const Text('Search web'),
      icon: const FaIcon(FontAwesomeIcons.google),
      onPressed: () {
        String artists = '';
        String title = '';

        if (tags.isNotEmpty) {
          title = tags.firstWhere((test) {return test.name == 'album';}).value;
          List<Tag> artistsList = tags.where((test) {return test.name == 'artist';}).toList();
          artists = artistsList.expand((tag){return [tag.value];}).toList().join(',');

          _logger.d('TagsLoaded - title:$title, artists: $artists');

        }
        else {
          _logger.d('not TagsLoaded');
        }

        /*Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => GoogleSearch(
                artists: artists,
                title: title,
              )), //EditPage(Player.currentTrackFile)),
        );*/
      },
    );
  }
}


