import 'dart:typed_data';

typedef BytesToValueMapper = Object? Function(List<int>);

class LittleEndianExtractor {
  static int extractUint8(final List<int> bytes) {
    final data = ByteData.view(Uint8List.fromList(bytes).buffer);
    return data.getUint8(0);
  }

  static int extractUint16(final List<int> bytes) {
    final data = ByteData.view(Uint8List.fromList(bytes).buffer);
    return data.getUint16(0, Endian.little);
  }

  static int extractInt16(final List<int> bytes) {
    final data = ByteData.view(Uint8List.fromList(bytes).buffer);
    return data.getInt16(0, Endian.little);
  }

  static int extractInt64(final List<int> bytes) {
    final data = ByteData.view(Uint8List.fromList(bytes).buffer);
    return data.getInt64(0, Endian.little);
  }
}