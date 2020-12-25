import 'dart:html';

import 'package:meta/meta.dart';

import 'duration.dart';
import 'move.dart';

class Song extends Moveable {
  final Iterable<String> _artists;
  Iterable<String> get artists => _artists;
  final Duration duration;

  Song({
    @required String name,
    @required Iterable<String> artists,
    @required String id,
    @required String coverArtUrl,
    @required Duration duration,
  })  : _artists = artists,
        duration = Duration(seconds: (duration.inMilliseconds / 1000).ceil()),
        super(id: id, name: name, pictureUrl: coverArtUrl);

  @override
  String toQuery() => _toQuery().trim().toLowerCase();

  String _toQuery() => '$name ${artists.join(' ')}';

  @override
  String toString() => artists.join(', ') + ' - "' + name + '"';

  @override
  Iterable<String> meta() => [artists.join(', '), durationString(duration)];

  @override
  List<Element> metaElements() => [
        SpanElement()..text = artists.join(', '),
        SpanElement()
          ..text = durationString(duration)
          ..className = 'source-duration'
      ];
}

class YouTubeSong extends Song {
  YouTubeSong({
    @required String name,
    @required Iterable<String> artists,
    @required String id,
    @required String coverArtUrl,
    @required Duration duration,
  }) : super(
          name: name,
          artists: artists,
          id: id,
          coverArtUrl: coverArtUrl,
          duration: duration,
        );

  static String _removeTopic(String s) =>
      s.endsWith(' - Topic') ? s.substring(0, s.length - 8) : s;

  @override
  Iterable<String> get artists => _artists.map((a) => _removeTopic(a));

  Iterable<String> get artistsReduced => _artists
      .where((a) => a.endsWith(' - Topic'))
      .map((a) => a.substring(0, a.length - 8));

  @override
  String _toQuery() => '$name ${artistsReduced.join(' ')}';
}
