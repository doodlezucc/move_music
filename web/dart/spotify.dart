import 'dart:async';
import 'dart:html';

import 'package:spotify/spotify.dart';
import 'package:oauth2/oauth2.dart';

import 'song.dart';

SpotifyApiCredentials credentials;
SpotifyApi spotify;
AuthorizationCodeGrant grant;

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
  print(query);
  await ensureCredentials();
  var bundledPages = spotify.search.get(query, types: [
    SearchType.track,
  ]);

  var page = (await bundledPages.first(5)).first;
  var tracks = List<Track>.from(page.items);
  return tracks.map((e) => Song(
      e.name, e.artists.map((e) => e.name), e.id, e.album.images.first.url));
}

Future<void> ensureGrant() async {
  await ensureCredentials();
  if (grant != null) return;

  grant = SpotifyApi.authorizationCodeGrant(credentials);

  var redirectUri = 'http://localhost:8080/spotify/callback.html';

  var authUri = grant.getAuthorizationUrl(
    Uri.parse(redirectUri),
    scopes: ['user-library-read'],
  );

  var completer = Completer();

  StreamSubscription sub;
  sub = window.onMessage.listen((e) {
    if (e.origin == window.location.origin) {
      completer.complete(Uri.parse(e.data));
      sub.cancel();
    }
  });

  var inset = 200;
  var width = window.outerWidth - inset * 2;
  var height = window.outerHeight - inset * 2;

  window.open(authUri.toString(), 'Spotify Authorization',
      'left=$inset, top=$inset, width=$width, height=$height');

  // wait for the pop-up to notify this window
  Uri resultUri = await completer.future;

  print('he actually did it whaaaaa-');
  print(resultUri.queryParameters);
}

Future<void> displayUserLikes() async {
  await ensureGrant();
}
