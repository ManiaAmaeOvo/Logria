import 'package:flutter/services.dart';

/// Android Storage Access Framework: no broad storage/network permissions.
abstract final class DocumentFiles {
  static const channel = MethodChannel('com.logria.logria/documents');
  static Future<bool> save(String name, String content) async =>
      await channel.invokeMethod<bool>('save', {
        'name': name,
        'content': content,
      }) ??
      false;
  static Future<String?> open() => channel.invokeMethod<String>('open');
}
