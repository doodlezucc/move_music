import 'dart:html';

import 'package:googleapis/youtube/v3.dart';

import '../main.dart';
import 'duration.dart';
import 'helpers.dart';
import 'move.dart';
import 'song.dart';
import 'spotify.dart' as spotify;
import 'youtube.dart';

final Map<String, MoveElement> allIdMoves = {};

abstract class PlaylistElement {
  final String id;
  final String name;
  final String description;
  final String thumbnailUrl;
  final int songCount;
  final List<String> itemIds = [];
  HtmlElement e;
  bool get ignored => e.classes.contains('ignored');
  set ignored(bool v) {
    e.classes.toggle('ignored', v);
  }

  PlaylistElement(
      this.id, this.name, this.description, this.thumbnailUrl, this.songCount) {
    e = LIElement()
      ..className = 'playlist responsive'
      ..append(squareImage(src: thumbnailUrl))
      ..append(DivElement()
        ..className = 'meta'
        ..append(HeadingElement.h3()..text = name)
        ..append(SpanElement()..innerHtml = '$songCount Songs<br>$description'))
      ..onClick.listen((event) {
        e.classes.toggle('ignored');
        onPlaylistToggle();
      });
    querySelector('#playlists').append(e);
  }

  Future<void> displayAllMatches() async {
    await for (var song in getAllSongs()) {
      if (!allIdMoves.containsKey(song.id)) {
        var moveElem = MoveElement(song);
        allIdMoves[song.id] = moveElem;
        await moveElem.findSpotifyMatches();
      }
      itemIds.add(song.id);
    }
  }

  Future<void> move() async {
    var matchedSongs = List<Song>.from(itemIds
        .map((id) => allIdMoves[id].match?.target)
        .where((song) => song != null));

    if (matchedSongs.isEmpty) {
      print('Playlist $name will not be moved because no matches were found.');
      return;
    }

    await _move(matchedSongs);
  }

  Future<void> _move(Iterable<Song> songs);

  PlaylistElement.fromPlaylist(Playlist pl)
      : this(pl.id, pl.snippet.title, pl.snippet.description,
            pl.snippet.thumbnails.medium.url, pl.contentDetails.itemCount);

  Stream<Song> getAllSongs();
}

class YouTubePlaylistElement extends PlaylistElement {
  YouTubePlaylistElement._likes(int songCount)
      : super('LL', 'Liked Songs', '', 'style/likes.png', songCount);

  YouTubePlaylistElement.fromPlaylist(Playlist pl)
      : super(pl.id, pl.snippet.title, pl.snippet.description,
            pl.snippet.thumbnails.medium.url, pl.contentDetails.itemCount);

  @override
  Stream<Song> getAllSongs() async* {
    await for (var video in getAllVideos()) {
      yield vidToSong(video);
    }
  }

  Future<VideoListResponse> getVideosOnPage(String pageToken) async {
    var response = await yt.playlistItems.list(
      ['contentDetails'],
      playlistId: id,
      maxResults: 50,
      pageToken: pageToken,
    );
    // make Videos out of PlaylistItems
    return (await yt.videos.list(
      ['snippet', 'contentDetails', 'statistics'],
      id: response.items
          .map((plItem) => plItem.contentDetails.videoId)
          .toList(),
      maxResults: 50,
    ))
      ..nextPageToken = response.nextPageToken;
  }

  Stream<Video> getAllVideos(
      {String pageToken,
      bool musicOnly = true,
      bool firstPageOnly = false}) async* {
    var videos = await getVideosOnPage(pageToken);
    var output = videos.items;

    if (musicOnly) {
      output = output.where((vid) {
        // 10 means Music
        if (vid.snippet.categoryId == '10') {
          return true;
        }
        print('Skipping "${vid.snippet.title}" (not categorized as music)');
        return false;
      }).toList();
    }

    yield* Stream.fromIterable(output);

    if (!firstPageOnly && videos.nextPageToken != null) {
      yield* getAllVideos(pageToken: videos.nextPageToken);
    }
  }

  @override
  Future<void> _move(Iterable<Song> matchedSongs) async {
    await spotify.createPlaylist(
        name, description, matchedSongs.map((e) => e.id));
  }

  static YouTubeSong vidToSong(Video v) {
    return YouTubeSong(
      name: v.snippet.title,
      artists: [v.snippet.channelTitle],
      id: v.id,
      coverArtUrl: v.snippet.thumbnails.medium.url,
      duration: parseIsoDuration(v.contentDetails.duration),
      views: int.parse(v.statistics.viewCount),
    );
  }
}

class LikesPlaylistElement extends YouTubePlaylistElement {
  bool orderMatters = false;

  LikesPlaylistElement(int songCount) : super._likes(songCount);

  @override
  Future<VideoListResponse> getVideosOnPage(String pageToken) async {
    return await yt.videos.list(
      ['snippet', 'contentDetails', 'statistics'],
      myRating: 'like',
      maxResults: 50,
      pageToken: pageToken,
    );
  }

  @override
  Future<void> _move(Iterable<Song> matchedSongs) async {
    var ids = matchedSongs.map((song) => song.id);
    await spotify.likeTracks(ids, orderMatters: orderMatters);
  }
}
