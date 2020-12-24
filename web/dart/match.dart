import 'song.dart';
import 'spotify.dart';
import 'package:string_similarity/string_similarity.dart';

class SongMatch {
  final Song song;
  final double similarity;

  SongMatch(Song query, this.song)
      : similarity = calculateSimilarity(query, song);

  static String trim(Song s) {
    return (s.name + ' ' + s.artists.join())
        .toLowerCase()
        .replaceAll(
            RegExp(r"[^\p{L}0-9' ]", unicode: true), // special characters
            ' ') // to spaces
        .replaceAll(RegExp(r'  +'), ' '); // multiple spaces to one
  }

  static double calculateSimilarity(Song a, Song b) {
    return trim(a).similarityTo(trim(b));
  }
}

Future<List<SongMatch>> searchSongMatches(Song s, {String query}) async {
  query = query ?? s.toQuery();
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
