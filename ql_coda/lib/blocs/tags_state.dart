import 'package:equatable/equatable.dart';
import 'package:coda/models/tags_model.dart';

abstract class TagsState extends Equatable {
  const TagsState();

  @override
  List<Object> get props => [];
}

class TagsLoaded extends TagsState {
  final Tags tags;

  const TagsLoaded({required this.tags});

  @override
  List<Object> get props => [tags];
}

class TagsEmpty extends TagsState {}
class TagsLoading extends TagsState {}
//class TagsReloading extends TagsState {}
class TagsError extends TagsState {}