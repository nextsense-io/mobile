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
