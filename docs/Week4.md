- BÀI TẬP TUẦN


Nhắc lại

▪Đã nắm được tổng quan đề tài và quy trình bảo vệ

▪Đã nắm được các API thuộc nhóm User profile, Categories,

Product/ Listings

▪Tiếp tục với nhóm API Comment/Like/Report, Search, News và

các giao diện đi kèm với chúng


Mục lục

1. Comment / Like / Report / Rating
    + get_comments_product
    + set_comments_product
    + like_product
    + report_product
    + get_rates
    + set_rates


Mục lục

```
2. Search
+ search
+ del_saved_search
+ get_list_saved_search
3. News
+ get_list_news
+ get_news
```

get_comments_product

```
API này dùng để lấy danh sách comment của một sản
phẩm, hỗ trợ phân trang thông qua tham số index và
count. Kết quả trả về bao gồm nội dung comment, thời
gian tạo, và thông tin người đăng comment.
Request dạng POST
```

get_comments_product


get_comments_product


Test case cho get_comments_product

```
▪ Truyền product_id, index, count đầy đủ
Kết quả mong đợi: 1000 | OK. Thông báo thành công, giao
diện load các comment của sản phẩm ứng với product_id
tương ứng, bắt đầu từ index với số lượng comment mỗi lần
<= count.
```
```
▪ Người dùng truyền thiếu 1 trong các tham số, product_id,
index hoặc count.
Kết quả mong đợi: 1002 | Parameter is not enough. Thông
báo lỗi, ứng dụng vẫn giữ nguyên ở màn hình chi tiết sản
phẩm và không load được comment.
```

Test case cho get_comments_product (2)

```
▪ Truyền product_id không tồn tại trong danh sách product_id
của sản phẩm
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo lỗi, ứng dụng giữ nguyên ở màn hình chi tiết sản phẩm và
không load được comment.
```

set_comments_product

```
API dùng để tạo (đăng) một comment cho sản phẩm. Sau
khi comment được tạo thành công, API sẽ trả về danh
sách comment (phục vụ client cập nhật UI ngay), thông
qua cơ chế phân trang index, count — thường dùng để
“lấy về những comment mới mà client chưa có”.
Request dạng POST
```

set_comments_product


set_comments_product


Test case cho set_comments_product

```
▪ Truyền đầy đủ các trường dữ liệu; trong đó, index, count,
comment đúng định dạng được nhà phát triển quy định, token
hợp lệ, product_id đã tồn tại
Kết quả mong đợi: 1000 | OK. Thông báo thành công, giao
diện hiển thị comment người dùng mới đánh giá cho sản phẩm
dựa trên index và count.
▪ Người dùng truyền thiếu 1 trong các tham số, product_id,
index, comment hoặc count.
Kết quả mong đợi: 1002 | Parameter is not enough. Thông
báo lỗi, ứng dụng vẫn giữ nguyên ở màn hình để người dùng
đánh giá sản phẩm.
```

Test case cho set_comments_product (2)

```
▪ Truyền đầy đủ các trường dữ liệu; trong đó, index, count,
comment đúng định dạng được nhà phát triển quy định,
product_id đã tồn tại, tuy nhiên token bị lỗi hoặc đã hết hạn.
Kết quả mong đợi: 9998 | Token is invalid. Thông báo lỗi,
ứng dụng vẫn giữ nguyên ở màn hình để người dùng đánh
giá sản phẩm.
▪ Người dùng truyền đầy đủ các tham số, token hợp lệ, tuy nhiên
rơi vào 1 trong các trường hợp, product_id chưa tồn tại,
comment sai định dạng được quy định bởi nhà phát triển
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo lỗi, ứng dụng vẫn giữ nguyên ở màn hình ứng dụng vẫn
giữ nguyên ở màn hình để người dùng đánh giá sản phẩm.
```

like_product

```
API dùng để like hoặc unlike một sản phẩm (toggle).
Khi user gọi API:
```
- Nếu user chưa like sản phẩm → hệ thống thêm like
- Nếu user đã like sản phẩm → hệ thống bỏ like (unlike)
Sau đó API trả về tổng số like hiện tại của sản phẩm để
client cập nhật UI ngay.
Request dạng POST


like_product


like_product

- Khi người dùng ấn vào biểu tượng Like sản phẩm, sản
phẩm sẽ được thêm vào danh sách like, nếu người dùng đã
like sản phẩm và click thì sẽ bỏ like sản phẩm


like_product

- Ví dụ cho sản phẩm đã được like


report_product

```
API dùng để báo cáo (report) một sản phẩm khi người
dùng phát hiện nội dung vi phạm/chưa phù hợp, ví dụ:
```
- Hàng giả/hàng cấm
- Nội dung mô tả sai sự thật
- Spam/quảng cáo
- Ảnh phản cảm
- Gian lận, lừa đảo, v.v.
Khi gọi API, hệ thống sẽ ghi nhận report kèm người
report, sản phẩm bị report, chủ đề report và chi tiết mô tả
để admin/moderator xử lý.
Request dạng POST


report_product


Test case cho report_product

```
▪ Truyền đầy đủ các trường dữ liệu; token hợp lệ, product_id đã
tồn tại, subject và detailed đúng định dạng được nhà phát triển
quy định
Kết quả mong đợi: 1000 | OK. Thông báo thành công, giao
diện hiển thị thông báo thành công đến người dùng.
```
```
▪ Người dùng truyền thiếu 1 trong các tham số, product_id,
index, comment hoặc count.
Kết quả mong đợi: 1002 | Parameter is not enough. Thông
báo lỗi, ứng dụng vẫn giữ nguyên ở màn hình để người dùng
báo cáo sản phẩm
```

Test case cho report_product (2)

```
Truyền đầy đủ các trường dữ liệu nhưng token không hợp lệ
(hết hạn)
Kết quả mong đợi: 9998 | Token is invalid. Thông báo lỗi,
ứng dụng vẫn giữ nguyên ở màn hình để người dùng
báo cáo sản phẩm.
```
```
Người dùng truyền đầy đủ các trường dữ liệu nhưng
product_id không tồn tại hoặc subject, detailed sai định dạng
được nhà phát triển quy định
Kết quả mong đợi: 1004 | Parameter value is invalid. Thông
báo lỗi, ứng dụng vẫn giữ nguyên ở màn hình để người dùng
báo cáo sản phẩm
```

get_rates

```
API này dùng để lấy danh sách các đánh giá
(rating/review) của một user, product hoặc đơn hàng; bao
gồm nội dung đánh giá, người đánh giá, mức đánh giá
(level), và thời gian tạo.
API hỗ trợ:
```
- Lấy rating của một user/product/đơn hàng cụ thể
- Hoặc lấy rating của user đang đăng nhập
- Lọc rating theo mức đánh giá (level)
- Phân trang bằng index và count
Request dạng POST


get_rates


get_rates

```
Ví dụ giao diện đánh giá 1 user
```

get_rates

- Ở giao diện trên, nếu người dùng truyền vào
    “level = 0”, sẽ trả về tất cả các đánh giá.
- Tương tự, nếu người dùng trên vào với các
    level khác nhau ( từ 1->5 ) thì sẽ hiển thị tương
    ứng.
- Nếu lấy đánh giá của chính bản thân thì không
    cần truyền user_id, chỉ cần truyền user_id nếu
    xem đánh giá của người dùng khác

```
Lưu ý:
```

Test case cho get_rates

```
▪ Truyền đầy đủ các trường dữ liệu; token hợp lệ, không cần
truyền user_id, các trường khác đúng định dạng nhà phát triển
quy định.
Kết quả mong đợi: 1000 | OK. Thông báo thành công, giao
diện hiển thị toàn bộ đánh giá đối với người dùng hiện thời
đăng nhập, index và count giúp giới hạn số đánh giá trên 1
trang
```

Test case cho get_rates (2)

```
▪ Truyền đầy đủ các trường dữ liệu; token hợp lệ,user_id của
người dùng đã tồn tại trong hệ thống, các trường khác đúng
định dạng nhà phát triển quy định
Kết quả mong đợi: 1000 | OK. Thông báo thành công, giao
diện hiển thị toàn bộ đánh giá đối với người dùng có user_id
trùng với user_id được truyền vào, index và count giúp giới
hạn số đánh giá trên 1 trang.
```

Test case cho get_rates (3)

```
▪ Truyền đầy đủ các trường dữ liệu nhưng token không hợp lệ
( hết hạn )
Kết quả mong đợi: 9998 | Token is invalid. Thông báo lỗi,
app không tải được các đánh giá của người dùng.
```

set_rates

```
API dùng để tạo đánh giá (rating) kèm nội dung cho một
đối tượng liên quan đến giao dịch, bao gồm:
```
- Sản phẩm (product_id)
- Giao dịch mua (purchase_id)
- Người dùng (user_id) – thường là người bán/đối tác
    giao dịch
User sau khi mua hàng có thể chấm sao (1–5) và viết nhận
xét.
Request dạng POST


set_rates


set_rates

```
Ví dụ cho việc đánh giá đơn mua (sử dụng purchase_id)
```

Test case cho set_rates

```
Truyền đầy đủ các trường dữ liệu; token hợp lệ, truyền 1 trong
3 trường id, các trường khác đúng định dạng nhà phát triển quy
định
Kết quả mong đợi: 1000 | OK. App thông báo đánh giá
thành công, giao diện cập nhật hiển thị đánh giá của người
dùng.
```

Test case cho set_rates (2)

```
▪ Truyền đầy đủ các trường dữ liệu; token không hợp lệ (hết
hạn).
Kết quả mong đợi: 9998 | Token is not valid. App thông báo
đánh giá không thành công, giao diện vẫn ở màn hình đánh
giá sản phẩm.
```

Test case cho set_rates (3)

```
▪ Truyền đầy đủ các trường dữ liệu; token hợp lệ, truyền 1 trong
3 trường id nhưng id chưa tồn tại trong hệ thống, các trường
khác đúng định dạng nhà phát triển quy định
Kết quả mong đợi: 1004 | Parameter value is invalid. App
thông báo đánh giá không thành công, giao diện vẫn ở màn
hình đánh giá sản phẩm.
```

Test case cho set_rates ( 4 )

```
▪ Truyền đầy đủ các trường dữ liệu; token hợp lệ, truyền 1 trong
3 trường id đã tồn tại trong hệ thống, các trường khác sai định
dạng nhà phát triển quy định
Kết quả mong đợi: 1004 | Parameter value is invalid. App
thông báo đánh giá không thành công, giao diện vẫn ở màn
hình đánh giá sản phẩm.
```

search

```
API này dùng để tìm kiếm danh sách sản phẩm theo từ
khóa và các điều kiện lọc, ví dụ:
```
- Tìm theo tên sản phẩm (keyword)
- Lọc theo danh mục (category_id)
- Lọc theo thương hiệu (brand_id)
- Lọc theo size (product_size_id)
- Lọc theo khoảng giá (price_min, price_max)
- Lọc theo tình trạng sản phẩm (condition)
API hỗ trợ phân trang bằng index và count.

```
Chú ý: bắt buộc phải có 1 điều kiện lọc để xác định
```

search


search

```
Ví dụ cho giao diện tìm kiếm và các điều kiện lọc
```

Test case cho search

```
▪ Người dùng không truyền vào 1 filter nào
Kết quả mong đợi: 1000 | OK. Tuy nhiên, app sẽ không trả
về danh sách tìm kiếm và giữ nguyên ở màn hình home.
```
```
▪ Người dùng truyền vào filter nhưng 1 số điều kiện bị mâu
thuẫn với nhau ( ví dụ price_min > price_max )
Kết quả mong đợi: 1000 | OK. Tuy nhiên, app sẽ không trả
về danh sách tìm kiếm rỗng.
```

del_saved_search

```
API dùng để xóa lịch sử tìm kiếm của người dùng. Hệ
thống hỗ trợ xóa một từ khóa tìm kiếm cụ thể hoặc xóa
toàn bộ lịch sử.
Request dạng POST
```

del_saved_search


get_list_saved_search

```
API này dùng để lấy danh sách các từ khóa tìm kiếm đã
được lưu trước đó của người dùng.
Danh sách này được sử dụng để:
```
- Hiển thị recent search (tìm kiếm gần đây)
- Giúp người dùng chọn lại từ khóa đã tìm
- Cải thiện trải nghiệm tìm kiếm nhanh
API hỗ trợ phân trang thông qua tham số index và count.
Request dạng POST


get_list_saved_search


get_list_saved_search


get_list_news

```
API này dùng để lấy danh sách các bài viết tin tức (news)
từ hệ thống.
Danh sách news có thể được hiển thị tại các màn hình như
trang chủ ứng dụng
API hỗ trợ phân trang thông qua tham số index và count.
Request dạng POST
```

get_list_news


get_list_news

```
Ví dụ cho việc gọi API get_list_news ở trang chủ của hệ thống
```

Test case cho get_list_news

```
Ví dụ về các nút để chuyển trang tin tức
```

Test case cho get_list_news

```
▪ Không truyền vào 1 trường dữ liệu nào, lúc này inpt = {}
Kết quả mong đợi: 1000 | OK. Danh sách tin tức sẽ được
hiện thị mặc định ( default mode ) theo cách thiết kế của nhà
phát triển.
```
```
▪ Truyền vào đầy đủ các trường giá trị của input = {index,
count}
Kết quả mong đợi: 1000 | OK. Danh sách tin tức sẽ được
hiển thị bắt đầu từ index và sử dụng count để phân trang (
quy định số tin tức tối đa trên cùng 1 trang), sử dụng các nút
để chuyển sang các trang tin tức khác.
```

get_news

```
API này dùng để lấy thông tin chi tiết của một bài tin tức
(news) dựa trên id của bài tin.
Thông tin trả về bao gồm:
```
- Tiêu đề bài tin
- Nội dung bài tin
- Thời gian tạo bài tin
API này thường được sử dụng khi người dùng chọn một
bài news từ danh sách news để xem chi tiết.
Request dạng POST.


get_news


Test case cho get_news

```
Truyền vào id đúng định dạng, id đã tồn tại trong list danh
sách tin tức
Kết quả mong đợi: 1000 | OK. Thông báo thành công, ứng
dụng tải tin tức thành công, hiển thị nội dung của tin tức
```
```
Truyền vào id đúng định dạng nhưng id chưa tồn tại trong
danh sách tin tức.
Kết quả mong đợi: 1004 | Parameter value is invalid.
Thông báo lỗi, ứng dụng tải tin tức không thành công.
```

HẾT TUẦN 4


Thank you

for your

attentions**!**


