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
       // Usually a [key] isn't initialized by the consumer, but in this case
       // since we're using the [address] and [port] as the identity, it makes
       // sense to 
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
            _TextInputControl(onTextInput: _socket.sendText),
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

class _TextInputControl extends StatefulWidget {

  _TextInputControl({
    Key key,
    @required this.onTextInput,
  }) : assert(onTextInput != null),
       super(key: key);

  final ValueChanged<String> onTextInput;

  @override
  _TextInputControlState createState() => _TextInputControlState();
}

class _TextInputControlState extends State<_TextInputControl>
    with SingleTickerProviderStateMixin {

  final GlobalKey<EditableTextState> _editableTextKey = GlobalKey<EditableTextState>();
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

  Future<bool> _handleBackPress() {
    _animationController.reverse();
    return Future.value(true);
  }

  void _showKeyboard() {
    final EditableTextState editableText = _editableTextKey.currentState;
    editableText.requestKeyboard();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: ValueListenableBuilder(
        valueListenable: _animationController,
        builder: (BuildContext context, double value, _){
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
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((150 * value).round()))),
              Offstage(
                offstage: true,
                child: EditableText(
                  key: _editableTextKey,
                  focusNode: _focusNode,
                  controller: _textEditingController,
                  backgroundCursorColor: Colors.transparent,
                  cursorColor: Colors.transparent,
                  style: const TextStyle(),
                  inputFormatters: <TextInputFormatter>[
                    _RedirectingFormatter(widget.onTextInput)
                  ])),
            ]);
        }));
  }
}

class _RedirectingFormatter implements TextInputFormatter {

  _RedirectingFormatter(this.onTextInput);

  final ValueChanged<String> onTextInput;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue newValue) {
    if (newValue.text.isNotEmpty) {
      onTextInput(newValue.text);
    }
    return TextEditingValue.empty;
  }
}

