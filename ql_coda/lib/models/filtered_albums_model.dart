import 'package:equatable/equatable.dart';

class FilteredAlbums  extends Equatable {
  final List<dynamic> albums;

  @override
  List<Object> get props => [albums];

  FilteredAlbums(this.albums);
}
