import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';

import 'package:coda/repositories/repositories.dart';
import 'package:coda/models/filtered_albums_model.dart';

class FilteredAlbumsBloc extends Bloc<FilteredAlbumsEvent, FilteredAlbumsState> {
  final FilteredAlbumsRepository filteredAlbumsRepository;

  FilteredAlbumsBloc({required this.filteredAlbumsRepository})
      : super(FilteredAlbumsEmpty());

  FilteredAlbumsState get initialState => FilteredAlbumsEmpty();

  Stream<FilteredAlbumsState> mapEventToState(FilteredAlbumsEvent event) async* {
    if (event is FetchFilteredAlbums) {
      yield FilteredAlbumsLoading();
      try {
        final FilteredAlbums filteredAlbums = await filteredAlbumsRepository.getFilteredAlbums(event.query);
        yield FilteredAlbumsLoaded(filteredAlbums: filteredAlbums);
      } catch (_) {
        yield FilteredAlbumsError();
      }
    }
    if (event is SortFilteredAlbums) {
      yield FilteredAlbumsLoading();
      FilteredAlbums filteredAlbums = event.filteredAlbums;
      filteredAlbums.albums.sort((a, b) => a[event.sortBy].toString().compareTo(b[event.sortBy].toString()));
      yield FilteredAlbumsLoaded(filteredAlbums: filteredAlbums);
    }
    if (event is ErrorInFilteredAlbums) {
      yield FilteredAlbumsError();
    }
  }
}

abstract class FilteredAlbumsState extends Equatable {
  const FilteredAlbumsState();

  @override
  List<Object> get props => [];
}

class FilteredAlbumsLoaded extends FilteredAlbumsState {
  final FilteredAlbums filteredAlbums;

  const FilteredAlbumsLoaded({required this.filteredAlbums});

  @override
  List<Object> get props => [filteredAlbums];
}

class FilteredAlbumsEmpty extends FilteredAlbumsState {}
class FilteredAlbumsLoading extends FilteredAlbumsState {}
class FilteredAlbumsError extends FilteredAlbumsState {}