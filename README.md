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
- **Trừ độ theo độ ẩm (Cà nhân)**: nhập **độ ẩm (%)**, app tự tra *bảng trừ trọng lượng cà phê
  nhân xô* để ra `%độ` (15,5 độ → trừ 0,57 %; 17,2 độ → trừ 2,57 %). Độ ẩm ≤ 15 độ không trừ;
  trên 25 độ áp mức tối đa 19,47 %. Độ ẩm và % trừ được in trên phiếu, Excel và file sao lưu.
  Số kg trừ độ được **làm tròn tới kg gần nhất** (5,7 kg → 6 kg) rồi mới trừ vào khối lượng.
- **Phiếu mới sạch số**: lưu phiếu xong (hoặc bấm *Xóa số cân*), toàn bộ thông số cài đặt — bì,
  số bao bì, số bao, độ ẩm, tạp, đơn giá — tự về 0 cho phiếu mới.
- **Phiếu cân**: nhập tên khách/ghi chú, **sửa lại số cân** của phiếu (kể cả phiếu đã lưu), lưu,
  xoá, chia sẻ ảnh phiếu qua Zalo/Messenger…
- **Số mạ chỉ hiển thị**: Cài đặt hiện *Số mạ đã nhập* (đếm theo số ô có số), không nhập tay; phiếu
  cũng chỉ hiện số mạ. Muốn đổi số mạ thì sửa số ô cân (hoặc dùng *Sửa số cân*).
- **Sửa mọi thông số của phiếu đã lưu**: bì mỗi bao, số bao bì trừ, độ ẩm, trừ tạp, đơn giá —
  sửa trên phiếu rồi bấm *Lưu thay đổi*. Đổi độ ẩm thì % trừ độ tự tra lại theo bảng; *Thành tiền*
  chỉ hiển thị, luôn tính tự động từ các thông số trên.
- **Tự xuống ô**: trong Cài đặt chọn *Tắt / 2 số / 3 số / 4 số* — nhập đủ số là con trỏ tự nhảy
  sang ô kế tiếp (chờ 0,4 giây, nên gõ `62,5` vẫn không bị nhảy ngang).
- **Cột gọn, số tổng tự thu nhỏ**: các cột có khoảng cách, số tổng dài tự co lại vừa cột nên
  không đè lên nhau, dễ đọc trên màn hình nhỏ.
- **Chạy trên web**: `flutter build web --release` ra `build/web`. Trên trình duyệt, *Xuất Excel*,
  *Sao lưu JSON* và *Chia sẻ ảnh phiếu* sẽ **tải file trực tiếp** về máy; dữ liệu lưu trong
  `localStorage` nên có dải nhắc sao lưu ở màn hình Lịch sử.
- **Giao diện theo từng phần**: Cà tươi dùng màu xanh dương, Cà nhân dùng màu xanh lá. Hai số quan trọng
  nhất (khối lượng thực và thành tiền) luôn hiện ở thanh dưới cùng, kèm nút *TÍNH TIỀN*; dải trên cùng
  cho biết số mạ, tổng cân, trừ bì và tỷ lệ thực/trừ. Ô cân đổi màu khi đã nhập, số dài tự thu nhỏ chữ.
- **Chữ nhỏ gọn**: toàn bộ cỡ chữ giảm 10 % so với cài đặt cỡ chữ của máy.
- **Lịch sử**: tìm theo tên khách/ghi chú, lọc theo loại; **thống kê** theo tháng, theo ngày,
  theo khách hàng (số phiếu, số bao, khối lượng thực, thành tiền).
- **Xuất Excel** (tất cả hoặc tháng đang xem) và **sao lưu / khôi phục** file JSON.

## Cấu trúc mã nguồn

| File | Nội dung |
| --- | --- |
| `lib/main.dart` | Khởi động app, 2 tab Cà tươi / Cà nhân (`IndexedStack`) |
| `lib/models.dart` | `Block` (lưới 25 ô), `Calc` (công thức tính), `Ticket` (phiếu + JSON) |
| `lib/do_am_ca_phe.dart` | Bảng trừ độ ẩm và hàm tra cứu (15 → 25 độ) |
| `lib/weigh_screen.dart` | Màn hình cân: dải tổng hợp, lưới ô, thanh kết quả, bảng cài đặt |
| `lib/receipt_screen.dart` | Xem phiếu, sửa tên khách/ghi chú, lưu, chia sẻ ảnh, xoá |
| `lib/grid_editor.dart` | Sửa số cân của phiếu đã lưu |
| `lib/history_screen.dart` | Danh sách phiếu và thống kê |
| `lib/storage.dart` | Lưu phiếu trong `SharedPreferences` |
| `lib/settings.dart` | Lưu cài đặt nhập liệu theo từng phần |
| `lib/export.dart` | Xuất Excel, sao lưu/khôi phục, chia sẻ ảnh |
| `lib/utils.dart` | Màu sắc, đọc số, định dạng kg / % / tiền / ngày giờ |
| `lib/theme.dart` | Hệ thống giao diện: bảng màu, bo góc, kiểu chữ số, thẻ và nhãn dùng chung |
| `lib/weight_cell.dart` | Ô nhập số cân dùng chung cho màn hình cân và màn hình sửa số cân |
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
