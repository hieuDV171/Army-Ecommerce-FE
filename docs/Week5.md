- BÀI TẬP TUẦN


Nhắc lại

- Đã hoàn thành được phần API thuộc nhóm Comment/Like
    /Report/Rating và News
- Đã nắm được API thuộc nhóm Follow/Block và
    Notification/Chatting.
- Tiếp tục với các API mục Follow/Block và
    Notification/Chatting kèm theo giao diện mô phỏng.


Danh sách API
FOLLOW/BLOCK

- set_user_follow: Follow / Unfollow 1 user.
- get_list_followed: Danh sách user mình đang follow.
- get_list_following: Danh sách user đang follow mình.
- get_list_blocks: Danh sách user mình đã block.
- set_blocks: Block / Unblock user.


Danh sách API
NOTIFICATION/CHATTING

- send_message: Gửi tin nhắn, auto tạo conversation mới nếu
    chưa tồn tại.
- get_notification: danh sách thông báo hệ thống (đơn hàng, like,
    follow...).
- set_read_notification: đánh dấu đã đọc notification.
- set_read_message: đánh dấu đã đọc tin nhắn (read receipt).
- get_conversation: lấy 1 conversation.
- get_list_conversation: danh sách các conversation.
- get_conversation_detail: lấy thông tin sản phẩm mà người mua
    đang trao đổi với người bán.


Phần 1

FOLLOW/BLOCK


API set_user_follow

API này được dùng để follow/unfollow 1 user.
Dữ liệu trả về bao gồm:
id của user được follow/bị unfollow (followee_id)
Trạng thái sau khi thực hiện hành động (đã follow/đã unfollow)
Số người đang theo dõi followee_id
Số người mà người dùng hiện đang theo dõi
Phương thức: POST.


API set_user_follow

```
Follow
Ấn vào “Theo dõi”
→ Giao diện nút chuyển thành
“Đang theo dõi”
```
```
Unfollow
Ấn vào “Đang theo dõi”
→ Giao diện nút chuyển thành
“Theo dõi”
```

API set_user_follow


Testcase cho set_user_follow (1)

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, followee_id có tồn tại trong database và
đúng action (“follow” cho user chưa được theo dõi hoặc
“unfollow” cho user đã được theo dõi).
Kết quả mong đợi: 1000 | OK. Thông báo thành công, số
lượng người mà người dùng đang theo dõi tăng lên 1, số lượng
người theo dõi “followee_id” đó tăng lên 1.
```

Testcase cho set_user_follow (2)

```
▪ Truyền token hợp lệ nhưng followee_id không tồn tại trong
database.
Kết quả mong đợi: 1013 | User does not exist. Thông báo
user mà người dùng mong muốn follow/unfollow không tồn tại,
không thông báo ra giao diện.
▪ Truyền token hợp lệ, nhưng followee_id là id của chính người
dùng đang đăng nhập.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.
```

Testcase cho set_user_follow ( 3 )

```
▪ Truyền token hợp lệ, followee_id có tồn tại trong database
nhưng sai action (follow cho user đã được theo dõi hoặc
unfollow cho user chưa được theo dõi.
Kết quả mong đợi: 1010 | Action has been done previously
by this user. Không thông báo ra giao diện.
```

API get_list_followed

```
API này được dùng để lấy ra danh sách các user đang theo dõi
user_id.
Dữ liệu trả về bao gồm một mảng các thông tin của từng user đang
theo dõi user_id như sau:
id của user đang theo dõi user_id
username của user đang theo dõi user_id
avatar của user đang theo dõi user_id
Trạng thái của người dùng đang đăng nhập (token) đối với
user đó (đã theo dõi hoặc chưa theo dõi)
Phương thức: POST.
```

API get_list_followed

```
Giao diện tổng quan hiển thị số lượng
user đang theo dõi user_id
```
```
Xem chi tiết các user đang theo dõi
user_id
Ấn vào “xxx Người theo dõi”, giao
diện trả về danh sách các user đang
theo dõi user_id
```

API get_list_followed


Testcase cho get_list_followed (1)

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, index, count đúng định dạng được nhà
phát triển quy định, user_id có tồn tại trong database (user_id
có thể là người dùng đang đăng nhập hoặc khác)
Kết quả mong đợi: 1000 | OK. Trả ra kết quả danh sách dữ
liệu ra giao diện.
```

Testcase cho get_list_followed (2)

▪ Truyền token hợp lệ, index, count đúng định dạng được nhà
phát triển quy định, user_id không tồn tại trong database
(user_id có thể là người dùng đang đăng nhập hoặc khác).
Kết quả mong đợi: 1013 | User does not exist. Thông báo
user mà người dùng mong muốn xem danh sách người theo dõi
không tồn tại, không thông báo ra giao diện.


Testcase cho get_list_followed (3)

▪ Truyền token hợp lệ, index, count đúng định dạng được nhà
phát triển quy định, user_id đang bị người dùng đang đăng nhập
(token) chặn (hoặc truyền vào user_id đang chặn người dùng
đang đăng nhập).
Kết quả mong đợi: 1009 | Not access. Thông báo người
dùng không được phép truy cập tài nguyên, không thông báo ra
giao diện.


API get_list_following

API này được dùng để lấy ra danh sách các user mà user_id đang
theo dõi.
Dữ liệu trả về bao gồm một mảng các thông tin của từng user mà
user_id đang theo dõi như sau:
id của user mà user_id đang theo dõi
username của user mà user_id đang theo dõi
avatar của user mà user_id đang theo dõi
Trạng thái của người dùng đang đăng nhập (token) đối với
user đó (đã theo dõi hoặc chưa theo dõi)
Phương thức: POST.


API get_list_following

```
Giao diện tổng quan hiển thị số lượng
user mà user_id đang theo dõi.
```
```
Xem chi tiết các user mà user_id
đang theo dõi
Ấn vào “xxx Đang theo dõi”, giao
diện trả về danh sách các user mà
user_id đang theo dõi.
```

API get_list_following


Testcase cho get_list_following (1)

```
Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
Truyền token hợp lệ, index, count đúng định dạng được nhà
phát triển quy định, user_id có tồn tại trong database (user_id
có thể là người dùng đang đăng nhập hoặc khác)
Kết quả mong đợi: 1000 | OK. Trả ra kết quả danh sách dữ
liệu ra giao diện.
```

Testcase cho get_list_following (2)

▪ Truyền token hợp lệ, index, count đúng định dạng được nhà
phát triển quy định, user_id không tồn tại trong database
(user_id có thể là người dùng đang đăng nhập hoặc khác).
Kết quả mong đợi: 1013 | User does not exist. Thông báo
user mà người dùng mong muốn xem danh sách người theo dõi
không tồn tại, không thông báo ra giao diện.


Testcase cho get_list_following (3)

▪ Truyền token hợp lệ, index, count đúng định dạng được nhà
phát triển quy định, user_id đang bị người dùng đang đăng nhập
(token) chặn (hoặc truyền vào user_id đang chặn người dùng
đang đăng nhập).
Kết quả mong đợi: 1009 | Not access. Thông báo người
dùng không được phép truy cập tài nguyên, không thông báo ra
giao diện.


API get_list_blocks

API này được dùng để lấy ra danh sách các user mà người dùng
đang đăng nhập đã chặn.
Dữ liệu trả về bao gồm một mảng các thông tin của từng user đang
theo dõi user_id như sau:
id của user mà người dùng đang đăng nhập đã chặn
username của user mà người dùng đang đăng nhập đã chặn
avatar (image) của user mà người dùng đang đăng nhập đã
chặn
Phương thức: POST.


API get_list_blocks

```
Giao diện tổng quan hiển thị danh
sách user mà người dùng đã chặn.
```
```
Xem chi tiết các user mà người
dùng đã chặn
Ấn vào “Người dùng đã bị chặn”,
giao diện trả về danh sách các user
mà người dùng đã chặn.
```

API get_list_blocks


Testcase cho get_list_blocks

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, index, count đúng định dạng được nhà
phát triển quy định
Kết quả mong đợi: 1000 | OK. Trả ra kết quả danh sách dữ
liệu ra giao diện.
```

API blocks

API này được dùng để block/unblock 1 user.
Phương thức: POST.


API blocks

```
*Đây chỉ là giao diện mô phỏng
Giao diện để chặn user
```
```
*Đây chỉ là giao diện mô phỏng
Giao diện để bỏ chặn user
```

API blocks


Testcase cho blocks (1)

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, user_id có tồn tại trong database và đúng
action (“block” cho user chưa bị chặn hoặc “unblock” cho user
đã bị chặn).
Kết quả mong đợi: 1000 | OK. Thông báo thành công,
thêm/mất thông tin của user bị chặn/bỏ chặn trên giao diện.
```

Testcase cho blocks (2)

```
▪ Truyền token hợp lệ nhưng user_id không tồn tại trong
database.
Kết quả mong đợi: 1013 | User does not exist. Thông báo
user mà người dùng mong muốn block/unblock không tồn tại,
không thông báo ra giao diện.
▪ Truyền token hợp lệ, nhưng user_id là id của chính người dùng
đang đăng nhập.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.
```

Testcase cho blocks (3)

```
▪ Truyền token hợp lệ, user_id có tồn tại trong database nhưng sai
action (block cho user đã bị chặn hoặc unblock cho user chưa bị
chặn.
Kết quả mong đợi: 1010 | Action has been done previously
by this user. Không thông báo ra giao diện.
```

Phần 2

Notification/Chatting


API send_message

API này được dùng để gửi tin nhắn giữa người dùng đang đăng
nhập và to_id, nếu giữa họ chưa từng có một conversation nào thì sẽ
auto tạo conversation_id mới, nếu đã từng có, trả ra conversation_id
trong database.
Dữ liệu trả về bao gồm một mảng các thông tin của từng user mà
user_id đang theo dõi như sau:
conversation_id giữa người dùng đang đăng nhập và to_id
message_id
Thời gian tạo message_id đó
Phương thức: POST.


API send_message


API send_message


Testcase cho send_message (1)

```
Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
Truyền token hợp lệ, to_id, product_id (hoặc không truyền
product_id) có tồn tại trong database, message
Kết quả mong đợi: 1000 | OK. Thông báo thành công, tạo
mới một khung chat giữa người dùng và to_id trong trường hợp
chưa từng tồn tại conversation, nếu đã từng tồn tại trả về
conversation_id trong database.
```

Testcase cho send_message (2)

▪ Truyền token hợp lệ, to_id không tồn tại trong database.

```
Kết quả mong đợi: 1013 | User does not exist. Thông báo
user mà người dùng mong muốn tạo conversation không tồn tại,
không thông báo ra giao diện.
▪ Truyền token hợp lệ, to_id là id của chính người dùng đang
đăng nhập, hoặc truyền product_id không tồn tại.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.
```

Testcase cho send_message (3)

```
▪ Truyền token hợp lệ, to_id là id của user đã block người dùng
đang đăng nhập/bị người dùng đang đăng nhập block.
Kết quả mong đợi: 1009 | Not access. Thông báo tài nguyên
không được phép truy cập, không thông báo ra giao diện.
```

API get_list_conversation

API này được dùng để lấy danh sách các conversation của người
dùng đang đăng nhập.
Phương thức: POST.


API get_list_conversation


API get_list_conversation


Testcase cho get_list_conversation

```
Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
Truyền token hợp lệ, index, count đúng định dạng được nhà
phát triển quy định.
Kết quả mong đợi: 1000 | OK. Trả ra kết quả danh sách dữ
liệu ra giao diện.
```

API get_conversation

API này được dùng để lấy đầy đủ chi tiết các messages trong một
conversation cụ thể giữa người dùng đang đăng nhập và partner_id.
Phương thức: POST.


API get_conversation


API get_conversation


Testcase cho get_conversation ( 1 )

▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, index, count đúng định dạng được nhà
phát triển quy định, partner_id và product_id, hoặc
conversation_id có tồn tại trong database.
Kết quả mong đợi: 1000 | OK. Thông báo thành
công, trả dữ liệu ra giao diện.


Testcase cho get_conversation (2)

▪ Truyền token hợp lệ, index, count đúng định dạng được nhà
phát triển quy định, partner_id không tồn tại trong database.
Kết quả mong đợi: 1013 | User does not exist. Thông báo
user mà người dùng mong muốn tạo conversation không tồn tại,
không thông báo ra giao diện.


Testcase cho get_conversation (3)

Truyền token hợp lệ, index, count đúng định dạng được nhà
phát triển quy định, partner_id của chính người dùng đang đăng
nhập (token), product_id, conversation_id không tồn tại trong
database.
Kết quả mong đợi: 1004 | Parameter value is invalid.
Thông báo giá trị tham số truyền vào không hợp lệ, không thông
báo ra giao diện.


API get_notification

API này được dùng để lấy ra các thông báo cho người dùng.
Phương thức: POST.


API get_notification


API get_notification


Testcase cho get_notification

▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ index, count đúng định dạng được nhà phát
triển quy định.
Kết quả mong đợi: 1000 | OK. Thông báo thành
công, trả dữ liệu ra giao diện.


API set_read_notification

API này được dùng để đánh dấu những thông báo đã được đọc.
Phương thức: POST.


API set_read_notification


API set_read_notification


Testcase cho set_read_notification
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, notification_id có tồn tại trong database.
Kết quả mong đợi: 1000 | OK. Thông báo thành
công, trả dữ liệu ra giao diện.
▪ Truyền token hợp lệ, notification_id không tồn tại trong
database.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.


API set_read_message

API này được dùng để đánh dấu những tin nhắn đã được đọc.
Phương thức: POST.


API set_read_message

```
Chú ý: phía mobile không cần làm chức năng hiển thị “Đã xem” cho tin nhắn
```

API set_read_message


Testcase cho set_read_message (1)

▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, partner_id, product_id có tồn tại trong
database.
Kết quả mong đợi: 1000 | OK. Thông báo thành
công, trả dữ liệu ra giao diện.


Testcase cho set_read_message ( 2 )

▪ Truyền token hợp lệ, partner_id không tồn tại trong database.

```
Kết quả mong đợi: 1013 | User does not exist. Thông báo
user mà người dùng mong muốn tạo conversation không tồn tại,
không thông báo ra giao diện.
```

Testcase cho set_read_message (3)

▪ Truyền token hợp lệ, partner_id của chính người dùng đang
đăng nhập (token), product_id không tồn tại trong database.
Kết quả mong đợi: 1004 | Parameter value is invalid.
Thông báo giá trị tham số truyền vào không hợp lệ, không thông
báo ra giao diện.


HẾT TUẦN 5


Thank you
foryour
attentions**!**


