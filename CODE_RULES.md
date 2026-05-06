# 📋 QUY TẮC CODE - Army eCommerce Team

Tài liệu này quy định các quy tắc code mà tất cả các thành viên trong team phải tuân theo.

---

## 1. 📝 NGÔN NGỮ COMMENT VÀ THÔNG BÁO

### 1.1 Tất cả comment phải là Tiếng Việt

```dart
// ✅ ĐÚNG
// Kiểm tra xem người dùng có đăng nhập hay không
bool isLoggedIn = await checkUserLogin();

// ❌ SAI
// Check if user is logged in
bool isLoggedIn = await checkUserLogin();
```

### 1.2 Tất cả thông báo, log, snackbar, dialog đều phải là Tiếng Việt

```dart
// ✅ ĐÚNG
print('Tải dữ liệu thành công');
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Đăng nhập thành công')),
);

// ❌ SAI
print('Loading data successfully');
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Login successful')),
);
```

### 1.3 Đặt comment trước hoặc trên dòng code

```dart
// ✅ ĐÚNG - Comment trước logic
// Lọc danh sách sản phẩm theo giá
List<Product> filteredProducts = products.where((p) => p.price > minPrice).toList();

// ✅ ĐÚNG - Comment inline cho biến
bool isActive = user.status == 'active'; // Kiểm tra trạng thái kích hoạt
```

---

## 2. 🔍 QUY TẮC COMMENT CODE

### 2.1 Mỗi hàm phải có comment giải thích

```dart
// Tính tổng giá trị đơn hàng bao gồm thuế
// Tham số: orderId - ID của đơn hàng
// Trả về: Tổng giá trị đơn hàng (double)
double calculateOrderTotal(String orderId) {
  // Lấy thông tin đơn hàng từ database
  Order order = getOrder(orderId);
  
  // Tính tổng tiền hàng
  double subtotal = order.items.fold(0, (sum, item) => sum + item.total);
  
  // Tính tiền thuế (VAT 10%)
  double tax = subtotal * 0.1;
  
  // Trả về tổng cộng
  return subtotal + tax;
}
```

### 2.2 Comment cho logic phức tạp

```dart
// Xác thực token JWT từ Firebase
// Kiểm tra signature, expiration time, và user permissions
Future<bool> validateToken(String token) {
  try {
    // Decode token và kiểm tra chữ ký
    final decodedToken = decodeJWT(token);
    
    // Kiểm tra hạn sử dụng (exp)
    if (DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000)
        .isBefore(DateTime.now())) {
      return false; // Token đã hết hạn
    }
    
    return true;
  } catch (e) {
    // Log lỗi giải mã token
    print('Lỗi xác thực token: $e');
    return false;
  }
}
```

### 2.3 Comment cho Widget UI

```dart
// Widget hiển thị danh sách sản phẩm
// - Hỗ trợ cuộn vô hạn (infinite scroll)
// - Hỗ trợ lọc theo danh mục
// - Hỗ trợ sắp xếp theo giá
class ProductListWidget extends StatefulWidget {
  @override
  State<ProductListWidget> createState() => _ProductListWidgetState();
}

class _ProductListWidgetState extends State<ProductListWidget> {
  // TODO: Thêm pull-to-refresh functionality
  // TODO: Cache dữ liệu sản phẩm cục bộ
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        // Render từng sản phẩm
        return ProductCard(product: products[index]);
      },
    );
  }
}
```

---

## 3. 🎯 CODING CONVENTIONS (Quy tắc viết code)

### 3.1 Đặt tên biến, hàm, class

```dart
// ✅ ĐÚNG - CamelCase cho biến và hàm
String userName = 'Nguyễn Văn A';
Future<void> fetchUserData() { }
class ProductDataProvider { }

// ❌ SAI
String user_name = 'Nguyễn Văn A';
String UserName = 'Nguyễn Văn A';
Future<void> fetch_user_data() { }
class productDataProvider { }
```

### 3.2 Tên các biến phải meaningful, rõ ràng

```dart
// ✅ ĐÚNG
int totalProductsInCart = 5;
bool isUserPremium = true;
List<String> selectedCategoryIds = [];

// ❌ SAI
int total = 5;
bool isPremium = true;
List<String> ids = [];
```

### 3.3 Sử dụng const và final

```dart
// ✅ ĐÚNG - Dùng const cho hằng số
const String API_BASE_URL = 'https://api.example.com';
final DateTime createdDateTime = DateTime.now();

// ❌ SAI
var API_BASE_URL = 'https://api.example.com';
var createdDateTime = DateTime.now();
```

### 3.4 Cấu trúc file Dart

```dart
// 1. Imports (import package trước, rồi đến relative imports)
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'models/product.dart';
import 'repositories/product_repository.dart';

// 2. Constants
const String PRODUCTS_TABLE = 'products';
const Duration CACHE_DURATION = Duration(minutes: 15);

// 3. Class/Widget
class ProductPage extends StatefulWidget {
  final String productId;
  
  const ProductPage({required this.productId});
  
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  // 4. Variables
  late ProductRepository repository;
  
  // 5. Life cycle methods
  @override
  void initState() {
    super.initState();
    // Khởi tạo dữ liệu
  }
  
  // 6. Methods
  void loadProduct() {
    // Logic tải dữ liệu
  }
  
  // 7. Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
```

### 3.5 Indentation - Thụt lề

```dart
// ✅ ĐÚNG - 2 space hoặc 1 tab
class Product {
  String name;
  
  void printDetails() {
    print('Sản phẩm: $name');
  }
}

// ❌ SAI - Thụt lề không đều
class Product{
    String name;
void printDetails(){
print('Sản phẩm: $name');
}
}
```

### 3.6 Dòng code không quá 100 ký tự

```dart
// ✅ ĐÚNG
Future<List<Product>> fetchProductsByCategory(
  String categoryId,
  {int limit = 20}
) {
  return repository.getProducts(categoryId, limit: limit);
}

// ❌ SAI
Future<List<Product>> fetchProductsByCategory(String categoryId, {int limit = 20}) { return repository.getProducts(categoryId, limit: limit); }
```

### 3.7 Null safety

```dart
// ✅ ĐÚNG - Xử lý null an toàn
String? userName;
if (userName != null) {
  print('Tên: $userName');
}

// ✅ ĐÚNG - Sử dụng null coalescing
String displayName = userName ?? 'Khách hàng ẩn danh';

// ❌ SAI - Không xử lý null
String userName;
print('Tên: $userName'); // Có thể crash
```

---

**Cập nhật lần cuối: May 6, 2026**
**Người tạo: Team Lead**

---
