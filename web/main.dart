import 'dart:html';

import 'dart/spotify.dart' as spotify;
import 'dart/youtube.dart' as yt;

void main() {
  querySelector('#output').text = 'Your Dart app is running.';

  querySelector('#authYT').onClick.listen((event) async {
    await yt.initClient(true);
    await yt.displayUserPlaylists();
  });
  querySelector('#searchSpotify').onClick.listen((event) async {
    await spotify.search('what once was');
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
