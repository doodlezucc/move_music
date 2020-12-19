import 'song.dart';
import 'spotify.dart';
import 'package:string_similarity/string_similarity.dart';

class SongMatch {
  final Song song;
  final double similarity;

  SongMatch(Song query, this.song)
      : similarity = calculateSimilarity(query, song);

  static double calculateSimilarity(Song a, Song b) {
    return (a.name.toLowerCase().similarityTo(b.name.toLowerCase()) +
            a.artists
                .join()
                .toLowerCase()
                .similarityTo(b.artists.join().toLowerCase())) /
        2;
  }
}

Future<List<SongMatch>> searchSongMatches(Song s) async {
  var query = '${s.name} ${s.artists.first}';
  var searchResults = await search(query);

  if (searchResults.isEmpty) {
    searchResults = await search(query.replaceAll(RegExp(r'\(([^)]+)\)'), ''));
  }

  return searchResults.map((e) => SongMatch(s, e)).toList()
    ..sort((a, b) => b.similarity.compareTo(a.similarity));
}
