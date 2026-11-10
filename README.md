# Cân cà phê (can_lua)

Ứng dụng Android (Flutter) dùng để **cân và tính tiền cà phê** tại điểm thu mua: nhập trọng lượng
từng bao, trừ bì, trừ độ/tạp, tính thành tiền, lưu phiếu, xem lịch sử – thống kê và xuất Excel /
chia sẻ ảnh phiếu.

## Tính năng

- **Hai phần riêng biệt** — *Cà tươi* và *Cà nhân* — mỗi phần có số liệu và cài đặt riêng
  (chuyển qua lại không mất dữ liệu).
- **Lưới nhập 5 cột × 5 hàng** cho mỗi khối (25 bao/khối): mỗi ô là một bao, nhãn 5/10/15/20/25
  là số bao tích luỹ; cột cuối đầy thì tự thêm khối mới.
- **Công thức**: `thực = (tổng − bì × số bao bì) × (1 − %độ − %tạp)`, `tiền = thực × đơn giá`.
  `%độ` và `%tạp` chỉ áp dụng cho *Cà nhân*; số bao bì để trống = bằng số bao đã cân.
- **Nhớ cài đặt**: bì mỗi bao, số bao bì, % trừ, đơn giá được lưu riêng cho từng phần và tự điền
  lại khi mở app.
- **Phiếu cân**: nhập tên khách/ghi chú, **sửa lại số cân** của phiếu (kể cả phiếu đã lưu), lưu,
  xoá, chia sẻ ảnh phiếu qua Zalo/Messenger…
- **Lịch sử**: tìm theo tên khách/ghi chú, lọc theo loại; **thống kê** theo tháng, theo ngày,
  theo khách hàng (số phiếu, số bao, khối lượng thực, thành tiền).
- **Xuất Excel** (tất cả hoặc tháng đang xem) và **sao lưu / khôi phục** file JSON.

## Cấu trúc mã nguồn

| File | Nội dung |
| --- | --- |
| `lib/main.dart` | Khởi động app, 2 tab Cà tươi / Cà nhân (`IndexedStack`) |
| `lib/models.dart` | `Block` (lưới 25 ô), `Calc` (công thức tính), `Ticket` (phiếu + JSON) |
| `lib/weigh_screen.dart` | Màn hình cân, bảng cài đặt, thanh tổng kết |
| `lib/receipt_screen.dart` | Xem phiếu, sửa tên khách/ghi chú, lưu, chia sẻ ảnh, xoá |
| `lib/grid_editor.dart` | Sửa số cân của phiếu đã lưu |
| `lib/history_screen.dart` | Danh sách phiếu và thống kê |
| `lib/storage.dart` | Lưu phiếu trong `SharedPreferences` |
| `lib/settings.dart` | Lưu cài đặt nhập liệu theo từng phần |
| `lib/export.dart` | Xuất Excel, sao lưu/khôi phục, chia sẻ ảnh |
| `lib/utils.dart` | Màu sắc, đọc số, định dạng kg / % / tiền / ngày giờ |
| `tool/generate_icons.py` | Sinh lại bộ icon (Pillow) |

## Chạy và kiểm thử

```bash
flutter pub get
flutter run                 # chạy trên máy/emulator đang kết nối
flutter test                # 22 test: công thức, lưu trữ, giao diện cơ bản
flutter analyze
flutter build apk --release # tạo build/app/outputs/flutter-apk/app-release.apk
```

## Ký bản release

Bản release dùng khoá riêng, cấu hình trong `android/key.properties` (đã bị `.gitignore` bỏ qua):

```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=upload-keystore.jks
```

- Keystore: `android/app/upload-keystore.jks`.
- **Sao lưu keystore và mật khẩu ở nơi an toàn** — mất keystore là không thể cập nhật app trên
  CH Play cho các bản đã phát hành; cũng không được commit các file này.
- Máy chưa có `key.properties` vẫn build được (ký tạm bằng khoá debug).
- Trước khi phát hành chính thức: đổi `applicationId` (hiện là `com.example.can_lua`), kèm di
  chuyển `MainActivity` sang package mới.

## Ghi chú kỹ thuật

- Dữ liệu lưu bằng `SharedPreferences` dưới dạng một chuỗi JSON; phù hợp vài nghìn phiếu, nếu
  nhiều hơn nên chuyển sang SQLite.
- Mọi chữ trong app là tiếng Việt, số dùng dấu `.` ngăn nghìn và dấu `,`/`.` cho phần thập phân.
