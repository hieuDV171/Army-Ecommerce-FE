- BÀI TẬP TUẦN


Nhắc lại

Đã nắm được tổng quan đề tài và quy trình bảo vệ
Đã hoàn thành được API thuộc nhóm Account
Tiếp tục với nhóm API thuộc nhóm User profile,
Catalog/Category/Filter, Listing


Mục lục

1. User profile
    + get_user_info
    + set_user_info
2. Catalog/Category/Filter
    + get_categories
    + get_list_products
    + get_product
    + get_list_brands


Mục lục

```
3. Product/Listing
+ add_product
+ edit_product
+ del_product
+ get_user_listings
```

get_user_info

```
API get_user_info được sử dụng để lấy thông tin hồ sơ (profile)
của người dùng. API này có thể dùng để lấy thông tin của chính
người dùng đang đăng nhập hoặc thông tin của một người dùng
khác dựa trên user_id.
```

get_user_info

- Nếu gửi token hợp lệ và không gửi user_id, hệ thống sẽ
    trả về thông tin đầy đủ của user đang đăng nhập, bao
    gồm các thông tin cá nhân như email, số điện thoại, địa
    chỉ, và địa chỉ mặc định.
- Nếu gửi user_id, hệ thống sẽ trả về thông tin hồ sơ
    công khai của người dùng tương ứng, như username,
    avatar, trạng thái, số lượng sản phẩm đã đăng bán,
    trạng thái online, và các thông tin hiển thị công khai
    khác. Một số thông tin riêng tư sẽ không được trả về
    trong trường hợp này.


get_user_info


get_user_info


Test case cho get_user_info

```
▪ Người dùng lấy thông tin của chính người dùng đó
Kết quả mong đợi: 1000 | OK. Thông báo thành công, dữ
liệu trả về đầy đủ các field (kể cả những field có tính riêng
tư) của output như email, phonenumber, firstname,
lastname, address, city, default_address
```
```
▪ Người dùng truyền token không hợp lệ (hết hạn, token sai,...)
Kết quả mong đợi: 9998 | Token is invalid. Thông báo lỗi, ứng
dụng giữ nguyên ở màn hình xem hồ sơ người dùng.
```

Test case cho get_user_info (2)

```
Người dùng lấy thông tin của chính người dùng khác bằng
user_id
Kết quả mong đợi: 1000 | OK. Thông báo thành công, dữ
liệu trả về các field không có tính riêng tư của output như
id, username, status, avatar, cover_image, listing,..
```

set_user_info

```
API set_user_info được sử dụng để cập nhật và lưu thông
tin hồ sơ của người dùng đang đăng nhập. Người dùng gửi
lên token xác thực cùng với các thông tin cần cập nhật
như email, username, trạng thái, thông tin cá nhân
(firstname, lastname, address), mật khẩu, hoặc các hình
ảnh hồ sơ như avatar, cover_image, ...
Request dạng POST
```

set_user_info

```
Các trường thông tin là không bắt buộc, nghĩa là người
dùng có thể cập nhật một hoặc nhiều trường tùy nhu cầu,
những trường không được gửi lên sẽ giữ nguyên giá trị
hiện tại. Sau khi cập nhật thành công, hệ thống sẽ lưu
thông tin mới vào database và trả về đường dẫn của các
hình ảnh hồ sơ đã được cập nhật để ứng dụng hiển thị.
```

set_user_info


set_user_info


Test case cho set_user_info

```
▪ Người dùng nhập data đầu vào vào các ô nhập liệu đúng định
dạng được quy định bởi nhà phát triển ( không bắt buộc nhập
hết các ô)
Kết quả mong đợi: 1000 | OK. Thông báo cập nhật thành công,
ứng dụng chuyển về giao diện hồ sơ người dùng
```
```
▪ Người dùng nhập data đầu vào vào các ô nhập liệu sai định
dạng được quy định bởi nhà phát triển (dù chỉ 1 field sai)
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo lỗi, ứng dụng chuyển giữ nguyên ở giao diện cập nhật hồ
sơ người dùng
```

get_categories

```
API get_categories được sử dụng để lấy danh sách các
danh mục (categories) trong hệ thống. API cho phép lấy
toàn bộ danh mục gốc hoặc các danh mục con dựa trên
parent_id.
Nếu không truyền parent_id hoặc parent_id = 0 → API trả
về danh sách các danh mục cấp cao nhất (root categories).
Nếu truyền parent_id hợp lệ → API trả về danh sách các
danh mục con thuộc danh mục cha đó.
API này thường được dùng để hiển thị danh mục sản
phẩm khi đăng bán, tìm kiếm, hoặc lọc sản phẩm.
Request dạng POST
```

get_categories


get_categories

- Khi bạn ở giao diện Home, app gọi { “parent_id” = 0 }, app sẽ trả về
    danh mục cha hiển thị như hình ở trên slide trước đó.
       (Slide trên minh họa cho danh mục sản phẩm của 1 sàn thương mai
       điện tử, sẽ thay đổi tùy vào yêu cầu của sàn)


get_list_products

```
API get_list_products dùng để lấy danh sách sản phẩm
theo nhiều tiêu chí lọc và sắp xếp khác nhau, phục vụ các
màn hình như: trang danh sách sản phẩm, tìm kiếm, lọc
theo category/brand/size, lọc theo khoảng giá, lọc theo
tình trạng sản phẩm, xem sản phẩm của một người bán,
hoặc lấy sản phẩm trong chiến dịch (campaign).
Request dạng POST
```

get_list_products

```
Input
```

get_list_products

```
Output
```

get_list_products

```
Ví dụ về giao diện trả về của get_list_product
```

get_list_products

- Ở ví dụ trên, khi user truyền vào input keyword (
    mimi kara oboeru n 3 từ vựng ), app sẽ trả về các sản
    phẩm có keyword liên quan.
- Ngoài ra, ở giao diện cũng sẽ có các trường input
    khác như condition, price_max, price_min,... dùng để
    thay đổi tùy chọn trả về của API get_list_product, ví
    dụ như sau (giả sử truyền vào condition = “mới
    nhất”, price_min = 70000 , price_max = 200000 ) :


get_list_products


get_list_products ( 3 )

Đầu vào last_id để phục vụ việc hiển thị các bài viết mới chính xác
hơn. Tại sao?

```
Tình huống lúc 9:00AM, ứng dụng nhận được dữ liệu bài viết từ A 1
đến A 20. Lúc 9:01AM, server có bài viết mới B 1 đến B 10. Lúc
9:02AM, ứng dụng yêu cầu thêm 20 bài nữa (index = 20 và count =
20 ).
```
```
Vậy server sẽ trả về bài A 21 đến A 40 hay bài A 11 đến A 30?
Làm thế nào để ứng dụng biết còn có các bài mới B 1 đến B 10?
```

get_product

```
API get_product dùng để lấy thông tin chi tiết của một sản
phẩm theo id sản phẩm.Nó thường dùng cho màn hình:
```
- Chi tiết sản phẩm (product detail page)
- Xem đầy đủ ảnh/video, mô tả, giá, người bán, category,
    size/brand, trạng thái mua được hay không,...
Request dạng POST


Input/Output của get_product (1)


Input/Output của get_product ( 2 )


get_product


get_product

- Khi ta click vào 1 sản phẩm từ phần ứng dụng trên, api get_product sẽ
trả về màn hình giao diện như sau


get_list_brands

```
API get_list_brands được sử dụng để lấy danh sách các
thương hiệu (brand) trong hệ thống. API cho phép lấy
toàn bộ danh sách brand được lọc theo danh mục sản
phẩm (category_id), đồng thời hỗ trợ phân trang thông
qua các tham số index và count.
Request dạng POST
```

get_list_brands


get_list_brands

- Khi user lấy list danh mục sản phẩm bằng API get_categories, giao
diện sẽ như hình dưới


get_list_brands

- Nếu user click vào 1 sản phẩm bất kỳ ( ví dụ là thời trang nam), app
sẽ trả về giao diện có các brand của danh mục thời trang nam như sau.


get_list_brands

- Để tránh quá tải, 2 trường input index và count giúp hiển thị số lượng
brand cố định cho 1 trang hiển thị, khi muốn hiển thị các brand còn lại
có thể nhấn button như hình dưới.


get_list_brands

- Khi đó, app sẽ trả về các brand khác như hình ví dụ dưới đây.


add_product

```
API add_product được sử dụng để đăng bán/đăng mới một
sản phẩm lên hệ thống. Người dùng phải gửi token để xác
thực và cung cấp các thông tin cơ bản của sản phẩm như
tên sản phẩm, giá, danh mục (category_id), thông tin tình
trạng, nơi gửi hàng, mô tả,... Đồng thời sản phẩm bắt
buộc phải có ít nhất một nội dung media (ảnh hoặc video)
để có thể đăng thành công.
Request dạng POST
```

add_product


add_product


Test case cho add_product

```
Người bán đăng sản phẩm với đầy đủ các field bắt buộc, token
hợp lệ, giá trị của các field đúng với định dạng được quy định
bởi nhà phát triển
Kết quả mong đợi: 1000 | OK. Thông báo upload sản phẩm
thành công.
```
```
Người bán truyền token không hợp lệ (hết hạn, token sai,...)
Kết quả mong đợi: 9998 | Token is invalid. Thông báo lỗi,
ứng dụng giữ nguyên ở màn hình upload sản phẩm
```

Test case cho add_product ( 2 )

```
▪ Người bán đăng sản phẩm không đầy đủ các field bắt buộc của
dữ liệu đầu vào.
Kết quả mong đợi: 1002 | Parameter is not enough. Thông
báo lỗi, ứng dụng giữ nguyên ở màn hình upload sản phẩm
```
```
▪ Người bán đăng sản phẩm với đầy đủ các trường bắt buộc của
dữ liệu đầu vào, tuy nhiên định dạng dữ liệu của 1 hoặc nhiều
trường bị sai ( có thể xảy ra đối với các trường không bắt buộc)
Kết quả mong đợi: 1003 | Parameter type is invalid. Thông
báo lỗi, ứng dụng giữ nguyên ở màn hình upload sản phẩm
```

edit_product

```
API dùng để cập nhật thông tin một sản phẩm đã đăng bán
trên hệ thống. Cho phép thay đổi các thuộc tính như tên, giá,
giá mới, mô tả, size, brand, category, nơi gửi, tình trạng, đồng
thời hỗ trợ cập nhật media (thêm ảnh mới, xoá ảnh cũ, sắp xếp
lại ảnh), cập nhật video, và các thông tin phụ thuộc category
như kích thước (dimension), cân nặng (weight).
Request dạng POST
```

edit_product


edit_product


Test case cho edit_product

```
Người bán chỉnh sửa sản phẩm với đầy đủ các field bắt buộc,
token hợp lệ, id sản phẩm đã tồn tại, giá trị của các field đúng
với định dạng được quy định bởi nhà phát triển
Kết quả mong đợi: 1000 | OK. Thông báo update sản phẩm
thành công.
```
```
Người bán truyền token không hợp lệ (hết hạn, token sai,...)
Kết quả mong đợi: 9998 | Token is invalid. Thông báo lỗi,
ứng dụng giữ nguyên ở màn hình update sản phẩm
```

Test case cho edit_product ( 2 )

```
Người bán chỉnh sửa sản phẩm với đầy đủ các field bắt buộc,
nhưng id sản phẩm chưa tồn tại.
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo lỗi, ứng dụng giữ nguyên ở màn hình update sản phẩm
```
```
Người bán chỉnh sửa sản phẩm nhưng không update toàn bộ
các trường bắt buộc.
Kết quả mong đợi: 1002 | Paramter is not enough. Thông
báo lỗi, ứng dụng giữ nguyên ở màn hình update sản phẩm
```

Test case cho edit_product ( 3 )

```
▪ Người bán chỉnh sửa sản phẩm với đầy đủ các field bắt buộc,
token hợp lệ, id sản phẩm đã tồn tại, nhưng 1 trong các trường
dữ liệu sai với định dạng của nhà phát triển (có thể xảy ra với
các trường không bắt buộc).
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo lỗi, ứng dụng giữ nguyên ở màn hình update sản phẩm
```

del_product

```
API dùng để xóa một sản phẩm khỏi hệ thống. Khi gọi API
này, sản phẩm tương ứng với id sẽ bị xóa khỏi danh sách sản
phẩm của hệ thống. Việc xóa là xóa hoàn toàn (hard delete)
theo thiết kế hệ thống, sản phẩm sẽ không còn hiển thị trên
ứng dụng và không thể mua bán.
Request dạng POST
```

del_product


Giao diện của del_product


get_user_listings

```
API dùng để lấy danh sách sản phẩm đã đăng của một người
bán đồng thời hỗ trợ lọc theo trạng thái giao dịch, tìm kiếm
theo từ khóa, lọc theo chuyên mục, và phân trang.
Request dạng POST.
```

get_user_listings


get_user_listings


Test case cho get_user_listings

```
▪ Người bán truyền token hợp lệ nhưng không truyền user_id
Kết quả mong đợi: 1000 | OK. Thông báo thành công, hệ thống
trả về My Listing ( listing của user trong token)
```
```
▪ Người bán không truyền token hợp lệ nhưng truyền user_id
Kết quả mong đợi: 1000 | OK. Thông báo thành công, ứng
dụng hiển thị listing ứng với user_id đó.
```

Test case cho get_user_listings ( 2 )

```
Người bán truyền token sai hoặc hết hạn
Kết quả mong đợi: 9998 | Token is invalid. Thông báo lỗi, giao
diện hiển thị thông báo load listing không thành công
```
```
Người bán không truyền user_id không tồn tại
Kết quả mong đợi: 1004 | Parameter value is invalid.
Thông báo lỗi, giao diện hiển thị thông
báo load listing
không thành công
```

HẾT TUẦN 3


Thank you

foryour

attentions**!**


