- BÀI TẬP TUẦN


Nhắc lại

```
Đã nắm được tổng quan đề tài và quy trình bảo vệ
```
```
Đã nắm được một số API thuộc nhóm Account
```
```
Tiếp tục với nhóm API Account và các giao diện đi kèm với chúng
```

Mục lục

1. create_code_reset_password
2. check_code_reset_password
3. reset_password
4. change_password
5. change_info_after_signup
6. set_devtoken
7. get_push_setting
8. set_push_setting


create_code_reset_password

```
API này được sử dụng để tạo và gửi mã xác thực (verify
code) đến số điện thoại của người dùng khi thực hiện chức
năng quên mật khẩu.
Request dạng POST.
Hệ thống sẽ kiểm tra xem số điện thoại có tồn tại trong hệ
thống hay không. Nếu tồn tại, hệ thống sẽ tạo một mã xác
thực ngẫu nhiên và gửi mã này đến số điện thoại đã cung cấp
thông qua SMS.
Mã xác thực này sẽ được sử dụng ở bước tiếp theo để xác
minh người dùng và cho phép đặt lại mật khẩu mới. Mã có
thời hạn sử dụng trong một khoảng thời gian nhất định vì lý
do bảo mật.
```

create_code_reset_password


create_code_reset_password

- Khi bấm Quên mật khẩu ở màn
    hình đăng nhập, giao diện của
    ứng dụng sẽ chuyển sang màn
    hình đặt lại mật khẩu.
- Ở màn hình đặt lại mật khẩu,
    mọi người nhập số điện thoại
    đã đăng kí và sẽ được chuyển
    sang màn hình nhập mã OTP
    như bên dưới


create_code_reset_password

- Nếu số điện thoại đã được đăng ký thì
mã OTP sẽ được gửi qua SMS hoặc
email để có thể xác nhận đổi mật khẩu


Test case cho create_code_reset_password

```
Người dùng truyền đúng số điện thoại đã được đăng ký trước
đó.
Kết quả mong đợi: 1000 | OK. Thông báo thành công, OTP
được gửi kèm response để người dùng xác nhận thay đổi
mật khẩu.
```
```
Người dùng truyền số điện thoại sai định dạng được quy định
từ trước ( quá dài, quá ngắn, ....)
Kết quả mong đợi: 1004 | Parameter value is invalid. Ứng
dụng giữ nguyên ở giao diện nhập số điện thoại.
```

Test case cho create_code_reset_password

```
Người dùng truyền đúng số điện thoại chưa được đăng ký
trước đó.
Kết quả mong đợi: 9995 | User is not validated. Thông báo
lỗi, ứng dụng giữ nguyên ở màn hình nhập số điện thoại.
```

check_code_reset_password

```
API check_code_reset_password được sử dụng để kiểm tra mã
xác thực (reset code/OTP) mà người dùng nhận được qua SMS
trong chức năng quên mật khẩu.
Request dạng POST
```
```
Người dùng sẽ gửi lên số điện thoại và mã xác nhận đã nhận. Hệ
thống sẽ đối chiếu mã này với dữ liệu đã được tạo trước đó (từ
API create_code_reset_password) và kiểm tra các điều kiện hợp lệ
như: mã có tồn tại hay không, có đúng với số điện thoại hay
không, và còn trong thời hạn sử dụng hay không.
```
```
Nếu mã hợp lệ: trả về trạng thái thành công để cho phép người
dùng chuyển sang bước đặt lại mật khẩu.
```

check_code_reset_password


check_code_reset_password

- Sau khi nhập mã OTP được gửi
kèm với response ở API trước,
nhấn Kế Tiếp, nếu mã OTP chính
xác, thì chuyển sang màn hình
đổi mật khẩu.


Test case cho check_code_reset_password

```
Người dùng truyền đúng số điện thoại và đúng mã xác thực đến
server
```
```
Kết quả mong đợi: 1000 | OK. Thông báo thành công, gửi
cho ứng dụng mã phiên đăng nhập, mã id người
dùng và mã xác thực cũ sẽ chính thức bị xóa khỏi server.
Người dùng truyền đúng số điện thoại nhưng mã xác thực bị sai.
Kết quả mong đợi: 9993 | Code verify is incorrect. Thông
báo lỗi, ứng dụng giữ nguyên ở màn hình nhập mã
xác nhận.
```

Test case cho check_code_reset_password ( 2 )

```
Người dùng truyền một số điện thoại đúng định dạng nhưng
```
nhưng truyền 1 mã xác thực đã được sử dụng từ trước đó.

```
Kết quả mong đợi: 9993 | Code verify is incorrect. Thông báo
lỗi, ứng dụng giữ nguyên ở màn hình nhập mã xác nhận.
```

Test case cho check_code_reset_password ( 3 )

```
Người dùng truyền một số điện thoại đúng định dạng nhưng
```
nhưng truyền 1 mã xác thực đã bị quá thời hạn.

```
Kết quả mong đợi: 9993 | Code verify is incorrect. Thông báo
lỗi, ứng dụng giữ nguyên ở màn hình nhập mã xác nhận.
```

reset_password

```
API reset_password được sử dụng để đặt lại mật khẩu mới cho
người dùng sau khi người dùng đã xác thực thành công mã reset
(OTP/code) ở bước trước (check_code_reset_password).
```
```
Request dạng POST.
```
```
Người dùng gửi lên số điện thoại và mật khẩu mới. Hệ thống sẽ
kiểm tra tính hợp lệ của yêu cầu (tài khoản tồn tại, đã verify code
hợp lệ trước đó, mật khẩu mới đúng định dạng/chính sách).
```
```
Nếu hợp lệ, hệ thống sẽ cập nhật mật khẩu mới cho tài khoản
tương ứng và tự động đăng nhập cho người dùng bằng cách trả về
thông tin user kèm token phiên đăng nhập.
```

reset_password


reset_password

- Ở màn hình tạo mật khẩu
mới, chúng ta nhập mật khẩu
vào ô nhập liệu, sau đó bấm
nút “Tiếp theo” xác nhận thay
đổi mật khẩu. Nếu thành công
thì giao diện sẽ trở thành như
slide dưới.


reset_password


Test case cho reset_password

```
Người dùng truyền mật khẩu đúng với quy tắc được quy định
bởi nhà phát triển
```
```
Kết quả mong đợi: 1000 | OK. Thông báo thành công, giao
diện ứng dụng chuyển về thông báo đổi mật khẩu thành
công
```

Test case cho reset_password ( 2 )

```
Người dùng truyền mật khẩu sai với quy tắc được quy định bởi
nhà phát triển (không đủ độ dài tối thiểu, trùng mật khẩu cũ,...)
```
```
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo lỗi, giao diện ứng dụng giữ nguyên ở màn hình thay đổi
mật khẩu.
```

Test case cho reset_password ( 3 )

```
▪ Người dùng không nhập mật khẩu vào ô nhập liệu.
```
```
Kết quả mong đợi: 1002 | Parameter is not enough. Thông
báo lỗi, giao diện ứng dụng giữ nguyên ở màn hình thay đổi
mật khẩu.
```

change_password

```
API change_password được sử dụng để thay đổi mật khẩu của
người dùng khi đã đăng nhập. Người dùng cần cung cấp token
phiên đăng nhập hợp lệ, mật khẩu hiện tại và mật khẩu mới.
```
```
Request dạng POST
```
```
Hệ thống sẽ xác thực token để xác định người dùng, sau đó
kiểm tra tính chính xác của mật khẩu hiện tại. Nếu hợp lệ, hệ
thống sẽ cập nhật mật khẩu mới cho tài khoản và đảm bảo mật
khẩu mới tuân thủ các quy định bảo mật.
```
```
Sau khi thay đổi thành công, mật khẩu cũ sẽ không còn hiệu lực
và người dùng có thể tiếp tục sử dụng tài khoản với mật khẩu
mới.
```

change_password


change_password


change_password

- Đầu tiên, hệ thống sẽ yêu cầu xác minh lại mật khẩu cũ để xác minh
danh tính, nếu thành công, hệ thống sẽ chuyển sang giao diện thay
đổi mật khẩu như dưới đây.


Test case cho change_password

```
Người dùng không nhập mật khẩu cũ, mật khẩu mới và xác
nhận mật khẩu chính xác, đúng định dạng mà nhà phát triển
yêu cầu
Kết quả mong đợi: 1000 | OK. Thông báo thành công, hiển thị
thông báo và giao diện ứng dụng chuyển về trang chủ.
```

Test case cho change_password ( 2 )

```
▪ Người dùng nhập mật khẩu cũ không chính xác
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo lỗi, giao diện ứng dụng giữ nguyên ở màn hình xác nhận
danh tính.
```
```
Người dùng không nhập xác nhận mật khẩu không trùng với
mật khẩu mới
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo lỗi, giao diện ứng dụng giữ nguyên ở màn hình thay đổi
mật khẩu.
```

Test case cho change_password ( 3 )

```
Người dùng không nhập mật khẩu mới theo đúng định dạng mà
nhà phát triển quy định ( trùng với mật khẩu cũ, quá ngắn, ....)
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo lỗi, giao diện ứng dụng giữ nguyên ở màn hình thay đổi
mật khẩu.
```
```
Người dùng không nhập đầy đủ ô xác nhận mật khẩu và mật
khẩu mới
Kết quả mong đợi: 1002 | Parameter is not enough. Thông
báo lỗi, giao diện ứng dụng giữ nguyên ở màn hình thay đổi
mật khẩu.
```

change_info_after_signup

API thực hiện việc thay đổi thông tin người dùng một khi đăng ký

thành công

Request dạng POST

Tham số: token (mã phiên đăng nhập) và username (tên hiển thị) và

avatar (ảnh đại diện)

Nếu thay đổi thành công thì sẽ có các mã id (định danh người

dùng), username, phonenumber (có thể không có), created (thời

gian tạo), avatar (link của ảnh đại diện), trường is_blocked và

online. Nếu không thành công thì sẽ có các thông báo lỗi tương ứng


Change_info_after_signup


Test case cho change_info_after_signup

```
Người dùng truyền đúng mã phiên đăng nhập và tên người dùng
phù hợp cũng như ảnh avatar đúng quy định lên server
Kết quả mong đợi: 1000 | OK. Thông báo thành công, gửi cho
ứng dụng các thông tin cần thiết.
Người dùng gửi sai mã phiên đăng nhập (mã bị trống hoặc quá
ngắn).
Kết quả mong đợi: 1004 | Parameter is invalid. Nếu mã phiên
đăng nhập quá ngắn hoặc bỏ trống thì ứng dụng có thể tự kiểm
tra.
```

Test case cho change_info_after_signup ( 2 )

▪Người dùng truyền một mã phiên đăng nhập của người khác hoặc

một mã phiên đã cũ.

```
Kết quả mong đợi: Ứng dụng (Client) sẽ dựa vào trường code
được trả về trong Response từ API để biết mà đăng xuất người
dùng ra khỏi. Khi đăng xuất sẽ được chuyển sang màn hình
đăng nhập.
```
▪Người dùng truyền một mã phiên hợp lệ nhưng tên username

không hợp lệ (nhưng chưa đến mức bị khóa)

```
Kết quả mong đợi: 1004 | Parameter is invalid. Phía client cần
hiển thị đúng một loại thông báo hợp lý cho mã lỗi này.
```

Test case cho change_info_after_signup ( 3 )

```
Người dùng truyền một mã phiên hợp lệ nhưng tên username
```
không hợp lệ (đến mức bị khóa)

```
Kết quả mong đợi: Trường is_blocked được gán giá trị phù hợp.
Phía client chuyển người dùng sang trang đăng nhập và hiển thị
thông báo hợp lý cho loại mã lỗi này.
Người dùng truyền mã phiên hợp lệ, tên username hợp lệ nhưng
```
ảnh avatar không hợp lệ do dung lượng quá lớn.

```
Kết quả mong đợi: ứng dụng cần kiểm tra ngay phía mình để
đảm bảo không gửi dữ liệu không chính xác. Thông báo cần
hiển thị là dung lượng ảnh quá lớn.
```

set_devtoken

```
API set_devtoken được sử dụng để đăng ký hoặc cập nhật device
token của thiết bị người dùng với hệ thống. Device token này dùng
để gửi thông báo đẩy (push notification) từ server đến thiết bị cụ
thể của người dùng thông qua các dịch vụ như Firebase Cloud
Messaging (FCM) hoặc Apple Push Notification Service (APNs).
```
```
Khi người dùng đăng nhập hoặc cài đặt ứng dụng trên một thiết bị
mới, ứng dụng sẽ gửi device token và loại thiết bị (iOS hoặc
Android) lên server thông qua API này.
```
```
Server sẽ lưu thông tin này và sử dụng để gửi các thông báo như:
tin nhắn mới, thông báo đơn hàng, cập nhật trạng thái, hoặc các
thông báo hệ thống khác đến đúng thiết bị của người dùng.
```

set_devtoken


get_push_setting

```
API get_push_setting được sử dụng để lấy cấu hình cài đặt thông
báo đẩy (push notification) hiện tại của người dùng đang đăng
nhập.
Người dùng gửi lên token để xác thực. Hệ thống sẽ xác định user
tương ứng và trả về các trạng thái bật/tắt ( 0 / 1 ) cho từng loại thông
báo, ví dụ: like, comment, transaction, announcement, cũng như
các cài đặt liên quan đến âm thanh như sound_on và
sound_default.
Kết quả trả về giúp ứng dụng hiển thị đúng trạng thái công tắc
trong màn hình cài đặt thông báo và đảm bảo server chỉ gửi các
thông báo mà người dùng đã cho phép.
```

get_push_setting


set_push_setting

```
API set_push_setting được sử dụng để cập nhật cấu hình cài đặt
thông báo đẩy (push notification) của người dùng đang đăng nhập.
```
```
Người dùng gửi lên token để xác thực, kèm theo các trường cài
đặt muốn thay đổi như: like, comment, transaction,
announcement, sound_on, sound_default (giá trị 0/1, trong đó 0
= off, 1 = on).
Các trường này là không bắt buộc, nghĩa là người dùng có thể
chỉ cập nhật một vài mục, những mục không gửi lên sẽ được
giữ nguyên như hiện tại.
```
```
Sau khi cập nhật thành công, hệ thống lưu lại các thiết lập mới để
đảm bảo server chỉ gửi các loại thông báo mà người dùng cho phép
và ứng dụng hiển thị đúng trạng thái cài đặt.
```

set_push_setting
**GỢI Ý CÁCH TỔ CHỨC GIAO DIỆN**


set_push_setting


HẾT TUẦN 2


Thank you

foryour

attentions**!**


