import 'package:meta/meta.dart';

class Song {
  final String id;
  final String name;
  final Iterable<String> artists;
  final String coverArtUrl;
  final Duration duration;

  static String _removeTopic(String s) =>
      s.endsWith(' - Topic') ? s.substring(0, s.length - 8) : s;

  Song({
    @required this.name,
    @required Iterable<String> artists,
    @required this.id,
    @required this.coverArtUrl,
    @required Duration duration,
  })  : artists = artists.map((a) => _removeTopic(a)),
        duration = Duration(seconds: (duration.inMilliseconds / 1000).ceil());

  @override
  String toString() => artists.join(', ') + ' - "' + name + '"';
}
