import 'dart:html';

import 'dart/move.dart';
import 'dart/playlist.dart';
import 'dart/song.dart';
import 'dart/youtube.dart' as yt;
import 'dart/spotify.dart' as spotify;

Iterable<PlaylistElement> _allPlaylists;
Iterable<MoveElement> _allArtists;
Iterable<PlaylistElement> get playlists =>
    _allPlaylists.where((pl) => !pl.ignored);

bool showMatched = false;

final ButtonElement moveButton = querySelector('#move');

void main() {
  querySelector('#authYT').onClick.listen((event) async {
    await yt.initClient(true);
    changeSection('#playlistSection');
    _allPlaylists = await yt.displayUserPlaylists().toList();
    _allArtists = await yt.displayFollowedArtistsMatches().toList();
    maxSearches = _allArtists.length;
  });
  querySelector('#submitPlaylists').onClick.listen((event) async {
    maxSearches = _allArtists.length +
        playlists.fold(
            0, (previousValue, element) => previousValue + element.songCount);
    changeSection('#conflictSection');
    for (var pl in playlists) {
      await pl.displayAllMatches();
    }
    querySelector('#conflictProgress').remove();
    moveButton.disabled = false;
  });
  moveButton.onClick.listen((event) async {
    moveButton.disabled = true;
    if (!await spotify.ensureGrant()) {
      return moveButton.disabled = false;
    }

    changeSection('#processSection');
    await spotify.followArtists(_allArtists
        .where((a) => a.match != null)
        .map((a) => a.match.target.id));
    for (var pl in playlists) {
      await pl.move();
    }
  });

  var showBtn = querySelector('#showMatched');
  var conflicts = querySelector('#conflicts');

  showBtn.onClick.listen((event) {
    showMatched = !showMatched;
    showBtn.classes.toggle('checked', showMatched);
    conflicts.classes.toggle('hide-matched', !showMatched);
  });

  document.onKeyPress.listen((event) {
    if (event.target is InputElement) return;
    if (event.key == 'R') {
      _reloadCss();
    }
  });

  var test = false;
  if (test) {
    _testMoveElems();
  }
}

void _reloadCss() {
  querySelectorAll<LinkElement>('link').forEach((link) => link.href += '');
}

void changeSection(String next) {
  querySelector('.section.show').classes.remove('show');
  querySelector(next).classes.add('show');
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
      name: '爱多甜蜜',
      artists: ['刘初寻（二逗）＋曾溢（小五） & 曾溢'],
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
