import 'dart:html';

import 'package:meta/meta.dart';

import 'artist.dart';
import 'helpers.dart';
import 'match.dart';

final IFrameElement spotifyFrame = querySelector('iframe#spotify')
  ..onMouseLeave.listen((e) {
    spotifyFrame.classes.remove('show');
    spotifyFrame.src = '';
  });

final subText = querySelector('#conflictSub');
final conflictCounter = querySelector('#conflictCounter');
int _conflicts = 0;
int get conflicts => _conflicts;
set conflicts(int v) {
  if (searchDone) {
    subText.classes.toggle('hidden', v > 0);
  }
  _conflicts = v;
  conflictCounter.text = v.toString();
}

final ButtonElement moveButton = querySelector('#move');
int _songsToBeMoved = 0;
int _artistsToBeMoved = 0;
void _updateMoveButton() {
  var s = 'Move $_songsToBeMoved songs';
  if (_artistsToBeMoved > 0) s += ' and $_artistsToBeMoved followed artists';
  moveButton.text = s;
}

bool searchDone = false;
int maxSearches = 1;
int _searches = 0;
void updateSearchProgress() {
  if (!searchDone) {
    subText.text = 'Searching... ' +
        (100 * _searches / maxSearches).toStringAsFixed(1) +
        '%';
  }
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
  Match get match =>
      (selected >= 0 && matches.isNotEmpty) ? matches[selected] : null;
  HtmlElement e;
  SpanElement status;
  bool get _collapsed => e.classes.contains('slim');
  set _collapsed(bool v) {
    e.classes.toggleAll(['slim', 'matched'], v);
    e.querySelector('.meta').classes.toggle('slim', v);
  }

  List<Element> get rows => e.querySelectorAll('.matches > tr').toList();

  MoveElement(this.source) {
    var artistClass = (source is Artist) ? ' artist' : '';

    e = LIElement()
      ..className = 'conflict slim' + artistClass
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
    querySelector('#conflicts').append(e);
  }

  void onSearchKeyDown(KeyboardEvent e) {
    if (e.keyCode == 13) {
      var query = (e.target as InputElement).value;
      findSpotifyMatches(query: query.isNotEmpty ? query : null);
    }
  }

  void selectMatch(Match s) {
    if (selected >= 0) {
      rows[selected].classes.remove('selected');
    } else {
      _countMe(1);
      conflicts--;
    }
    selected = matches.indexOf(s);
    rows[selected].classes.add('selected');
    _collapsed = true;
  }

  void _countMe(int add) {
    if (source is Artist) {
      _artistsToBeMoved += add;
    } else {
      _songsToBeMoved += add;
    }
    _updateMoveButton();
  }

  Future<void> findSpotifyMatches({String query}) async {
    query = query ?? source.toQuery();
    rows.forEach((row) {
      row.remove();
    });
    status.text = 'Searching...';

    var init = matches.isEmpty;
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
      if (init) _countMe(1);
      selectMatch(matches.first);
    } else if (selected >= 0) {
      if (!init) _countMe(-1);
      conflicts++;
      selected = -1;
      _collapsed = false;
    }
    _searches++;
    updateSearchProgress();
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
      ..onClick.listen((_) => selectMatch(m));

    matchE.onContextMenu.listen((e) async {
      e.preventDefault();
      var isArtist = m.target is Artist;
      var type = isArtist ? 'artist' : 'track';

      var pos = e.page;
      spotifyFrame
        ..style.left = '${pos.x - 50}px'
        ..style.top = '${pos.y - 50}px'
        ..width = '300'
        ..height = isArtist ? '400' : '80'
        ..src = 'https://open.spotify.com/embed/$type/' + m.target.id
        ..classes.add('show');
    });

    var children = e.querySelector('.matches').children;
    children.insert(children.length - 1, matchE);
  }
}
