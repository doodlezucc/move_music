import 'dart:html';

import 'spotify.dart';
import 'youtube.dart';

void main() {
  querySelector('#output').text = 'Your Dart app is running.';

  querySelector('#authYT').onClick.listen((event) {
    initClient();
  });
  querySelector('#authSpotify').onClick.listen((event) {
    search('what once was');
  });
}
