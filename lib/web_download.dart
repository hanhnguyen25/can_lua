// Chọn bản "tải file" phù hợp: web dùng Blob của trình duyệt,
// nền tảng khác dùng bản rỗng (đã chia sẻ bằng share_plus).
export 'web_download_stub.dart'
    if (dart.library.js_interop) 'web_download_web.dart';
