import 'package:lucid_reality/domain/reality_test.dart';

class ToneCategory {
  late String _name;
  late String _description;
  late String _totemSound;
  late String _type;
  late String _realityTestID;
  late String _image;
  bool _isSelected = false;

  ToneCategory(this._name, this._description, this._totemSound, this._type, this._realityTestID,
      this._image);

  String get image => _image;

  set image(String value) {
    _image = value;
  }

  String get realityTestID => _realityTestID;

  set realityTestID(String value) {
    _realityTestID = value;
  }

  String get type => _type;

  set type(String value) {
    _type = value;
  }

  String get totemSound => _totemSound;

  set totemSound(String value) {
    _totemSound = value;
  }

  String get description => _description;

  set description(String value) {
    _description = value;
  }

  String get name => _name;

  set name(String value) {
    _name = value;
  }

  bool get isSelected => _isSelected;

  set isSelected(bool value) {
    _isSelected = value;
  }

  RealityTest toRealityTest() {
    final instance = RealityTest.instance;
    instance.setName(name);
    instance.setDescription(description);
    instance.setTotemSound(totemSound);
    instance.setType(type);
    instance.setRealityTestID(realityTestID);
    instance.setImage(image);
    return instance;
  }
}

class Tone {
  late final String _tone;
  late final String _musicFile;
  bool _isSelected = false;

  Tone(this._tone, this._musicFile);

  String get musicFile => _musicFile;

  set musicFile(String value) {
    _musicFile = value;
  }

  String get tone => _tone;

  set tone(String value) {
    _tone = value;
  }

  bool get isSelected => _isSelected;

  set isSelected(bool value) {
    _isSelected = value;
  }

  String getFileExtension() {
    try {
      return _musicFile.split('.').last;
    } catch (e) {
      return '';
    }
  }
}
