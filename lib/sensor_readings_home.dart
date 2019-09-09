import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sensors/sensors.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:gyro_recorder/database_handler.dart';

class SensorReadingsHome extends StatefulWidget {
  @override
  _SensorReadingsHomeState createState() => _SensorReadingsHomeState();
}

class _SensorReadingsHomeState extends State<SensorReadingsHome> {
  //List<double> _accelerometerValues;

  List<double> _gyroscopeValues;
  List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];

  String avgGyroReadings = "-";

  String fileName;
  Directory directory;
  File file;
  IOSink sink;

  Data data;
  final GlobalKey<ScaffoldState> _scaffoldState =
      new GlobalKey<ScaffoldState>();

  PermissionStatus permissionResult;

  _checkPermission() async {
    permissionResult = await SimplePermissions.requestPermission(
        Permission.WriteExternalStorage);
    if (permissionResult == PermissionStatus.authorized) {
      debugPrint('External Write possible.');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkPermission();
    data = Data();
  }

  _subscribeToGyro() async {
    await _deleteRecords();

    fileName = DateTime.now().millisecondsSinceEpoch.toString() + ".txt";

    getExternalStorageDirectory().then((value) {
      setState(() {
        directory = value;
        file = File('${directory.path}/$fileName');
        debugPrint('${directory.path}/$fileName');
        sink = file.openWrite(mode: FileMode.append);
      });

      var counter = 0;
      //UserAccelerometer events
      _streamSubscriptions.add(gyroscopeEvents.listen((GyroscopeEvent event) {
        setState(() {
          _gyroscopeValues = <double>[event.x, event.y, event.z];
        });

        String temp = DateTime.now().millisecondsSinceEpoch.toString() +
            "," +
            event.x.toString() +
            "," +
            event.y.toString() +
            "," +
            event.z.toString() +
            "\n";

        debugPrint(temp);
        _insert(temp);

        counter++;
        debugPrint(counter.toString());
        if (counter >= 14) {
          _unsubscribeToGyro();
        }
      }));
    });
  }

  _insert(String value) async {
    data.data = value;
    DatabaseHandler helper = DatabaseHandler.instance;
    await helper.insert(data);
  }

  _deleteRecords() async {
    DatabaseHandler helper = DatabaseHandler.instance;
    helper.deleteAllData();
  }

  Future<Null> writeFile(String text) async {
    debugPrint('$text\n');
    sink.add(utf8.encode('$text\n')); //Use newline as the delimiter
  }

  double xValue = 0.0, yValue = 0.0, zValue = 0.0;

  _read() async {
    DatabaseHandler helper = DatabaseHandler.instance;

    fileName = DateTime.now().millisecondsSinceEpoch.toString() + ".txt";
    getApplicationDocumentsDirectory().then((value) async {
      directory = value;
      file = File('${directory.path}/$fileName');
      debugPrint('${directory.path}/$fileName');
      sink = file.openWrite(mode: FileMode.append);

      List<Map> maps = await helper.queryAllData();
      maps.forEach((value) {
        xValue = xValue + double.parse(value['data'].toString().split(",")[1]);
        yValue = yValue + double.parse(value['data'].toString().split(",")[2]);
        zValue = zValue + double.parse(value['data'].toString().split(",")[3]);
        debugPrint(xValue.toString() +
            " , " +
            yValue.toString() +
            " , " +
            zValue.toString());
      });

      setState(() {
        avgGyroReadings = (xValue / 15).toString() +
            "," +
            (yValue / 15).toString() +
            "," +
            (zValue / 15).toString();

        debugPrint('avgGyroReadings: ' + avgGyroReadings);
        sink.add(utf8.encode(avgGyroReadings));
      });
    });
  }

  _unsubscribeToGyro() async {
    await sink.flush();
    await sink.close();
    await _read();
    _showMessage('Gyro data exported.');
    for (StreamSubscription<dynamic> sub in _streamSubscriptions) {
      sub.cancel();
    }
  }

  @override
  void dispose() {
    for (StreamSubscription<dynamic> sub in _streamSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /*final List<String> accelerometer =
        _accelerometerValues?.map((double v) => v.toStringAsFixed(6))?.toList();*/
    final List<String> gyroscope =
        _gyroscopeValues?.map((double v) => v.toStringAsFixed(6))?.toList();

    return Scaffold(
      key: _scaffoldState,
      appBar: AppBar(title: Text('Gyro Data Recorder')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          /*Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Accelerometer: $accelerometer'),
            ),*/
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Gyroscope: $gyroscope'),
          ),
          RaisedButton(
              child: Text('Start'),
              onPressed: () {
                _subscribeToGyro();
              }),
          Padding(
            padding: EdgeInsets.fromLTRB(5.0, 10.0, 5.0, 5.0),
            child: Text(
              'Average Gyro Readings (x, y, z rad/s):',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(5.0, 0.0, 5.0, 5.0),
            child: Text(avgGyroReadings),
          ),
        ],
      ),
    );
  }

  _showMessage(String message) {
    _scaffoldState.currentState.showSnackBar(
      new SnackBar(
        content: new Text(
          message,
        ),
      ),
    );
  }
}
