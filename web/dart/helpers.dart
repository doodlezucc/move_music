import 'dart:html';
import 'dart:math';

import 'package:meta/meta.dart';

Stream<int> batchOperation<T>(
  Iterable<T> allItems, {
  @required int batchSize,
  @required Future<void> Function(Iterable<T> items) operation,
}) async* {
  for (var i = 0; i < allItems.length; i += batchSize) {
    await operation(allItems.skip(i).take(batchSize));
    yield min(i + batchSize, allItems.length);
  }
}

WindowBase openCenteredPopup(String url,
    {String name = 'Popup', int width = 800}) {
  var inset = 150;
  var left = (window.outerWidth - width) / 2;
  var height = window.outerHeight - inset * 2;

  return window.open(
      url, name, 'left=$left, top=$inset, width=$width, height=$height');
}
