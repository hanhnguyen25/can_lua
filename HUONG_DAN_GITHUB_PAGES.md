# Đưa app "Cân cà phê" lên GitHub Pages — hướng dẫn siêu chi tiết

> Chọn **Phần A** nếu bạn không muốn cài phần mềm (chỉ dùng trình duyệt).
> Chọn **Phần B** nếu muốn tự động cập nhật mỗi lần sửa code (cần cài Git + GitHub Desktop).

Trước khi bắt đầu, bạn cần:
- Tài khoản GitHub (chưa có: vào https://github.com → **Sign up** → xác nhận email).
- Project ở `D:\android_can_lua\can_lua` (đã có sẵn code + workflow + gói web).

---

## PHẦN A — Upload bằng trình duyệt, không cần cài gì

### A1. Tạo repository (kho chứa code trên GitHub)

1. Mở trình duyệt, vào **https://github.com/new**
2. Ô **Repository name**: gõ `can_lua`
3. Ô Description: gõ `Cân cà phê` (không bắt buộc)
4. Chọn **Public** (bắt buộc — Pages miễn phí chỉ chạy với repo Public)
5. Các ô còn lại **để nguyên** (không tick "Add a README file")
6. Bấm nút xanh **Create repository**

✅ Xong bước này bạn có trang: `https://github.com/<tên-tài-khoản>/can_lua`

### A2. Giải nén gói web đã build sẵn

1. Mở **File Explorer**, vào `D:\android_can_lua\can_lua`
2. Chuột phải file `can_lua-web-github-pages.zip` → **Extract All…**
3. Ô địa chỉ, gõ `D:\android_can_lua\web_upload` → **Extract**
4. Mở thư mục `web_upload`, bên trong phải có:
   `index.html`, `main.dart.js`, `assets`, `canvaskit`, `icons`, `flutter.js`, `manifest.json`, `.nojekyll`

> File `.nojekyll` có thể bị ẩn. Nếu không thấy: trong File Explorer bấm **View → Show → Hidden items**.

### A3. Upload toàn bộ file lên GitHub

1. Trong repo vừa tạo, bấm **Add file** (góc phải) → **Upload files**
2. Mở thư mục `web_upload` → bấm **Ctrl + A** (chọn tất cả) → kéo thả vào khung **"Drag files here"**
   - Hoặc bấm **choose your files** rồi chọn tất cả file/thư mục
3. Đợi thanh tiến trình chạy xong (khoảng 14 MB, 1–2 phút)
4. Kéo xuống dưới, ô **Commit changes**: gõ `Upload web build`
5. Bấm **Commit changes**

**Nếu danh sách không có `.nojekyll`** (quan trọng, thiếu là web có thể lỗi):
- Bấm **Add file → Create new file**
- Ô tên file: gõ `.nojekyll` (có dấu chấm ở đầu)
- Nội dung: để trống
- Bấm **Commit changes**

### A4. Bật GitHub Pages

1. Trong repo, bấm tab **Settings** (thanh menu phía trên)
2. Menu bên trái, bấm **Pages**
3. Mục **Build and deployment**:
   - **Source**: chọn **Deploy from a branch**
   - **Branch**: chọn **main**, thư mục chọn **/ (root)**
4. Bấm **Save**
5. Đợi 1–2 phút, tải lại trang (F5) — phía trên sẽ hiện:
   **"Your site is live at https://\<tên-tài-khoản\>.github.io/can_lua/"**

### A5. Mở thử trên điện thoại

- Mở link vừa hiện bằng Chrome trên điện thoại.
- Thấy app "Cân cà phê" là thành công.
- Muốn dùng như app: menu **⋮ → Thêm vào màn hình chính**.

### A6. Khi sửa code (cách A)

Mỗi lần sửa xong, làm lại 3 bước:

```powershell
cd D:\android_can_lua\can_lua
flutter build web --release --base-href /can_lua/
New-Item build\web\.nojekyll
```

Rồi upload lại như **A3** (GitHub tự ghi đè file trùng), đợi 1–2 phút.

---

## PHẦN B — Tự động cập nhật bằng GitHub Actions

### B1. Cài Git

1. Vào **https://git-scm.com/download/win**
2. Bấm **Click here to download...** (bản 64-bit)
3. Chạy file vừa tải → bấm **Next** liên tục (để mặc định) → **Install** → **Finish**
4. Kiểm tra: mở **PowerShell**, gõ `git --version`, thấy `git version 2.x` là được

### B2. Cài GitHub Desktop

1. Vào **https://desktop.github.com/download/** → tải và chạy file cài
2. Mở **GitHub Desktop**
3. Bấm **Sign in to GitHub.com** → trình duyệt mở ra → đăng nhập → **Authorize desktop**

### B3. Đưa project vào GitHub Desktop

1. Trong GitHub Desktop: **File → Add local repository…**
2. Ô **Local path**: bấm **Choose…** → chọn `D:\android_can_lua\can_lua` → **Add repository**
3. Nếu hiện thông báo *"this directory does not appear to be a Git repository"*:
   - Bấm **create a repository**
   - **Name**: `can_lua`
   - **Local path**: `D:\android_can_lua`
   - Bấm **Create repository**
4. Cửa sổ **Changes** hiện danh sách file — vài trăm file là bình thường.
5. Góc dưới trái, ô **Summary**: gõ `Cân cà phê - bản web`
6. Bấm nút xanh **Commit to main**
7. Thanh trên bấm **Publish repository**:
   - **Name**: `can_lua`
   - **BỎ TICK** ô *"Keep this code private"* (phải Public)
   - Bấm **Publish repository**

### B4. Bật Pages bằng Actions

1. Trong GitHub Desktop: **Repository → View on GitHub** (mở repo trên web)
2. Vào **Settings → Pages**
3. Mục **Build and deployment → Source**: chọn **GitHub Actions** (không chọn branch)
4. Bấm tab **Actions** (trên cùng repo):
   - Thấy workflow **"Deploy web lên GitHub Pages"** đang chạy (chấm vàng)
   - Đợi 2–4 phút → chấm **xanh** là xong
5. Vào lại **Settings → Pages**, sẽ thấy link:
   `https://<tên-tài-khoản>.github.io/can_lua/`

### B5. Lần sau sửa code

1. Sửa code trong `D:\android_can_lua\can_lua`
2. Mở GitHub Desktop → thấy file thay đổi ở **Changes**
3. Gõ Summary (ví dụ `Sửa giá`) → **Commit to main**
4. Bấm **Push origin** (thanh trên)
5. Vào tab **Actions** chờ chấm xanh (~3 phút) → web tự cập nhật

---

## Lỗi thường gặp & cách sửa

| Hiện tượng | Nguyên nhân | Cách sửa |
|---|---|---|
| Mở link bị **404** | Chưa bật Pages hoặc chọn sai branch | Settings → Pages: branch `main`, thư mục `/(root)`; chờ 2–3 phút |
| Trang **trắng**, F12 thấy 404 file `.js` | Sai `base-href` (tên repo khác `can_lua`) | Build lại `--base-href /tên-repo/`; nếu dùng Actions thì workflow tự đúng |
| Repo báo **private không bật được Pages** | Pages miễn phí chỉ cho repo Public | Settings → General → kéo xuống **Change visibility → Public** |
| GitHub Desktop báo **not a Git repository** | Chưa có `.git` | Làm B3 bước 3 (create a repository) |
| Push bị **rejected** | Trên GitHub có commit mới hơn | Bấm **Pull origin** rồi **Push origin** |
| Actions chấm **đỏ (failed)** | Thiếu gói/Flutter lỗi | Bấm vào workflow → bấm dòng đỏ → chụp ảnh log gửi mình |
| Thiếu file `.nojekyll` | Upload bằng tay bị bỏ file ẩn | Add file → Create new file → `.nojekyll` → Commit |
| App chạy nhưng **mất dữ liệu cũ** | Mỗi tên miền một kho dữ liệu riêng | Dùng **Sao lưu JSON** ở nơi cũ → **Khôi phục** ở nơi mới |

---

## Checklist trước khi bấm Publish

- [ ] Repo **Public**, tên đúng `can_lua`
- [ ] Ở thư mục gốc repo có `index.html`
- [ ] Có file `.nojekyll`
- [ ] Có thư mục `.github/workflows/web.yml` (nếu dùng cách B)
- [ ] **Không** có `android/key.properties` và file `.jks` trong repo (đã được .gitignore chặn — đừng gỡ)
- [ ] Settings → Pages đã bật đúng nguồn

---

## Hiểu nhanh mấy từ hay gặp

| Từ | Nghĩa đơn giản |
|---|---|
| **Repository (repo)** | Thư mục code trên GitHub |
| **Commit** | "Chụp ảnh" các thay đổi kèm ghi chú |
| **Push** | Đẩy commit từ máy lên GitHub |
| **GitHub Pages** | Dịch vụ biến repo thành trang web miễn phí |
| **Actions** | Máy của GitHub tự build/deploy mỗi lần bạn push |
| **base-href** | Đường dẫn gốc của web; phải khớp tên repo (`/can_lua/`) |
