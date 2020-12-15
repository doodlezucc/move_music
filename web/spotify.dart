import 'dart:io';

import 'package:spotify/spotify.dart';

final clientSecret = File('client_secret').readAsStringSync();

final credentials = SpotifyApiCredentials(
  '14785ba1a003421cbef0535ced0159ae',
  clientSecret,
);
final spotify = SpotifyApi(credentials);

Future<void> search(String query) async {
  final bundledPages = spotify.search.get(query, types: [
    SearchType.track,
  ]);

  var page = (await bundledPages.first()).first;
  var tracks = List<Track>.from(page.items);
  tracks.forEach((t) {
    print(t.artists.map((a) => a.name).join(', ') + ' - "' + t.name + '"');
  });
}
