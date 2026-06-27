# Kế hoạch sửa lỗi — Đợt test của nhóm

**Người lập:** Lê Văn Quang · **Ngày:** 27/06/2026 · **Repo:** Army-Ecommerce-FE (frontend)

## Cách dùng tài liệu này

Mỗi lỗi được tách thành 1 **TIP** độc lập, có thể sửa riêng từng cái. Quy trình:

> Bạn chọn 1 TIP → mình sửa code → bạn test trên máy thật → nếu OK, mình commit (mỗi TIP 1 commit, message rõ ràng).

Một vài TIP cần biết **mã lỗi trả về từ Backend** (BE). Với các TIP đó, khi bắt tay vào sửa mình sẽ nhờ bạn reproduce và gửi dòng log `NHẬN VỀ ... code/message` để xử lý chính xác.

## Bảng tổng quan

| TIP | Lỗi (theo tester) | Loại | Độ ưu tiên | Độ khó | Cần thêm thông tin? |
|-----|-------------------|------|-----------|--------|---------------------|
| TIP-01 | Giao dịch "Expense" hiển thị dấu `+` | FE | Cao | Thấp | Không |
| TIP-02 | Tồn kho còn 1 vẫn đặt được 100 | FE | Cao | Thấp–TB | Không |
| TIP-03 | Mua variant hết hàng chưa có dialog | FE | TB–Cao | TB | Mã lỗi BE (tùy chọn) |
| TIP-04 | Số dư ví không đủ chưa có dialog | FE | Cao | TB | Mã lỗi BE |
| TIP-05 | Lịch sử số dư chưa có loadmore | FE | TB | TB | Không |
| TIP-06 | Xóa địa chỉ mặc định bị lỗi | FE + BE | Cao | TB | **Log lỗi khi reproduce** |
| TIP-07 | Kiểm tra BE đã trừ tồn kho chưa | BE | Cao | — | Kiểm chứng phía BE |

**Gợi ý thứ tự làm:** TIP-01 → TIP-02 → TIP-03 → TIP-04 → TIP-05 → TIP-06 → TIP-07 (dễ & thuần FE trước; TIP-06/07 cần thêm thông tin).

---

## TIP-01 — Giao dịch "Expense" hiển thị dấu `+`

- **Loại:** FE · **Ưu tiên:** Cao · **Độ khó:** Thấp
- **File:** `lib/ui/marketplace/list/wallet_page.dart` (dòng **35**, và **247–254**)
- **Nguyên nhân (đã xác định):** logic xác định dấu là
  ```dart
  final isPositive = item.type == 'income' || item.balance >= 0;
  ```
  Vế `|| item.balance >= 0` khiến giao dịch `type == 'expense'` nhưng `balance` lưu là **số dương (độ lớn)** vẫn bị coi là dương → hiển thị `+` và màu xanh.
- **Hướng sửa:** ưu tiên theo `type`, chỉ fallback theo dấu số khi `type` rỗng:
  ```dart
  final isPositive = item.type == 'income'
      ? true
      : item.type == 'expense'
          ? false
          : item.balance >= 0; // fallback khi BE không trả type
  ```
  Logic này lặp ở **2 nơi** (danh sách + bottom sheet chi tiết) → nên tách thành 1 helper dùng chung để không lệch nhau.
- **Kiểm thử:** Mở "Ví quân nhu" → giao dịch chi tiêu hiện `-… xu` màu đỏ, thu nhập `+… xu` màu xanh; mở chi tiết giao dịch khớp dấu/màu.

## TIP-02 — Tồn kho còn 1 vẫn đặt được 100

- **Loại:** FE (BE nên chặn thêm — xem TIP-07) · **Ưu tiên:** Cao · **Độ khó:** Thấp–TB
- **File:** `lib/ui/marketplace/product/product_detail_page.dart` — hàm `_showVariantSelectionSheet` (nút tăng số lượng ~dòng **1113–1116**; nút xác nhận ~**1158**)
- **Nguyên nhân (đã xác định):** nút `+` chạy `quantity++` **không giới hạn**; nút xác nhận không kiểm tra `quantity <= stock`. Model `ProductSizeModel.stock` (int?) đã có sẵn.
- **Hướng sửa:**
  - Khi đã chọn variant: `maxStock = selectedSize?.stock`. **Disable nút `+`** khi `quantity >= maxStock`; hiển thị "Còn {maxStock}".
  - Khi xác nhận: nếu `maxStock != null && quantity > maxStock` → chặn + báo "Chỉ còn {maxStock} sản phẩm".
  - Sản phẩm không có variant (chỉ có cờ `product.isStock`, không có số lượng cụ thể): nếu `!product.isStock` thì chặn (gộp với TIP-03).
- **Kiểm thử:** Sản phẩm tồn 1 → không tăng quá 1; cố đặt 100 → bị chặn rõ ràng.

## TIP-03 — Mua variant hết hàng chưa có dialog

- **Loại:** FE · **Ưu tiên:** TB–Cao · **Độ khó:** TB
- **File:** `product_detail_page.dart` (chip chọn variant ~**1059–1081**, nút Mua/Thêm giỏ ~**1155**); `lib/blocs/marketplace/checkout/checkout_bloc.dart` (bắt lỗi BE)
- **Nguyên nhân (đã xác định):** chip variant vẫn chọn được dù `stock == 0`; không có cảnh báo khi hết hàng.
- **Hướng sửa:**
  - Trong sheet: variant có `stock == 0` → `ChoiceChip(onSelected: null)` (disable) + nhãn "Hết hàng".
  - Khi bấm Mua/Thêm giỏ mà variant đã hết (hoặc `!product.isStock`) → `showDialog` "Sản phẩm đã hết hàng".
  - Ở checkout: bắt lỗi BE báo hết hàng → dialog tương tự (theo mẫu `_showProductNotExistedDialog` đã có).
- **Cần thêm (tùy chọn):** mã lỗi BE khi hết hàng (nghi ngờ `1011 productSold`) — xác nhận bằng reproduce.
- **Kiểm thử:** Chọn variant hết hàng → bị chặn + hiện dialog; sản phẩm hết hàng hoàn toàn → không cho mua.

## TIP-04 — Số dư ví không đủ chưa có dialog thân thiện

- **Loại:** FE (cần mã lỗi BE) · **Ưu tiên:** Cao · **Độ khó:** TB
- **File:** `checkout_bloc.dart` → `_onSubmitted` (~**120–189**); `lib/ui/marketplace/checkout/checkout_page.dart` → listener (~**82–97**)
- **Nguyên nhân (đã xác định):** khi `createOrder` lỗi, code chỉ xử lý riêng `productNotExisted (9992)` bằng dialog; **mọi lỗi khác** (gồm thiếu số dư) chỉ hiện SnackBar thô. `ResponseCode` hiện **chưa có** mã "thiếu số dư".
- **Hướng sửa (2 lớp):**
  1. **Chủ động (UX tốt nhất):** trước khi submit, gọi `getCurrentBalance()` so với `total = subtotal + shippingFee`. Nếu thiếu → `showDialog` "Số dư ví không đủ" (kèm số dư hiện có & số cần), **không** gọi `createOrder`. (Checkout hiện chưa load số dư ví → cần thêm.)
  2. **Phòng hờ:** trong `catch`, nhận diện mã/message lỗi thiếu số dư từ BE → cùng dialog đó.
- **Cần thêm:** mã/message BE khi thiếu số dư (reproduce) → bổ sung vào `ResponseCode`.
- **Kiểm thử:** Ví ít hơn tổng đơn → hiện dialog "Số dư ví không đủ", không tạo đơn.

## TIP-05 — Lịch sử số dư chưa có loadmore

- **Loại:** FE · **Ưu tiên:** TB · **Độ khó:** TB
- **File:** `lib/blocs/marketplace/wallet/wallet_bloc.dart` (chỉ load 1 lần `index:0, count:20`), `wallet_event.dart`, `wallet_state.dart`, `wallet_page.dart` (đang dùng `ListView` đổ hết)
- **Nguyên nhân (đã xác định):** chưa có phân trang. API `getBalanceHistory(index, count)` **đã hỗ trợ** phân trang; mã `noData 9994` = "đã hết danh sách".
- **Hướng sửa:** thêm event `WalletLoadMore`; state thêm `isLoadingMore`, `hasMore`, `currentIndex`. Khi cuộn gần cuối (ScrollController/`NotificationListener`) → tải trang kế (`index += count`), nối vào `history`; dừng khi số bản ghi trả về `< count` (hoặc gặp `noData`). Đổi `ListView` → `ListView.builder` + footer loading.
- **Kiểm thử:** Cuộn xuống cuối → tự tải thêm; hết dữ liệu thì dừng, không lặp vô hạn.

## TIP-06 — Xóa địa chỉ mặc định bị lỗi

- **Loại:** FE + BE · **Ưu tiên:** Cao · **Độ khó:** TB
- **File:** `lib/blocs/marketplace/address/address_bloc.dart` → `_onDeleted` (~**109–127**); `lib/ui/marketplace/address/address_list_page.dart` → `_confirmDelete` (~**147–171**); `marketplace_repository_impl.dart` → `deleteAddress` (~**389–396**)
- **Nguyên nhân (nghi ngờ — cần xác nhận):** nhiều khả năng BE **không cho xóa địa chỉ mặc định** (trả mã lỗi), hoặc sau khi xóa default thì luồng phía sau thiếu default gây lỗi. FE hiện chỉ hiện SnackBar lỗi thô.
- **Cần thêm (BẮT BUỘC trước khi sửa):** reproduce và gửi log lỗi (dòng `NHẬN VỀ` — code + message) khi xóa địa chỉ mặc định.
- **Hướng sửa (tùy nguyên nhân thực tế):**
  - Nếu BE cấm xóa default → ẩn/disable nút "Xóa" với địa chỉ `isDefault`, hoặc hiện dialog "Hãy đặt địa chỉ khác làm mặc định trước khi xóa".
  - Nếu lỗi do FE sau khi xóa → xử lý null/refresh an toàn, tự chọn default mới.
- **Kiểm thử:** Xóa địa chỉ mặc định → hành vi rõ ràng (chặn có hướng dẫn, hoặc xóa thành công + chọn default mới), không văng lỗi.

## TIP-07 — Kiểm tra BE đã trừ tồn kho khi đặt hàng chưa

- **Loại:** BE (kiểm chứng) · **Ưu tiên:** Cao · **Độ khó:** — (không sửa trong repo FE này)
- **Bối cảnh:** FE gửi `createOrder` với `items: [{product_id, quantity, variant_id}]` — đúng. Việc trừ tồn kho nằm ở **backend**; mã nguồn BE **không có** trong repo này (thư mục `BE/IT4788` không phải backend chạy được).
- **Cách kiểm chứng:** gọi `get_products(id)` ghi lại tồn → đặt 1 đơn → gọi `get_products(id)` lại → so tồn có giảm đúng số lượng (và đúng theo variant) không. Hoặc kiểm tra trực tiếp DB.
- **Phần FE liên quan:** sau khi đặt hàng thành công nên refresh lại chi tiết/list sản phẩm để hiển thị tồn mới (có thể gộp khi làm TIP-02/03).
- **Kết luận:** nếu BE chưa trừ tồn → báo team backend sửa; FE chỉ hỗ trợ hiển thị đúng.

---

## Ghi chú chung

- **Mã lỗi BE:** các TIP-03, 04, 06 cần biết chính xác mã/message BE. File khai báo mã hiện tại: `lib/core/constants/response_code.dart` (chưa có "thiếu số dư"). Khi sửa, mình sẽ bổ sung mã mới vào đây.
- **Defense-in-depth:** TIP-02 (chặn ở FE) và TIP-07 (chặn ở BE) bổ trợ nhau — lý tưởng là cả hai phía đều kiểm tra tồn kho.
- **Commit:** mỗi TIP 1 commit riêng (vd `fix(wallet): hiển thị đúng dấu giao dịch chi tiêu [TIP-01]`) để dễ review & revert.
