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
    return (a.name.similarityTo(b.name) +
            a.artists.first.similarityTo(b.artists.first)) /
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
      ..append(ImageElement(src: source.coverArtUrl))
      ..append(DivElement()
        ..className = 'meta'
        ..append(HeadingElement.h3()..text = source.name)
        ..append(SpanElement()..text = source.artists.join(', ')))
      ..append(DivElement()..className = 'matches')
      ..onClick.listen((event) => addOnSpotify());
  }

  void selectMatch(Song s) {
    match = s;
    e.classes.add('slim');
    e.querySelector('.meta').classes.add('slim');
  }

  Future<void> findSpotifyMatches() async {
    var matchParent = e.querySelector('.matches');
    var matches = await searchSongMatches(source);
    if (matches.isEmpty) {
      print('EMPTY RESULT LIST');
      return;
    }
    if (matches.first.similarity >= 0.95) {
      selectMatch(matches.first.song);
    } else {
      matches.forEach((m) {
        var matchE = DivElement()
          ..className = 'match'
          ..append(ImageElement(src: m.song.coverArtUrl))
          ..append(DivElement()
            ..className = 'meta slim'
            ..append(HeadingElement.h3()..text = m.song.name)
            ..append(SpanElement()..text = m.song.artists.join(', '))
            ..append(SpanElement()
              ..text = (m.similarity * 100).toStringAsFixed(0) + '% match'))
          ..onClick.listen((event) => addOnSpotify());

        matchParent.append(matchE);
      });
    }
    querySelector('#songs').append(e);
  }

  void addOnSpotify() {
    print('add on spotify');
  }
}
