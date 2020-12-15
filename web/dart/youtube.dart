import 'package:googleapis/youtube/v3.dart';
import 'package:googleapis_auth/auth_browser.dart';

import 'playlist.dart';

final clientId = ClientId(
    '468232094872-t07nmj1dniofgjs4p5shons0k1gj1d5j.apps.googleusercontent.com',
    null);
var scopes = [YoutubeApi.YoutubeForceSslScope];

Future<List<PlaylistElement>> retrievePlaylists(YoutubeApi yt) async {
  var playlists = await yt.playlists.list(
    ['snippet'],
    mine: true,
    maxResults: 10,
  );

  return [
    LikesPlaylistElement(),
    ...playlists.items.map((e) => PlaylistElement.fromPlaylist(e)),
  ];
}

Future<List<Video>> retrieveLikedVideos(YoutubeApi yt,
    {String pageToken,
    bool musicOnly = true,
    bool firstPageOnly = false}) async {
  var likes = await yt.videos.list(
    ['snippet'],
    myRating: 'like',
    maxResults: 50,
    pageToken: pageToken,
  );

  // likes.items.forEach((vid) {
  //   print(vid.snippet.channelTitle +
  //       ' - "' +
  //       vid.snippet.title +
  //       '" https://youtu.be/' +
  //       vid.id);
  // });

  //print(JsonEncoder.withIndent(' ').convert(likes.toJson()));
  //print(likes.nextPageToken);

  var output = likes.items;

  if (musicOnly) {
    var size = output.length;
    output = output.where((vid) => vid.snippet.categoryId == '10').toList();
    print('${size - output.length} videos removed because not music and stuff');
  }

  if (!firstPageOnly && likes.nextPageToken != null) {
    output
        .addAll(await retrieveLikedVideos(yt, pageToken: likes.nextPageToken));
  }

  return output;
}

Future<String> getLikedVideoPlaylistId(YoutubeApi yt,
    {bool safe = false}) async {
  if (!safe) return 'LL';

  var channel =
      (await yt.channels.list(['contentDetails'], mine: true)).items.first;
  var playlists = channel.contentDetails.relatedPlaylists;
  return playlists.likes;
}

void initClient() async {
  // Initialize the browser oauth2 flow functionality.
  var flow = await createImplicitBrowserFlow(clientId, scopes);
  var client = await flow.clientViaUserConsent(immediate: false);

  var yt = YoutubeApi(client);

  var likedPlaylist = await yt.playlists.list(
    ['contentDetails'],
    id: [await getLikedVideoPlaylistId(yt)],
  );

  var likeCount = likedPlaylist.items.first.contentDetails.itemCount;

  print('LIKES: $likeCount');
  //var likes = await retrieveLikedVideos(yt, firstPageOnly: true);
  //var playlists = await retrievePlaylists(yt);

  flow.close();
}
