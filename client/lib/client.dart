import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'messages.dart';

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

  FocusNode _focusNode;

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

  @override
  void initState() {
    super.initState();
    _connectToHost();
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(Client oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(widget.address == oldWidget.address &&
           widget.port == oldWidget.port);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (_socket == null) {
      _socketFuture.then((socket) => socket.close());
    } else {
      _socket.close();
    }
    super.dispose();
  }

  void _showKeyboard() {
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
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 48.0),
                      child: _MouseControl(
                        onMove: (details) => _socket.sendMouseMove(details.delta),
                        onLeftClick: _socket.sendMouseLeftClick,
                        onRightClick: _socket.sendMouseRightClick))),
                ],
            ]),
            if (_socket != null)
              _KeyboardControl(),
        ]));
  }
}

class _MouseControl extends StatelessWidget {

  _MouseControl({
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
            color: Colors.grey),
          child: SizedBox.expand())));
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

class _KeyboardControl extends StatefulWidget {

  @override
  _KeyboardControlState createState() => _KeyboardControlState();
}

class _KeyboardControlState extends State<_KeyboardControl>
    with SingleTickerProviderStateMixin
    implements TextInputClient {

  AnimationController _animationController;
  TextEditingController _textEditingController;
  FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 100),
      value: 0.0,
      vsync: this);
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
    _textEditingController.dispose();
    _animationController.dispose();
  }

  @override
  TextEditingValue get currentTextEditingValue => TextEditingValue.empty;

  @override
  void performAction(TextInputAction action) {
  }

  @override
  void updateEditingValue(TextEditingValue value) {
  }

  void updateFloatingCursor(RawFloatingCursorPoint _) { }

  @override
  void connectionClosed() {
  }

  void _showKeyboard() {
    TextInput.attach(
      this,
      TextInputConfiguration());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: _showKeyboard,
            child: SizedBox(
              height: 48.0,
              child: Center(
                child: Icon(Icons.keyboard))))),
        ValueListenableBuilder(
          valueListenable: _animationController,
          builder: (BuildContext context, double value, _) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha((150 * value).round())));
          }),
        Offstage(
          offstage: true,
          child: EditableText(
            controller: _textEditingController,
            focusNode: _focusNode,
            cursorColor: Colors.transparent,
            backgroundCursorColor: Colors.transparent,
            style: TextStyle(),
            onChanged: ))
      ]);
  }
}

