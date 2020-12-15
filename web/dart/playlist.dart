import 'dart:html';

import 'package:googleapis/youtube/v3.dart';

class PlaylistElement {
  final String name;
  final String description;
  final String thumbnailUrl;
  HtmlElement e;

  PlaylistElement(this.name, this.description, this.thumbnailUrl) {
    e = DivElement()
      ..className = 'playlist'
      ..append(ImageElement(src: thumbnailUrl))
      ..append(DivElement()
        ..className = 'meta'
        ..append(HeadingElement.h3()..text = name)
        ..append(SpanElement()..text = description));
    querySelector('#playlists').append(e);
  }

  PlaylistElement.fromPlaylist(Playlist pl)
      : this(pl.snippet.title, pl.snippet.description,
            pl.snippet.thumbnails.medium.url);
}

class LikesPlaylistElement extends PlaylistElement {
  LikesPlaylistElement() : super('Liked songs', '', 'style/likes.png');
}
