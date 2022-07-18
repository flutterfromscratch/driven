import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';

// class MD5Utils {
Future<String?> getMD5(String filePath) async {
  final file = File(filePath);
  if (!file.existsSync()) return null;
  try {
    final stream = file.openRead();
    final hash = await md5.bind(stream).first;
    // NOTE: You might not need to convert it to base64
    return HEX.encode(hash.bytes);
  } catch (exception) {
    return null;
  }
}
// }
