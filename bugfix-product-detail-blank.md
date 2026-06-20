# Báo cáo sửa lỗi: Trang chi tiết sản phẩm hiển thị trắng

**Người thực hiện:** Lê Văn Quang
**Ngày:** 20/06/2026
**Mức độ:** Cao (chặn toàn bộ màn hình chi tiết sản phẩm)
**Phạm vi sửa:** 1 dòng code, 1 file

---

## 1. Tóm tắt (TL;DR)

Trang chi tiết sản phẩm (`ProductDetailPage`) bị **trắng hoàn toàn** dù API trả về thành công. Nguyên nhân **không phải ở backend** mà là lỗi layout phía frontend: widget dùng chung `SectionHeader` (bên trong có `Expanded`) bị đặt trực tiếp trong một `Row` mà không bọc `Expanded`/`Flexible`, khiến nó nhận chiều rộng **vô hạn (unbounded)** và làm sập toàn bộ `ListView` của trang.

**Cách sửa:** bọc `SectionHeader` trong `Expanded`.

---

## 2. Triệu chứng

- Bấm vào một sản phẩm từ `ProductCard` → mở `ProductDetailPage` → màn hình trắng, không hiển thị nội dung.
- Log gọi API **bình thường**: `get_products`, `get_comments_product`, `get_rates` đều trả về `[201]` thành công.
- Console Flutter văng hàng loạt exception về layout.

## 3. Môi trường

- Flutter stable (bản mới), chạy chế độ **debug** trên thiết bị Android thật.
- File liên quan:
  - `lib/ui/marketplace/product/product_detail_page.dart`
  - `lib/ui/util/widgets/section_header.dart`

## 4. Log lỗi (rút gọn)

```text
RenderFlex children have non-zero flex but incoming width constraints are unbounded.
RenderBox was not laid out: RenderFlex#... NEEDS-PAINT NEEDS-COMPOSITING-BITS-UPDATE
'package:flutter/src/rendering/sliver_multi_box_adaptor.dart':
    Failed assertion: line 629 pos 12: 'child.hasSize': is not true.
Null check operator used on a null value
```

> **Lưu ý quan trọng:** Dòng lỗi **đầu tiên** mới là nguyên nhân gốc. Các dòng `RenderBox was not laid out`, `child.hasSize` và `Null check operator` chỉ là hệ quả dây chuyền theo sau.

## 5. Phân tích nguyên nhân gốc (Root cause)

### a. Widget `SectionHeader` chứa `Expanded`

`SectionHeader` được build như sau (`section_header.dart`):

```dart
Row(
  children: [
    Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
    if (actionLabel != null) TextButton(...),
  ],
)
```

`Expanded` **bắt buộc** widget cha phải cấp cho nó chiều rộng **hữu hạn**.

### b. Nơi đặt sai

Tại mục "Đánh giá" (`_RatingsSection` trong `product_detail_page.dart`), `SectionHeader` bị đặt **trực tiếp** trong một `Row` khác mà không bọc `Expanded`/`Flexible`:

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const SectionHeader(title: 'Đánh giá'),   // ❌ nhận chiều rộng vô hạn
    PopupMenuButton<int>(...),
  ],
)
```

### c. Cơ chế gây lỗi

1. `Row` cấp chiều rộng **vô hạn (unbounded)** cho các con **không-flex** theo trục ngang.
2. `SectionHeader` (không-flex) nhận chiều rộng vô hạn, nhưng bên trong nó lại có `Expanded` → `Expanded` không có giới hạn để co giãn → ném lỗi `RenderFlex children have non-zero flex but incoming width constraints are unbounded`.
3. Một widget con của `ListView` bị lỗi layout sẽ **không có kích thước** → assertion `child.hasSize` trong sliver thất bại → `ListView` không dựng được → **cả trang trắng**.

## 6. Cách sửa

Bọc `SectionHeader` trong `Expanded` để nó nhận được chiều rộng hữu hạn từ `Row`.

**Trước:**

```dart
children: [
  const SectionHeader(title: 'Đánh giá'),
  PopupMenuButton<int>(...),
],
```

**Sau:**

```dart
children: [
  const Expanded(child: SectionHeader(title: 'Đánh giá')),
  PopupMenuButton<int>(...),
],
```

**File:** `lib/ui/marketplace/product/product_detail_page.dart` — mục `_RatingsSection`.

## 7. Phạm vi ảnh hưởng & rà soát

- Đã rà soát **toàn bộ** vị trí sử dụng `SectionHeader` trong dự án (checkout, wallet, seller_listings, marketplace_home, buyer/seller order detail...).
- Tất cả các chỗ khác đều nằm trong `Column` / `Sliver` / `ListView` — vốn đã cấp chiều rộng hữu hạn → **an toàn**, không dính lỗi.
- Chỉ **duy nhất 1 vị trí** (mục "Đánh giá") bị lỗi → đã sửa.

## 8. Cách kiểm thử lại

1. Trong cửa sổ đang chạy `flutter run`, nhấn **`R`** (hot restart).
2. Mở một sản phẩm bất kỳ từ danh sách.
3. **Kỳ vọng:** trang chi tiết hiển thị đầy đủ (ảnh, giá, mô tả, thông tin sản phẩm, người bán, đánh giá, bình luận); console không còn lỗi `RenderFlex` / `child.hasSize`.

## 9. Bài học & khuyến nghị

- Widget dùng chung có chứa `Expanded`/`Flexible`/`Spacer` (như `SectionHeader`) **chỉ an toàn khi cha cấp chiều rộng hữu hạn**. Khi đặt trong `Row`, phải bọc `Expanded`/`Flexible`.
- Cân nhắc làm `SectionHeader` "phòng thủ" hơn (ví dụ dùng `Flexible` thay `Expanded`, hoặc ghi chú cảnh báo khi dùng trong `Row`) để tránh lặp lại lỗi tương tự.
- Khi gặp **màn hình trắng**, hãy đọc **dòng lỗi đầu tiên** trong console thay vì bị nhiễu bởi các lỗi hệ quả phía sau.
