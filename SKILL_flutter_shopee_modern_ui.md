---
name: flutter-shopee-modern-ui
version: 1.0
for: Claude Code / Builder coding agent
project_type: Flutter ecommerce marketplace frontend
state_management: BLoC / flutter_bloc
---

# Flutter Shopee Modern UI Skill

Use this skill when implementing or improving the Flutter frontend for the IT4788 ecommerce marketplace product.

The target UI is **Shopee-inspired**, but must be more modern, polished, animated, and premium. The app uses **BLoC** for state management.

---

## 1. ROLE

You are the **UI Builder**.

Your job:
- Implement Flutter screens and reusable UI components.
- Follow the existing app architecture.
- Use `flutter_bloc` / BLoC only for state management.
- Build modern marketplace UX with strong visual polish.
- Integrate with repositories/BLoCs, not directly with Dio inside widgets.

You must not:
- Replace BLoC with Provider, Riverpod, GetX, MobX, or setState-heavy architecture.
- Put API calls inside widgets.
- Hardcode production data.
- Create inconsistent one-off styles.
- Ignore loading/empty/error states.

---

## 2. DESIGN NORTH STAR

Reference: Shopee marketplace.

Upgrade direction:
- Cleaner spacing.
- More premium cards.
- Smooth motion.
- Modern rounded surfaces.
- Better product imagery.
- Strong visual hierarchy.
- Skeleton loading and micro-interactions.

Visual identity: **Combat Market Modern**

Mood:
- Fast marketplace.
- Trustworthy ecommerce.
- Slight tactical/mission vibe.
- Not childish, not cluttered.

---

## 3. DESIGN TOKENS

Use central tokens. Do not duplicate magic values across screens.

### Colors

```dart
class AppColors {
  static const primary = Color(0xFFFF5A1F);
  static const primaryDark = Color(0xFFE83A14);
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
}
```

### Radius

```dart
class AppRadius {
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
}
```

### Spacing

```dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}
```

---

## 4. TYPOGRAPHY RULES

Use app-wide text styles.

- Screen title: bold, 20–24.
- Section title: bold, 16–18.
- Product title: medium, 13–14, max 2 lines.
- Product price: bold, 16–20, primary color.
- Metadata: 11–12, muted color.
- Button text: semibold, 14–16.

Never use tiny unreadable text under 10 unless it is a badge.

---

## 5. UI COMPONENT RULES

Build reusable components first:

- `AppButton`
- `AppTextField`
- `SearchPill`
- `GradientHeader`
- `ProductCard`
- `ProductGrid`
- `CategoryBubble`
- `SellerMiniCard`
- `PriceText`
- `RatingStars`
- `StatusChip`
- `AnimatedLikeButton`
- `AppBottomSheet`
- `ShimmerBox`
- `ShimmerProductGrid`
- `EmptyState`
- `ErrorState`
- `LoadingOverlay`

All feature screens should compose these components instead of inventing new styles.

---

## 6. SCREEN-SPECIFIC UI GUIDELINES

## 6.1. Home Screen

Structure:

```txt
Gradient Header
├── Search pill
├── Notification icon
├── Chat icon
└── Wallet chip

Promo carousel
Category bubbles
Flash / urgent supplies section
Recommended product grid
```

Requirements:
- Header should feel energetic like Shopee but cleaner.
- Search bar should be sticky or visually prominent.
- Product feed must support pull-to-refresh and infinite scroll.
- Loading must use shimmer grid.
- Empty state must suggest changing filters/search.

Motion:
- Header/search opacity or size change on scroll if feasible.
- Product cards fade/slide in.

---

## 6.2. Product Card

Required elements:
- Image 1:1 with rounded top corners.
- Title max 2 lines.
- Price in primary color.
- Rating/sold/like metadata if available.
- Seller/location chip if available.
- Like affordance if screen context allows.

Rules:
- Use `CachedNetworkImage`.
- Provide fallback image placeholder.
- Card must be lightweight for long lists.
- Avoid heavy shadows on every card; use subtle border/shadow.

---

## 6.3. Product Detail

Structure:

```txt
Image/video gallery with Hero
Product title + price
Stats row: like / rating / sold
Variant selector if available
Description
Seller mini card
Shipping info
Comments / ratings preview
Similar products
Sticky bottom action bar: Chat | Like/Cart | Buy Now
```

Requirements:
- Buy/Chat actions always accessible.
- Like animation uses scale/pop.
- Comments can open as bottom sheet.
- Report product opens bottom sheet.
- Long content must scroll smoothly.

---

## 6.4. Auth Screens

Style:
- Clean gradient header.
- Large app name/logo zone.
- Rounded input card.
- Primary CTA button.
- Secondary links: forgot password, signup/login.

Rules:
- Validate password min length 6.
- Show field-level validation.
- Never clear user input on API error unless necessary.

Forgot password flow:
```txt
Phone → OTP → New Password → Success
```

---

## 6.5. Profile / Seller Page

Structure:

```txt
Cover image with parallax/fade
Avatar overlapping cover
Username + status/rating
Stats row
Follow/Edit button
Tabs: Listings | Reviews | About
Product grid/list
```

Rules:
- Public profile hides private fields.
- Follow button must animate between states.
- Use seller/listing card consistency.

---

## 6.6. Search / Filter

Search page:
- Recent searches.
- Saved searches.
- Popular categories.
- Search suggestions if available.

Result page:
- Search term header.
- Filter chips.
- Sort menu.
- Product grid.
- Save search CTA.

Filter bottom sheet:
- Category.
- Brand.
- Price min/max.
- Condition.
- Sort.
- Apply/reset buttons sticky bottom.

---

## 6.7. Checkout

Structure:

```txt
Address card
Product summary card(s)
Shipping fee row
Note field
Total payment card
Sticky pay button
```

Rules:
- Missing address blocks order creation.
- Show fee loading state when recalculating.
- Total must be visually prominent.

---

## 6.8. Orders

Order list:
- Tabs: pending / confirmed / shipping / delivered / cancelled / refunded.
- Order card: status, products, total, action buttons.

Order detail:
- Status header.
- Timeline stepper.
- Address.
- Products.
- Payment summary.
- Contextual actions.

Use status colors consistently.

---

## 6.9. Chat

Structure:
- Product context card pinned at top.
- Message list.
- Composer bottom bar.

Rules:
- Optimistic send.
- Failed send shows retry.
- Read message endpoint should be called when entering conversation.

---

## 6.10. Wallet

Structure:

```txt
Gradient wallet card
├── Available balance
├── Pending balance
└── CTA / history shortcut

Balance history list
Reward upload / appeal entry points
```

Motion:
- Balance count-up animation if simple to implement.
- History item slide/fade.

---

## 7. BLOC UI CONTRACT

Every screen must render these states:

```txt
Initial
Loading
Success/Data
Empty
Failure/Error
Refreshing/LoadingMore where applicable
```

Use:
- `BlocBuilder` for UI render.
- `BlocListener` for one-time effects: snackbar, navigation, dialog.
- `BlocConsumer` only when both are needed.
- `BlocSelector` / `buildWhen` for performance-sensitive subtrees.

Do not trigger API calls repeatedly in `build()`.

Correct pattern:
- Dispatch initial event in `initState` or route entry.
- Dispatch refresh on pull-to-refresh.
- Dispatch load more on scroll threshold.

---

## 8. PAGINATION PATTERN

For list screens:

State should include:
- `items`
- `isInitialLoading`
- `isRefreshing`
- `isLoadingMore`
- `hasReachedEnd`
- `errorMessage`
- `index`
- `count`
- `lastId` if API supports

Rules:
- Deduplicate by id.
- Do not fire multiple load-more requests concurrently.
- Pull-to-refresh resets index and list.
- Show bottom loading indicator for load more.

---

## 9. ERROR / EMPTY / LOADING UX

Loading:
- Product grid: shimmer cards.
- Detail page: shimmer sections.
- Form submit: button loading state or overlay.

Empty:
- Friendly icon/illustration.
- Clear message.
- One helpful CTA.

Error:
- Short human-readable message.
- Retry button when useful.
- Token invalid should route login, not just snackbar.

---

## 10. MICRO-INTERACTIONS

Use lightweight interactions:
- Like button scale pop.
- Button press scale/opacity.
- Bottom sheet slide.
- Product image Hero transition.
- Search chip selection animation.
- Status chip color transition.
- Shimmer skeleton.

Do not add expensive animations inside every product grid cell if it hurts scroll performance.

---

## 11. API-AWARE UI STATES

Common backend codes:

- `1000 OK`: render success.
- `1002 Parameter is not enough`: validation error.
- `1004 Parameter value is invalid`: validation or invalid action.
- `9998 Token is invalid`: clear token and navigate login.
- `9995 User is not validated`: show account/phone issue.
- `9993 Code verify is incorrect`: show OTP error.
- `1013 User does not exist`: show not found or silent depending context.
- `1009 Not access`: show blocked/no access state.
- `1010 Action already done`: refresh current state silently.

UI should not expose raw backend English errors if a better Vietnamese message is obvious.

---

## 12. RESPONSIVE RULES

Target mobile first.

Test widths:
- 360px small Android.
- 390px common phone.
- 430px large phone.
- Tablet if app supports it.

Rules:
- Product grid: usually 2 columns on phone.
- Avoid horizontal overflow.
- Long Vietnamese text must wrap safely.
- Bottom action bars must respect safe area.

---

## 13. PERFORMANCE RULES

- Use `const` constructors where possible.
- Keep product cards stateless and cheap.
- Avoid nesting many `BlocBuilder`s unnecessarily.
- Use `CachedNetworkImage` with placeholders.
- Avoid rebuilding whole page for like count changes; use local Bloc/Cubit or selector.
- Do not put heavy blur effects in long lists.

---

## 14. ACCESSIBILITY / UX QUALITY

- Tap targets at least 44px high.
- Inputs have labels/hints.
- Buttons show disabled/loading states.
- Color is not the only indicator for status.
- Important icons have tooltip/semantic labels where practical.

---

## 15. OUTPUT / REPORT FORMAT

After each UI task, report:

```markdown
## UI COMPLETION REPORT

**STATUS:** DONE / PARTIAL / BLOCKED

**SCREENS IMPLEMENTED:**
- [Screen]: [status]

**WIDGETS CREATED/UPDATED:**
- [Widget]: [purpose]

**BLOC INTEGRATION:**
- [Bloc]: [states/events used]

**API CONNECTION:**
- [Endpoint]: [integrated/mock/blocked]

**UX STATES COVERED:**
- Loading: yes/no
- Empty: yes/no
- Error: yes/no
- Success: yes/no

**MOTION/POLISH ADDED:**
- [animation/effect]

**TEST RESULTS:**
- flutter analyze: PASS/FAIL/NOT RUN
- manual UI check: PASS/FAIL/PARTIAL

**ISSUES / DEVIATIONS:**
- [issue]
```

---

## 16. GOLDEN RULES

1. BLoC only for state management.
2. Widgets do not call API directly.
3. Every screen has loading/empty/error/success.
4. Shopee-inspired, but cleaner and more premium.
5. Reuse design tokens and shared widgets.
6. Make lists performant.
7. Handle token invalid globally.
8. Do not ship placeholder UI as final.
9. Report blockers instead of guessing.
10. Prefer polished small scope over unfinished huge scope.
