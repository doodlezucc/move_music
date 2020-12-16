import 'dart:html';

import 'package:googleapis/youtube/v3.dart';

import 'move.dart';
import 'song.dart';
import 'youtube.dart';

class PlaylistElement {
  final String name;
  final String description;
  final String thumbnailUrl;
  final int songCount;
  HtmlElement e;

  PlaylistElement(
      this.name, this.description, this.thumbnailUrl, this.songCount) {
    e = DivElement()
      ..className = 'playlist'
      ..append(ImageElement(src: thumbnailUrl))
      ..append(DivElement()
        ..className = 'meta'
        ..append(HeadingElement.h3()..text = name)
        ..append(SpanElement()..text = '$songCount Songs\n$description'))
      ..onClick.listen((event) async {
        print('Getting all songs of $name');
        var songs = await getAllSongs();
        songs = songs.take(10);
        for (var song in songs) {
          var matches = await searchSongMatches(song);
          matches.forEach((m) {
            print(
                '${m.song.artists.first} - "${m.song.name}" (${m.similarity * 100}%)');
          });
        }
      });
    querySelector('#playlists').append(e);
  }

  PlaylistElement.fromPlaylist(Playlist pl)
      : this(pl.snippet.title, pl.snippet.description,
            pl.snippet.thumbnails.medium.url, pl.contentDetails.itemCount);

  Future<Iterable<Song>> getAllSongs() async {
    return [];
  }
}

class LikesPlaylistElement extends PlaylistElement {
  LikesPlaylistElement(int songCount)
      : super('Liked Songs', '', 'style/likes.png', songCount);

  @override
  Future<Iterable<Song>> getAllSongs() async {
    var videos = await retrieveLikedVideos(firstPageOnly: true);
    return videos
        .map((e) => Song(e.snippet.title, [e.snippet.channelTitle], e.id));
  }

  Future<List<Video>> retrieveLikedVideos(
      {String pageToken,
      bool musicOnly = true,
      bool firstPageOnly = false}) async {
    var likes = await yt.videos.list(
      ['snippet'],
      myRating: 'like',
      maxResults: 50,
      pageToken: pageToken,
    );

    //print(JsonEncoder.withIndent(' ').convert(likes.toJson()));

    var output = likes.items;

    if (musicOnly) {
      var size = output.length;
      output = output.where((vid) {
        if (vid.snippet.categoryId == '10') {
          return true;
        }
        print('SKIPPING: ' + vid.snippet.title);
        return false;
      }).toList();
      if (size > output.length) {
        print('${size - output.length} non-music videos skipped.');
      }
    }

    if (!firstPageOnly && likes.nextPageToken != null) {
      output.addAll(await retrieveLikedVideos(pageToken: likes.nextPageToken));
    }

    return output;
  }
}
