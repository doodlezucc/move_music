import 'dart:html';

import 'dart/playlist.dart';
import 'dart/spotify.dart' as spotify;
import 'dart/youtube.dart' as yt;

void main() {
  List<PlaylistElement> playlists;

  querySelector('#authYT').onClick.listen((event) async {
    await yt.initClient(true);
    playlists = (await yt.displayUserPlaylists()).toList();
  });
  querySelector('#searchSpotify').onClick.listen((event) async {
    await spotify.search('what once was');
  });
  querySelector('#authSpotify').onClick.listen((event) async {
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
