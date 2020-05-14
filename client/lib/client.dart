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
  FocusNode _focusNode;
  FocusAttachment _focusAttachment;
  TextInputConnection _textInputConnection;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 100),
      value: 0.0,
      vsync: this);
    _focusNode = FocusNode();
    _focusAttachment = _focusNode.attach(context);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _textInputConnection?.close();
    _focusAttachment.detach();
    _focusNode.dispose();
    _animationController.dispose();
  }

  void _showKeyboard() {
    print('Showing keyboard');
    if (!_focusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_focusNode);
    } else {
      _maybeOpenInputConnection();
    }
  }

  void _handleFocusChange() {
    print('Focus changed to ${_focusNode.hasFocus}');
    if (_focusNode.hasFocus && _focusNode.consumeKeyboardToken()) {
      _maybeOpenInputConnection();
    } else {
      if (_textInputConnection != null) {
        _textInputConnection.close();
        _textInputConnection = null;
      }
    }
  }

  void _maybeOpenInputConnection() {
    if (_textInputConnection == null) {
      print('Opening input connection');
      _textInputConnection = TextInput.attach(this, TextInputConfiguration());
    }
    print('showing input connection');
    _textInputConnection.show();
  }

  @override
  TextEditingValue get currentTextEditingValue => null;

  @override
  void performAction(TextInputAction action) {
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    print('Updating text editing value to: ${value.text}');
  }

  void updateFloatingCursor(RawFloatingCursorPoint _) {}

  @override
  void connectionClosed() {
    print('Connection closed');
    assert(_textInputConnection != null);
    _textInputConnection.connectionClosedReceived();
    _textInputConnection = null;
  }

  Future<bool> _maybeHandleBackPress() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _maybeHandleBackPress,
      child: Stack(
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
        ]));
  }
}

