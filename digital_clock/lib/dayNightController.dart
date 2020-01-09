import 'package:digital_clock/FlareTimeControls.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare.dart';

class DayNightController extends FlareTimeControls {
  // Storage for our matrix to get global Flutter coordinates into Flare world coordinates.
  Mat2D _globalToFlareWorld = Mat2D();

  double _elapsed;

  DayNightController(this._elapsed);

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    super.advance(artboard, elapsed);
    return true;
  }

  // Fetch references for the `ctrl_face` node and store a copy of its original translation.
  @override
  void initialize(FlutterActorArtboard artboard) {
    super.initialize(artboard);
    play("Day/Nigh", time: _elapsed);
  }

  onCompleted(String name) {
    //play("idle");
  }

  // Called by [FlareActor] when the view transform changes.
  // Updates the matrix that transforms Global-Flutter-coordinates into Flare-World-coordinates.
  @override
  void setViewTransform(Mat2D viewTransform) {
    Mat2D.invert(_globalToFlareWorld, viewTransform);
  }
}
