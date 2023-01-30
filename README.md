# ql_coda
A remote browser and controller for the Quodlibet music player. 
## Features:
+ view currrent track, progress bar, volume control, skip to next, previous, random track
+ edit any track tags (including custom ones) and view metadata.
+ view playlist.
+ browse albums, create filter using Quodlibet queries , browse tracks
+ add albums and tracks to Quodlibet queue.
+ browse queue, remove tracks from queue.
## Motivation.
Other remote options provide basic player control and track information but dont offer access to some of Quodlibet's major strengths such. as rich tagging and querying.
## Platforms
+ Android, Linux desktop 
+ ql_coda is written in Flutter and Dart so should be deployaable to iOS iPhone, web, and Mac, Windows desktops where Flutter is supported. ql_coda hasn't been tested with other MQTT providers.
## Dependencies:
+ Quodlibet and Operon 4.6
+ Quodlibet MQTT plugin
+ MQTT tranport (eg Mosquitto)
+ ql_coda_host running on the Quodlibet host+ ql_coda_host running on the Quodlibet host
