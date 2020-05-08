import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Box get _box => widget.box;

  void _onAddHost() async {
    final MapEntry<String, int> host = await _showAddHostDialog(context);
    if (host != null) {
      setState(() {
        widget.box.put(host.key, host.value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List addresses = _box.keys.toList();
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: SizedBox(
            height: 48.0,
            child: NavigationToolbar(
              middle: Text('Kemo'),
              trailing: IconButton(
                icon: Icon(Icons.add),
                onPressed: _onAddHost)))),
        Expanded(
          child: ListView.builder(
            itemCount: addresses.length,
            itemBuilder: (BuildContext context, int index) {
              final String address = addresses[index];
              final int port = _box.get(address);
              return ListTile(
                title: Text('$address:$port'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Client(address: address, port: port)));
                });
            }))
      ]);
  }
}

Future<MapEntry<String, int>> _showAddHostDialog(BuildContext context) {

  String ipAddress;
  String portNumber;

  final ValueNotifier<bool> valuesAreValid = ValueNotifier(false);
  void validateValues() {
    valuesAreValid.value = ipAddress.isNotEmpty && int.tryParse(portNumber) != null;
  }
  
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Add Host',
                  style: TextStyle()))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter host IP address'),
                onChanged: (String newIpAddress) {
                  ipAddress = newIpAddress;
                  validateValues();
                })),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter host port number'),
                onChanged: (String newPortNumber) {
                  portNumber = newPortNumber;
                  validateValues();
                })),
            ValueListenableBuilder(
              valueListenable: valuesAreValid,
              builder: (BuildContext context, bool valuesAreValid, _) {
                return FlatButton(
                  child: Text('Confirm'),
                  onPressed: valuesAreValid
                    ? () => Navigator.pop(context, MapEntry(ipAddress, int.parse(portNumber)))
                    : null);
              })
          ]));
    });
}

