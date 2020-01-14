import 'package:digital_clock/FlareTimeControls.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flutter_clock_helper/model.dart';

class DayNightController extends FlareTimeControls {
  static const int animationLength = 24;

  Mat2D _globalToFlareWorld = Mat2D();
  DateTime _currentTime;

  WeatherCondition get weatherCondition => _weatherCondition;
  WeatherCondition _weatherCondition;

  DayNightController(this._currentTime, this._weatherCondition);

  FlutterActorArtboard _artboard;

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
    _artboard = artboard;
    play("Day/Nigh", time: getAnimationStartTime(_currentTime));

    String weatherAnimationName = getWeatherAnimationName(_weatherCondition);

    if (weatherAnimationName.isNotEmpty) {
      play(weatherAnimationName, time: getAnimationStartTime(_currentTime));
    }
  }

  String getWeatherAnimationName(WeatherCondition weatherCondition) {
    String weatherAnimationName = "";

    switch (weatherCondition) {
      case WeatherCondition.cloudy:
        {
          weatherAnimationName = "cloud";
          break;
        }
      case WeatherCondition.foggy:
        {
          break;
        }
      case WeatherCondition.rainy:
        {
          break;
        }
      case WeatherCondition.snowy:
        {
          break;
        }
      case WeatherCondition.sunny:
        {
          break;
        }
      case WeatherCondition.thunderstorm:
        {
          break;
        }
      case WeatherCondition.windy:
        {
          break;
        }
      default:
        {
          break;
        }
    }

    return weatherAnimationName;
  }

  // Called by [FlareActor] when the view transform changes.
  // Updates the matrix that transforms Global-Flutter-coordinates into Flare-World-coordinates.
  @override
  void setViewTransform(Mat2D viewTransform) {
    Mat2D.invert(_globalToFlareWorld, viewTransform);
  }

  void resetAnimation(DateTime currentTime, WeatherCondition weatherCondition) {
    _currentTime = currentTime;
    _weatherCondition = weatherCondition;
    initialize(_artboard);
  }

  double getAnimationStartTime(DateTime currentTime) {
    final minutesInCurrentDay =
        (currentTime.hour * Duration.minutesPerHour) + currentTime.minute;
    final currentDayCompletionPercent =
        minutesInCurrentDay / Duration.minutesPerDay;

    return animationLength * currentDayCompletionPercent;
  }
}
