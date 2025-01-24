import 'package:flutter/cupertino.dart';
import 'package:f_m/module_detection/models/screen_params.dart';

/// Represents the recognition output from the model
class Recognition {
  final int _id;
  final String _label;
  final double _score;
  final Rect _location;
  Recognition(this._id, this._label, this._score, this._location);
  int get id => _id;
  String get label => _label;
  double get score => _score;
  Rect get location => _location;

  Recognition.nullObject()
      : _id = -1,
        _label = 'Unknown',
        _score = 0.0,
        _location = Rect.zero;

  Rect get renderLocation {
    final double scaleX = ScreenParams.screenPreviewSize.width / 300;
    final double scaleY = ScreenParams.screenPreviewSize.height / 300;
    return Rect.fromLTWH(
      location.left * scaleX,
      location.top * scaleY,
      location.width * scaleX,
      location.height * scaleY,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'location': {
        'left': _location.left,
        'top': _location.top,
        'width': _location.width,
        'height': _location.height,
      }
    };

  }

  static Recognition fromMap(Map<String, dynamic> map) {
    final locationMap = map['location'] as Map<String, dynamic>;
    final location = Rect.fromLTWH(locationMap['left'], locationMap['top'], locationMap['width'], locationMap['height']);
    return Recognition(map['id'], map['label'], map['score'], location);
  }
  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: $score, location: $location)';
  }
}
