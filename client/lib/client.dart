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
          flex: 9,
          fit: FlexFit.tight,
          child: GestureDetector(
            onPanUpdate: (DragUpdateDetails details) => onMove(details.delta),
            child: CustomPaint(
              painter: _TouchPadPainter(lineColor: Colors.grey),
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
    @required this.onBackspace,
  }) : assert(onText != null),
       super(key: key);

  final ValueChanged<String> onText;

  final VoidCallback onBackspace;

  @override
  _TextInputControlState createState() => _TextInputControlState();
}

class _TextInputControlState extends State<_TextInputControl>
    with SingleTickerProviderStateMixin {

  final GlobalKey<EditableTextState> _editableTextKey = GlobalKey<EditableTextState>();
  TextEditingController _textEditingController;
  FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
    _textEditingController.dispose();
  }

  void requestKeyboard() {
    final EditableTextState editableText = _editableTextKey.currentState;
    editableText.requestKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.of(context).viewInsets;
    final double bottomCustomKeysPadding = viewInsets.bottom > 0 ? viewInsets.bottom - 48 : 0;
    return Column(
      children: <Widget>[
        Spacer(),
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
        Padding(
          padding: EdgeInsets.only(
            bottom: bottomCustomKeysPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              FlatButton(
                onPressed: widget.onBackspace,
                child: Text('Backspace'))
            ])),
        GestureDetector(
          onTap: requestKeyboard,
          child: SizedBox(
            height: 48.0,
            child: Center(
              child: Icon(Icons.keyboard))))
      ]);
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

  final GlobalKey<_TextInputControlState> _textInputControlKey = GlobalKey<_TextInputControlState>();
  Future<Socket> _socketFuture;
  Socket _socket;
  AnimationController _switcherController;

  static const Duration _kSwitcherDuration = Duration(milliseconds: 250);

  void _handleAnimationStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      final _TextInputControlState textInputControl = _textInputControlKey.currentState;
      textInputControl.requestKeyboard();
    }
  }

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
    _switcherController.addStatusListener(_handleAnimationStatusChange);
  }

  @override
  void didUpdateWidget(Client oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(widget.address == oldWidget.address &&
           widget.port == oldWidget.port);
  }

  @override
  void dispose() {
    _switcherController.removeStatusListener(_handleAnimationStatusChange);
    _switcherController.dispose();
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
                  key: _textInputControlKey,
                  onText: _socket.sendText,
                  onBackspace: _socket.sendBackspace)))
        ]));
  }
}

