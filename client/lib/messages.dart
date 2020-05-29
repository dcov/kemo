import 'dart:convert' show utf8;
import 'dart:io' show Socket;
import 'dart:typed_data' show Uint8List;
import 'dart:ui' show Offset;

extension SocketMessenger on Socket {

  void _send(Uint8List msg) => this.add(msg);

  void sendMove(Offset offset) {

    int convert(double value) => value.round().clamp(-63, 63);

    final int dx = convert(offset.dx);
    final int dy = convert(offset.dy);

    // If we haven't moved in any axis, there's no point in sending a message.
    if (dx == 0 && dy == 0) return;

    // Move values are packed into 8 bits:
    //
    //     1 - 8th bit is always set to 0.
    // 0 | 1 - 7th bit is the sign bit.
    // 0 | 1 - The remaining 6 bits hold the data.
    // 0 | 1
    // 0 | 1
    // 0 | 1
    // 0 | 1
    // 0 | 1
    int pack(int value) {
      if (value < 0) {
        return value.abs() | 0x40;
      }
      return value;
    }

    // Move messages are sent in 2 bytes: 1st byte is the x-axis offset, 2nd byte is the y-axis offset.
    final Uint8List data = Uint8List(2);
    data[0] = pack(dx);
    data[1] = pack(dy);

    _send(data);
  }

  void sendScroll(Offset offset) {
    final int dy = offset.dy.round().clamp(-31, 31);

    if (dy  == 0) return;

    final Uint8List data = Uint8List(1);
    data[0] = dy < 0 ? dy.abs() | 0xE0 : dy | 0xC0;

    _send(data);
  }

  void sendLeftClick() {
    final Uint8List data = Uint8List(1);
    // Left click is packed into a single byte where only the 8th bit is set to one.
    data[0] = 0x80;
    _send(data);
  }

  void sendRightClick() {
    final Uint8List data = Uint8List(1);
    // Right click is packed into a single byte where the 8th and the 7th bit are set to one.
    data[0] = 0xC0;
    _send(data);
  }

  void sendText(String value) {
    assert(value.length == 1);
    // Text values are packed using the UTF-8 encoding scheme.
    _send(utf8.encode(value));
  }

  void sendBackspace() {
    _send(Uint8List.fromList([0x08]));
  }
}

