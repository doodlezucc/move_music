class Song {
  final String id;
  final String name;
  final Iterable<String> artists;
  final String coverArtUrl;

  static String _removeTopic(String s) =>
      s.endsWith(' - Topic') ? s.substring(0, s.length - 8) : s;

  Song(this.name, Iterable<String> artists, this.id, this.coverArtUrl)
      : artists = artists.map((a) => _removeTopic(a));
}
