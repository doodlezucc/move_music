import 'dart:html';

final DivElement _log = querySelector('#processLog');

class Line {
  final SpanElement e;

  set text(String msg) {
    e.text = msg;
  }

  void finish() {
    e.classes.add('done');
  }

  Line(String msg) : e = SpanElement()..text = msg {
    _log.append(e);
    _log.scrollTop = _log.scrollHeight;
  }
}
