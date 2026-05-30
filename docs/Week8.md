- BÀI TẬP TUẦN


Nhắc lại

- Đã hoàn thành được phần API thuộc nhóm SHIPPING.
- Đã nắm được API thuộc nhóm Wallet và Upload media.
- Tiếp tục với các API mục Wallet/Withdraw và Upload media
    kèm theo giao diện mô phỏng.


Danh sách API
WALLET

- get_current_balance: số dư hiện tại.
- get_balance_history: lịch sử biến động số dư (income/expense).


Danh sách API
UPLOAD MEDIA

- upload_video: upload video cho listing/chat/news.
- get_reward_history: xem lịch sử quy đổi điểm
- create_reward_appeal: API khiếu nại điểm thưởng.


Phần 1

WALLET


API get_current_balance

API này được dùng để trả về thông tin tài khoản hiện tại của người
dùng đang đăng nhập.
Dữ liệu trả về bao gồm:
available_balance là số xu hiện tại có thể sử dụng được của người
dùng đang đăng nhập (sau này mở rộng phía seller thì cũng là số xu
phía seller có thể rút về ngân hàng.
pending_balance là số xu đang bị tạm giữ và chưa thể sử dụng
cho đến khi một giao hoàn tất
Phương thức: POST.


API get_current_balance

```
*Đây chỉ là minh họa tương tự
```

API get_current_balance


Testcase cho get_current_balance

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ.
Kết quả mong đợi: 1000 | OK. Thông báo thành công, trả
kết quả dữ liệu ra giao diện.
```

API get_balance_history

```
API này được dùng để lấy ra danh sách các user đang theo dõi
user_id.
Dữ liệu trả về bao gồm một mảng các thông tin của từng user đang
theo dõi user_id như sau:
id của user đang theo dõi user_id
username của user đang theo dõi user_id
avatar (image) của user đang theo dõi user_id
Trạng thái của người dùng đang đăng nhập (token) đối với
user đó (đã theo dõi hoặc chưa theo dõi)
Phương thức: POST.
```

API get_balance_history


API get_balance_history


Testcase cho get_balance_history

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, index, count đúng định dạng được nhà
phát triển quy định.
Kết quả mong đợi: 1000 | OK. Trả ra kết quả danh sách dữ
liệu ra giao diện.
```

Phần 2

UPLOAD MEDIA


API upload_video

API này được dùng để tải video lên chấm điểm quy đổi sang xu nội
bộ
Phương thức: POST.


API upload_video


API liên quan đến AI chấm điểm từ video...


API get_reward_history

API này được dùng để xem lịch sử quy đổi điểm của người dùng
đang đăng nhập
Phương thức: POST.


API get_reward_history


Testcase cho get_reward_history

```
▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, index, count đúng định dạng được nhà
phát triển quy định.
Kết quả mong đợi: 1000 | OK. Trả ra kết quả danh sách dữ
liệu ra giao diện.
```

API create_reward_appeal

API này được dùng để tạo yêu cầu khiếu nại xu được quy đổi từ
điểm thưởng.
Phương thức: POST.


API create_reward_appeal


Testcase cho create_reward_appeal

▪ Token hết hạn, không đúng,... (không hợp lệ).
Kết quả mong đợi: 9998 | Token is invalid. Màn hình chuyển
về trang đăng nhập, yêu cầu người dùng đăng nhập lại.
▪ Truyền token hợp lệ, reward_id có tồn tại trong database.
Kết quả mong đợi: 1000 | OK. Trả ra kết quả danh sách dữ
liệu ra giao diện.
▪ Truyền token hợp lệ, reward_id không tồn tại trong database.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo giá trị tham số truyền vào không hợp lệ, không thông báo ra
giao diện.


Mở rộng ( 1 )

Do phía seller có thể rút từ xu nội bộ về tiền trong tài khoản ngân
hàng, nên sau đó sẽ có một số API cần phát triển thêm.

- get_bank_accounts (api for seller): lấy ra danh sách các tài
    khoản ngân hàng
- add_bank_account (api for seller): thêm tài khoản ngân hàng
- edit_bank_account (api for seller): chỉnh sửa tài khoản ngân
    hàng
- delete_bank_account (api for seller): xóa tài khoản ngân hàng
- set_default_bank_account (api for seller): đặt một tài khoản
    ngân hàng là mặc định


Mở rộng ( 2 )

- create_withdraw_request (api for seller): yêu cầu rút tiền từ xu
    nội bộ về tài khoản ngân hàng
- set_request_withdraw: đồng ý/từ chối yêu cầu rút tiền (có thể
    không cần thiết)
- get_withdraw_history (api for seller): lịch sử rút tiền


HẾT TUẦN 5


Thank you
foryour
attentions**!**


