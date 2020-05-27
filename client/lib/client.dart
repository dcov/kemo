import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'messages.dart';
import 'widgets.dart';

class _TouchPadPainter extends CustomPainter {

  const _TouchPadPainter({ this.lineColor });

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double offsetX = size.width / 2;
    canvas.drawLine(
      Offset(offsetX, size.height),
      Offset(offsetX, size.height - (size.height / 5)),
      Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(_TouchPadPainter oldPainter) {
    return this.lineColor != oldPainter.lineColor;
  }
}

class _TouchInputControl extends StatelessWidget {

  _TouchInputControl({
    Key key,
    @required this.onMove,
    @required this.onScroll,
    @required this.onLeftClick,
    @required this.onRightClick,
  }) : assert(onMove != null),
       assert(onScroll != null),
       assert(onLeftClick != null),
       assert(onRightClick != null),
       super(key: key);

  final ValueChanged<Offset> onMove;
  
  final ValueChanged<Offset> onScroll;

  final VoidCallback onLeftClick;

  final VoidCallback onRightClick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Flexible(
          flex: 4,
          fit: FlexFit.tight,
          child: CustomPaint(
            painter: _TouchPadPainter(lineColor: Colors.grey),
            child: GestureDetector(
              onPanUpdate: (DragUpdateDetails details) => onMove(details.delta),
              child: Row(
                children: <Widget>[
                  Flexible(
                    flex: 1,
                    fit: FlexFit.tight,
                    child:  GestureDetector(
                      onTap: onLeftClick)),
                  Flexible(
                    flex: 1,
                    fit: FlexFit.tight,
                    child: GestureDetector(
                      onTap: onRightClick))
                ])))),
        Flexible(
          flex: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.grey),
            child: GestureDetector(
              onVerticalDragUpdate: (DragUpdateDetails details) {
                onScroll(details.delta);
              }))),
      ]);
  }
}

class _RedirectingFormatter implements TextInputFormatter {

  _RedirectingFormatter(this.onText);

  final ValueChanged<String> onText;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue newValue) {
    if (newValue.text.isNotEmpty) {
      onText(newValue.text);
    }
    return TextEditingValue.empty;
  }
}


class _TextInputControl extends StatefulWidget {

  _TextInputControl({
    Key key,
    @required this.onText,
  }) : assert(onText != null),
       super(key: key);

  final ValueChanged<String> onText;

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
                    _RedirectingFormatter(widget.onText)
                  ])),
            ]);
        }));
  }
}

class Client extends StatefulWidget {

  Client({
    @required this.address,
    @required this.port
  }) : assert(address != null),
       assert(port != null),
       // Usually a [Key] isn't initialized by the consumer, but in this case
       // we're using the [address] and [port] as the 'identity' of the [Widget]
       // instead of the [key].
       super(key: ValueKey('$address:$port'));

  final String address;
  final int port;

  @override
  _ClientState createState() => _ClientState();
}

class _ClientState extends State<Client>
    with SingleTickerProviderStateMixin {

  Future<Socket> _socketFuture;
  Socket _socket;
  AnimationController _switcherController;
  FocusNode _textInputFocus;

  static const Duration _kSwitcherDuration = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    // We initialize the [_socket] in an anonymous async function, and store the
    // [Future] in case we are disposed before it completes so that we can then 
    // listen to the [Future] to dispose it once it completes.
    _socketFuture = () async {
      final Socket socket = await Socket.connect(widget.address, widget.port);
      _socket = socket;
      if (mounted) {
        setState(() { });
      }
      return socket;
    }();

    _switcherController = AnimationController(
      duration: _kSwitcherDuration,
      value: 0.0,
      vsync: this);

    _textInputFocus = FocusNode();
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
      _socketFuture.then((Socket socket) => socket.close());
    } else {
      _socket.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top),
            child: SizedBox(
              height: 48.0,
              child: NavigationToolbar(
                middle: Text(widget.address),
                trailing: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0),
                  child: IconButtonSwitcher(
                    animation: _switcherController,
                    firstIcon: Icons.keyboard,
                    secondIcon: Icons.mouse,
                    onFirstPressed: _switcherController.forward,
                    onSecondPressed: _switcherController.reverse))))),
          if (_socket == null)
            Expanded(
              child: Center(
                child: CircularProgressIndicator()))
          else
            Expanded(
              child: VerticalSwitcher(
                animation: _switcherController,
                top: _TouchInputControl(
                  onMove: _socket.sendMove,
                  onScroll: _socket.sendScroll,
                  onLeftClick: _socket.sendLeftClick,
                  onRightClick: _socket.sendRightClick),
                bottom: _TextInputControl(
                  onText: _socket.sendText)))
        ]));
  }
}

