# BẢN THI CÔNG FRONTEND FLUTTER — VIBECODE KIT

> Dành cho Codex / coding agent triển khai frontend Flutter.  
> Sản phẩm: sàn thương mại điện tử nội bộ dùng tiền ảo, tương tự Shopee nhưng giao diện hiện đại hơn, giàu hiệu ứng hơn.  
> State management bắt buộc: **BLoC / flutter_bloc**.

---

## 0. ROLE — BUILDER CONTRACT

Bạn là **BUILDER** trong workflow Vibecode Kit.

Nhiệm vụ của bạn:
- Scan codebase Flutter hiện tại nếu có.
- Thi công frontend theo đúng bản thi công này.
- Tích hợp backend theo `api_doc.md`.
- Dùng BLoC để quản lý state.
- Tự test theo acceptance criteria.
- Báo cáo kết quả theo Completion Report.

Không được:
- Không đổi kiến trúc state management sang Provider/Riverpod/GetX.
- Không tự ý thêm package nặng nếu không cần.
- Không hardcode token, base URL, user id.
- Không bỏ qua error handling cho token hết hạn / lỗi tham số / lỗi mạng.
- Không làm UI sơ sài kiểu CRUD form; phải có chất lượng app thương mại điện tử hiện đại.

---

## 1. PRODUCT CONTEXT

### 1.1. Bối cảnh sản phẩm

Sản phẩm là một hệ thống thương mại điện tử đặc thù:

- Người dùng có tài khoản và ví tiền ảo.
- Người dùng có thể đăng bán sản phẩm/listing.
- Người dùng có thể tìm kiếm, lọc, xem chi tiết, like, comment, report sản phẩm.
- Người dùng có thể theo dõi/block người dùng khác.
- Có chat/messaging giữa người mua và người bán theo sản phẩm.
- Có notification.
- Có địa chỉ giao hàng, phí ship, đơn hàng, lịch sử đơn.
- Có wallet/balance/history.
- Có upload media/video để quy đổi điểm thưởng và khiếu nại điểm thưởng.

### 1.2. Định hướng UI

Mẫu tham chiếu: **Shopee**.

Nhưng cần:
- Đẹp hơn, hiện đại hơn.
- Motion nhiều hơn nhưng không rối.
- Card sản phẩm nổi khối, ảnh lớn, bo góc mềm.
- Home nhiều section như marketplace thật.
- Product detail có gallery/video, seller card, rating, comment, action sticky bottom.
- Checkout/order/wallet có cảm giác fintech + ecommerce.
- Skeleton loading, shimmer, pull-to-refresh, infinite scroll.

### 1.3. Tech stack bắt buộc

- Flutter stable.
- Dart null-safety.
- `flutter_bloc` + `bloc`.
- `equatable` cho state/event/model equality.
- `dio` cho HTTP client.
- `shared_preferences` hoặc `flutter_secure_storage` cho token; ưu tiên secure storage nếu đã có package.
- `go_router` hoặc Navigator 2.0 nếu project đã dùng; nếu project chưa có router thì dùng `go_router`.
- `cached_network_image` cho ảnh sản phẩm/avatar.
- `shimmer` cho loading UI.
- `intl` cho format tiền/ngày.

Nếu codebase hiện tại đã có package tương đương, reuse package hiện tại thay vì thêm trùng.

---

## 2. API INTEGRATION MAP

Base URL lấy từ config/env, không hardcode trực tiếp trong widget.

### 2.1. Auth

Endpoints:
- `POST /auth/signup`
- `POST /auth/login`
- `POST /auth/logout`
- `GET /auth/me`
- `POST /auth/change_info_after_signup`
- `POST /auth/change_password`
- `POST /auth/create_code_reset_password`
- `POST /auth/check_code_reset_password`
- `POST /auth/reset_password`
- `POST /dev_tokens/set_devtoken`
- `POST /push_settings/get_push_setting`
- `POST /push_settings/set_push_setting`

Screens:
- Splash / session check.
- Login.
- Signup.
- Complete profile after signup.
- Forgot password: phone → OTP → new password → success.
- Change password.

BLoCs:
- `AuthBloc`
- `ForgotPasswordBloc`
- `ProfileSetupBloc`

Rules:
- Password min length: 6.
- Phone number required.
- Token invalid code `9998` → clear session → route login.

---

### 2.2. Profile / Social

Endpoints:
- `POST /users/get_user_info`
- `POST /users/set_user_info`
- `POST /get_list_followed`
- `POST /get_list_following`
- `POST /set_user_follow`
- `POST /get_list_blocks`
- `POST /set_user_block`

Screens:
- My profile.
- Public seller/user profile.
- Edit profile.
- Followers list.
- Following list.
- Blocked users list.

BLoCs:
- `ProfileBloc`
- `EditProfileBloc`
- `FollowBloc`
- `BlockBloc`

UI requirements:
- Cover image header with parallax or fade effect.
- Avatar overlaps cover.
- Stats row: listings / followers / following / rating.
- Follow button animated state transition.
- Seller products grid below profile.

---

### 2.3. Catalog / Products / Listing

Endpoints:
- `POST /api/get_categories`
- `POST /api/get_list_brands`
- `POST /api/get_list_products`
- `POST /api/get_products`
- `POST /api/get_user_listings`
- `POST /api/add_product`
- `PATCH /api/update/{id}`
- `DELETE /api/delete/{id}`
- `POST /upload/file`

Screens:
- Home.
- Category listing.
- Product list/search results.
- Product detail.
- Seller listings.
- Add product.
- Edit product.
- My selling products.

BLoCs:
- `HomeBloc`
- `CategoryBloc`
- `ProductListBloc`
- `ProductDetailBloc`
- `ListingBloc`
- `ProductFormBloc`
- `UploadBloc`

Home UI sections:
1. Gradient top bar with search box, notification icon, chat icon, wallet chip.
2. Promo/banner carousel.
3. Category horizontal grid.
4. Flash / urgent supply section.
5. Recommended products masonry/grid.
6. Recently viewed or trending search chips if data exists.

Product card:
- Image 1:1.
- Price prominent.
- Title max 2 lines.
- Like count / sold count / rating if available.
- Seller/location chip if available.
- Hero animation to detail page.

Pagination:
- Use `index`, `count`, `last_id` where API supports.
- Implement infinite scroll.
- Deduplicate products by id.
- Pull-to-refresh resets index.

---

### 2.4. Comment / Like / Report / Rating

Endpoints:
- `POST /api/get_comments_product`
- `POST /api/set_comments_product`
- `POST /api/like_product`
- `POST /api/report_product`
- `POST /api/get_rates`
- `POST /api/set_rates`

Screens:
- Product comments bottom sheet / section.
- Write comment.
- Report product sheet.
- Rating list.
- Rate seller/product after purchase.

BLoCs:
- `CommentBloc`
- `LikeCubit` or `LikeBloc`
- `ReportProductBloc`
- `RatingBloc`

UI requirements:
- Like animation: scale + color transition.
- Comment composer sticky at bottom in comment view.
- Report sheet with predefined reasons + detail textarea.
- Rating stars animated.

---

### 2.5. Search / Saved Search / News

Endpoints:
- `POST /api/search`
- `POST /api/save_search`
- `POST /api/get_list_saved_search`
- `POST /News/list_news`
- `GET /News/{id}`

Screens:
- Search input page.
- Search result page with filters.
- Saved searches.
- News list.
- News detail.

BLoCs:
- `SearchBloc`
- `SavedSearchBloc`
- `NewsBloc`

UI requirements:
- Search suggestions chips.
- Filter bottom sheet: category, brand, price min/max, condition, sort.
- Save search CTA after query.
- News cards with image, title, summary, date.

---

### 2.6. Messaging / Notifications

Endpoints:
- `POST /conversation/get_list_conversation`
- `POST /conversation/get_conversation`
- `POST /conversation/send_message`
- `POST /conversation/set_read_message`
- `POST /notification/get_notification`
- `POST /notification/set_read_notification`

Screens:
- Conversation list.
- Chat detail.
- Notification center.

BLoCs:
- `ConversationListBloc`
- `ChatBloc`
- `NotificationBloc`

UI requirements:
- Chat bubble modern, product context card pinned at top.
- Optimistic message send.
- Read/unread visual state.
- Notification grouped by type if API supports `group`.

---

### 2.7. Shipping / Address / Order / Checkout

Endpoints:
- `GET /order/get_list_order_address`
- `POST /order/add_order_address`
- `PATCH /order/update/{id}`
- `DELETE /order/delete/{id}`
- `GET /order/get_ship_from`
- `POST /order/get_ship_fee`
- `POST /order/create_order`
- `POST /order/get_list_purchases`
- `POST /order/get_purchase`
- `POST /order/get_order_status`
- `POST /order/get_order_timeline`
- `POST /order/edit_purchase`
- `POST /order/cancel_order`
- `POST /order/seller_mark_as_shipped`
- `POST /order/buyer_confirm_received`
- `POST /order/set_accept_buyer`
- `POST /order/refund_order`

Screens:
- Address list.
- Add/edit address.
- Checkout.
- Order list with tabs: pending / confirmed / shipping / delivered / cancelled / refunded.
- Order detail.
- Order timeline.
- Seller order management.
- Refund request.

BLoCs:
- `AddressBloc`
- `CheckoutBloc`
- `OrderListBloc`
- `OrderDetailBloc`
- `OrderActionBloc`

UI requirements:
- Checkout: address card, product summary, ship fee, total, pay button sticky bottom.
- Order list: tabs + status chips.
- Timeline: vertical stepper with icon and timestamp.
- Cancel/refund actions require confirmation sheet.

---

### 2.8. Wallet / Reward / Upload Media

Endpoints:
- `POST /wallets/get_current_balance`
- `POST /wallets/get_balance_history`
- `POST /upload/file`
- Reward endpoints if present in backend/docs: reward history, reward appeal.

Screens:
- Wallet dashboard.
- Balance history.
- Upload reward video.
- Reward history.
- Reward appeal.

BLoCs:
- `WalletBloc`
- `BalanceHistoryBloc`
- `RewardBloc`
- `MediaUploadBloc`

UI requirements:
- Wallet card with gradient and animated balance count-up.
- History list with income/expense visual distinction.
- Upload progress indicator.
- Appeal form with reason + detail.

---

## 3. FRONTEND ARCHITECTURE

Use feature-first clean-ish architecture:

```txt
lib/
  main.dart
  app.dart
  core/
    config/
      app_config.dart
      env.dart
    constants/
      api_paths.dart
      app_colors.dart
      app_spacing.dart
      app_radius.dart
    network/
      dio_client.dart
      auth_interceptor.dart
      api_exception.dart
      api_response_parser.dart
    router/
      app_router.dart
      route_names.dart
    storage/
      token_storage.dart
    theme/
      app_theme.dart
      app_text_styles.dart
    widgets/
      app_button.dart
      app_text_field.dart
      app_image.dart
      shimmer_box.dart
      empty_state.dart
      error_state.dart
      loading_overlay.dart
      animated_like_button.dart
      product_card.dart
      section_header.dart
  features/
    auth/
      data/
      domain/
      presentation/
        bloc/
        pages/
        widgets/
    home/
    product/
    listing/
    search/
    profile/
    social/
    cart_checkout/
    order/
    address/
    wallet/
    notification/
    chat/
    news/
    upload/
```

Each feature:

```txt
feature_name/
  data/
    models/
    datasources/
    repositories/
  domain/
    entities/
    repositories/
    usecases/
  presentation/
    bloc/
    pages/
    widgets/
```

If project is small, domain layer may be lighter, but keep at least:
- API service / datasource.
- Repository.
- BLoC.
- Page/widgets.

---

## 4. DATA / NETWORK RULES

### 4.1. Dio client

Implement central `DioClient`:
- Base URL from config.
- JSON headers.
- Bearer token injection from `TokenStorage`.
- Timeout config.
- Logging only in debug mode.
- Convert backend errors into typed `ApiException`.

### 4.2. Error mapping

Backend common codes:

| Code | Meaning | Frontend behavior |
|---|---|---|
| 1000 | OK | success |
| 1002 | Parameter is not enough | show validation error |
| 1004 | Parameter value is invalid | show validation error / keep screen |
| 9998 | Token is invalid | clear token, route login |
| 9995 | User is not validated | show account/phone error |
| 9993 | Code verify is incorrect | show OTP error |
| 1013 | User does not exist | silent or snackbar depending context |
| 1009 | Not access | show no-access state |
| 1010 | Action already done | ignore or refresh state |

### 4.3. Repository rule

Widgets must never call Dio directly.

Allowed path:

```txt
Widget → Bloc Event → UseCase/Repository → Datasource/Dio → API
```

---

## 5. UI DESIGN SYSTEM

### 5.1. Visual direction

Name: **Combat Market Modern**

Tone:
- Marketplace energetic like Shopee.
- Cleaner and more premium.
- Slight tactical/mission feeling due to product context.

Primary palette:
- Primary orange/red: `#FF5A1F`
- Deep orange: `#E83A14`
- Dark text: `#111827`
- Muted text: `#6B7280`
- Background: `#F7F8FA`
- Card: `#FFFFFF`
- Success: `#16A34A`
- Warning: `#F59E0B`
- Danger: `#EF4444`

Design tokens:
- Radius small: 8
- Radius medium: 14
- Radius large: 20
- Card elevation: soft shadow, not heavy.
- Default page padding: 16.
- Product grid gap: 10–12.

Typography:
- Use system font unless project already has font.
- Headline: bold, compact.
- Product title: medium, max 2 lines.
- Price: bold, primary color.

### 5.2. Motion requirements

Use motion deliberately:
- Hero image transition from product card → detail.
- Animated search bar shrink/fade on scroll.
- Like button pop animation.
- Add-to-cart / buy button press scale.
- Skeleton shimmer on network loading.
- Fade/slide list item entrance.
- Bottom sheets with rounded top corners and drag handle.

Do not overuse animations that hurt performance.

### 5.3. Core reusable widgets

Implement or reuse:
- `AppScaffold`
- `AppTopBar`
- `GradientHeader`
- `SearchPill`
- `ProductCard`
- `ProductGrid`
- `CategoryBubble`
- `SellerMiniCard`
- `PriceText`
- `RatingStars`
- `StatusChip`
- `AnimatedLikeButton`
- `ShimmerProductGrid`
- `EmptyState`
- `ErrorState`
- `AppBottomSheet`
- `PrimaryButton`
- `SecondaryButton`
- `AppTextField`
- `PasswordField`
- `OtpInput`

---

## 6. TASK GRAPH

```txt
TIP-001: Scan Flutter Codebase
  └── TIP-002: Core Architecture + Dependencies
        ├── TIP-003: Design System + Reusable Widgets
        ├── TIP-004: Network Layer + API Error Handling
        └── TIP-005: Auth Flow
              ├── TIP-006: Home + Catalog + Product List
              │     └── TIP-007: Product Detail + Like/Comment/Report/Rating
              ├── TIP-008: Search + Saved Search + News
              ├── TIP-009: Profile + Follow/Block + Seller Listings
              ├── TIP-010: Address + Shipping + Checkout
              │     └── TIP-011: Orders + Timeline + Order Actions
              ├── TIP-012: Chat + Notifications
              ├── TIP-013: Wallet + Balance History + Reward Upload
              ├── TIP-014: Polish Motion + Loading/Empty/Error States
              └── TIP-015: QA Verify + Completion Report
```

---

## 7. TASK INSTRUCTION PACKS

## TIP-001: Scan Flutter Codebase

### TASK
Scan current project structure before coding.

### MUST REPORT
- Flutter version and Dart SDK.
- `pubspec.yaml` dependencies.
- Current folder structure.
- Existing router/state management.
- Existing API/network layer.
- Existing screens.
- Existing theme/design system.
- Build status.
- Lint/analyzer errors.

### ACCEPTANCE CRITERIA
Given a Flutter project exists, when scan finishes, then report architecture, dependencies, gaps, and risk areas clearly.

---

## TIP-002: Core Architecture + Dependencies

### TASK
Set up project foundation.

### IMPLEMENT
- Feature-first folder structure.
- App router.
- Core config.
- Token storage.
- Central theme.
- Dependency injection pattern suitable for project size.

### REQUIRED PACKAGES
Use existing if already present; otherwise add:
- `flutter_bloc`
- `bloc`
- `equatable`
- `dio`
- `go_router`
- `cached_network_image`
- `shimmer`
- `intl`

### ACCEPTANCE CRITERIA
Given the app starts, when running `flutter analyze`, then no new critical analyzer errors should be introduced.

---

## TIP-003: Design System + Reusable Widgets

### TASK
Build Shopee-inspired modern UI foundation.

### IMPLEMENT
- `AppTheme`
- color/spacing/radius tokens
- buttons
- text fields
- product card
- shimmer states
- empty/error states
- bottom sheet shell
- status chips

### ACCEPTANCE CRITERIA
Given any feature page, when using shared widgets, then UI looks consistent and no screen implements duplicate button/textfield styles.

---

## TIP-004: Network Layer + API Error Handling

### TASK
Implement backend integration foundation.

### IMPLEMENT
- `DioClient`
- auth interceptor
- API paths constants
- typed API exception
- response parser tolerant of inconsistent schemas
- token invalid handler

### ACCEPTANCE CRITERIA
Given an API returns `9998`, when repository receives it, then app clears session and navigates to login.

---

## TIP-005: Auth Flow

### TASK
Implement authentication screens and BLoCs.

### SCREENS
- Splash/session check
- Login
- Signup
- Complete profile
- Forgot password phone
- OTP verify
- Reset password
- Change password

### ACCEPTANCE CRITERIA
- Login with valid phone/password stores token and routes home.
- Invalid phone/password shows error without crashing.
- Forgot password flow preserves phone across steps.
- Password shorter than 6 chars is blocked client-side.

---

## TIP-006: Home + Catalog + Product List

### TASK
Implement marketplace home and product browsing.

### SCREENS
- Home
- Category list
- Brand/category filter
- Product list with infinite scroll

### ACCEPTANCE CRITERIA
- Home loads categories and product feed.
- Product list supports pull-to-refresh.
- Infinite scroll loads next page once near bottom.
- Loading uses shimmer, not blank screen.

---

## TIP-007: Product Detail + Interactions

### TASK
Implement product detail and social interactions.

### SCREENS
- Product detail
- Comment list/sheet
- Report sheet
- Rating list

### ACCEPTANCE CRITERIA
- Product detail shows image gallery, title, price, description, seller, category/brand/variants if available.
- Like toggles optimistically and reconciles with API.
- Comment submit updates visible comments.
- Report shows success/failure feedback.
- Buy/chat buttons remain sticky at bottom.

---

## TIP-008: Search + Saved Search + News

### TASK
Implement search and news.

### ACCEPTANCE CRITERIA
- Search accepts keyword and filter params.
- Saved search can be listed and created.
- News list and detail render API content safely.

---

## TIP-009: Profile + Follow/Block + Seller Listings

### TASK
Implement profile/social pages.

### ACCEPTANCE CRITERIA
- My profile shows private info when available.
- Public profile hides private info.
- Follow/unfollow changes button state.
- Followers/following lists paginate.
- Seller listings load under profile.

---

## TIP-010: Address + Shipping + Checkout

### TASK
Implement address, shipping fee, checkout.

### ACCEPTANCE CRITERIA
- User can list/add/edit/delete address.
- Checkout can select address and calculate/display ship fee.
- Create order sends items, source, address_id.
- Invalid/missing address blocks checkout with clear message.

---

## TIP-011: Orders + Timeline + Order Actions

### TASK
Implement buyer/seller order flows.

### ACCEPTANCE CRITERIA
- Order list has state tabs.
- Order detail displays products, address, total, status.
- Timeline screen shows order history.
- Cancel/confirm/refund/mark shipped actions call correct endpoints and refresh state.

---

## TIP-012: Chat + Notifications

### TASK
Implement notification center and conversations.

### ACCEPTANCE CRITERIA
- Conversation list paginates.
- Chat detail loads messages and sends new messages.
- New message appears optimistically.
- Notifications can be marked read.

---

## TIP-013: Wallet + Balance History + Reward Upload

### TASK
Implement wallet and media upload surfaces.

### ACCEPTANCE CRITERIA
- Wallet shows available and pending balance.
- Balance history paginates.
- Upload file/video shows progress and result.
- Reward/appeal screens are implemented if endpoint exists; otherwise create UI shell marked TODO API.

---

## TIP-014: Polish Motion + Loading/Empty/Error States

### TASK
Upgrade UX quality across app.

### ACCEPTANCE CRITERIA
- Every network page has loading, empty, error, success states.
- Important actions have feedback: snackbar/toast/dialog.
- Scroll performance remains smooth on product grid.
- No placeholder lorem ipsum remains.

---

## TIP-015: QA Verify + Completion Report

### TASK
Run full QA.

### REQUIRED COMMANDS
```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

If a command cannot run due to environment, report honestly.

### VERIFY CHECKLIST
- Auth flow works.
- Home/product list/detail work.
- Search/filter work.
- Profile/follow/block work.
- Checkout/order work.
- Wallet works.
- Chat/notification work.
- Token invalid routes login.
- UI responsive on small Android viewport.
- No hardcoded fake data remains unless explicitly marked mock fallback.

---

## 8. COMPLETION REPORT FORMAT

After each TIP, report:

```markdown
## COMPLETION REPORT — TIP-[XXX]

**STATUS:** DONE / PARTIAL / BLOCKED

**FILES CHANGED:**
- Created: [list + purpose]
- Modified: [list + purpose]

**BLOCs CREATED/UPDATED:**
- [Bloc/Cubit]: [events/states/use]

**API INTEGRATION:**
- [Endpoint]: [integrated/tested/mock/blocked]

**TEST RESULTS:**
- Acceptance criteria: [X/Y passed]
- flutter analyze: PASS/FAIL/NOT RUN
- flutter test: PASS/FAIL/NOT RUN

**ISSUES DISCOVERED:**
- [severity] [description]

**DEVIATIONS FROM SPEC:**
- [what changed] — [why] — [impact]

**SUGGESTIONS FOR CONTRACTOR:**
- [recommendation]
```

---

## 9. IMPORTANT IMPLEMENTATION NOTES

1. API docs sometimes have missing response schemas. Implement model parsing defensively.
2. Product images/videos may be absent; UI must fallback gracefully.
3. Use optimistic updates only for low-risk actions: like, follow, read notification, send message.
4. Do not use fake data as final behavior. Fake data is allowed only as clearly isolated mock fallback during blocked API integration.
5. Keep UI fast: avoid rebuilding full product grid on small state changes.
6. Prefer `BlocSelector` / `buildWhen` for performance-critical widgets.
7. Keep product card lightweight.
8. Use `const` constructors where possible.
9. Always separate screen-level BLoC from reusable widgets.
10. Every BLoC state must include enough info to render loading/success/error/empty.
