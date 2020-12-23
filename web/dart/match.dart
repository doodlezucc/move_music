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
  var query = '${s.name} ${s.artists.join(' ')}';
  print(query);
  var searchMatches = (await search(query)).map((e) => SongMatch(s, e));

  // True if no search results are promising
  var suspicious = !(searchMatches.any((sm) => sm.similarity > 0.7));

  if (suspicious) {
    // Remove stuff inside parantheses, might give better results
    var queryNew = query.replaceAll(RegExp(r'\(([^)]+)\)'), '');
    if (queryNew != query) {
      searchMatches = (await search(queryNew)).map((e) => SongMatch(s, e));
    }
  }

  return searchMatches.toList()
    ..sort((a, b) => b.similarity.compareTo(a.similarity));
}
