import 'dart:html';

import 'package:googleapis/youtube/v3.dart';

import 'duration.dart';
import 'move.dart';
import 'song.dart';
import 'spotify.dart' as spotify;
import 'youtube.dart';

class PlaylistElement {
  final String name;
  final String description;
  final String thumbnailUrl;
  final int songCount;
  final List<MoveElement> moves = [];
  HtmlElement e;

  PlaylistElement(
      this.name, this.description, this.thumbnailUrl, this.songCount) {
    e = LIElement()
      ..className = 'playlist'
      ..append(ImageElement(src: thumbnailUrl)..className = 'square')
      ..append(DivElement()
        ..className = 'meta'
        ..append(HeadingElement.h3()..text = name)
        ..append(SpanElement()..text = '$songCount Songs\n$description'))
      ..onClick.listen((event) => displayAllMatches());
    querySelector('#playlists').append(e);
  }

  Future<void> displayAllMatches() async {
    print('Getting all songs of $name');
    var songs = await getAllSongs();
    songs = songs.take(10);

    for (var song in songs) {
      var moveElem = MoveElement(song);
      await moveElem.findSpotifyMatches();
      moves.add(moveElem);
    }

    await move();
  }

  Future<void> move() async {
    print('Not implemented yet. lol.');
  }

  PlaylistElement.fromPlaylist(Playlist pl)
      : this(pl.snippet.title, pl.snippet.description,
            pl.snippet.thumbnails.medium.url, pl.contentDetails.itemCount);

  Future<Iterable<Song>> getAllSongs() async {
    return [];
  }
}

Song _vidToSong(Video v) {
  return Song(
    name: v.snippet.title,
    artists: [v.snippet.channelTitle],
    id: v.id,
    coverArtUrl: v.snippet.thumbnails.medium.url,
    duration: parseIsoDuration(v.contentDetails.duration),
  );
}

class LikesPlaylistElement extends PlaylistElement {
  LikesPlaylistElement(int songCount)
      : super('Liked Songs', '', 'style/likes.png', songCount);

  @override
  Future<Iterable<Song>> getAllSongs() async {
    var videos = await retrieveLikedVideos(firstPageOnly: true);
    return videos.map((v) => _vidToSong(v));
  }

  Future<List<Video>> retrieveLikedVideos(
      {String pageToken,
      bool musicOnly = true,
      bool firstPageOnly = false}) async {
    var likes = await yt.videos.list(
      ['snippet', 'contentDetails'],
      myRating: 'like',
      maxResults: 50,
      pageToken: pageToken,
    );

    var output = likes.items;

    if (musicOnly) {
      var size = output.length;
      output = output.where((vid) {
        // 10 means Music
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

  @override
  Future<void> move() async {
    print('Moving all liked songs');
    var ids = moves.where((m) => m.match != null).map((e) => e.match.id);
    await spotify.likeTracks(ids);
    print('Moved $name!');
  }
}
