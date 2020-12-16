import 'song.dart';
import 'spotify.dart';
import 'package:string_similarity/string_similarity.dart';

class SongMatch {
  final Song song;
  final double similarity;

  SongMatch(Song query, this.song)
      : similarity = calculateSimilarity(query, song);

  static double calculateSimilarity(Song a, Song b) {
    return (a.name.similarityTo(b.name) +
            a.artists.first.similarityTo(b.artists.first)) /
        2;
  }
}

Future<List<SongMatch>> searchSongMatches(Song s) async {
  var query = '${s.name} ${s.artists.first}';
  print(query);
  var searchResults = await search(query);

  if (searchResults.isEmpty) {
    searchResults = await search(query.replaceAll(RegExp(r'\(([^)]+)\)'), ''));
  }

  return searchResults.map((e) => SongMatch(s, e)).toList()
    ..sort((a, b) => b.similarity.compareTo(a.similarity));
}
