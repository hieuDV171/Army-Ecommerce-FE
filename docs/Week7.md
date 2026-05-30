- BÀI TẬP TUẦN


Nhắc lại

- Đã hoàn thành được phần API thuộc nhóm Order.
- Đã nắm được API thuộc nhóm Shipping.
- Tiếp tục với các API mục Shipping kèm theo giao diện mô
    phỏng.


Danh sách API
SHIPPING

- get_ship_from: danh sách địa điểm “gửi từ” (tỉnh/thành) hoặc
    địa chỉ kho.
- get_ship_fee: tính phí ship theo ship_from → ship_to (suy nghĩ
    về việc tính toán thêm cả kích thước/khối lượng đơn hàng).
- get_list_order_address: danh sách địa chỉ nhận hàng của user.
- add_order_address / edit_order_address / delete_order_address:
    CRUD địa chỉ nhận hàng.


API get_ship_from

API này được dùng để lấy địa chỉ bán hoặc mua có những kho hàng
nào.
Phương thức: POST.


API get_ship_from


Testcase cho get_ship_from

```
Truyền index, count đúng định dạng được nhà phát triển quy
định, parent_id (id tỉnh, phường,...) có tồn tại trong database.
Kết quả mong đợi: 1000 | OK.
Truyền index, count đúng định dạng được nhà phát triển quy
định, parent_id (id tỉnh, phường,...) không tồn tại trong
database.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.
```

API get_ship_fee

API này được dùng để tính phí ship theo ship_from → ship_to.
(Có thể mở rộng tính toán chi phí dựa theo cả khối lượng/kích
thước hàng hóa).
Phương thức: POST.


API get_ship_fee


API get_ship_fee


Testcase cho get_ship_fee

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, purchase_id, provice_id, ward_id có tồn
tại trong database.
Kết quả mong đợi: 1000 | OK. Trả ra kết quả danh sách dữ
liệu ra giao diện.
```

Testcase cho get_ship_fee

```
Truyền token hợp lệ, purchase_id, provice_id, ward_id không
tồn tại trong database.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.
```

API get_list_order_address

API này được dùng để lấy danh sách địa chỉ nhận hàng của user.
Phương thức: POST.


API get_list_order_address


API get_list_order_address


Testcase cho get_list_order_address

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ.
Kết quả mong đợi: 1000 | OK. Trả ra kết quả danh sách dữ
liệu ra giao diện.
```

API add_order_address

API này được dùng để thêm địa chỉ nhận hàng.
Phương thức: POST.


API add_order_address


API add_order_address


Testcase cho add_order_address

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, address, address_id có tồn tại trong
database.
Kết quả mong đợi: 1000 | OK. Thông báo thành công, thông
báo thêm thành công địa chỉ nhận hàng.
```

Testcase cho add_order_address

```
Truyền token hợp lệ, address, address_id không tồn tại trong
database.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.
```

API edit_order_address

API này được dùng để chỉnh sửa địa chỉ nhận hàng.
Phương thức: POST.


API edit_order_address


API edit_order_address


Testcase cho edit_order_address

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, address, address_id, id của địa chỉ có tồn
tại trong database.
Kết quả mong đợi: 1000 | OK. Thông báo thay đổi thành
công.
```

Testcase cho edit_order_address

```
▪ Truyền token hợp lệ, address, address_id, id của địa chỉ không
tồn tại trong database.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.
▪ Truyền token hợp lệ, address_id (mới) trùng với id của địa chỉ
(cũ).
Kết quả mong đợi: 1010 | Action has been done previously
by this user.
```

API delete_order_address

API này được dùng để xóa địa chỉ nhận hàng.
Phương thức: POST.


API delete_order_address


API delete_order_address


Testcase cho delete_order_address (1)

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, id của một địa chỉ có tồn tại trong
database.
Kết quả mong đợi: 1000 | OK. Thông báo thành công xóa
địa chỉ đó.
```

Testcase cho delete_order_address ( 2 )

▪ Truyền token hợp lệ, id của một địa chỉ không tồn tại trong
database.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.


HẾT TUẦN 7


Thank you
for your
attentions**!**


