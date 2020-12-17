import 'dart:html';

import 'package:spotify/spotify.dart';

import 'song.dart';

SpotifyApiCredentials credentials;
SpotifyApi spotify;

Future<void> ensureCredentials() async {
  if (spotify != null) return;

  final clientSecret = await HttpRequest.getString('client_secret');

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
  final bundledPages = spotify.search.get(query, types: [
    SearchType.track,
  ]);

  var page = (await bundledPages.first(5)).first;
  var tracks = List<Track>.from(page.items);
  return tracks.map((e) => Song(
      e.name, e.artists.map((e) => e.name), e.id, e.album.images.first.url));
}
