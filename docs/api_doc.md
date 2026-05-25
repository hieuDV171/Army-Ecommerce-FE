# Huong dan API (IT 4788)

Tai lieu tong hop day du request/response theo schema tu OpenAPI (api-docs-json).

## Thong tin chung

- Dinh dang: JSON
- Chuan tai lieu: OpenAPI 3.0
- Base URL: https://<domain>
- Auth: Bearer JWT trong header `Authorization` (neu endpoint co security)

## Addresses

### POST /addresses/create

- Auth: Bearer JWT
- Response:
  - 200: (khong co schema)

### GET /addresses/me

- Auth: Bearer JWT
- Response:
  - 200: (khong co schema)

## App

### GET /

- Auth: Khong
- Response:
  - 200: string

### GET /get-test-token

- Auth: Khong
- Response:
  - 200: string

## Auth

### POST /auth/change_info_after_signup

- Auth: Khong
- Request body (application/json):
  - Schema: ChangeInfoAfterSignupDto
  - username: string (required: yes) - minLength=3, maxLength=50
  - avatar: string (required: no)
- Response:
  - 201: (khong co schema)

### POST /auth/change_password

- Auth: Khong
- Request body (application/json):
  - Schema: ChangePasswordDto
  - token: string (required: no)
  - password: string (required: yes)
  - new_password: string (required: yes) - minLength=6
- Response:
  - 201: (khong co schema)

### POST /auth/check_code_reset_password

- Auth: Khong
- Request body (application/json):
  - Schema: CheckCodeResetPasswordDto
  - phone_number: string (required: yes)
  - reset_code: string (required: yes)
- Response:
  - 201: (khong co schema)

### POST /auth/create_code_reset_password

- Auth: Khong
- Request body (application/json):
  - Schema: CreateCodeResetPasswordDto
  - phone_number: string (required: yes)
- Response:
  - 201: (khong co schema)

### POST /auth/login

- Auth: Khong
- Request body (application/json):
  - Schema: LoginDto
  - phone_number: string (required: yes)
  - password: string (required: yes) - minLength=6
- Response:
  - 201: (khong co schema)

### POST /auth/logout

- Auth: Khong
- Response:
  - 201: (khong co schema)

### GET /auth/me

- Auth: Khong
- Response:
  - 200: (khong co schema)

### POST /auth/reset_password

- Auth: Khong
- Request body (application/json):
  - Schema: ResetPasswordDto
  - phone_number: string (required: yes)
  - password: string (required: yes) - minLength=6
- Response:
  - 201: (khong co schema)

### POST /auth/signup

- Auth: Khong
- Request body (application/json):
  - Schema: SignupDto
  - phone_number: string (required: yes)
  - password: string (required: yes) - minLength=6
  - uuid: string (required: yes)
- Response:
  - 201: (khong co schema)

## Blocks

### POST /get_list_blocks

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetListBlocksDto
  - index: object (required: yes)
  - count: object (required: yes)
- Response:
  - 200: (khong co schema)

### POST /set_user_block

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: SetUserBlockDto
  - user_id: object (required: yes)
  - type: object (required: yes)
- Response:
  - 200: (khong co schema)

## Conversations

### POST /conversation/get_conversation

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetConvDto
  - partner_id: number (required: yes) - ID nguoi nhan tin nhan
  - conversation_id: number (required: yes) - ID oan hoi thoai
  - index: number (required: yes) - So thu tu trang tin nhan tai ve (phan trang)
  - count: number (required: yes) - So luong tin nhan trong mot trang
- Response:
  - 200: object

### POST /conversation/get_list_conversation

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetListConvDto
  - index: number (required: yes) - So thu tu trang hoi thoai (phan trang)
  - count: number (required: yes) - So hoi thoai trong 1 trang
- Response:
  - 200: (khong co schema)

### POST /conversation/send_message

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: SendMessageDto
  - to_id: number (required: yes) - ID nguoi nhan tin nhan
  - message: string (required: yes) - Noi dung tin nhan
  - type_message: string (required: yes) - Kieu tin nhan
  - product_id: number (required: yes) - ID cua san pham trong oan hoi thoai
- Response:
  - 200: object

### POST /conversation/set_read_message

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: SetReadMessageDto
  - partner_id: number (required: yes) - ID nguoi hoi thoai cung
- Response:
  - 200: (khong co schema)

## DevTokens

### POST /dev_tokens/set_devtoken

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: SetDevtokenDto
  - devtype: string (required: yes) - enum=['0', '1']
  - devtoken: string (required: yes) - minLength=10
- Response:
  - 201: (khong co schema)

## Follow

### POST /get_list_followed

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetListFollowedDto
  - user_id: object (required: yes)
  - index: object (required: yes)
  - count: object (required: yes)
- Response:
  - 200: (khong co schema)

### POST /get_list_following

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetListFollowingDto
  - user_id: object (required: yes)
  - index: object (required: yes)
  - count: object (required: yes)
- Response:
  - 200: (khong co schema)

### POST /set_user_follow

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: SetUserFollowDto
  - followee_id: object (required: yes)
  - action: string (required: yes)
- Response:
  - 200: (khong co schema)

## news

### POST /News/list_news

- Mo ta: lay danh sach news
- Auth: Khong
- Request body (application/json):
  - Schema: GetListNewsDto
  - index: number (required: yes) - index e hien thi tu trang
  - count: number (required: yes) - So trang 
- Response:
  - 201: object

### GET /News/{id}

- Mo ta: Lay news
- Auth: Khong
- Parameters:
  - id (path, number, required: yes)
- Response:
  - 200: object

## Notifications

### POST /notification/get_notification

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetNotiticationDto
  - index: number (required: yes)
  - count: number (required: yes)
  - group: number (required: yes)
- Response:
  - 200: object

### POST /notification/set_read_notification

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: SetReadNotificationDto
  - notification_id: number (required: yes)
- Response:
  - 200: object

## Orders

### POST /order/add_order_address

- Mo ta: Them ia chi nguoi dung
- Auth: Bearer JWT
- Response:
  - 200: object

### POST /order/buyer_confirm_received

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: BuyerConfirmReceivedDto
  - purchase_id: string (required: yes)
  - state: string (required: no)
- Response:
  - 201: (khong co schema)

### POST /order/cancel_order

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: CancelOrderDto
  - id: string (required: yes)
  - reason: number (required: no)
- Response:
  - 201: (khong co schema)

### POST /order/create_order

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: CreateOrderDto
  - items: array<CreateOrderItemDto> (required: yes)
  - source: string (required: yes)
  - address_id: number (required: yes)
- Response:
  - 201: (khong co schema)

### DELETE /order/delete/{id}

- Mo ta: Xoa ia chi nguoi dung
- Auth: Bearer JWT
- Parameters:
  - id (path, number, required: yes)
- Response:
  - 200: object

### POST /order/edit_purchase

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: EditPurchaseDto
  - id: string (required: yes)
  - name: string (required: no)
  - address: string (required: no)
  - address_id: string (required: no)
  - note: string (required: no)
- Response:
  - 201: (khong co schema)

### GET /order/get_list_order_address

- Mo ta: lay danh sach ia chi cua nguoi mua
- Auth: Bearer JWT
- Response:
  - 200: object

### POST /order/get_list_purchases

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetListPurchasesDto
  - index: string (required: yes)
  - count: string (required: yes)
  - state: string (required: no)
- Response:
  - 201: (khong co schema)

### POST /order/get_order_status

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetOrderStatusDto
  - purchase_id: number (required: yes) - ma on hang
- Response:
  - 201: object

### POST /order/get_order_timeline

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetOrderTimelineDto
  - purchase_id: string (required: yes)
- Response:
  - 201: (khong co schema)

### POST /order/get_purchase

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetPurchaseDto
  - id: string (required: yes)
- Response:
  - 201: (khong co schema)

### POST /order/get_ship_fee

- Mo ta: Phi ship
- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetShipFeeDto
  - product_id: number (required: yes) - ma san pham
  - address_id: number (required: yes) - Ma ia chi nguoi dung
- Response:
  - 200: object

### GET /order/get_ship_from

- Mo ta: Lay danh sach kho hang theo khu vuc 0-phuong, 1-tinh
- Auth: Bearer JWT
- Parameters:
  - level (query, number, required: no) - level ma ia chi 
  - index (query, number, required: yes) - minimum=0
  - count (query, number, required: yes) - minimum=1
  - parent_id (query, string, required: yes) - ma tinh hoac ma phuong
- Response:
  - 200: object

### POST /order/refund_order

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: RefundOrderDto
  - purchase_id: string (required: yes)
  - state: string (required: no)
  - reason: string (required: no)
- Response:
  - 201: (khong co schema)

### POST /order/seller_mark_as_shipped

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: SellerMarkAsShippedDto
  - purchase_id: string (required: yes)
  - buyer_id: string (required: yes)
- Response:
  - 201: (khong co schema)

### POST /order/set_accept_buyer

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: SetAcceptBuyerDto
  - purchase_id: string (required: yes)
  - buyer_id: string (required: yes)
  - is_accept: number (required: yes)
- Response:
  - 201: (khong co schema)

### PATCH /order/update/{id}

- Mo ta: Sua ia chi nguoi dung
- Auth: Bearer JWT
- Parameters:
  - id (path, number, required: yes)
- Request body (application/json):
  - Schema: UpdateOrderAddressDto
  - address: string (required: no) - ia chi chi tiet
  - is_default: boolean (required: no) - anh dau ia chi mac inh
  - address_id: array<number> (required: no) - mang cac id, 0-ward_id, 1-province_id
  - lat: number (required: no) - Vi o
  - lng: number (required: no) - Kinh o
  - receiver_name: string (required: no) - Ho va ten nguoi nhan
  - phone: string (required: no) - So ien thoai
  - full_address: string (required: no) - ca ia chi
  - address_detail: string (required: no) - address detail
- Response:
  - 200: object

## Products

### POST /api/add_product

- Mo ta: Nguoi ban them san pham
- Auth: Bearer JWT
- Request body (application/json):
  - Schema: CreateProductDto
  - title: string (required: yes) - Product name; maxLength=255
  - price: number (required: yes) - price; minimum=0
  - description: string (required: yes) - Product description
  - image_urls: array<string> (required: no) - Product image url
  - brand_id: number (required: yes) - ID of the brand
  - variants: array<CreateProductVariantDto> (required: yes) - Product variants
  - category_id: number (required: yes) - category
  - ship_from_id: number (required: yes) - ID of the shipping address (Warehouse)
  - videos: array<VideoDto> (required: yes) - uong link video va thumb
- Response:
  - 201: object

### DELETE /api/delete/{id}

- Mo ta: Nguoi ban xoa san pham
- Auth: Bearer JWT
- Parameters:
  - id (path, number, required: yes)
- Response:
  - 200: object

### POST /api/get_categories

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetCategoriesDto
  - parent_id: number (required: no) - 0 la root category, neu khong truyen thi lay tat ca
- Response:
  - 201: (khong co schema)

### POST /api/get_comments_product

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetCommentsProductDto
  - product_id: number (required: yes)
  - index: number (required: yes) - minimum=0
  - count: number (required: yes) - minimum=1
- Response:
  - 201: (khong co schema)

### POST /api/get_list_brands

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetListBrandsDto
  - category_id: number (required: no) - 0 hoac null => lay tat ca
  - index: number (required: no) - minimum=0
  - count: number (required: no) - minimum=1
- Response:
  - 201: (khong co schema)

### POST /api/get_list_products

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetListProductsDto
  - category_id: number (required: no)
  - keyword: string (required: no)
  - brand_id: number (required: no)
  - product_size_id: number (required: no) - 0: all size
  - price_min: number (required: no)
  - price_max: number (required: no)
  - condition: string (required: no) - new, like new ...
  - order: string (required: no) - price_asc | price_desc | created_desc | discount_percent_desc | discount_value_desc | like_desc | comment_desc | distance_asc
  - latitude: number (required: no)
  - longitude: number (required: no)
  - last_id: number (required: no) - last id tra ve lan truoc
  - index: number (required: yes) - minimum=0
  - count: number (required: yes) - minimum=1
- Response:
  - 201: (khong co schema)

### POST /api/get_products

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetProductsDto
  - id: number (required: yes)
- Response:
  - 201: (khong co schema)

### POST /api/get_user_listings

- Mo ta: Lay danh sach san pham cua nguoi ban
- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetUserListingsDto
  - index: number (required: yes) - index
  - count: number (required: yes) - count
  - user_id: number (required: yes) - user_id
  - keyword: string (required: yes) - Tu khoa tim kiem
  - category_id: number (required: yes) - thuoc tinh san pham
- Response:
  - 201: object

### POST /api/like_product

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: LikeProductDto
  - product_id: number (required: yes)
- Response:
  - 201: (khong co schema)

### POST /api/report_product

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: ReportProductDto
  - product_id: number (required: yes)
  - subject: string (required: yes)
  - details: string (required: yes)
- Response:
  - 201: (khong co schema)

### POST /api/set_comments_product

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: SetCommentsProductDto
  - product_id: number (required: yes)
  - content: string (required: yes)
  - index: number (required: yes) - minimum=0
  - count: number (required: yes) - minimum=1
- Response:
  - 201: (khong co schema)

### PATCH /api/update/{id}

- Mo ta: Nguoi ban cap nhat thong tin san pham
- Auth: Bearer JWT
- Parameters:
  - id (path, number, required: yes)
- Request body (application/json):
  - Schema: UpdateProductDto
  - title: string (required: no) - Product name; maxLength=255
  - price: number (required: no) - price; minimum=0
  - description: string (required: no) - Product description
  - image_urls: array<string> (required: no) - Product image url
  - brand_id: number (required: no) - ID of the brand
  - variants: array<CreateProductVariantDto> (required: no) - Product variants
  - category_id: number (required: no) - category
  - ship_from_id: number (required: no) - ID of the shipping address (Warehouse)
  - videos: array<VideoDto> (required: no) - uong link video va thumb
  - image_urls_del: array<string> (required: no) - delete product image url
  - price_discount: number (required: yes) - price_discount; minimum=0
- Response:
  - 200: object

## PushSettings

### POST /push_settings/get_push_setting

- Auth: Bearer JWT
- Response:
  - 201: (khong co schema)

### POST /push_settings/set_push_setting

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: SetPushSettingDto
  - like: string (required: no) - enum=['0', '1']
  - comment: string (required: no) - enum=['0', '1']
  - transaction: string (required: no) - enum=['0', '1']
  - announcement: string (required: no) - enum=['0', '1']
  - sound_on: string (required: no) - enum=['0', '1']
  - sound_default: string (required: no)
- Response:
  - 201: (khong co schema)

## Rates

### POST /api/get_rates

- Auth: Khong
- Request body (application/json):
  - Schema: GetRatesDto
  - user_id: number (required: no)
  - level: number (required: no) - minimum=0, maximum=5
  - index: number (required: no) - minimum=0
  - count: number (required: no) - minimum=1
- Response:
  - 201: (khong co schema)

### POST /api/set_rates

- Auth: Khong
- Request body (application/json):
  - Schema: SetRateDto
  - user_id: number (required: yes)
  - level: number (required: yes) - minimum=1, maximum=5
  - content: string (required: yes)
  - product_id: number (required: no)
  - purchase_id: number (required: no)
- Response:
  - 201: (khong co schema)

## Searches

### POST /api/get_list_saved_search

- Auth: Khong
- Request body (application/json):
  - Schema: GetListSavedSearchDto
  - index: number (required: yes) - minimum=0
  - count: number (required: yes) - minimum=1
- Response:
  - 201: (khong co schema)

### POST /api/save_search

- Auth: Khong
- Request body (application/json):
  - Schema: SaveSearchDto
  - keyword: string (required: yes)
- Response:
  - 201: (khong co schema)

### POST /api/search

- Auth: Khong
- Request body (application/json):
  - Schema: SearchDto
  - keyword: string (required: no)
  - category_id: number (required: no)
  - brand_id: number (required: no)
  - price_min: number (required: no)
  - price_max: number (required: no)
  - index: number (required: no) - minimum=0
  - count: number (required: no) - minimum=1
- Response:
  - 201: (khong co schema)

## Upload

### POST /upload/file

- Mo ta: Upload file len server
- Auth: Bearer JWT
- Request body (multipart/form-data):
  - Schema: object
  - file: string (required: yes) - format=binary
- Response:
  - 201: (khong co schema)

## Users

### POST /users/get_user_info

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetUserInfoDto
  - user_id: number (required: yes)
- Response:
  - 200: object

### POST /users/set_user_info

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: SetUserInfoDto
  - email: string (required: yes) - format=email
  - username: string (required: yes)
  - status: string (required: yes)
  - avatar: string (required: yes)
  - firstname: string (required: yes)
  - lastname: string (required: yes)
  - address: string (required: yes)
  - cover_image: string (required: yes)
  - cover_image_web: string (required: yes)
- Response:
  - 200: object

## Wallets

### POST /wallets/get_balance_history

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetBalanceHistoryDto
  - index: string (required: yes)
  - count: string (required: yes)
- Response:
  - 201: (khong co schema)

### POST /wallets/get_current_balance

- Auth: Bearer JWT
- Request body (application/json):
  - Schema: GetCurrentBalanceDto
  - (khong co fields)
- Response:
  - 201: (khong co schema)

## Danh sach schema

### BuyerConfirmReceivedDto

- purchase_id: string (required: yes)
- state: string (required: no)

### CancelOrderDto

- id: string (required: yes)
- reason: number (required: no)

### ChangeInfoAfterSignupDto

- username: string (required: yes) - minLength=3, maxLength=50
- avatar: string (required: no)

### ChangePasswordDto

- token: string (required: no)
- password: string (required: yes)
- new_password: string (required: yes) - minLength=6

### CheckCodeResetPasswordDto

- phone_number: string (required: yes)
- reset_code: string (required: yes)

### CreateCodeResetPasswordDto

- phone_number: string (required: yes)

### CreateOrderDto

- items: array<CreateOrderItemDto> (required: yes)
- source: string (required: yes)
- address_id: number (required: yes)

### CreateOrderItemDto

- product_id: number (required: yes)
- quantity: number (required: yes) - minimum=1

### CreateProductDto

- title: string (required: yes) - Product name; maxLength=255
- price: number (required: yes) - price; minimum=0
- description: string (required: yes) - Product description
- image_urls: array<string> (required: no) - Product image url
- brand_id: number (required: yes) - ID of the brand
- variants: array<CreateProductVariantDto> (required: yes) - Product variants
- category_id: number (required: yes) - category
- ship_from_id: number (required: yes) - ID of the shipping address (Warehouse)
- videos: array<VideoDto> (required: yes) - uong link video va thumb

### CreateProductVariantDto

- id: number (required: no) - variant id (optional when create)
- size: string (required: yes) - kich co cua mat hang
- stock: number (required: yes) - so hang trong kho; minimum=0
- color: string (required: yes) - Mau sac
- weight: number (required: yes) - Khoi luong

### EditPurchaseDto

- id: string (required: yes)
- name: string (required: no)
- address: string (required: no)
- address_id: string (required: no)
- note: string (required: no)

### GetBalanceHistoryDto

- index: string (required: yes)
- count: string (required: yes)

### GetCategoriesDto

- parent_id: number (required: no) - 0 la root category, neu khong truyen thi lay tat ca

### GetCommentsProductDto

- product_id: number (required: yes)
- index: number (required: yes) - minimum=0
- count: number (required: yes) - minimum=1

### GetConvDto

- partner_id: number (required: yes) - ID nguoi nhan tin nhan
- conversation_id: number (required: yes) - ID oan hoi thoai
- index: number (required: yes) - So thu tu trang tin nhan tai ve (phan trang)
- count: number (required: yes) - So luong tin nhan trong mot trang

### GetCurrentBalanceDto

- (khong co fields)

### GetListBlocksDto

- index: object (required: yes)
- count: object (required: yes)

### GetListBrandsDto

- category_id: number (required: no) - 0 hoac null => lay tat ca
- index: number (required: no) - minimum=0
- count: number (required: no) - minimum=1

### GetListConvDto

- index: number (required: yes) - So thu tu trang hoi thoai (phan trang)
- count: number (required: yes) - So hoi thoai trong 1 trang

### GetListFollowedDto

- user_id: object (required: yes)
- index: object (required: yes)
- count: object (required: yes)

### GetListFollowingDto

- user_id: object (required: yes)
- index: object (required: yes)
- count: object (required: yes)

### GetListNewsDto

- index: number (required: yes) - index e hien thi tu trang
- count: number (required: yes) - So trang 

### GetListProductsDto

- category_id: number (required: no)
- keyword: string (required: no)
- brand_id: number (required: no)
- product_size_id: number (required: no) - 0: all size
- price_min: number (required: no)
- price_max: number (required: no)
- condition: string (required: no) - new, like new ...
- order: string (required: no) - price_asc | price_desc | created_desc | discount_percent_desc | discount_value_desc | like_desc | comment_desc | distance_asc
- latitude: number (required: no)
- longitude: number (required: no)
- last_id: number (required: no) - last id tra ve lan truoc
- index: number (required: yes) - minimum=0
- count: number (required: yes) - minimum=1

### GetListPurchasesDto

- index: string (required: yes)
- count: string (required: yes)
- state: string (required: no)

### GetListSavedSearchDto

- index: number (required: yes) - minimum=0
- count: number (required: yes) - minimum=1

### GetNotiticationDto

- index: number (required: yes)
- count: number (required: yes)
- group: number (required: yes)

### GetOrderStatusDto

- purchase_id: number (required: yes) - ma on hang

### GetOrderTimelineDto

- purchase_id: string (required: yes)

### GetProductsDto

- id: number (required: yes)

### GetPurchaseDto

- id: string (required: yes)

### GetRatesDto

- user_id: number (required: no)
- level: number (required: no) - minimum=0, maximum=5
- index: number (required: no) - minimum=0
- count: number (required: no) - minimum=1

### GetShipFeeDto

- product_id: number (required: yes) - ma san pham
- address_id: number (required: yes) - Ma ia chi nguoi dung

### GetUserInfoDto

- user_id: number (required: yes)

### GetUserListingsDto

- index: number (required: yes) - index
- count: number (required: yes) - count
- user_id: number (required: yes) - user_id
- keyword: string (required: yes) - Tu khoa tim kiem
- category_id: number (required: yes) - thuoc tinh san pham

### LikeProductDto

- product_id: number (required: yes)

### LoginDto

- phone_number: string (required: yes)
- password: string (required: yes) - minLength=6

### RefundOrderDto

- purchase_id: string (required: yes)
- state: string (required: no)
- reason: string (required: no)

### ReportProductDto

- product_id: number (required: yes)
- subject: string (required: yes)
- details: string (required: yes)

### ResetPasswordDto

- phone_number: string (required: yes)
- password: string (required: yes) - minLength=6

### SaveSearchDto

- keyword: string (required: yes)

### SearchDto

- keyword: string (required: no)
- category_id: number (required: no)
- brand_id: number (required: no)
- price_min: number (required: no)
- price_max: number (required: no)
- index: number (required: no) - minimum=0
- count: number (required: no) - minimum=1

### SellerMarkAsShippedDto

- purchase_id: string (required: yes)
- buyer_id: string (required: yes)

### SendMessageDto

- to_id: number (required: yes) - ID nguoi nhan tin nhan
- message: string (required: yes) - Noi dung tin nhan
- type_message: string (required: yes) - Kieu tin nhan
- product_id: number (required: yes) - ID cua san pham trong oan hoi thoai

### SetAcceptBuyerDto

- purchase_id: string (required: yes)
- buyer_id: string (required: yes)
- is_accept: number (required: yes)

### SetCommentsProductDto

- product_id: number (required: yes)
- content: string (required: yes)
- index: number (required: yes) - minimum=0
- count: number (required: yes) - minimum=1

### SetDevtokenDto

- devtype: string (required: yes) - enum=['0', '1']
- devtoken: string (required: yes) - minLength=10

### SetPushSettingDto

- like: string (required: no) - enum=['0', '1']
- comment: string (required: no) - enum=['0', '1']
- transaction: string (required: no) - enum=['0', '1']
- announcement: string (required: no) - enum=['0', '1']
- sound_on: string (required: no) - enum=['0', '1']
- sound_default: string (required: no)

### SetRateDto

- user_id: number (required: yes)
- level: number (required: yes) - minimum=1, maximum=5
- content: string (required: yes)
- product_id: number (required: no)
- purchase_id: number (required: no)

### SetReadMessageDto

- partner_id: number (required: yes) - ID nguoi hoi thoai cung

### SetReadNotificationDto

- notification_id: number (required: yes)

### SetUserBlockDto

- user_id: object (required: yes)
- type: object (required: yes)

### SetUserFollowDto

- followee_id: object (required: yes)
- action: string (required: yes)

### SetUserInfoDto

- email: string (required: yes) - format=email
- username: string (required: yes)
- status: string (required: yes)
- avatar: string (required: yes)
- firstname: string (required: yes)
- lastname: string (required: yes)
- address: string (required: yes)
- cover_image: string (required: yes)
- cover_image_web: string (required: yes)

### SignupDto

- phone_number: string (required: yes)
- password: string (required: yes) - minLength=6
- uuid: string (required: yes)

### UpdateOrderAddressDto

- address: string (required: no) - ia chi chi tiet
- is_default: boolean (required: no) - anh dau ia chi mac inh
- address_id: array<number> (required: no) - mang cac id, 0-ward_id, 1-province_id
- lat: number (required: no) - Vi o
- lng: number (required: no) - Kinh o
- receiver_name: string (required: no) - Ho va ten nguoi nhan
- phone: string (required: no) - So ien thoai
- full_address: string (required: no) - ca ia chi
- address_detail: string (required: no) - address detail

### UpdateProductDto

- title: string (required: no) - Product name; maxLength=255
- price: number (required: no) - price; minimum=0
- description: string (required: no) - Product description
- image_urls: array<string> (required: no) - Product image url
- brand_id: number (required: no) - ID of the brand
- variants: array<CreateProductVariantDto> (required: no) - Product variants
- category_id: number (required: no) - category
- ship_from_id: number (required: no) - ID of the shipping address (Warehouse)
- videos: array<VideoDto> (required: no) - uong link video va thumb
- image_urls_del: array<string> (required: no) - delete product image url
- price_discount: number (required: yes) - price_discount; minimum=0

### VideoDto

- url: string (required: yes) - https://example.com/video.mp4

