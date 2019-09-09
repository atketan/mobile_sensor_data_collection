import 'package:flutter/material.dart';
import 'package:gyro_recorder/sensor_readings_home.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gyro Data Recorder',
      theme: new ThemeData(primarySwatch: Colors.amber),
      home: new SensorReadingsHome(),
    );
  }
}