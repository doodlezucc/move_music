import 'dart:html';

import 'dart/move.dart';
import 'dart/playlist.dart';
import 'dart/song.dart';
import 'dart/youtube.dart' as yt;

Iterable<PlaylistElement> _allPlaylists;
Iterable<PlaylistElement> get playlists =>
    _allPlaylists.where((pl) => !pl.ignored);

void main() {
  querySelector('#authYT').onClick.listen((event) async {
    await yt.initClient(true);
    _allPlaylists = (await yt.displayUserPlaylists()).toList();
  });
  querySelector('#submitPlaylists').onClick.listen((event) async {
    for (var pl in playlists) {
      await pl.displayAllMatches();
    }
  });
  querySelector('#move').onClick.listen((event) async {
    for (var pl in playlists) {
      await pl.move();
    }
  });

  document.onKeyPress.listen((event) {
    if (event.target is InputElement) return;
    if (event.key == 'R') {
      _reloadCss();
    }
  });

  _testMoveElems();
}

void _reloadCss() {
  querySelectorAll<LinkElement>('link').forEach((link) => link.href += '');
}

void _testMoveElems() {
  MoveElement(Song(
      name: 'Cool With You',
      artists: ["Her's"],
      id: '',
      coverArtUrl: 'style/likes.png',
      duration: Duration(minutes: 2, seconds: 51)))
    ..findSpotifyMatches();
  MoveElement(YouTubeSong(
      name: 'Her\'s - "Cool With You"',
      artists: ['random youtube channel'], // missing YTM " - Topic" suffix
      id: '',
      coverArtUrl: 'style/likes.png',
      duration: Duration(minutes: 2, seconds: 51)))
    ..findSpotifyMatches();
  MoveElement(YouTubeSong(
      name: 'still feel.',
      artists: ['half·alive - Topic'],
      id: '',
      coverArtUrl: 'style/likes.png',
      duration: Duration(hours: 1, seconds: 123)))
    ..findSpotifyMatches();
  MoveElement(YouTubeSong(
      name: 'jkashfkjahsf',
      artists: ['random youtube channel'],
      id: '',
      coverArtUrl: 'style/likes.png',
      duration: Duration(minutes: 2, seconds: 51)))
    ..findSpotifyMatches();
}
