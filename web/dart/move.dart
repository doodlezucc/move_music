import 'dart:html';

import 'duration.dart';
import 'match.dart';
import 'song.dart';

class MoveElement {
  final Song source;
  int selected = -1;
  List<SongMatch> matches;
  SongMatch get match => matches[selected];
  HtmlElement e;
  set _collapsed(bool v) {
    print(v);
    e.classes.toggle('slim', v);
    e.querySelector('.meta').classes.toggle('slim', v);
  }

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
      ..onClick.listen((event) {
        if (!(event.target as HtmlElement).matchesWithAncestors('table')) {
          _collapsed = false;
        }
      });
  }

  void selectMatch(SongMatch s) {
    var rows = e.querySelector('.matches').children;
    if (selected >= 0) {
      rows[selected].classes.remove('selected');
    }
    selected = matches.indexOf(s);
    rows[selected].classes.add('selected');
    _collapsed = true;
  }

  Future<void> findSpotifyMatches() async {
    matches = await searchSongMatches(source);
    matches.forEach((m) {
      _createRow(m);
    });
    if (matches.isEmpty) {
      print('NO MATCHES FOUND');
      print(source);
    } else if (matches.first.similarity >= 0.95) {
      selectMatch(matches.first);
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
      ..onClick.listen((event) => selectMatch(m));

    e.querySelector('.matches').append(matchE);
  }
}
