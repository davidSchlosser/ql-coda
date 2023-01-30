import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('coverStream', Level.debug);

const defaultFilters = <String, dynamic>{
  'Added recently': '&(#(lastplayed > 20 days), #(added < 20 days))',
  'Any - no mood': '!mood=/[a-z]/',
  'Classical - no mood': '&(genre=/^Classical/, !mood=/[a-z]/)',
  'Jazz - no mood': '&(genre=/^Jazz/, !mood=/[a-z]/)'
};

class SavedFiltersBloc extends Bloc<SavedFiltersEvent, SavedFiltersState> {
  final SavedFiltersRepository savedFiltersRepository;

  SavedFiltersBloc({required this.savedFiltersRepository}) : super(SavedFiltersEmpty());

  SavedFiltersState get initialState => SavedFiltersEmpty();

  Stream<SavedFiltersState> mapEventToState(SavedFiltersEvent event) async* {
    if (event is FetchSavedFilters) {
      yield SavedFiltersLoading();
      try {
        final Map<String, dynamic> savedFilters = await savedFiltersRepository.getSavedFilters();
        yield SavedFiltersLoaded(savedFilters: savedFilters);
      } catch (e) {
        _logger.e('loading exception: $e');
        yield SavedFiltersError();
      }
    }
    if (event is StoreSavedFilters) {
      yield SavedFiltersLoading();
      savedFiltersRepository.storeSavedFilters();
    }
    if (event is SaveFilter) {
      await savedFiltersRepository.saveFilter(event.name, event.filter);
      add(const FetchSavedFilters());
    }
    if (event is UnSaveFilter) {
      await savedFiltersRepository.unsaveFilter(event.name);
      add(const FetchSavedFilters());
    }
    if (event is ErrorInSavedFilters) {
      yield SavedFiltersError();
    }
  }
}

class SavedFiltersRepository {
  final SavedFiltersApiClient savedFiltersApiClient;

  SavedFiltersRepository({required this.savedFiltersApiClient});

  Future <void> storeSavedFilters() async {
    return await savedFiltersApiClient.storeSavedFilters();
  }

  Future<void> saveFilter(String name, String filter) async {
    return await savedFiltersApiClient.save(name, filter);
  }

  Future<void> unsaveFilter(String name) async {
    return savedFiltersApiClient.unsave(name);
  }

  Future<Map<String, dynamic>> getSavedFilters() async {
    return savedFiltersApiClient.fetchSavedFilters();
  }
}

class SavedFiltersApiClient {
  static Map<String, dynamic> savedFilters = {};

  SavedFiltersApiClient();

  Future<Map<String, dynamic>> fetchSavedFilters() async {
    //final Map<String, dynamic> savedFilters = {};

    final directory = await getApplicationDocumentsDirectory();
    final File filtersFile = File('${directory.path}/saved_filters.txt');
    if (await filtersFile.exists()) {
      //print('filtersFile exists');
      String str = await filtersFile.readAsString();
      //print('filtersFile: $str');
      Map<String, dynamic> jStr = const JsonDecoder().convert(str);
      savedFilters.addAll(jStr);
    }
    else {
      _logger.d("filtersFile doesn't exist");
      savedFilters.addAll(defaultFilters);
    }
    return savedFilters;
  }

  Future save(String name, String filter) async {
    savedFilters[name] = filter;
    await storeSavedFilters();
    //await fetchSavedFilters();
  }

  Future unsave(String name) async {
    savedFilters.remove(name);
    await storeSavedFilters();
    await fetchSavedFilters();
  }

  Future storeSavedFilters() async { //storeSavedFilters(Map<String, dynamic> savedFilters) async {
    final directory = await getApplicationDocumentsDirectory();
    final File filtersFile = File('${directory.path}/saved_filters.txt');
    if (await filtersFile.exists()) {
      await filtersFile.delete();
    }
    await filtersFile.writeAsString(jsonEncode(savedFilters), mode: FileMode.append, flush: true);
  }
}

abstract class SavedFiltersState extends Equatable {
  const SavedFiltersState();

  @override
  List<Object> get props => [];
}

class SavedFiltersLoaded extends SavedFiltersState {
  final Map<String, dynamic> savedFilters;

  const SavedFiltersLoaded({ required this.savedFilters});

  @override
  List<Object> get props => [savedFilters];
}

class SavedFiltersEmpty extends SavedFiltersState {}
class SavedFiltersLoading extends SavedFiltersState {}
class SavedFiltersError extends SavedFiltersState {}

abstract class SavedFiltersEvent extends Equatable {
  const SavedFiltersEvent();
}

class FetchSavedFilters extends SavedFiltersEvent {
  const FetchSavedFilters();

  @override
  List<Object> get props => [];
}

class StoreSavedFilters extends SavedFiltersEvent {
  //final Map<String, dynamic> savedFilters;

  const StoreSavedFilters();
  //const StoreSavedFilters(this.savedFilters) : assert(savedFilters != null);

  @override
  List<Object> get props => []; //[savedFilters];
}

class SaveFilter extends SavedFiltersEvent {
  final String name, filter;
  const SaveFilter(this.name, this.filter);
  //SaveFilter(this.name, this.filter){print('SaveFilter');}
  @override
  List<Object> get props => [name, filter];
}

class UnSaveFilter extends SavedFiltersEvent {
  final String name;
  const UnSaveFilter(this.name);
  @override
  List<Object> get props => [name];
}

class ErrorInSavedFilters extends SavedFiltersEvent {
  @override
  List<Object> get props => [];
}