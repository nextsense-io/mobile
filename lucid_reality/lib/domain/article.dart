import 'dart:ui';

class Article {
  late final String _headline;
  late final String _content;
  late final String _image;

  Article(this._headline, this._content, this._image);

  String get image => _image;

  set image(String value) {
    _image = value;
  }

  String get content => _content;

  set content(String value) {
    _content = value;
  }

  String get headline => _headline;

  set headline(String value) {
    _headline = value;
  }
}

class InsightLearnItem {
  late final String _title;
  late final String _image;
  late final Article _article;
  late final Color _color;

  InsightLearnItem(this._title, this._image, this._color, this._article);

  Article get article => _article;

  set article(Article value) {
    _article = value;
  }

  String get image => _image;

  set image(String value) {
    _image = value;
  }

  String get title => _title;

  set title(String value) {
    _title = value;
  }

  Color get color => _color;

  set color(Color value) {
    _color = value;
  }
}
