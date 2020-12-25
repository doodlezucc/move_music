import 'package:googleapis/youtube/v3.dart';
import 'package:googleapis_auth/auth_browser.dart';

import 'artist.dart';
import 'move.dart';
import 'playlist.dart';

final clientId = ClientId(
    '468232094872-t07nmj1dniofgjs4p5shons0k1gj1d5j.apps.googleusercontent.com',
    null);
final scopes = [YoutubeApi.YoutubeForceSslScope];
YoutubeApi yt;

Stream<YouTubePlaylistElement> retrievePlaylists({String pageToken}) async* {
  var response = await yt.playlists.list(
    ['snippet', 'contentDetails'],
    mine: true,
    maxResults: 50,
    pageToken: pageToken,
  );

  yield* Stream.fromIterable(
      response.items.map((e) => YouTubePlaylistElement.fromPlaylist(e)));

  if (response.nextPageToken != null) {
    yield* retrievePlaylists(pageToken: response.nextPageToken);
  }
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

Stream<YouTubePlaylistElement> displayUserPlaylists() async* {
  var likedPlaylist = await yt.playlists.list(
    ['contentDetails'],
    id: [await getLikedVideoPlaylistId()],
  );

  var likeCount = likedPlaylist.items.first.contentDetails.itemCount;

  yield LikesPlaylistElement(likeCount);
  yield* retrievePlaylists();
}

Stream<Artist> retrieveSubscriptions({String pageToken}) async* {
  var responseSubs = await yt.subscriptions.list(
    ['snippet'],
    order: 'alphabetical',
    mine: true,
    maxResults: 10,
    pageToken: pageToken,
  );
  var responseChannels = await yt.channels.list(
    ['topicDetails', 'statistics'],
    id: responseSubs.items.map((e) => e.snippet.resourceId.channelId).toList(),
    maxResults: 10,
  );

  var validChannels = responseSubs.items.where((s) => responseChannels.items
      .singleWhere((ch) {
        return s.snippet.resourceId.channelId == ch.id;
      })
      .topicDetails
      .topicIds
      .contains('/m/04rlf')); // Channel contains "Music" topic

  yield* Stream.fromIterable(validChannels.map((r) => Artist(
        id: r.snippet.resourceId.channelId,
        name: r.snippet.title,
        pictureUrl: r.snippet.thumbnails.medium.url,
        popularity: int.parse(responseChannels.items
            .singleWhere((ch) {
              return r.snippet.resourceId.channelId == ch.id;
            })
            .statistics
            .viewCount),
      )));

  if (responseChannels.nextPageToken != null) {
    yield* retrieveSubscriptions(pageToken: responseChannels.nextPageToken);
  }
}

Stream<MoveElement> displayFollowedArtistsMatches() async* {
  yield* retrieveSubscriptions()
      .map((artist) => MoveElement(artist)..findSpotifyMatches());
}
