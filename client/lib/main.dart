import 'dart:io' show Directory;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as pathProvider;

import 'home.dart';

void main() {
  runApp(Builder(
    builder: (BuildContext context) {
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.portraitUp
      ]);
      return Kemo();
    }));
}

class Kemo extends StatefulWidget {

  Kemo({ Key key }) : super(key: key);

  @override
  _KemoState createState() => _KemoState();
}

class _KemoState extends State<Kemo> {

  Box _box;

  void _initBox() async {
    final Directory appDir = await pathProvider.getApplicationDocumentsDirectory();
    Hive.init(path.join(path.join(appDir.path, 'data')));
    final Box box = await Hive.openBox('main');
    setState(() { _box = box; });

  }

  @override
  void initState() {
    super.initState();
    _initBox();
  }

  @override
  void dispose() {
    if (_box != null) _box.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Material(
        child: _box == null
          ? Center(child: CircularProgressIndicator())
          : Home(box: _box)));
  }
}

