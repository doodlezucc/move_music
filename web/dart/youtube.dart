import 'package:googleapis/youtube/v3.dart';
import 'package:googleapis_auth/auth_browser.dart';

import 'playlist.dart';

final clientId = ClientId(
    '468232094872-t07nmj1dniofgjs4p5shons0k1gj1d5j.apps.googleusercontent.com',
    null);
final scopes = [YoutubeApi.YoutubeForceSslScope];
YoutubeApi yt;

Future<Iterable<PlaylistElement>> retrievePlaylists() async {
  var playlists = await yt.playlists.list(
    ['snippet'],
    mine: true,
    maxResults: 10,
  );

  return playlists.items.map((e) => PlaylistElement.fromPlaylist(e));
}

Future<String> getLikedVideoPlaylistId({bool safe = false}) async {
  if (!safe) return 'LL';

  var channel =
      (await yt.channels.list(['contentDetails'], mine: true)).items.first;
  var playlists = channel.contentDetails.relatedPlaylists;
  return playlists.likes;
}

void initClient(bool immediate) async {
  // Initialize the browser oauth2 flow functionality.
  var flow = await createImplicitBrowserFlow(clientId, scopes);
  var client = await flow.clientViaUserConsent(immediate: immediate);
  flow.close();

  yt = YoutubeApi(client);
}

void displayUserPlaylists() async {
  var likedPlaylist = await yt.playlists.list(
    ['contentDetails'],
    id: [await getLikedVideoPlaylistId()],
  );

  var likeCount = likedPlaylist.items.first.contentDetails.itemCount;

  LikesPlaylistElement(likeCount);
  await retrievePlaylists();
}
