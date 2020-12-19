import 'dart:html';

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

class MoveElement {
  final Song source;
  Song match;
  HtmlElement e;

  MoveElement(this.source) {
    e = LIElement()
      ..className = 'song'
      ..append(ImageElement(src: source.coverArtUrl)..className = 'square')
      ..append(DivElement()
        ..className = 'meta'
        ..append(HeadingElement.h3()..text = source.name)
        ..append(SpanElement()..text = source.artists.join(', ')))
      ..append(TableElement()..className = 'matches')
      ..onClick.listen((event) => addOnSpotify());
  }

  void selectMatch(Song s) {
    match = s;
    e.classes.add('slim');
    e.querySelector('.meta').classes.add('slim');
  }

  Future<void> findSpotifyMatches() async {
    var matches = await searchSongMatches(source);
    if (matches.isEmpty) {
      print(source);
    } else if (matches.first.similarity >= 0.95) {
      selectMatch(matches.first.song);
    } else {
      matches.forEach((m) {
        _createRow(m);
      });
    }
    querySelector('#songs').append(e);
  }

  void _createRow(SongMatch m) {
    TableCellElement cell(dynamic child) {
      if (child is HtmlElement) return TableCellElement()..append(child);
      return TableCellElement()..text = child;
    }

    var matchE = TableRowElement()
      ..append(
          cell(ImageElement(src: m.song.coverArtUrl)..className = 'square'))
      ..append(cell(m.song.name))
      ..append(cell(m.song.artists.join(', ')))
      ..append(cell((m.similarity * 100).toStringAsFixed(0) + '% match'))
      ..onClick.listen((event) => addOnSpotify());

    e.querySelector('.matches').append(matchE);
  }

  void addOnSpotify() {
    print('add on spotify');
  }
}
