import 'package:meta/meta.dart';

class Song {
  final String id;
  final String name;
  final Iterable<String> artists;
  final String coverArtUrl;

  static String _removeTopic(String s) =>
      s.endsWith(' - Topic') ? s.substring(0, s.length - 8) : s;

  Song({
    @required this.name,
    @required Iterable<String> artists,
    @required this.id,
    @required this.coverArtUrl,
  }) : artists = artists.map((a) => _removeTopic(a));

  @override
  String toString() => artists.join(', ') + ' - "' + name + '"';
}
