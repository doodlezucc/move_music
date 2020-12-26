import 'dart:async';
import 'dart:html';

import 'package:spotify/spotify.dart';

import 'artist.dart' as artist;
import 'helpers.dart';
import 'song.dart';

SpotifyApiCredentials credentials;
SpotifyApi spotify;
bool gotUserGrant = false;
User user;

Future<void> ensureCredentials() async {
  if (spotify != null) return;

  var clientSecret = await HttpRequest.getString('client_secret');

  credentials = SpotifyApiCredentials(
    '14785ba1a003421cbef0535ced0159ae',
    clientSecret,
  );
  spotify = SpotifyApi(credentials);
}

Future<Iterable<Song>> searchSong(String query) async {
  await ensureCredentials();
  var bundledPages = spotify.search.get(query, types: [SearchType.track]);

  var page = (await bundledPages.first(5)).first;
  var tracks = List<Track>.from(page.items);
  return tracks.map((s) => Song(
        name: s.name,
        artists: s.artists.map((e) => e.name),
        id: s.id,
        coverArtUrl: s.album.images.first.url,
        duration: s.duration,
        popularity: s.popularity,
      ));
}

Future<Iterable<artist.Artist>> searchArtist(String query) async {
  await ensureCredentials();
  var bundledPages = spotify.search.get(query, types: [SearchType.artist]);

  var page = (await bundledPages.first(5)).first;
  var artists = List<Artist>.from(page.items);
  return artists.map((a) => artist.Artist(
        id: a.id,
        name: a.name,
        pictureUrl: a.images.isNotEmpty ? a.images.first.url : '',
        popularity: a.popularity,
      ));
}

Future<bool> ensureGrant() async {
  if (gotUserGrant) return true;
  await ensureCredentials();

  var grant = SpotifyApi.authorizationCodeGrant(credentials);
  var redirectUri = 'http://localhost:8080/spotify/callback.html';
  var authUri = grant.getAuthorizationUrl(
    Uri.parse(redirectUri),
    scopes: [
      'user-library-modify',
      'playlist-modify-private',
      'user-follow-modify'
    ],
  );

  var completer = Completer<bool>();

  var popup = openCenteredPopup(
    authUri.toString(),
    name: 'Spotify Authorization',
  );

  StreamSubscription sub;
  var checkClosed = Timer.periodic(Duration(milliseconds: 100), (timer) {
    if (popup.closed) {
      timer.cancel();
      sub.cancel();
      completer.complete(false);
    }
  });

  // Wait for the pop-up to notify this window
  sub = window.onMessage.listen((e) {
    if (e.origin == window.location.origin) {
      checkClosed.cancel();
      sub.cancel();

      // The pop-up message is defined as its window location (a URL)
      // in web/spotify/callback.html
      var spotifyParams = Uri.parse(e.data).queryParameters;

      if (spotifyParams.containsKey('error')) {
        print('Spotify Auth Error: ' + spotifyParams['error']);
        return completer.complete(false);
      }

      spotify = SpotifyApi.fromAuthCodeGrant(grant, e.data);
      spotify.me.get().then((value) {
        user = value;
        gotUserGrant = true;
        completer.complete(true);
      });
    }
  });

  return completer.future;
}

Future<void> createPlaylist(
    String name, String description, Iterable<String> itemIds) async {
  if (await ensureGrant()) {
    var playlist = await spotify.playlists.createPlaylist(
      user.id,
      name,
      public: false,
      description: description,
    );
    print('Playlist created');
    await for (var done in addIdsToPlaylist(itemIds, playlist.id)) {
      print('$done songs added to playlist');
    }
  }
}

Stream<int> addIdsToPlaylist(Iterable<String> ids, String playlistId) =>
    batchOperation(
      ids,
      batchSize: 100,
      operation: (items) => spotify.playlists.addTracks(
        items.map((id) => 'spotify:track:$id').toList(),
        playlistId,
      ),
    );

Future<void> likeTracks(Iterable<String> ids,
    {bool orderMatters = false}) async {
  if (await ensureGrant()) {
    // Access granted
    var idList = ids.toList();

    if (orderMatters) {
      for (var i = 1; i <= ids.length; i++) {
        var id = idList[ids.length - i];
        await spotify.tracks.me.saveOne(id);
        print('Liked ' + id + ' | $i/${ids.length}');
        // Spotify scrambles the order if two or more tracks are added
        // to a playlist in less than a second. idk why. this makes me sad.
        await Future.delayed(Duration(milliseconds: 1000));
      }
    } else {
      await for (var done in batchOperation(
        idList,
        batchSize: 50,
        operation: (ids) => spotify.tracks.me.save(ids.toList()),
      )) {
        print('$done songs liked.');
      }
    }
  } else {
    print('Access denied');
  }
}

Future<void> followArtists(Iterable<String> ids) async {
  if (await ensureGrant()) {
    await for (var done in batchOperation(
      ids,
      batchSize: 50,
      operation: (ids) async =>
          await spotify.me.follow(FollowingType.artist, ids.toList()),
    )) {
      print('$done artists followed.');
    }
  }
}
