import 'dart:html';

import 'package:googleapis/youtube/v3.dart';

import 'duration.dart';
import 'move.dart';
import 'song.dart';
import 'spotify.dart' as spotify;
import 'youtube.dart';

class PlaylistElement {
  final String id;
  final String name;
  final String description;
  final String thumbnailUrl;
  final int songCount;
  final List<MoveElement> moves = [];
  HtmlElement e;

  PlaylistElement(
      this.id, this.name, this.description, this.thumbnailUrl, this.songCount) {
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

    for (var song in songs) {
      var moveElem = MoveElement(song);
      await moveElem.findSpotifyMatches();
      moves.add(moveElem);
    }
  }

  Future<void> move() async {
    print('Not implemented yet. lol.');
  }

  PlaylistElement.fromPlaylist(Playlist pl)
      : this(pl.id, pl.snippet.title, pl.snippet.description,
            pl.snippet.thumbnails.medium.url, pl.contentDetails.itemCount);

  Future<Iterable<Song>> getAllSongs() async {
    return (await _getAllVideos()).map((v) => _vidToSong(v));
  }

  Future<VideoListResponse> _getVideosOnPage(String pageToken) async {
    var response = await yt.playlistItems.list(
      ['contentDetails'],
      playlistId: id,
      maxResults: 50,
      pageToken: pageToken,
    );
    // make Videos out of PlaylistItems
    return (await yt.videos.list(
      ['snippet', 'contentDetails'],
      id: response.items
          .map((plItem) => plItem.contentDetails.videoId)
          .toList(),
      maxResults: 50,
    ))
      ..nextPageToken = response.nextPageToken;
  }

  Future<List<Video>> _getAllVideos(
      {String pageToken,
      bool musicOnly = true,
      bool firstPageOnly = false}) async {
    var videos = await _getVideosOnPage(pageToken);
    var output = videos.items;

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

    print('Got page $pageToken');

    if (!firstPageOnly && videos.nextPageToken != null) {
      output.addAll(await _getAllVideos(pageToken: videos.nextPageToken));
    }

    return output;
  }
}

Song _vidToSong(dynamic v) {
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
      : super('LL', 'Liked Songs', '', 'style/likes.png', songCount);

  @override
  Future<VideoListResponse> _getVideosOnPage(String pageToken) async {
    return await yt.videos.list(
      ['snippet', 'contentDetails'],
      myRating: 'like',
      maxResults: 50,
      pageToken: pageToken,
    );
  }

  @override
  Future<void> move() async {
    print('Moving all liked songs');
    var ids = moves.where((m) => m.match != null).map((e) => e.match.song.id);
    await spotify.likeTracks(ids);
    print('Moved $name!');
  }
}
