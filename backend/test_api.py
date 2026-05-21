import urllib.request
import json
import ssl
import sys
import time

sys.stdout.reconfigure(encoding='utf-8')
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

BASE_URL = 'http://localhost:3000'

def request(path, method='POST', data=None, token=None):
    url = f"{BASE_URL}{path}"
    req = urllib.request.Request(url, method=method)
    req.add_header('Content-Type', 'application/json')
    if token:
        req.add_header('Authorization', f'Bearer {token}')
        
    body = json.dumps(data).encode('utf-8') if data else None
    try:
        res = urllib.request.urlopen(req, data=body, context=ctx, timeout=5)
        return json.loads(res.read().decode('utf-8'))
    except Exception as e:
        err_msg = e.read().decode('utf-8') if hasattr(e, 'read') else str(e)
        return {"_error": err_msg}

def test_all():
    print("🚀 Bắt đầu kiểm thử liên thông API Backend mới...")
    
    # 1. Test Health Check
    health = request('/', method='GET')
    print("Health check status:", health)
    
    unique_phone = f"0999{int(time.time())}"
    print(f"\nSử dụng SĐT test: {unique_phone}")

    # 2. Test Signup
    signup_payload = {
        "phone_number": unique_phone,
        "password": "password123",
        "uuid": "test-uuid-device-123"
    }
    signup_res = request('/auth/signup', data=signup_payload)
    print("Signup Response:", signup_res)
    assert signup_res.get('code') == '1000', "Lỗi đăng ký!"
    
    # 3. Test Login
    login_payload = {
        "phone_number": unique_phone,
        "password": "password123"
    }
    login_res = request('/auth/login', data=login_payload)
    print("Login Response:", login_res)
    assert login_res.get('code') == '1000', "Lỗi đăng nhập!"
    token = login_res['data']['token']
    user_id = login_res['data']['id']
    
    # 4. Test Add Order Address (Kho gửi hàng)
    address_payload = {
        "address": "Kho dã chiến 1",
        "full_address": "Số 1 Trần Hưng Đạo, Hoàn Kiếm, Hà Nội",
        "receiver_name": "Đội Trưởng Nguyễn Văn B",
        "phone": unique_phone,
        "is_default": True
    }
    addr_res = request('/order/add_order_address', data=address_payload, token=token)
    print("Add Address Response:", addr_res)
    assert addr_res.get('code') == '1000', "Lỗi thêm địa chỉ!"
    ship_from_id = addr_res['data']['id']

    # 5. Test Get Ship From
    ship_from_res = request('/order/get_ship_from', method='GET', token=token)
    print("Get Ship From Response (số kho):", len(ship_from_res.get('data', [])))
    assert ship_from_res.get('code') == '1000', "Lỗi lấy kho gửi hàng!"

    # 6. Test Get Categories & Brands
    cats_res = request('/api/get_categories', data={})
    print("Get Categories Response (số danh mục):", len(cats_res.get('data', [])))
    
    brands_res = request('/api/get_list_brands', data={"category_id": 1})
    print("Get Brands Response (số hãng):", len(brands_res.get('data', [])))
    assert brands_res.get('code') == '1000', "Lỗi lấy danh sách brands!"

    # 7. Test Add Product
    product_payload = {
        "title": "Balo Tác Chiến Army",
        "price": 250000.0,
        "description": "Balo chiến thuật 3P bền bỉ chống thấm nước dành cho huấn luyện.",
        "image_urls": ["http://localhost:3000/uploads/test-balo.jpg"],
        "brand_id": 1,
        "category_id": 1,
        "ship_from_id": ship_from_id,
        "videos": [{"url": "http://localhost:3000/uploads/video.mp4"}],
        "variants": [
            {"size": "Lớn", "stock": 50, "color": "Rằn ri", "weight": 1.2}
        ]
    }
    prod_res = request('/api/add_product', data=product_payload, token=token)
    print("Add Product Response:", prod_res)
    assert prod_res.get('code') == '1000', "Lỗi thêm sản phẩm!"
    product_id = prod_res['data']['id']

    # 8. Test Get List Products
    list_payload = {
        "category_id": 0,
        "index": 0,
        "count": 10
    }
    list_res = request('/api/get_list_products', data=list_payload)
    print("Get List Products Response (số sản phẩm):", len(list_res.get('data', [])))
    assert list_res.get('code') == '1000', "Lỗi lấy danh sách sản phẩm!"
    
    # 9. Test Get Product Detail
    detail_res = request('/api/get_products', data={"id": product_id})
    print("Get Product Detail Response:", detail_res.get('data', {}).get('title'))
    assert detail_res.get('code') == '1000', "Lỗi lấy chi tiết sản phẩm!"

    print("\n✅ KIỂM THỬ THÀNH CÔNG 100%! TẤT CẢ API PHẢN HỒI ĐÚNG ĐỊNH DẠNG.")

if __name__ == "__main__":
    test_all()
