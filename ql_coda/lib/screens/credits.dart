import 'package:coda/blocs/tags_bloc.dart';
import 'package:coda/logger.dart';
import 'package:coda/models/tags_model.dart';
//import 'package:co2/models/playlist.dart';
//import 'package:coda/screens/google_icon_button.dart';
import 'package:coda/screens/ui_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:logger/logger.dart';
import 'package:coda/repositories/repositories.dart';


Logger _logger = getLogger('CreditsPage', Level.info);

class Credits extends StatefulWidget {
  final List<dynamic> _playlist;

  const Credits(this._playlist, {super.key});

  @override
  CreditsState createState() => CreditsState();
}

class CreditsState extends State<Credits> {
  static final Map _credits = {};

  final TagsRepository tagsRepository = TagsRepository(
    tagsApiClient: TagsApiClient(),
  );

  @override
  void initState() {
    //_logger.d('initState: ${widget._playlist}');
    _credits.clear();
    _credits.addAll(_extractCredits(widget._playlist));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => TagsBloc(tagsRepository: tagsRepository),
    child: Scaffold(
        appBar: AppBar(
          title: const Text('Playlist Credits'),
          actions: <Widget>[
            // TODO GoogleIconButton(), // TODO webview SDK dependency problem here
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.floppyDisk),
              onPressed: (){
                _logger.d('pressed save');
              },
            )
          ],
        ),
        body: ListView(
          //
          // TODO sort alphabetically
          //
          children: [... _credits.entries.map((cred) {
            //_logger.d('cred.value: ${cred.value.toString()}');
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditCredit(cred.key, cred.value)),
                );},
              child: Card(        // TODO BoxConstraints bug
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(cred.key,    // Role
                        style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 12.0),
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 2.0)),
                      ... cred.value.entries.map((performance){
                        return Text(
                          '${performance.key} (${readable(performance.value)})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16.0,
                          ),
                        );
                      }),
                    ],
                  ),
                )
              ),
            );
          })],
        ),
      floatingActionButton:  FloatingActionButton(
        child: const Icon(Icons.add_comment),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddCredit()), //EditPage(Player.currentTrackFile)),
          );
        },
      ),
    ));
  }
}

class AddCredit extends StatelessWidget {
  const AddCredit({super.key});

  @override
  Widget build(BuildContext context) {
    // return Container(child: const Text('add'));
    return const Text('add');
  }
}

class EditCredit extends StatefulWidget {
  final String role; // {role: {artist: {disc: [tracks]}}}
  final Map performances;

  const EditCredit(this.role, this.performances, {super.key});

  @override
  EditCreditState createState() => EditCreditState();
}

class EditCreditState extends State<EditCredit> {
  final _formKey = GlobalKey<FormState>();
  final roleController = TextEditingController();
  final artistController = TextEditingController();
  final trackController = TextEditingController();
  final List<String> roleMatches = TagCache().valuesFor('role');
  final List<String> artistMatches = TagCache().valuesFor('artist');

  @override
  void initState() {
    // TODO: implement initState
    roleController.text = widget.role;
    //artistController.text = widget.
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit credit'),
      content: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                autofocus: false,
                // following avoids [VERBOSE-2:ui_dart_state.cc(157)] Unhandled Exception: NoSuchMethodError: The method 'call' was called on null.
                onChanged: (_){},
                controller: roleController,
                decoration: const InputDecoration(
                  labelText: 'Role',
                ),
              ),
              suggestionsCallback: (pattern) {
                if (roleMatches.isNotEmpty) {
                  roleMatches.retainWhere(
                          (s) => s.toLowerCase().startsWith(pattern.toLowerCase()));
                }
                return roleMatches;
              },
              transitionBuilder: (context, suggestionsBox, controller) {
                return suggestionsBox;
              },
              itemBuilder: (context, suggestion) {
                return Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(suggestion),
                );
              },
              onSuggestionSelected: (suggestion) {
                roleController.text = suggestion;
              },
              validator:  (value) {
                if (value == null || value.isEmpty) {
                  return 'This can\'t be blank';
                }
                return null;
              },
            ),
            TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                autofocus: false,
                // following avoids [VERBOSE-2:ui_dart_state.cc(157)] Unhandled Exception: NoSuchMethodError: The method 'call' was called on null.
                onChanged: (_){},
                controller: artistController,
                decoration: const InputDecoration(
                  labelText: 'Artist-performer',
                ),
              ),
              suggestionsCallback: (pattern) {
                if (artistMatches.isNotEmpty) {
                  artistMatches.retainWhere(
                          (s) => s.toLowerCase().startsWith(pattern.toLowerCase()));
                }
                return artistMatches;
              },
              transitionBuilder: (context, suggestionsBox, controller) {
                return suggestionsBox;
              },
              itemBuilder: (context, suggestion) {
                return Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(suggestion),
                );
              },
              onSuggestionSelected: (suggestion) {
                artistController.text = suggestion;
              },
              validator: (value) {
                if (value!.isEmpty) {
                  return 'This can\'t be blank';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'disc:tracks'),
              //initialValue: ,
              validator: (String? text) { return null;},
            )
          ])),
      actions: [
        TextButton(
          child: const Icon(Icons.done), //Text('Done'),
          onPressed: () {
            _logger.d('in Done onPressed');
            Navigator.of(context).pop();
            if (_formKey.currentState!.validate()) {
              _logger.d('in Done validated');
            }
          },
        ),
      ],

    );
  }
}


String readable(Map discTracks) {
  List sortedDiscs = discTracks.keys.toList()..sort();

  String ret = '';

  for (var disc in sortedDiscs) {
    List sortedTracks = discTracks[disc]..sort();

    if (ret.isNotEmpty) { ret += '; '; }
    ret += disc == 0 ? '' : 'disc${disc.toString()}: ';
    ret += sortedTracks.join(',');

  }

  return ret;
}

Map _extractCredits(List<dynamic> playlist) {
  final Map credits = {}; // {role: {artist: {disc: [tracks]}}}
  final RegExp reRole = RegExp(r'\((.+)\)');
  Iterable bracketMatches;

  for (var trackDetail in playlist) {
    List<String> performers = performerRoles(trackDetail['performers']);
    int track = int.parse(trackDetail['track']);
    int disc = (trackDetail['disc'].isNotEmpty) ? int.parse(trackDetail['disc']) : 0;
    // Billy Cobham (Drums),  Jack DeJohnette (Drums),  Dave Holland (Bass,  Electric bass),  Chick Corea (Electric piano),  Joe Zawinul (Electric piano),  Miles Davis (Trumpet),  Khalil Balakrishna (Sitar),  Airto Moreira (Percussion),  Steve Grossman (Soprano saxophone),  Wayne Shorter (Soprano saxophone),  Teo Macero (Producer),  John McLaughlin (Guitar),  Bennie Maupin (Bass clarinet)

    for (var performer in performers) {
      if (performer.trim().isNotEmpty) {

        //_logger.d('_performer: $_performer');
        List<String> roles, artists;
        String rolesPart, artistsPart;

        if (!reRole.hasMatch(performer)) {
          rolesPart = '';
          artistsPart = performer;
        }
        else {
          bracketMatches = reRole.allMatches(performer);
          rolesPart = performer.substring(
              bracketMatches.last.start + 1, performer.length - 1);
          artistsPart = performer.substring(0, bracketMatches.last.start);
        }

        // TODO roles, artists
        roles = rolesPart.split(',');
        artists = artistsPart.split(',');
        //roles = roles.map((String r){}).toList();
        //artists = artists.map((String r){;}).toList();
        //roles = roles.map((String r){continue;}).toList();
        //artists = artists.map((String r){continue;}).toList();

        //_logger.d('roles: $roles, artists = $artists');

        for (var role in roles) {
          if (credits.containsKey(role)) {
            for (var artist in artists) {
              //_logger.d('credits[role]: ${credits[role]}');
              if (credits[role].containsKey(artist)) {
                if (credits[role][artist].containsKey(disc)) {
                  credits[role][artist][disc].add(track);
                } else {
                  credits[role][artist][disc] = [track];
                }
              }
              else {
                credits[role][artist] = {disc: [track]};
              }
            }
          }
          else {
            credits[role] = {};
            for (var artist in artists) {
              credits[role][artist] = {disc: [track]};
            }
          }
        }
      }
    }
  }
  //_logger.d('credits: $credits');
  return credits;
}
