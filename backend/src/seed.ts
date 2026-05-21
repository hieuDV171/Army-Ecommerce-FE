import prisma from './config/db';
import bcrypt from 'bcryptjs';

async function main() {
  console.log('🌱 Bắt đầu seed dữ liệu mẫu cho Army Ecommerce...');

  // 1. Hash mật khẩu chung
  const hashedPassword = await bcrypt.hash('password123', 10);

  // 2. Tạo hoặc Cập nhật User
  console.log('👤 Tạo tài khoản người dùng mẫu...');
  const seller = await prisma.user.upsert({
    where: { phone_number: '0988888888' },
    update: {
      username: 'Quân Nhu Store',
      firstname: 'Quân Nhu',
      lastname: 'Cửa hàng',
      avatar: 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=150',
      available_balance: 5000000.0,
      pending_balance: 0.0,
      role: 'soldier',
    },
    create: {
      phone_number: '0988888888',
      password: hashedPassword,
      username: 'Quân Nhu Store',
      firstname: 'Quân Nhu',
      lastname: 'Cửa hàng',
      avatar: 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=150',
      available_balance: 5000000.0,
      pending_balance: 0.0,
      role: 'soldier',
    },
  });

  const buyer = await prisma.user.upsert({
    where: { phone_number: '0977777777' },
    update: {
      username: 'Nguyễn Văn Chiến',
      firstname: 'Chiến',
      lastname: 'Nguyễn Văn',
      avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      available_balance: 10000000.0, // Cho hẳn 10 triệu xu để test mua sắm
      pending_balance: 0.0,
      role: 'soldier',
    },
    create: {
      phone_number: '0977777777',
      password: hashedPassword,
      username: 'Nguyễn Văn Chiến',
      firstname: 'Chiến',
      lastname: 'Nguyễn Văn',
      avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      available_balance: 10000000.0,
      pending_balance: 0.0,
      role: 'soldier',
    },
  });
  console.log(`✅ Đã tạo/cập nhật user: Seller ID: ${seller.id}, Buyer ID: ${buyer.id}`);

  // 3. Tạo địa chỉ kho gửi hàng cho Seller và địa chỉ nhận cho Buyer
  console.log('📍 Thiết lập địa chỉ nhận hàng và kho...');
  const sellerAddress = await prisma.orderAddress.create({
    data: {
      user_id: seller.id,
      receiver_name: 'Tổng Kho Quân Nhu V20',
      phone: '0988888888',
      address: '20 đường Cộng Hòa, P. 12',
      full_address: '20 đường Cộng Hòa, P. 12, Q. Tân Bình, TP. Hồ Chí Minh',
      is_default: true,
      is_warehouse: true,
    },
  });

  await prisma.orderAddress.create({
    data: {
      user_id: buyer.id,
      receiver_name: 'Nguyễn Văn Chiến',
      phone: '0977777777',
      address: '123 Hoàng Hoa Thám, P. 7',
      full_address: '123 Hoàng Hoa Thám, P. 7, Q. Phú Nhuận, TP. Hồ Chí Minh',
      is_default: true,
      is_warehouse: false,
    },
  });
  console.log('✅ Đã tạo địa chỉ kho và địa chỉ giao nhận.');

  // 4. Seed Categories
  console.log('📂 Khởi tạo danh mục sản phẩm...');
  const categories = [
    { id: 1, name: 'Quân trang dã chiến', parent_id: 0 },
    { id: 2, name: 'Thiết bị chiến thuật', parent_id: 0 },
    { id: 3, name: 'Dụng cụ sinh tồn', parent_id: 0 },
    { id: 4, name: 'Phụ kiện quân đội', parent_id: 0 },
  ];

  for (const c of categories) {
    await prisma.category.upsert({
      where: { id: c.id },
      update: { name: c.name, parent_id: c.parent_id },
      create: c,
    });
  }
  console.log(`✅ Đã seed ${categories.length} Categories.`);

  // 5. Seed Brands
  console.log('🏷️ Khởi tạo thương hiệu...');
  const brands = [
    { id: 1, name: 'Công ty Cổ phần 20 (Bộ Quốc Phòng)', category_id: 1 },
    { id: 2, name: 'Công ty 26 (Bộ Quốc Phòng)', category_id: 1 },
    { id: 3, name: 'TacGear Vietnam', category_id: 2 },
    { id: 4, name: 'Condor Outdoor', category_id: 2 },
    { id: 5, name: 'Victorinox Survival', category_id: 3 },
    { id: 6, name: 'Gerber Gear', category_id: 3 },
    { id: 7, name: 'Military Spec', category_id: 4 },
  ];

  for (const b of brands) {
    await prisma.brand.upsert({
      where: { id: b.id },
      update: { name: b.name, category_id: b.category_id },
      create: b,
    });
  }
  console.log(`✅ Đã seed ${brands.length} Brands.`);

  // 6. Tạo 10 sản phẩm quân sự Tactical chất lượng cao
  console.log('📦 Đang tạo 10 sản phẩm mẫu quân nhu chất lượng cao...');
  const productsData = [
    {
      title: 'Áo khoác dã chiến M65 Tactical',
      price: 650000,
      description: 'Áo khoác dã chiến kiểu dáng M65 chuẩn quân sự, chất liệu vải Kaki bền bỉ, cản gió giữ ấm cực tốt, có nón giấu cổ và nhiều túi chiến thuật tiện lợi.',
      brand_id: 1,
      category_id: 1,
      image_urls: JSON.stringify([
        'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600',
        'https://images.unsplash.com/photo-1544022613-e87ca75a784a?w=600'
      ]),
      variants: [
        { size: 'M', color: 'Rằn ri', stock: 50, weight: 0.8 },
        { size: 'L', color: 'Rằn ri', stock: 40, weight: 0.85 },
        { size: 'XL', color: 'Xanh O-liu', stock: 30, weight: 0.9 },
      ]
    },
    {
      title: 'Balo chiến thuật 3P Assault Pack 30L',
      price: 450000,
      description: 'Balo sinh tồn dã ngoại dung tích 30 lít, hệ thống đai Molle chuẩn quân đội, chất liệu vải Nylon Oxford 600D chống nước nhẹ, siêu bền.',
      brand_id: 3,
      category_id: 2,
      image_urls: JSON.stringify([
        'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600',
        'https://images.unsplash.com/photo-1622560480605-d83c853bc5c3?w=600'
      ]),
      variants: [
        { size: '30L', color: 'Đen nhám', stock: 100, weight: 1.1 },
        { size: '30L', color: 'Vàng Cát Coyote', stock: 80, weight: 1.1 },
        { size: '30L', color: 'Rằn ri CP', stock: 90, weight: 1.1 },
      ]
    },
    {
      title: 'Găng tay cơ động cụt ngón 5.11 Tactical',
      price: 120000,
      description: 'Găng tay chiến thuật bảo vệ khớp tay bằng cao su non đúc, tăng độ bám chống trơn trượt, thích hợp cho leo núi, đi xe máy dã ngoại.',
      brand_id: 7,
      category_id: 4,
      image_urls: JSON.stringify([
        'https://images.unsplash.com/photo-1504805572947-34fad45aed93?w=600'
      ]),
      variants: [
        { size: 'L', color: 'Đen', stock: 150, weight: 0.15 },
        { size: 'XL', color: 'Xanh lính', stock: 120, weight: 0.16 },
      ]
    },
    {
      title: 'Mũ bảo hiểm Fast Helmet chiến thuật',
      price: 380000,
      description: 'Mũ bảo hiểm Fast Helmet chuyên dụng có ray gắn thiết bị nhìn đêm (NVG Mount) và camera hành trình, lớp lót xốp giảm chấn cực êm.',
      brand_id: 4,
      category_id: 2,
      image_urls: JSON.stringify([
        'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600'
      ]),
      variants: [
        { size: 'Free Size', color: 'Xám Carbon', stock: 60, weight: 0.65 },
        { size: 'Free Size', color: 'Vàng Cát', stock: 45, weight: 0.65 },
      ]
    },
    {
      title: 'Giày bốt hành quân Delta Cổ cao',
      price: 580000,
      description: 'Giày bốt đặc nhiệm Delta, thiết kế dây kéo bên hông tháo mở nhanh, đế cao su chống đinh chống trượt vượt địa hình lầy lội cực tốt.',
      brand_id: 4,
      category_id: 1,
      image_urls: JSON.stringify([
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600'
      ]),
      variants: [
        { size: '41', color: 'Vàng Cát', stock: 35, weight: 1.2 },
        { size: '42', color: 'Vàng Cát', stock: 40, weight: 1.25 },
        { size: '43', color: 'Đen', stock: 25, weight: 1.3 },
      ]
    },
    {
      title: 'Bộ dụng cụ sinh tồn 12 món đa năng',
      price: 250000,
      description: 'Bộ công cụ nhỏ gọn xếp trong hộp nhựa chống nước gồm đá lửa, cưa dây, la bàn, dao đa năng, đèn pin mini, thẻ sinh tồn... không thể thiếu cho dã ngoại.',
      brand_id: 5,
      category_id: 3,
      image_urls: JSON.stringify([
        'https://images.unsplash.com/photo-1594494811566-7f9bcd26c84c?w=600'
      ]),
      variants: [
        { size: 'Tiêu chuẩn', color: 'Đen đỏ', stock: 120, weight: 0.4 },
      ]
    },
    {
      title: 'Kính mát phi công AO chính hãng Spec',
      price: 320000,
      description: 'Kính phi công American Optical huyền thoại, gọng mạ vàng tĩnh điện sáng bóng, mắt kính thủy tinh chống tia UV400 bảo vệ mắt tuyệt đối.',
      brand_id: 7,
      category_id: 4,
      image_urls: JSON.stringify([
        'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=600'
      ]),
      variants: [
        { size: '52mm', color: 'Gọng Vàng - Tròng Xanh Đen', stock: 50, weight: 0.1 },
        { size: '54mm', color: 'Gọng Bạc - Tròng Đen', stock: 35, weight: 0.1 },
      ]
    },
    {
      title: 'Võng mùng dù sinh tồn cắm trại',
      price: 180000,
      description: 'Võng vải dù 2 lớp siêu chịu lực tích hợp mùng chống muỗi chống côn trùng, thiết kế khóa kéo kín kẽ, kèm dây đai buộc gốc cây chắc chắn.',
      brand_id: 6,
      category_id: 3,
      image_urls: JSON.stringify([
        'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=600'
      ]),
      variants: [
        { size: '260x140cm', color: 'Xanh lục đậm', stock: 80, weight: 0.7 },
      ]
    },
    {
      title: 'Đèn pin siêu sáng XML-T6 Zoom xa 500m',
      price: 150000,
      description: 'Đèn pin cầm tay hợp kim nhôm siêu bền chống nước, bóng led Cree T6 độ sáng 1000 Lumens, pin sạc Lithium 18650, có 5 chế độ chiếu sáng bao gồm SOS.',
      brand_id: 6,
      category_id: 3,
      image_urls: JSON.stringify([
        'https://images.unsplash.com/photo-1517524006129-47024cbd6a13?w=600'
      ]),
      variants: [
        { size: 'Tiêu chuẩn', color: 'Đen bóng', stock: 200, weight: 0.25 },
      ]
    },
    {
      title: 'Bình nước nhôm quân nhu kèm bi đông nhôm',
      price: 195000,
      description: 'Bi đông đựng nước dã ngoại kèm ca nấu bằng nhôm chuyên dụng quân đội, bao đựng vải dù rằn ri có móc đeo đai chiến thuật.',
      brand_id: 2,
      category_id: 4,
      image_urls: JSON.stringify([
        'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=600'
      ]),
      variants: [
        { size: '1L', color: 'Vải bao rằn ri K07', stock: 90, weight: 0.35 },
      ]
    }
  ];

  for (const item of productsData) {
    const product = await prisma.product.create({
      data: {
        title: item.title,
        price: item.price,
        description: item.description,
        brand_id: item.brand_id,
        category_id: item.category_id,
        ship_from_id: sellerAddress.id,
        seller_id: seller.id,
        image_urls: item.image_urls,
        status: 'new',
      },
    });

    // Thêm các variant
    for (const v of item.variants) {
      await prisma.productVariant.create({
        data: {
          product_id: product.id,
          size: v.size,
          stock: v.stock,
          color: v.color,
          weight: v.weight,
        },
      });
    }

    // Thêm 1 video mock cho sản phẩm
    await prisma.productVideo.create({
      data: {
        product_id: product.id,
        url: 'https://www.w3schools.com/html/mov_bbb.mp4',
      },
    });
  }
  console.log('✅ Đã hoàn thành nạp 10 sản phẩm Tactical cùng các biến thể.');

  // 7. Seed Tin Tức (News)
  console.log('📰 Khởi tạo tin tức mẫu quân sự...');
  const newsList = [
    {
      title: 'Giới thiệu trang phục dã chiến K24 mới',
      content: 'Bộ Quốc phòng vừa phê duyệt mẫu quân phục dã chiến K24 thế hệ mới với hoa văn ngụy trang tối ưu hóa địa hình Việt Nam. Chất vải thoáng khí, chống mài mòn cao giúp người lính linh hoạt trong các điều kiện chiến đấu dã ngoại.',
      image_url: 'https://images.unsplash.com/photo-1590247813693-5541f1c609fd?w=600',
    },
    {
      title: 'Bí quyết chọn balo sinh tồn khi hành quân xa',
      content: 'Một chiếc balo tốt phải phân bổ đều trọng lượng lên cơ thể qua đai hông và đai ngực. Dưới đây là 5 nguyên tắc sắp xếp đồ dùng chiến thuật giúp tối ưu hóa không gian balo khi tham gia huấn luyện thực địa dài ngày.',
      image_url: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600',
    },
    {
      title: 'Thông tin diễn tập thực binh phòng thủ năm 2026',
      content: 'Các đơn vị chủ lực phối hợp lực lượng vũ trang địa phương vừa hoàn thành xuất sắc cuộc diễn tập hiệp đồng tác chiến phòng thủ khu vực năm 2026, khẳng định năng lực sẵn sàng chiến đấu và trang bị kỹ thuật hiện đại.',
      image_url: 'https://images.unsplash.com/photo-1579621970795-87facc2f976d?w=600',
    }
  ];

  for (const n of newsList) {
    await prisma.news.create({ data: n });
  }
  console.log('✅ Đã seed tin tức.');

  // 8. Tạo một số Notification ban đầu cho Buyer
  console.log('🔔 Tạo thông báo mẫu...');
  const notifications = [
    {
      user_id: buyer.id,
      title: 'Chào mừng chiến hữu!',
      content: 'Chào mừng đồng chí đến với Army Ecommerce. Hệ thống đã tặng đồng chí 10.000.000 xu để tự do đặt mua quân trang!',
      type: 'announce',
      group: 1,
    },
    {
      user_id: buyer.id,
      title: 'Nhắc nhở bảo mật',
      content: 'Hãy bảo quản mật khẩu tài khoản và không chia sẻ mã xác minh OTP cho bất kỳ ai để đảm bảo an toàn giao dịch.',
      type: 'announce',
      group: 1,
    }
  ];

  for (const notif of notifications) {
    await prisma.notification.create({ data: notif });
  }
  console.log('✅ Đã seed thông báo.');

  // 9. Tạo WalletTransaction ban đầu
  console.log('💳 Ghi nhận lịch sử giao dịch ví...');
  await prisma.walletTransaction.create({
    data: {
      user_id: buyer.id,
      amount: 10000000.0,
      type: 'reward',
      description: 'Quà tặng tân binh từ hệ thống Army Ecommerce',
    },
  });

  await prisma.walletTransaction.create({
    data: {
      user_id: seller.id,
      amount: 5000000.0,
      type: 'reward',
      description: 'Vốn hỗ trợ khởi tạo gian hàng quân nhu',
    },
  });
  console.log('✅ Đã tạo lịch sử giao dịch ví.');

  console.log('🌱 Hoàn thành seed toàn bộ dữ liệu mẫu một cách tốt đẹp!');
}

main()
  .catch((e) => {
    console.error('❌ Lỗi seed dữ liệu:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
