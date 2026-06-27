# TIP-07 — Kiểm chứng Backend có trừ tồn kho khi đặt hàng

**Loại:** Backend (kiểm chứng) · FE không có gì để sửa thêm.

## Kết luận phía FE (đã rà code)

FE gửi **đúng** dữ liệu khi tạo đơn. Trong `lib/blocs/marketplace/checkout/checkout_bloc.dart` (`_onSubmitted`), payload gọi `createOrder` gồm:

```jsonc
{
  "items": [
    { "product_id": <int>, "quantity": <int>, "variant_id": <int?> } // variant_id nếu có
  ],
  "order_source": <int>,
  "source": <int>,
  "address_id": <int>
}
```

→ Backend nhận đủ `product_id`, `variant_id`, `quantity` để trừ tồn. Việc trừ tồn nằm ở endpoint **`POST /order/create_order`** (mã nguồn BE không có trong repo FE này).

## Cách kiểm chứng

### Cách A — Qua app (nhanh)
1. Mở 1 sản phẩm **có variant**, còn tồn ít. Ghi lại số tồn ("Còn N" ở phần Phân loại / kích thước — thấy rõ sau fix TIP-02).
2. Đặt mua 1 cái cho variant đó, hoàn tất đơn.
3. Thoát rồi mở **lại** trang chi tiết sản phẩm (kéo refresh nếu cần).
4. So sánh: tồn giảm đúng (N → N−1) ⇒ BE OK. Tồn không đổi ⇒ **BE chưa trừ tồn**.

### Cách B — Gọi API trực tiếp (chắc chắn, cho dev/BE)
1. `POST /api/get_products` body `{ "id": <product_id> }` → ghi lại `stock` của từng variant trong `sizes`.
2. Đặt 1 đơn cho variant đó (qua app hoặc Postman kèm token).
3. Gọi lại `POST /api/get_products` cùng `product_id` → so sánh `stock`:
   - Giảm đúng số lượng đã mua ⇒ BE OK.
   - Không đổi ⇒ **BE chưa trừ tồn** (cần sửa phía Backend).
4. Trường hợp biên nên thử:
   - **Mua quá tồn** (tồn 1, gọi API đặt 5 — bỏ qua chặn của FE): BE phải từ chối. Nếu BE vẫn cho ⇒ lỗi BE (FE đã chặn ở TIP-02, nhưng BE cần chặn để chống oversell).
   - **Hủy / hoàn đơn**: tồn có được cộng trả lại không.

## Nếu BE chưa trừ tồn → việc của team Backend
- Khi `create_order` thành công: trừ `stock` của đúng variant (`variant_id`) theo `quantity`; nên dùng transaction + kiểm tra tồn để tránh bán âm.
- Khi hủy/hoàn đơn: cộng trả tồn.

## Liên quan FE (tùy chọn, làm sau nếu cần)
Hiện sau khi đặt đơn xong phải **mở lại** trang chi tiết mới thấy tồn mới. Có thể bổ sung: sau khi đặt thành công thì tự reload trang chi tiết. Báo mình nếu muốn làm.
