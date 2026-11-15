# Build web cho app "Cân cà phê" (can_lua)

App Flutter có sẵn thư mục `web/` nên build được bản chạy trên trình duyệt.

## 1. Chạy thử (dev, có hot reload)

```powershell
cd D:\android_can_lua\can_lua
flutter run -d chrome
```

Muốn dùng Edge: `flutter run -d edge`. Lần đầu Flutter tải thêm gói cho web, sau đó tự mở trình duyệt.

## 2. Build bản phát hành

```powershell
flutter build web --release
```

- Kết quả nằm trong `build\web\` (index.html, main.dart.js ~3 MB, assets…).
- Thời gian build khoảng 1–2 phút.
- Nếu deploy ở địa chỉ có thư mục con (GitHub Pages `user.github.io/can_lua/`):

```powershell
flutter build web --release --base-href /can_lua/
```

## 3. Chạy bản build trên máy

```powershell
python -m http.server 8099 --directory build\web
```

Mở **http://127.0.0.1:8099** trên Chrome/Edge.

> Không mở trực tiếp file `index.html` bằng `file://` — service worker và tài nguyên sẽ không tải đúng.

## 4. Đưa lên mạng (chọn 1 cách)

| Cách | Lệnh / thao tác |
|---|---|
| **Netlify Drop** (dễ nhất) | Vào netlify.com/drop → kéo thả thư mục `build\web` → nhận link |
| **Firebase Hosting** | `npm i -g firebase-tools` → `firebase login` → `firebase init hosting` (public: `build/web`) → `firebase deploy` |
| **Vercel** | `npm i -g vercel` → `vercel --prod` trong thư mục project |
| **GitHub Pages** | Xem hướng dẫn chi tiết bên dưới |

### GitHub Pages — cách A: upload bằng trình duyệt (không cần cài Git)

1. Tạo repo **Public** trên GitHub, tên đúng bằng `can_lua` (tên repo = đường dẫn web).
2. Build với base-href trùng tên repo (bản zip mình đã build sẵn dùng `/can_lua/`):

   ```powershell
   flutter build web --release --base-href /can_lua/
   New-Item build\web\.nojekyll
   ```

3. Giải nén `can_lua-web-github-pages.zip`, rồi trong repo: **Add file → Upload files** → kéo thả **toàn bộ nội dung** thư mục vừa giải nén (index.html, main.dart.js, assets, icons, .nojekyll…) → **Commit changes**.
4. Vào **Settings → Pages** → *Build and deployment* → Source: **Deploy from a branch** → Branch: `main`, folder `/ (root)` → **Save**.
5. Đợi 1–2 phút, mở: `https://<tên-github>.github.io/can_lua/`

> Nếu không thấy file `.nojekyll` sau khi kéo thả: **Add file → Create new file**, đặt tên `.nojekyll`, để trống nội dung rồi Commit. File này để Pages không bỏ qua các thư mục bắt đầu bằng `_`.

### GitHub Pages — cách B: tự động bằng GitHub Actions (khuyên dùng lâu dài)

Trong project đã có sẵn workflow `.github/workflows/web.yml` (tự build + deploy mỗi lần push).

1. Cài **Git** và **GitHub Desktop** (máy bạn chưa có `git`).
2. Tạo repo Public `can_lua`, đưa code lên (GitHub Desktop: Add local repository → Publish).
3. Trong repo: **Settings → Pages → Source: GitHub Actions**.
4. Push lên nhánh `main` → tab **Actions** chạy → xong sẽ có link `https://<tên-github>.github.io/can_lua/`.
5. Mỗi lần sửa code: commit + push, web tự cập nhật (workflow tự dùng `--base-href` theo tên repo).

### Lưu ý riêng của GitHub Pages

- Repo phải **Public** (Pages miễn phí chỉ cho repo public).
- **Tên repo phải khớp base-href**. Nếu đặt tên khác `can_lua`, build lại với `--base-href /tên-repo/`.
- Dữ liệu web lưu theo **tên miền** `https://<tên-github>.github.io`, nên mọi repo cùng tài khoản dùng **chung một kho dữ liệu** — cần thì bấm Sao lưu trước khi thử repo khác.
- Cách A: sửa code phải build lại + upload lại. Cách B: chỉ cần push.

## 5. Lưu ý khi dùng bản web

- **Dữ liệu** lưu trong `localStorage` của trình duyệt: mỗi máy/trình duyệt một kho riêng, **không đồng bộ** với app Android. Xoá dữ liệu trình duyệt là mất phiếu → nên dùng "Sao lưu" định kỳ. Màn hình Lịch sử có dải nhắc việc này.
- **Xuất Excel / Sao lưu JSON / Chia sẻ ảnh phiếu**: trên web đã hỗ trợ **tải file trực tiếp** về máy (Blob + thẻ `<a download>`), không cần `share_plus`.
- **Khôi phục sao lưu** (chọn file JSON) chạy được trên web.
- Có thể "Thêm vào màn hình chính" để dùng như app (PWA), nhưng vẫn cần mạng cho lần mở đầu.

## 6. Lỗi thường gặp

| Lỗi | Cách xử lý |
|---|---|
| `AGP 9.1.0 is lower than Flutter's minimum 9.1.1` | Sửa `android/settings.gradle.kts`: `com.android.application` version `9.1.1` |
| Trang trắng khi mở `index.html` bằng `file://` | Chạy qua http server (bước 3) |
| Deploy thư mục con bị 404 | Build lại với `--base-href /ten-thu-muc/` |

## 7. Kiểm tra nhanh

```powershell
flutter analyze
flutter test
flutter build web --release
```
