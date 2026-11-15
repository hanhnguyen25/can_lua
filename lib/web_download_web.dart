import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Tải file trực tiếp trên trình duyệt: tạo Blob rồi bấm thẻ <a download>.
void taiFile(Uint8List bytes, String tenFile, String mime) {
  final parts = <JSAny>[bytes.toJS].toJS;
  final blob = web.Blob(parts, web.BlobPropertyBag(type: mime));
  final url = web.URL.createObjectURL(blob);
  final a = web.document.createElement('a') as web.HTMLAnchorElement;
  a
    ..href = url
    ..download = tenFile
    ..click();
  // Thu hồi URL sau khi trình duyệt kịp bắt đầu tải
  Future<void>.delayed(
    const Duration(seconds: 5),
    () => web.URL.revokeObjectURL(url),
  );
}
