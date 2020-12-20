import 'dart:async';
import 'dart:html';

import 'package:spotify/spotify.dart';

import 'song.dart';

SpotifyApiCredentials credentials;
SpotifyApi spotify;
bool gotUserGrant = false;

Future<void> ensureCredentials() async {
  if (spotify != null) return;

  var clientSecret = await HttpRequest.getString('client_secret');

  credentials = SpotifyApiCredentials(
    '14785ba1a003421cbef0535ced0159ae',
    clientSecret,
  );
  spotify = SpotifyApi(credentials);
}

Future<Iterable<Song>> search(String query) async {
  query = query.replaceAll(RegExp(r'[^\p{L} 0-9]', unicode: true), ' ');
  await ensureCredentials();
  var bundledPages = spotify.search.get(query, types: [
    SearchType.track,
  ]);

  var page = (await bundledPages.first(5)).first;
  var tracks = List<Track>.from(page.items);
  return tracks.map((e) => Song(
        name: e.name,
        artists: e.artists.map((e) => e.name),
        id: e.id,
        coverArtUrl: e.album.images.first.url,
        duration: e.duration,
      ));
}

Future<bool> ensureGrant() async {
  if (gotUserGrant) return true;
  await ensureCredentials();

  var grant = SpotifyApi.authorizationCodeGrant(credentials);
  var redirectUri = 'http://localhost:8080/spotify/callback.html';
  var authUri = grant.getAuthorizationUrl(
    Uri.parse(redirectUri),
    scopes: ['user-library-modify'],
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
      print(spotifyParams);

      if (spotifyParams.containsKey('error')) {
        print('Spotify Auth Error: ' + spotifyParams['error']);
        return completer.complete(false);
      }

      spotify = SpotifyApi.fromAuthCodeGrant(grant, e.data);
      gotUserGrant = true;
      completer.complete(true);
    }
  });

  return completer.future;
}

WindowBase openCenteredPopup(String url,
    {String name = 'Popup', int width = 800}) {
  var inset = 150;
  var left = (window.outerWidth - width) / 2;
  var height = window.outerHeight - inset * 2;

  return window.open(
      url, name, 'left=$left, top=$inset, width=$width, height=$height');
}

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
      var batchSize = 50;
      for (var i = 0; i < ids.length; i += batchSize) {
        await spotify.tracks.me.save(idList.sublist(i));
        print('Liked ${i + batchSize} tracks.');
      }
    }
  } else {
    print('Access denied');
  }
}
