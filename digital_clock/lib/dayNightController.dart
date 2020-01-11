import 'package:digital_clock/FlareTimeControls.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare.dart';

class DayNightController extends FlareTimeControls {
  static const int animationLength = 24;

  Mat2D _globalToFlareWorld = Mat2D();
  DateTime _currentTime;

  DayNightController(this._currentTime);

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    //We divide elapsed time by 3600 to run 24sec animation for 24h
    //final animationElapse = elapsed / 10;
    super.advance(artboard, elapsed);
    return true;
  }

  // Fetch references for the `ctrl_face` node and store a copy of its original translation.
  @override
  void initialize(FlutterActorArtboard artboard) {
    super.initialize(artboard);
    play("Day/Nigh", time: getAnimationStartTime(_currentTime));
  }

  // Called by [FlareActor] when the view transform changes.
  // Updates the matrix that transforms Global-Flutter-coordinates into Flare-World-coordinates.
  @override
  void setViewTransform(Mat2D viewTransform) {
    Mat2D.invert(_globalToFlareWorld, viewTransform);
  }

  void updateCurrentTime(DateTime currentTime) {
    _currentTime = currentTime;
    var animationStartTime = getAnimationStartTime(_currentTime);
    play("Day/Nigh", time: animationStartTime);
  }

  double getAnimationStartTime(DateTime currentTime) {
    final minutesInCurrentDay =
        (currentTime.hour * Duration.minutesPerHour) + currentTime.minute;
    final currentDayCompletionPercent =
        minutesInCurrentDay / Duration.minutesPerDay;

    return animationLength * currentDayCompletionPercent;
  }
}
