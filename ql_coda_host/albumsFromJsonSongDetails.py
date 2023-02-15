"""
The input is a json list of maps containg data for each song
output desired is of the form
{
  "album": "Left of Cool",
  "artists": ["Béla Fleck","The Flecktones"],
  "dates": ["1998"],
  "genres": ["Jazz"],
  "styles": ["Fusion","Cool"],
  "mood": ["moderate","dynamic"],
  "directory": "/media/david/StarTechcom8Tb/qlMusic/Béla Fleck & The Flecktones - 1998, Left of Cool/",
}
input maps are like (leading & trailing single quotes included)
'{
    "album": "Left of Cool",
    "artist": "Béla Fleck & The Flecktones",
    "composer": "Béla Fleck",
    "date": "1998",
    "genre": "Jazz",
    "performer:banjo": "Béla Fleck",
    "performer:other": "The Flecktones",
    "title": "The Big Blink",
    "tracknumber": "14",
    "~#added": 1671770056,
    "~#bitrate": 320,
    "~#channels": 2,
    "~#filesize": 19112628,
    "~#lastplayed": 1672379086,
    "~#laststarted": 1672383797,
    "~#length": 477.70666666666665,
    "~#mtime": 1672287315.0196593,
    "~#playcount": 18,
    "~#samplerate": 44100,
    "~#skipcount": 7,
    "~encoding": "LAME 3.96.1+\nCBR\n-b 320",
    "~filename": "/media/david/StarTechcom8Tb/qlMusic/Béla Fleck & The Flecktones - 1998, Left of Cool/14 - The Big Blink.mp3",
    "~format": "MP3",
    "~mountpoint": "/media/david/StarTechcom8Tb"
 }'
"""

import json
import os

def albumsFromJsonSongDetails(jsonSongDetails):
    albums = {}  # map is keyed by album directory name

    for line in jsonSongDetails.splitlines():  # each line is a map of song tag details
        # decode the album record
        albumSummary = json.loads(line[1:-1])   # strip leading & trailing quotes

        # if the album directory isn't already in the albums
        if '~filename' not in albumSummary.keys():
            raise Exception("no album directory name found in input line: %s", line)
        else:
            # get the directory  from the song file name
            albumKey = os.path.dirname( os.path.abspath( albumSummary['~filename'] ) )
            # albumKey = albumSummary['~filename']

            if albumKey not in albums.keys():
                albums[albumKey] = {  # first song found for an album
                    'directory': albumKey,
                    'artists': set(),  # map to collect artists on this album
                    'genres': set(),  # etc
                    'styles': set(),
                    'dates': set(),
                    'moods': set()
                }

            albums[albumKey]['album'] = albumSummary['album']

            if 'artist' in albumSummary.keys():
                artists = albumSummary['artist'].split('\n')
                for artist in artists:
                    albums[albumKey]['artists'].add(artist)

            if 'genre' in albumSummary.keys():
                genres = albumSummary['genre'].split('\n')
                for genre in genres:
                    albums[albumKey]['genres'].add(genre)

            if 'date' in albumSummary.keys():
                dates = albumSummary['date'].split('\n')
                for date in dates:
                    albums[albumKey]['dates'].add(date)

            if 'style' in albumSummary.keys():
                styles = albumSummary['style'].split('\n')
                for style in styles:
                    albums[albumKey]['styles'].add(style)

            if 'mood' in albumSummary.keys():
                moods = albumSummary['mood'].split('\n')
                for mood in moods:
                    albums[albumKey]['moods'].add(mood)

    # create json compatible list of dict: lists
    albumsList = []
    for album in albums.values():
        # convert sets to lists where needed
        albumsList.append(
            {   'directory': album['directory'],
                'album': album['album'],
                'artists': list(album['artists']),
                'genres': list(album['genres']),
                'styles': list(album['styles']),
                'dates': list(album['dates']),
                'moods': list(album['moods']),
            }
        )

    return json.dumps(albumsList)
