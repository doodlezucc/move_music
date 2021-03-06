import 'dart:async';
import 'dart:html';

import 'dart/duration.dart';
import 'dart/move.dart';
import 'dart/playlist.dart';
import 'dart/process_log.dart';
import 'dart/song.dart';
import 'dart/youtube.dart' as yt;
import 'dart/spotify.dart' as spotify;

Iterable<PlaylistElement> _allPlaylists;
Iterable<MoveElement> _allArtists;
Iterable<PlaylistElement> get playlists =>
    _allPlaylists.where((pl) => !pl.ignored);

bool showMatched = false;

final ButtonElement authButton = querySelector('#authYT');
final ButtonElement submitPLButton = querySelector('#submitPlaylists');
final ButtonElement plAllButton = querySelector('#selectAll');
final ButtonElement plNoneButton = querySelector('#selectNone');

void onPlaylistToggle() {
  var selected = playlists.length;
  submitPLButton.text = selected > 0
      ? 'Continue with $selected playlist' + plural(selected)
      : 'Only move followed artists';
  plAllButton.disabled = _allPlaylists.length == selected;
  plNoneButton.disabled = selected == 0;
}

void main() async {
  StreamSubscription keyListener;
  authButton.onClick.listen((event) async {
    authButton.disabled = true;
    if (!await yt.initClient(false)) {
      return authButton.disabled = false;
    }
    _allPlaylists = await yt.displayUserPlaylists().toList();
    onPlaylistToggle();
    keyListener = document.onKeyDown.listen((event) {
      if (event.ctrlKey && event.key == 'a') {
        event.preventDefault();
        setAllPlaylistsIgnored(playlists.length == _allPlaylists.length);
      }
    });
    changeSection('#playlistSection');
    await spotify.ensureCredentials();
    _allArtists = await yt.displayFollowedArtistsMatches().toList();
    maxSearches = _allArtists.length;
  });

  plAllButton.onClick.listen((_) => setAllPlaylistsIgnored(false));
  plNoneButton.onClick.listen((_) => setAllPlaylistsIgnored(true));

  querySelector('#submitPlaylists').onClick.listen((event) async {
    await keyListener?.cancel();
    maxSearches = _allArtists.length +
        playlists.fold(
            0, (previousValue, element) => previousValue + element.songCount);
    updateSearchProgress();
    changeSection('#conflictSection');
    for (var pl in playlists) {
      await pl.displayAllMatches();
    }
    searchDone = true;
    querySelector('#conflictSub')
      ..classes.toggle('hidden', conflicts > 0)
      ..text = 'Everything can be moved!';
    moveButton.disabled = false;
  });

  var showBtn = querySelector('#showMatched');
  var conflictsContainer = querySelector('#conflicts');

  showBtn.onClick.listen((event) {
    showMatched = !showMatched;
    showBtn.classes.toggle('checked', showMatched);
    conflictsContainer.classes.toggle('hide-matched', !showMatched);
  });

  querySelector('#orderYes').onClick.listen((_) => move(true));
  querySelector('#orderNo').onClick.listen((_) => move(false));
  moveButton.onClick.listen((_) {
    var likesPl = playlists.singleWhere(
      (element) => element is LikesPlaylistElement,
      orElse: () => null,
    );
    if (likesPl != null) {
      var likes =
          likesPl.itemIds.where((id) => allIdMoves[id].match?.target != null);

      querySelector('#orderTime').text = durationSpelledOut(
          (spotify.millisPerLike * likes.length / 1000).ceil());
      querySelector('#likesCount').text = likes.length.toString();
      changeSection('#likesSection');
    } else {
      move();
    }
  });

  document.onKeyPress.listen((event) {
    if (event.target is InputElement) return;
    if (event.key == 'R') {
      _reloadCss();
    }
  });

  // Initialize section animations
  await Future.delayed(Duration(milliseconds: 500));
  querySelectorAll('.section').classes.add('init');

  var test = false;
  if (test) {
    _testMoveElems();
  }
}

void setAllPlaylistsIgnored(bool ignoreAll) {
  _allPlaylists.forEach((pl) => pl.ignored = ignoreAll);
  onPlaylistToggle();
}

Future<void> move([bool orderMatters]) async {
  moveButton.disabled = true;
  if (!await spotify.ensureGrant()) {
    return moveButton.disabled = false;
  }

  var exitBlock = window.onBeforeUnload.listen((e) {
    (e as BeforeUnloadEvent).returnValue = 'Not everything has been moved yet!';
  });

  changeSection('#processSection');
  await spotify.followArtists(
      _allArtists.where((a) => a.match != null).map((a) => a.match.target.id));
  for (var pl in playlists.toList().reversed) {
    if (pl is LikesPlaylistElement) pl.orderMatters = orderMatters;
    await pl.move();
  }
  Line('Done!').finish();
  await exitBlock.cancel();
  (querySelector('#openDestination') as ButtonElement).disabled = false;
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
