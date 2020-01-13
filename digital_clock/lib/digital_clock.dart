// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:digital_clock/dayNightController.dart';
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

enum _TemperatureStatus {
  hot,
  warm,
  neutral,
  chilly,
  cold,
}

final _lightTheme = {
  _Element.background: Color(0xFF81B3FE),
  _Element.text: Colors.white,
  _TemperatureStatus.hot: Colors.redAccent,
  _TemperatureStatus.warm: Colors.yellowAccent,
  _TemperatureStatus.neutral: Colors.white,
  _TemperatureStatus.chilly: Colors.lightBlueAccent,
  _TemperatureStatus.cold: Colors.indigoAccent
};

final _darkTheme = {
  _Element.background: Colors.black,
  _Element.text: Colors.white,
  _TemperatureStatus.hot: Colors.red,
  _TemperatureStatus.warm: Colors.yellow,
  _TemperatureStatus.neutral: Colors.white,
  _TemperatureStatus.chilly: Colors.lightBlue,
  _TemperatureStatus.cold: Colors.indigo
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
  bool _isDateSeparatorVisible = true;
  bool _isAnimationStateResetRequired = false;
  DayNightController _dayNightController;
  DateFormat _meridianFormatter = DateFormat('a');
  DateFormat _minutesFormatter = DateFormat('mm');
  DateFormat _hours24Formatter = DateFormat('HH');
  DateFormat _hours12Formatter = DateFormat('hh');
  DateFormat _dateFormat = DateFormat('EEEE, MMMM dd');

  @override
  void initState() {
    super.initState();
    _dayNightController = DayNightController(_dateTime);
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

      // we want to reset the animation when daylight saving time happens
      _isAnimationStateResetRequired =
          currentTime.difference(_dateTime).inMinutes > 2;

      _dateTime = currentTime;
      _isDateSeparatorVisible = !_isDateSeparatorVisible;
      // Update once per minute. If you want to update every second, use the
      // following code.
      _timer = Timer(
        Duration(minutes: 1) -
            Duration(seconds: _dateTime.second) -
            Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
      // Update once per second, but make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      /*_timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );*/
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.light
        ? _lightTheme
        : _darkTheme;
    final fontSize = MediaQuery.of(context).size.width / 8;
    final textGradientColor =
        getTemperatureGradient(widget.model.temperature, widget.model.unit);
    final defaultStyle = TextStyle(
        color: colors[_Element.text], fontFamily: 'Roboto', fontSize: fontSize);

    final hoursFormatter =
        widget.model.is24HourFormat ? _hours24Formatter : _hours12Formatter;
    final hour = hoursFormatter.format(_dateTime);
    final minute = _minutesFormatter.format(_dateTime);
    final date = _dateFormat.format(_dateTime);

    List<Widget> timeWidgets = _createTimeWidgets(
      hour,
      minute,
      textGradientColor,
      fontSize,
    );

    if (_isAnimationStateResetRequired) {
      _dayNightController.updateCurrentTime(_dateTime);
    }

    return Container(
      color: colors[_Element.background],
      child: Stack(
        children: <Widget>[
          FlareActor(
            "Day_Night.flr",
            shouldClip: false,
            alignment: Alignment.center,
            fit: BoxFit.cover,
            controller: _dayNightController,
          ),
          Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  DefaultTextStyle(
                      style: defaultStyle,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: timeWidgets,
                      )),
                  Stack(
                    children: <Widget>[
                      // Stroked text as border.
                      Text("$date",
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: fontSize / 5,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 3
                              ..color = Colors.black87,
                          )),
                      // Solid text as fill.
                      Text("$date",
                          style: TextStyle(
                              color: colors[_Element.text],
                              fontFamily: 'Roboto',
                              fontSize: fontSize / 5)),
                    ],
                  ),
                ],
              )),
        ],
      ),
    );
  }

  List<Widget> _createTimeWidgets(String hour, String minute,
      LinearGradient textGradientColor, double fontSize) {
    List<Widget> timeWidgets = [];
    timeWidgets.add(
        _createBorderedTextWithGradient(hour, textGradientColor, fontSize));
    timeWidgets
        .add(_createBorderedTextWithGradient(":", textGradientColor, fontSize));
    timeWidgets.add(
        _createBorderedTextWithGradient(minute, textGradientColor, fontSize));

    if (!widget.model.is24HourFormat) {
      final meridian = _meridianFormatter.format(_dateTime);
      timeWidgets.add(_createBorderedTextWithGradient(
          meridian, textGradientColor, fontSize / 2));
    }

    return timeWidgets;
  }

  LinearGradient getTemperatureGradient(num degrees, TemperatureUnit unit) {
    num celsiusTemperature = _convertToCelsius(degrees, unit);
    final theme = Theme.of(context).brightness == Brightness.light
        ? _lightTheme
        : _darkTheme;

    var colors;
    var stops;

    if (celsiusTemperature >= 20) {
      colors = [theme[_TemperatureStatus.hot], theme[_TemperatureStatus.hot]];
      stops = [1.0, 1.0];
    } else if (celsiusTemperature >= 10) {
      colors = [theme[_TemperatureStatus.warm], theme[_TemperatureStatus.hot]];
      stops = [(20 - celsiusTemperature) / 10, 1.0];
    } else if (celsiusTemperature >= 0) {
      colors = [
        theme[_TemperatureStatus.neutral],
        theme[_TemperatureStatus.warm]
      ];
      stops = [(10 - celsiusTemperature) / 10, 1.0];
    } else if (celsiusTemperature >= -10) {
      colors = [
        theme[_TemperatureStatus.chilly],
        theme[_TemperatureStatus.cold]
      ];
      stops = [((-10 - celsiusTemperature) / 10).abs(), 1.0];
    } else {
      colors = [theme[_TemperatureStatus.cold], theme[_TemperatureStatus.cold]];
      stops = [1.0, 1.0];
    }

    return LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        stops: stops,
        colors: colors);
  }

  num _convertToCelsius(num degrees, TemperatureUnit unit) {
    switch (unit) {
      case TemperatureUnit.fahrenheit:
        return (degrees - 32.0) * 5.0 / 9.0;
      case TemperatureUnit.celsius:
      default:
        return degrees;
        break;
    }
  }

  Widget _createBorderedTextWithGradient(
      String text, LinearGradient gradient, num fontSize) {
    return Stack(children: <Widget>[
      // Stroked text as border.
      Text(text,
          style: TextStyle(
            fontFamily: "Roboto",
            fontSize: fontSize,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.white,
          )),
      // Solid text as fill.
      ShaderMask(
          shaderCallback: (bounds) {
            return gradient.createShader(Offset.zero & bounds.size);
          },
          child: Text(text,
              style: TextStyle(fontFamily: "Roboto", fontSize: fontSize)))
    ]);
  }
}
