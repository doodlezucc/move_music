import 'package:meta/meta.dart';

class Song {
  final String id;
  final String name;
  final Iterable<String> _artists;
  Iterable<String> get artists => _artists;
  final String coverArtUrl;
  final Duration duration;

  Song({
    @required this.name,
    @required Iterable<String> artists,
    @required this.id,
    @required this.coverArtUrl,
    @required Duration duration,
  })  : _artists = artists,
        duration = Duration(seconds: (duration.inMilliseconds / 1000).ceil());

  String toQuery() => '$name ${artists.join(' ')}';

  @override
  String toString() => artists.join(', ') + ' - "' + name + '"';
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
  String toQuery() => '$name ${artistsReduced.join(' ')}';
}
