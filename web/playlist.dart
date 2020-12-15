import 'dart:html';

import 'package:googleapis/youtube/v3.dart';

class PlaylistElement {
  final Playlist pl;
  HtmlElement e;

  PlaylistElement(this.pl) {
    var snippet = pl.snippet;

    e = DivElement()
      ..className = 'playlist'
      ..append(ImageElement(src: snippet.thumbnails.medium.url))
      ..append(DivElement()
        ..className = 'meta'
        ..append(HeadingElement.h3()..text = snippet.title)
        ..append(SpanElement()..text = snippet.description));
    querySelector('#playlists').append(e);
  }
}
