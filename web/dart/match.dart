import 'move.dart';
import 'song.dart';
import 'spotify.dart';
import 'package:string_similarity/string_similarity.dart';

class Match<T extends Moveable> {
  final T target;
  final double similarity;

  Match(T source, this.target)
      : similarity = trim(source).similarityTo(trim(target));

  static String trim(Moveable t) {
    return t
        .toQuery()
        .toLowerCase()
        .replaceAll(
            RegExp(r"[^\p{L}0-9' ]", unicode: true), // special characters
            ' ') // to spaces
        .replaceAll(RegExp(r'  +'), ' '); // multiple spaces to one
  }
}

Future<Iterable<M>> _searchMoveable<M extends Moveable>(
    M m, String query) async {
  return await (m is Song ? searchSong(query) : searchArtist(query));
}

Future<Iterable<Match>> searchMatches(Moveable m, {String query}) async {
  query = query ?? m.toQuery();
  var searchMatches = (await _searchMoveable(m, query)).map((e) => Match(m, e));

  // True if no search results are promising
  var suspicious = !(searchMatches.any((sm) => sm.similarity > 0.7));

  if (suspicious) {
    // Remove stuff inside parantheses, might give better results
    var queryNew = query.replaceAll(RegExp(r'\(([^)]+)\)'), '');
    if (queryNew != query) {
      searchMatches =
          (await _searchMoveable(m, queryNew)).map((e) => Match(m, e));
    }
  }

  return searchMatches;
}
