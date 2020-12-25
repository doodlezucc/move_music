import 'package:meta/meta.dart';

import 'move.dart';

class Artist extends Moveable {
  Artist({
    @required String id,
    @required String name,
    @required String pictureUrl,
    @required int popularity,
  }) : super(
          id: id,
          name: name,
          pictureUrl: pictureUrl,
          popularity: popularity,
        );

  @override
  String toQuery() => name.trim().toLowerCase();

  // @override
  // Iterable<String> meta() => [popularity.toString()];
}
