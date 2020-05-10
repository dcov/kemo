import 'dart:io' show Socket;
import 'dart:typed_data' show Uint8List;
import 'dart:ui' show Offset;

extension SocketMessages on Socket {

  void _send(Uint8List msg) => this.add(msg);

  // Move values have to be integers between -63 and 63.
  int _convertMove(double value) => value.round().clamp(-63, 63);

  // Move values are packed into 8 bits:
  //
  //     1 - MSB is always set.
  // 0 | 1 - 7th bit is the sign bit.
  // 0 | 1 - The remaining 6 bits hold the data.
  // 0 | 1
  // 0 | 1
  // 0 | 1
  // 0 | 1
  // 0 | 1
  int _packMove(int value) {
    return value >= 0
          // Value is positive so the 7th bit is 0.
        ? (value | 0x80)
          // Value is negative so the 7th bit is 1, and the absolute value is used.
        : (value.abs() | 0xC0); 
  }

  void sendMouseMove(Offset offset) {
    final Uint8List data = Uint8List(2);
    final int dx = _convertMove(offset.dx);
    final int dy = _convertMove(offset.dy);

    if (dx == 0 && dy == 0) return;

    data[0] = _packMove(dx);
    data[1] = _packMove(dy);

    _send(data);
  }

  void sendMouseLeftClick() {
    final Uint8List data = Uint8List(1);
    data[0] = 0x80;
    _send(data);
  }

  void sendMouseRightClick() {
    final Uint8List data = Uint8List(1);
    data[0] = 0x81;
    _send(data);
  }
}

