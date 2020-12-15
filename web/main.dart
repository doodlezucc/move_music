import 'dart:html';

import 'youtube.dart';

void main() {
  querySelector('#output').text = 'Your Dart app is running.';

  querySelector('#authYT').onClick.listen((event) {
    initClient();
  });
}
