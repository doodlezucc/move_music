import 'dart:html';

import 'package:spotify/spotify.dart';

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

Future<void> search(String query) async {
  await ensureCredentials();
  final bundledPages = spotify.search.get(query, types: [
    SearchType.track,
  ]);

  var page = (await bundledPages.first()).first;
  var tracks = List<Track>.from(page.items);
  tracks.forEach((t) {
    print(t.artists.map((a) => a.name).join(', ') + ' - "' + t.name + '"');
  });
}
