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

final _lightTheme = {
  _Element.background: Color(0xFF81B3FE),
  _Element.text: Colors.white,
  _Element.shadow: Colors.black,
};

final _darkTheme = {
  _Element.background: Colors.black,
  _Element.text: Color(0xFF04E1FC),
  _Element.shadow: Color(0xFF174EA6),
};

/// A basic digital clock.
///
/// You can do better than this!
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
      /*_timer = Timer(
        Duration(minutes: 1) -
            Duration(seconds: _dateTime.second) -
            Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );*/
      // Update once per second, but make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.light
        ? _lightTheme
        : _darkTheme;
    final fontSize = MediaQuery.of(context).size.width / 8;
    final defaultStyle = TextStyle(
        color: colors[_Element.text], fontFamily: 'Roboto', fontSize: fontSize);

    final hoursFormatter =
        widget.model.is24HourFormat ? _hours24Formatter : _hours12Formatter;
    final hour = hoursFormatter.format(_dateTime);
    final minute = _minutesFormatter.format(_dateTime);

    List<Widget> dateWidgets = [];
    dateWidgets.add(Text("$hour"));
    dateWidgets.add(Text(":"));
    dateWidgets.add(Text("$minute"));

    if (!widget.model.is24HourFormat) {
      final meridian = _meridianFormatter.format(_dateTime);
      dateWidgets.add(Text(meridian,
          style: TextStyle(
              color: colors[_Element.text],
              fontFamily: 'Roboto',
              fontSize: fontSize / 2)));
    }

    if (_isAnimationStateResetRequired) {
      _dayNightController.updateCurrentTime(_dateTime);
    }

    return Container(
      color: colors[_Element.background],
      child: DefaultTextStyle(
        style: defaultStyle,
        child: Stack(
          children: <Widget>[
            FlareActor(
              "Day_Night.flr",
              shouldClip: false,
              alignment: Alignment.center,
              fit: BoxFit.cover,
              controller: _dayNightController,
            ),
            Positioned.fill(
              child: Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: dateWidgets,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
