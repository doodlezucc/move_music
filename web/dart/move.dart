import 'dart:html';

import 'package:meta/meta.dart';

import 'helpers.dart';
import 'match.dart';

final conflictCounter = querySelector('#conflicts');
int _conflicts = 0;
int get conflicts => _conflicts;
set conflicts(int v) {
  _conflicts = v;
  conflictCounter.text = v.toString();
}

abstract class Moveable {
  final String id;
  final String name;
  final String pictureUrl;
  final int popularity;

  Moveable(
      {@required this.id,
      @required this.name,
      @required this.pictureUrl,
      this.popularity = 1});

  String toQuery();

  Iterable<String> meta() => [];
  Iterable<Element> metaElements() =>
      meta().map((e) => SpanElement()..text = e);
}

class MoveElement<T extends Moveable> {
  final T source;
  int selected = 0;
  List<Match> matches = [];
  Match get match => selected >= 0 ? matches[selected] : null;
  HtmlElement e;
  SpanElement status;
  bool get _collapsed => e.classes.contains('slim');
  set _collapsed(bool v) {
    e.classes.toggle('slim', v);
    e.querySelector('.meta').classes.toggle('slim', v);
  }

  List<Element> get rows => e.querySelectorAll('.matches > tr').toList();

  MoveElement(this.source) {
    e = LIElement()
      ..className = 'song slim'
      ..append(squareImage(src: source.pictureUrl))
      ..append(DivElement()
        ..className = 'meta slim'
        ..append(HeadingElement.h3()..text = source.name)
        ..children.addAll(source.metaElements()))
      ..append(TableElement()
        ..className = 'matches'
        ..append(InputElement(type: 'text')
          ..className = 'search'
          ..placeholder = source.toQuery()
          ..onKeyDown.listen(onSearchKeyDown))
        ..append(status = SpanElement()..className = 'status'))
      ..onClick.listen((event) {
        if (!(event.target as HtmlElement).matchesWithAncestors('table')) {
          if (_collapsed || selected >= 0) {
            _collapsed = !_collapsed;
          }
        }
      });
    querySelector('#songs').append(e);
  }

  void onSearchKeyDown(KeyboardEvent e) {
    if (e.keyCode == 13) {
      var query = (e.target as InputElement).value;
      findSpotifyMatches(query: query.isNotEmpty ? query : null);
    }
  }

  void selectMatch(Match s, {userAction = true}) {
    if (selected >= 0) {
      rows[selected].classes.remove('selected');
    } else if (userAction) {
      conflicts--;
    }
    selected = matches.indexOf(s);
    rows[selected].classes.add('selected');
    _collapsed = true;
  }

  Future<void> findSpotifyMatches({String query}) async {
    query = query ?? source.toQuery();
    rows.forEach((row) {
      row.remove();
    });
    status.text = 'Searching...';
    matches = (await searchMatches(source, query: query)).toList()
      ..sort((a, b) {
        var similarity = b.similarity.compareTo(a.similarity);
        if (similarity == 0) {
          return b.target.popularity.compareTo(a.target.popularity);
        }
        return similarity;
      });
    matches.forEach((m) {
      _createRow(m);
    });
    status.text = 'No results found for "$query"';
    if (matches.isNotEmpty && matches.first.similarity >= 0.95) {
      selectMatch(matches.first, userAction: false);
    } else if (selected >= 0) {
      conflicts++;
      selected = -1;
      _collapsed = false;
    }
  }

  void _createRow(Match m) {
    TableCellElement cell(dynamic child) {
      if (child is HtmlElement) return TableCellElement()..append(child);
      return TableCellElement()..text = child;
    }

    var matchE = TableRowElement()
      ..append(cell(squareImage(src: m.target.pictureUrl)))
      ..append(cell(m.target.name))
      ..children.addAll(m.target.meta().map((meta) => cell(meta)))
      ..append(cell((m.similarity * 100).toStringAsFixed(0) + '% match'))
      ..onClick.listen((event) => selectMatch(m));

    var children = e.querySelector('.matches').children;
    children.insert(children.length - 1, matchE);
  }
}
