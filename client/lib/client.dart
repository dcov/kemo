import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

class Client extends StatefulWidget {

  Client({
    @required this.address,
    @required this.port
  }) : assert(address != null),
       assert(port != null),
       super(key: ValueKey('$address:$port'));

  final String address;
  final int port;

  @override
  _ClientState createState() => _ClientState();
}

class _ClientState extends State<Client> {

  Future<Socket> _socketFuture;
  Socket _socket;

  void  _connectToHost() {
    _socketFuture = () async {
      final Socket socket = await Socket.connect(widget.address, widget.port);
      _socket = socket;
      if (mounted) {
        setState(() { });
      }
      return socket;
    }();
  }

  void _handleMouseMove(DragUpdateDetails details) {
    print('MouseMove ${details.delta.dx}, ${details.delta.dy}');
  }

  void _handleMouseLeftClick() {
    print('MouseLeftClick');
  }

  void _handleMouseRightClick() {
    print('MouseRightClick');
  }

  @override
  void initState() {
    super.initState();
    _connectToHost();
  }

  @override
  void didUpdateWidget(Client oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(widget.address == oldWidget.address &&
           widget.port == oldWidget.port);
  }

  @override
  void dispose() {
    if (_socket == null) {
      _socketFuture.then((socket) => socket.close());
    } else {
      _socket.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                child: SizedBox(
                  height: 48.0,
                  child: NavigationToolbar(
                    middle: Text(widget.address)))),
              if (_socket == null)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator()))
              else
                ...[
                  _MouseControls(
                    onMove: _handleMouseMove,
                    onLeftClick: _handleMouseLeftClick,
                    onRightClick: _handleMouseRightClick),
                ],
            ]),

        ]));
  }
}

class _MouseControls extends StatelessWidget {

  _MouseControls({
    Key key,
    @required this.onMove,
    @required this.onLeftClick,
    @required this.onRightClick
  }) : assert(onMove != null),
       assert(onLeftClick != null),
       assert(onRightClick != null),
       super(key: key);

  final GestureDragUpdateCallback onMove;

  final VoidCallback onLeftClick;

  final VoidCallback onRightClick;

  Widget _buildMouseButton(VoidCallback onTap) {
    return Flexible(
      flex: 1,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.grey))));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onPanUpdate: onMove)),
        Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: SizedBox(
            height: 48.0,
            child: Row(
              children: <Widget>[
                _buildMouseButton(onLeftClick),
                _buildMouseButton(onRightClick)
              ])))
      ]);
  }
}

