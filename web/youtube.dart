import 'dart:convert';

import 'package:googleapis/youtube/v3.dart';
import 'package:googleapis_auth/auth_browser.dart';

import 'playlist.dart';

final clientId = ClientId(
    '468232094872-t07nmj1dniofgjs4p5shons0k1gj1d5j.apps.googleusercontent.com',
    null);
var scopes = [YoutubeApi.YoutubeForceSslScope];

void initClient() async {
  // Initialize the browser oauth2 flow functionality.
  var flow = await createImplicitBrowserFlow(clientId, scopes);
  var client = await flow.clientViaUserConsent(immediate: true);

  var ytApi = YoutubeApi(client);
  var response = await ytApi.playlists.list(
    ['snippet'],
    mine: true,
    maxResults: 10,
  );

  print(JsonEncoder.withIndent(' ').convert(response.toJson()));

  response.items.forEach((element) {
    PlaylistElement(element);
  });

  flow.close();
}
