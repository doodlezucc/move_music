import 'dart:html';

import 'duration.dart';
import 'helpers.dart';
import 'match.dart';
import 'song.dart';

final conflictCounter = querySelector('#conflicts');
int _conflicts = 0;
int get conflicts => _conflicts;
set conflicts(int v) {
  _conflicts = v;
  conflictCounter.text = v.toString();
}

class MoveElement {
  final Song source;
  int selected = -1;
  List<SongMatch> matches;
  SongMatch get match => matches[selected];
  HtmlElement e;
  set _collapsed(bool v) {
    e.classes.toggle('slim', v);
    e.querySelector('.meta').classes.toggle('slim', v);
  }

  MoveElement(this.source) {
    e = LIElement()
      ..className = 'song'
      ..append(squareImage(src: source.coverArtUrl))
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

  void selectMatch(SongMatch s, {userAction = true}) {
    var rows = e.querySelector('.matches').children;
    if (selected >= 0) {
      rows[selected].classes.remove('selected');
    } else if (userAction) {
      conflicts--;
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
    if (matches.isNotEmpty && matches.first.similarity >= 0.95) {
      selectMatch(matches.first, userAction: false);
    } else {
      conflicts++;
    }
    querySelector('#songs').append(e);
  }

  void _createRow(SongMatch m) {
    TableCellElement cell(dynamic child) {
      if (child is HtmlElement) return TableCellElement()..append(child);
      return TableCellElement()..text = child;
    }

    var matchE = TableRowElement()
      ..append(cell(squareImage(src: m.song.coverArtUrl)))
      ..append(cell(m.song.name))
      ..append(cell(m.song.artists.join(', ')))
      ..append(cell(durationString(m.song.duration)))
      ..append(cell((m.similarity * 100).toStringAsFixed(0) + '% match'))
      ..onClick.listen((event) => selectMatch(m));

    e.querySelector('.matches').append(matchE);
  }
}
