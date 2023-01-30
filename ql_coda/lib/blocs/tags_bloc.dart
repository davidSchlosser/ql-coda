import 'package:coda/logger.dart';
import 'package:logger/logger.dart';
import 'package:bloc/bloc.dart';
import 'package:coda/repositories/repositories.dart';
import 'package:coda/models/tags_model.dart';
import 'package:coda/blocs/blocs.dart';

Logger _logger = getLogger('EditTags', Level.info);

class TagsBloc extends Bloc<TagsEvent, TagsState> {
  final TagsRepository tagsRepository;

  TagsBloc({required this.tagsRepository}) : super(TagsEmpty());
  //TagsBloc({required this.tagsRepository});

  //@override
  TagsState get initialState => TagsEmpty();

  //@override
  Stream<TagsState> mapEventToState(TagsEvent event) async* {
    if (event is FetchTags) {
      yield TagsLoading();
      try {
        final Tags tags = await tagsRepository.getTags(event.song);
        yield TagsLoaded(tags: tags);
      } catch (e) {
        _logger.e('tagsError: $e');
        yield TagsError();
      }
    }
    if (event is UpdateTags) {
      _logger.d('event is UpdateTags');
      yield TagsLoading();
      try {
        yield TagsLoaded(tags: event.tags);
      } catch (_) {
        yield TagsError();
      }
    }
  }
}
