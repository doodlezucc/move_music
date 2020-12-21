import 'dart:html';

import 'dart/playlist.dart';
import 'dart/youtube.dart' as yt;

Iterable<PlaylistElement> _allPlaylists;
Iterable<PlaylistElement> get playlists =>
    _allPlaylists.where((pl) => !pl.ignored);

void main() {
  querySelector('#authYT').onClick.listen((event) async {
    await yt.initClient(true);
    _allPlaylists = (await yt.displayUserPlaylists()).toList();
  });
  querySelector('#submitPlaylists').onClick.listen((event) async {
    for (var pl in playlists) {
      await pl.displayAllMatches();
    }
  });
  querySelector('#move').onClick.listen((event) async {
    for (var pl in playlists) {
      await pl.move();
    }
  });

  document.onKeyPress.listen((event) {
    if (event.target is InputElement) return;
    if (event.key == 'R') {
      _reloadCss();
    }
  });
}

void _reloadCss() {
  querySelectorAll<LinkElement>('link').forEach((link) => link.href += '');
}
