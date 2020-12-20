import 'dart:html';

import 'duration.dart';
import 'match.dart';
import 'song.dart';

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
        ..append(SpanElement()..text = source.artists.join(', '))
        ..append(SpanElement()
          ..text = durationString(source.duration)
          ..className = 'source-duration'))
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
      print('NO MATCHES FOUND');
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
      ..append(cell(durationString(m.song.duration)))
      ..append(cell((m.similarity * 100).toStringAsFixed(0) + '% match'))
      ..onClick.listen((event) => addOnSpotify());

    e.querySelector('.matches').append(matchE);
  }

  void addOnSpotify() {
    print('add on spotify');
  }
}
