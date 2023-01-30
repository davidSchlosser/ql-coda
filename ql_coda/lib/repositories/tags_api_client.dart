import 'dart:convert';
import 'package:coda/models/tags_model.dart';
import 'package:coda/communicator.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('tags_api_client', Level.info);

class TagsApiClient {
  TagsApiClient();

  Future<Tags> fetchTags(String songFile) async {
    final List<Tag> tags = [];

    _logger.d('TagsApiClient songFile: $songFile');
    String exportTags = await Communicator().request('exporttags', [songFile]);

    List t = jsonDecode(exportTags);
    for (var tag in t) {
      tags.add(Tag(name: tag[0], value: tag[1]));
    }
    return Tags(tags); // Tags.fromExported(exportTags);
  }

}

class TagsRepository {
  final TagsApiClient tagsApiClient;

  TagsRepository({required this.tagsApiClient});

  Future<Tags> getTags(String songFile) async {
    return tagsApiClient.fetchTags(songFile);
  }
}