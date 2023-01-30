import 'package:coda/models/tags_model.dart';
import 'package:equatable/equatable.dart';

abstract class TagsEvent extends Equatable {
  const TagsEvent();
}

class FetchTags extends TagsEvent {
  final String song;

  const FetchTags({required this.song});

  @override
  List<Object> get props => [song];
}

class UpdateTags extends TagsEvent {
  final Tags tags;

  const UpdateTags({required this.tags});

  @override
  List<Object> get props => [tags];
}