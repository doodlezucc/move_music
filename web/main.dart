import 'dart:html';

import 'dart/spotify.dart' as spotify;
import 'dart/youtube.dart' as yt;

void main() {
  querySelector('#output').text = 'Your Dart app is running.';

  querySelector('#authYT').onClick.listen((event) async {
    await yt.initClient(true);
    await yt.displayUserPlaylists();
  });
  querySelector('#authSpotify').onClick.listen((event) async {
    await spotify.search('what once was');
  });
}
