import 'dart:convert';
import 'package:coda/communicator.dart';
import 'package:coda/models/filtered_albums_model.dart';
import 'package:equatable/equatable.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('filtered_albums_api_client', Level.debug);

class FilteredAlbumsApiClient {
  FilteredAlbumsApiClient();

  Future<FilteredAlbums> fetchFilteredAlbums(String query) async {
    List<dynamic> albumResults;

    String response = await Communicator().request('queryalbums', [query]);
    //
    // print(['fetchFilteredAlbums response: $response']);
    try {
      albumResults = jsonDecode(response);
    } catch (e) {
      _logger.d('exception: $e');
      rethrow;
    }
    return FilteredAlbums(albumResults);
  }

}

class FilteredAlbumsRepository {
  final FilteredAlbumsApiClient filteredAlbumsApiClient;

  FilteredAlbumsRepository({required this.filteredAlbumsApiClient});

  Future<FilteredAlbums> getFilteredAlbums(String query) async {
    return filteredAlbumsApiClient.fetchFilteredAlbums(query);
  }
}

abstract class FilteredAlbumsEvent extends Equatable {
  const FilteredAlbumsEvent();
}

class FetchFilteredAlbums extends FilteredAlbumsEvent {
  final String query;

  const FetchFilteredAlbums({required this.query});

  @override
  List<Object> get props => [query];
}

class SortFilteredAlbums extends FilteredAlbumsEvent {
  final String sortBy;
  final FilteredAlbums filteredAlbums;

  const SortFilteredAlbums({required this.sortBy, required this.filteredAlbums});

  @override
  List<Object> get props => [sortBy, filteredAlbums];
}

class ErrorInFilteredAlbums extends FilteredAlbumsEvent {
  @override
  List<Object> get props => [];
}