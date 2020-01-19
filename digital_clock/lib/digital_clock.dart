// Copyright 2019 Valerii Kuznietsov. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:digital_clock/day_night_animation_controller.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:intl/intl.dart';

enum _Element {
  background,
  text,
  shadow,
}

final _lightTheme = {
  _Element.background: Colors.black,
  _Element.text: Colors.white,
};

final _darkTheme = {
  _Element.background: Colors.black,
  _Element.text: Colors.white,
};

class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;

  bool _shouldResetAnimationState = false;
  DayNightAnimationController _dayNightController;

  @override
  void initState() {
    super.initState();
    _dayNightController = DayNightAnimationController(_dateTime);
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(DigitalClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  void _updateTime() {
    setState(() {
      final currentTime = DateTime.now();

      // we need to reset the animation when daylight saving time happens
      _shouldResetAnimationState =
          currentTime.difference(_dateTime).inMinutes > 2;

      _dateTime = currentTime;
      // Update once per minute.
      _timer = Timer(
        Duration(minutes: 1) -
            Duration(seconds: _dateTime.second) -
            Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    var model = widget.model;

    final colors = Theme.of(context).brightness == Brightness.light
        ? _lightTheme
        : _darkTheme;
    final fontSizeDivider = model.is24HourFormat ? 4 : 5;
    final fontSize = MediaQuery.of(context).size.width / fontSizeDivider - 5;
    final weatherAnimationSize = MediaQuery.of(context).size.height / 4;
    final defaultStyle = TextStyle(
      color: colors[_Element.text],
      fontFamily: 'Baloo',
      fontSize: fontSize,
    );

    DateFormat minutesFormatter = DateFormat('mm');

    final hoursFormatterPattern = model.is24HourFormat ? 'HH' : 'hh';
    final hoursFormatter = DateFormat(hoursFormatterPattern);
    final hour = hoursFormatter.format(_dateTime);
    final minute = minutesFormatter.format(_dateTime);
    List<Widget> timeWidgets = _createTimeWidgets(hour, minute, fontSize);

    if (_shouldResetAnimationState) {
      _dayNightController.resetAnimationTo(_dateTime);
    }

    final weatherArtboardName =
        _provideWeatherArtboardName(model.weatherCondition);

    return Container(
      color: colors[_Element.background],
      child: Stack(
        children: <Widget>[
          FlareActor(
            "daily.flr",
            shouldClip: false,
            alignment: Alignment.center,
            fit: BoxFit.cover,
            controller: _dayNightController,
          ),
          Semantics(
            readOnly: true,
            label: "Weather and Temperature",
            value: "${model.weatherString} ${model.temperatureString}",
            child: SizedBox(
              width: weatherAnimationSize,
              height: weatherAnimationSize,
              child: FlareActor(
                "daily.flr",
                animation: "anim",
                artboard: weatherArtboardName,
                shouldClip: false,
                alignment: Alignment.center,
                sizeFromArtboard: false,
                fit: BoxFit.scaleDown,
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: MergeSemantics(
              child: DefaultTextStyle(
                style: defaultStyle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: timeWidgets,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _createTimeWidgets(String hour, String minute, double fontSize) {
    List<Widget> timeWidgets = [];
    timeWidgets.add(Text("$hour"));
    timeWidgets.add(Text(":"));
    timeWidgets.add(Text("$minute"));

    if (!widget.model.is24HourFormat) {
      Text meridianText = _createMeridianText(fontSize);
      timeWidgets.add(meridianText);
    }

    return timeWidgets;
  }

  Text _createMeridianText(double fontSize) {
    final _meridianFormatter = DateFormat('a');
    final meridian = _meridianFormatter.format(_dateTime);
    var meridianTextWidget = Text(
      "$meridian",
      style: TextStyle(
        fontFamily: 'Baloo',
        fontSize: fontSize / 2,
      ),
    );

    return meridianTextWidget;
  }

  String _provideWeatherArtboardName(WeatherCondition weatherCondition) {
    switch (weatherCondition) {
      case WeatherCondition.cloudy:
        return "weather-cloudy";
      case WeatherCondition.foggy:
        return "weather-foggy";
      case WeatherCondition.rainy:
        return "weather-rainy";
      case WeatherCondition.snowy:
        return "weather-snowy";
      case WeatherCondition.sunny:
        return "weather-sunny";
      case WeatherCondition.thunderstorm:
        return "weather-thunderstorm";
      case WeatherCondition.windy:
        return "weather-windy";
    }

    return "weather-sunny";
  }
}
