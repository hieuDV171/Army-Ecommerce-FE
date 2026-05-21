- BÀI TẬP TUẦN


Nhắc lại

- Đã hoàn thành được phần API thuộc nhóm Follow/Block và
    Notification/Chatting.
- Đã nắm được API thuộc nhóm Order.
- Tiếp tục với các API mục Order kèm theo giao diện mô phỏng.

Các trạng thái của một đơn hàng:
pending/confirmed/shipping/delivered/cancelled/refunded.


Danh sách API
Order

- create_order (api for buyer): Tạo đơn hàng từ các sản phẩm đã
    chọn.
- get_list_purchases: Danh sách đơn (buyer xem đơn mình, seller
    xem đơn của seller).
- get_purchase: Chi tiết 1 đơn.
- edit_purchase (api for buyer): Sửa địa chỉ / ghi chú khi đơn
    chưa thanh toán.
- cancel_order (api for buyer): Hủy đơn hàng khi chưa ship.


Danh sách API
Order

- seller_mark_as_shipped (api for seller): Shop cập nhật trạng thái
    đã gửi hàng (purchase.state = “confirmed” → “shipping”.
- buyer_confirm_received (api for buyer): Buyer xác nhận đã
    nhận hàng.
- get_order_timeline: Lịch sử thay đổi trạng thái đơn.
- set_accept_buyer (api for seller): Chấp nhận / Từ chối đề nghị
    mua.
- refund_order (api for buyer): Gửi yêu cầu hoàn hàng / hoàn tiền.


API create_order

API này được dùng để tạo một đơn hàng mới.
Phương thức: POST.


API create_order


Testcase cho create_order

```
Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển về
trang đăng nhập, yêu cầu người dùng đăng nhập lại.
Truyền token hợp lệ followee_id có tồn tại và đúng action (follow
cho user chưa follow hoặc unfollow cho user đã follow)
Kết quả mong đợi: 1000 | OK. Thông báo thành công, số lượng
người dùng đang follow tăng lên 1 , số lượng người follow
“followee_id” đó tăng lên 1.
Truyền followee_id không tồn tại trong database
Kết quả mong đợi: 1013 | User does not exist. Thông báo user
mà người dùng mong muốn follow/unfollow không tồn tại, không
thông báo ra giao diện.
```

Testcase cho create_order

```
▪ Truyền đúng followee_id có tồn tại nhưng sai action (follow cho
user đã follow hoặc unfollow cho user chưa follow.
Kết quả mong đợi: 1010 | Action has been done previously
by this user. Không thông báo ra giao diện.
▪ Truyền followee_id là id của chính người dùng
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.
```

API get_list_purchases

API này được dùng để lấy ra danh sách các đơn hàng mà người dùng
đang đăng nhập đã đặt thành công.
Dữ liệu trả về bao gồm:
purchase_id là id của đơn hàng đó
Trạng thái của đơn hàng (tham khảo slide số 2)
Tổng giá trị của đơn hàng đó
Thông tin các sản phẩm có trong đơn hàng đó
Phương thức: POST.


API get_list_purchases


API get_list_purchases


Testcase cho get_list_purchases

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, index, count đúng định dạng được nhà
phát triển quy định.
Kết quả mong đợi: 1000 | OK. Trả ra kết quả danh sách dữ
liệu ra giao diện.
```

API get_purchase

API này được dùng để xem chi tiết 1 đơn hàng của người dùng
đang đăng nhập.
Phương thức: POST.


API get_purchase


API get_purchase


Testcase cho get_purchase
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, id (purchase_id) có tồn tại trong database.
Kết quả mong đợi: 1000 | OK. Trả ra kết quả danh sách dữ
liệu ra giao diện.
▪ Truyền token hợp lệ, id (purchase_id) không tồn tại trong
database.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.


API edit_purchase

API này được dùng để chỉnh sửa địa chỉ/ghi chú khi đơn chưa
chuyển sang trạng thái giao hàng.
Phương thức: POST.


API edit_purchase


API edit_purchase


Testcase cho edit_purchase (1)

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, id (purchase_id), address_id có tồn tại
trong database, purchase.state = “pending/confirmed”.
Kết quả mong đợi: 1000 | OK. Thông báo thành công, thay
đổi địa chỉ theo những giá trị đã truyền vào.
```

Testcase cho edit_purchase (2)

```
Truyền token hợp lên, id (purchase_id), address_id không tồn
tại trong database.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.
Truyền token hợp lệ, id (purchase_id), address_id có tồn tại
trong database, purchase.state khác “pending/confirmed”.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo phương thức này không được thực hiện, không được phép
thay đổi địa chỉ/ghi chú.
```

API cancel_order

API này được dùng để hủy một đơn hàng chưa chuyển sang trạng
thái giao hàng.
Dữ liệu trả về bao gồm:
id của đơn hàng đó
Trạng thái của đơn hàng đó (cancelled)
Số xu được hoàn lại
Thời điểm số xu được hoàn lại
Phương thức: POST.


API cancel_order


API cancel_order


Testcase cho cancel_order ( 1 )

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, id (purchase_id) có tồn tại trong database,
purchase.state = “pending/confirmed”.
Kết quả mong đợi: 1000 | OK. Thông báo thành công, hủy
đơn hàng thành công.
```

Testcase cho cancel_order (2)

```
▪ Truyền token hợp lệ, id (purchase_id) không tồn tại trong
database.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.
▪ Truyền token hợp lệ, id (purchase_id) có tồn tại trong database,
purchase.state khác “pending/confirmed”.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo phương thức này không được thực hiện, không được phép
hủy đơn hàng.
```

API set_accept_buyer

API này được dùng để seller xác nhận đồng ý/từ chối đơn mua của
buyer.
Phương thức: POST.


API set_accept_buyer


Testcase cho set_accept_buyer (1)

▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, purchase_id, buyer_id có tồn tại trong
database.
Kết quả mong đợi: 1000 | OK. Thông báo thành công, đồng
ý/từ chối bán đơn hàng.
▪ Truyền token hợp lệ, buyer_id không tồn tại trong database.

```
Kết quả mong đợi: 1013 | User does not exist. Thông báo
buyer không tồn tại.
```

Testcase cho set_accept_buyer (2)

```
Truyền token hợp lệ, purchase_id không tồn tại trong database.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.
Truyền token hợp lệ, purchase_id đã được xác nhận từ trước đó rồi
(đơn hàng có trạng thái khác “pending”)
Kết quả mong đợi: 1010 | Action has been done previously by
this user. Không thông báo ra giao diện.
```

API buyer_confirm_received

API này được dùng để buyer xác nhận mình đã nhận được hàng, khi
đó purchase.state = “shipping” → “delivered”.
Phương thức: POST.


API buyer_confirm_received


API buyer_confirm_received


Testcase cho buyer_confirm_received ( 1 )

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, purchase_id có tồn tại trong database,
purchase.state = shipping.
Kết quả mong đợi: 1000 | OK. Thông báo thành công, người
mua đã nhận được đơn hàng.
```

Testcase cho buyer_confirm_received (2)

```
▪ Truyền token hợp lệ, purchase_id không tồn tại.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.
▪ Truyền token hợp lệ, purchase_id có tồn tại trong database,
purchase_id.state khác “shipping”
Kết quả mong đợi: 1010 | Action has been done previously
by this user. Thông báo phương thức này không được thực hiện,
không được phép xác nhận đã nhận được hàng.
```

API refund_order

API này được dùng để buyer yêu cầu hoàn hàng/hoàn tiền trong các
trường hợp chưa nhận được hàng, hoặc đã nhận được hàng nhưng
muốn hoàn lại cho seller.
Phương thức: POST.


API refund_order


API refund_order


Testcase cho refund_order (1)

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, purchase_id có tồn tại trong database,
purchase.state = delivered.
Kết quả mong đợi: 1000 | OK. Thông báo thành công, người
mua đã yêu cầu thành công hoàn hàng/hoàn tiền.
```

Testcase cho refund_order ( 2 )

```
▪ Truyền token hợp lệ, purchase_id không tồn tại trong database.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.
▪ Truyền token hợp lệ, purchase_id có tồn tại trong database
nhưng purchase_id.state khác “delivered”.
Kết quả mong đợi: 1010 | Action has been done previously
by this user. Thông báo phương thức này không được thực hiện,
không được phép yêu cầu hoàn tiền/hoàn hàng.
```

Nên auto refund nếu buyer gửi yêu cầu, hay cần có sự accept từ
phía người bán/phía sàn thương mại?


API seller_mark_as_shipped

API này được dùng để seller xác nhận đã chuyển hàng cho đơn vị
vận chuyển, tức purchase.state = “confirmed” → “shipping”
Phương thức: POST.


API seller_mark_as_shipped


Testcase cho seller_mark_as_shipped (1)

```
Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
Truyền token hợp lệ, purchase_id, buyer_id có tồn tại trong
database.
Kết quả mong đợi: 1000 | OK. Thông báo thành công, thông
báo đơn hàng đã được chuyển cho bên vận chuyển.
Truyền token hợp lệ, buyer_id không tồn tại trong database.
Kết quả mong đợi: 1013 | User does not exist. Thông báo
buyer không tồn tại.
```

Testcase cho seller_mark_as_shipped (2)

▪ Truyền token hợp lệ, purchase_id không tồn tại trong database.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.
▪ Truyền token hợp lệ, buyer_id có tồn tại trong database,
purchase_id có tồn tại trong database nhưng purchase_id.state
khác “confirmed”.
Kết quả mong đợi: 1010 | Action has been done previously
by this user. Không thông báo ra giao diện.


HẾT TUẦN 6


Thank you
for your
attentions**!**


