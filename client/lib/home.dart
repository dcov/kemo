import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'client.dart';

class Home extends StatefulWidget {

  Home({
    Key key,
    @required this.box
  }) : super(key: key);

  final Box box;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  Future<void> _onAddHost() async {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(48.0),
        child: NavigationToolbar(
          middle: Text('Kemo'),
          trailing: IconButton(
            icon: Icon(Icons.add),
            onPressed: _onAddHost))));
  }
}

Future<String> _showAddHostDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext builderContext) {
    });
}

class _AddHostDialog extends StatefulWidget {

  _AddHostDialog({ Key key }) : super(key: key);

  @override
  _AddHostDialogState createState() => _AddHostDialogState();
}

class _AddHostDialogState extends State<_AddHostDialog> {

  @override
  Widget build(BuildContext context) {
    showDatePicker();
    return Dialog(
      child: SizedBox());
  }
}

