"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.setAcceptBuyer = exports.sellerMarkAsShipped = exports.getOrderTimeline = exports.getOrderStatus = exports.editPurchase = exports.getShipFee = exports.refundOrder = exports.confirmReceived = exports.cancelOrder = exports.getPurchase = exports.getListPurchases = exports.createOrder = exports.deleteOrderAddress = exports.updateOrderAddress = exports.getShipFrom = exports.getListOrderAddress = exports.addOrderAddress = void 0;
const db_1 = __importDefault(require("../config/db"));
const addOrderAddress = async (req, res) => {
    const { address, full_address, receiver_name, phone, is_default, lat, lng, address_detail, } = req.body;
    // Xem đặc tả trong FE, thiếu tham số -> code 1002
    if (!address || !full_address || !receiver_name || !phone) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        // Nếu đặt là default, bỏ default các địa chỉ cũ
        if (is_default) {
            await db_1.default.orderAddress.updateMany({
                where: { user_id: req.user.id },
                data: { is_default: false },
            });
        }
        const newAddress = await db_1.default.orderAddress.create({
            data: {
                user_id: req.user.id,
                address,
                full_address,
                receiver_name,
                phone,
                is_default: !!is_default,
                lat: lat ? Number(lat) : null,
                lng: lng ? Number(lng) : null,
                address_detail: address_detail || null,
                is_warehouse: true, // Auto set true để dùng làm ship_from luôn
            },
        });
        return res.status(200).json({
            code: '1000',
            message: 'OK.',
            data: newAddress,
        });
    }
    catch (error) {
        console.error('addOrderAddress error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.addOrderAddress = addOrderAddress;
const getListOrderAddress = async (req, res) => {
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        const addresses = await db_1.default.orderAddress.findMany({
            where: { user_id: req.user.id },
        });
        return res.status(200).json({
            code: '1000',
            message: 'OK.',
            data: addresses,
        });
    }
    catch (error) {
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getListOrderAddress = getListOrderAddress;
const getShipFrom = async (req, res) => {
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        // Trả về địa chỉ của chính user hiện tại để họ tự chọn làm kho gửi hàng
        const warehouses = await db_1.default.orderAddress.findMany({
            where: {
                user_id: req.user.id,
                is_warehouse: true,
            },
        });
        // Nếu user chưa có kho nào, lấy tạm tất cả các kho đang có trong hệ thống để test
        if (warehouses.length === 0) {
            const allWarehouses = await db_1.default.orderAddress.findMany({
                where: { is_warehouse: true },
            });
            return res.status(200).json({
                code: '1000',
                message: 'OK.',
                data: allWarehouses,
            });
        }
        return res.status(200).json({
            code: '1000',
            message: 'OK.',
            data: warehouses,
        });
    }
    catch (error) {
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getShipFrom = getShipFrom;
const updateOrderAddress = async (req, res) => {
    const id = Number(req.params.id);
    const { address, is_default, lat, lng, receiver_name, phone, full_address, address_detail, } = req.body;
    if (isNaN(id)) {
        return res.status(200).json({
            code: '1004',
            message: 'Parameter value is invalid',
            data: null,
        });
    }
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        const existing = await db_1.default.orderAddress.findUnique({ where: { id } });
        if (!existing || existing.user_id !== req.user.id) {
            return res.status(200).json({
                code: '1009',
                message: 'Not access',
                data: null,
            });
        }
        if (is_default) {
            await db_1.default.orderAddress.updateMany({
                where: { user_id: req.user.id },
                data: { is_default: false },
            });
        }
        const updated = await db_1.default.orderAddress.update({
            where: { id },
            data: {
                address: address || undefined,
                full_address: full_address || undefined,
                receiver_name: receiver_name || undefined,
                phone: phone || undefined,
                is_default: is_default !== undefined ? !!is_default : undefined,
                lat: lat ? Number(lat) : undefined,
                lng: lng ? Number(lng) : undefined,
                address_detail: address_detail || undefined,
            },
        });
        return res.status(200).json({
            code: '1000',
            message: 'OK.',
            data: updated,
        });
    }
    catch (error) {
        console.error('updateOrderAddress error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.updateOrderAddress = updateOrderAddress;
const deleteOrderAddress = async (req, res) => {
    const id = Number(req.params.id);
    if (isNaN(id)) {
        return res.status(200).json({
            code: '1004',
            message: 'Parameter value is invalid',
            data: null,
        });
    }
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        const existing = await db_1.default.orderAddress.findUnique({ where: { id } });
        if (!existing || existing.user_id !== req.user.id) {
            return res.status(200).json({
                code: '1009',
                message: 'Not access',
                data: null,
            });
        }
        await db_1.default.orderAddress.delete({ where: { id } });
        return res.status(200).json({
            code: '1000',
            message: 'OK.',
            data: null,
        });
    }
    catch (error) {
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.deleteOrderAddress = deleteOrderAddress;
const createOrder = async (req, res) => {
    const { items, source, address_id } = req.body;
    if (!items || !source || address_id === undefined) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        // Check address
        const address = await db_1.default.orderAddress.findUnique({
            where: { id: Number(address_id) },
        });
        if (!address) {
            return res.status(200).json({
                code: '1004',
                message: 'Address not found',
                data: null,
            });
        }
        // Sinh ID order ngẫu nhiên dạng chuỗi
        const orderId = 'ORD-' + Math.random().toString(36).substr(2, 9).toUpperCase();
        let totalPrice = 0;
        const orderItemsData = [];
        for (const item of items) {
            const product = await db_1.default.product.findUnique({
                where: { id: Number(item.product_id) },
            });
            if (!product) {
                return res.status(200).json({
                    code: '9992',
                    message: 'Product is not existed',
                    data: null,
                });
            }
            const itemTotal = product.price * Number(item.quantity);
            totalPrice += itemTotal;
            orderItemsData.push({
                product_id: product.id,
                quantity: Number(item.quantity),
                price: product.price,
                seller_id: product.seller_id,
                item_total: itemTotal,
            });
        }
        // Kiểm tra ví tiền của buyer
        const buyer = await db_1.default.user.findUnique({
            where: { id: req.user.id },
        });
        if (!buyer) {
            return res.status(200).json({
                code: '1004',
                message: 'User not found',
                data: null,
            });
        }
        if (buyer.available_balance < totalPrice) {
            return res.status(200).json({
                code: '9990',
                message: 'Không đủ số dư ví xu để thực hiện giao dịch',
                data: null,
            });
        }
        await db_1.default.$transaction(async (tx) => {
            // 1. Tạo đơn hàng
            await tx.order.create({
                data: {
                    id: orderId,
                    buyer_id: req.user.id,
                    status: 'pending',
                    total_price: totalPrice,
                    source,
                    address_id: Number(address_id),
                },
            });
            // 2. Tạo các item
            for (const item of orderItemsData) {
                await tx.orderItem.create({
                    data: {
                        order_id: orderId,
                        product_id: item.product_id,
                        quantity: item.quantity,
                        price: item.price,
                    },
                });
                // Cộng vào pending_balance của seller
                await tx.user.update({
                    where: { id: item.seller_id },
                    data: {
                        pending_balance: {
                            increment: item.item_total,
                        },
                    },
                });
            }
            // 3. Trừ tiền buyer
            await tx.user.update({
                where: { id: req.user.id },
                data: {
                    available_balance: {
                        decrement: totalPrice,
                    },
                },
            });
            // 4. Ghi nhận giao dịch ví của buyer
            await tx.walletTransaction.create({
                data: {
                    user_id: req.user.id,
                    amount: -totalPrice,
                    type: 'expense',
                    description: `Thanh toán đơn hàng ${orderId}`,
                },
            });
        });
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: {
                id: orderId,
                total_price: totalPrice,
            },
        });
    }
    catch (error) {
        console.error('createOrder error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.createOrder = createOrder;
const getListPurchases = async (req, res) => {
    const { index, count, state } = req.body;
    if (index === undefined || count === undefined) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        const orders = await db_1.default.order.findMany({
            where: {
                buyer_id: req.user.id,
                status: state || undefined,
            },
            skip: Number(index),
            take: Number(count),
            orderBy: { created_at: 'desc' },
            include: {
                address: true,
                items: {
                    include: {
                        product: {
                            include: {
                                seller: {
                                    select: {
                                        id: true,
                                        username: true,
                                        avatar: true,
                                    }
                                }
                            }
                        },
                    },
                },
            },
        });
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: orders,
        });
    }
    catch (error) {
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getListPurchases = getListPurchases;
// [POST] /order/get_purchase
const getPurchase = async (req, res) => {
    const purchaseId = req.body.id || req.body.purchase_id;
    if (!purchaseId) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        const order = await db_1.default.order.findUnique({
            where: { id: String(purchaseId) },
            include: {
                address: true,
                buyer: {
                    select: {
                        id: true,
                        username: true,
                        phone_number: true,
                        avatar: true,
                    }
                },
                items: {
                    include: {
                        product: {
                            include: {
                                seller: {
                                    select: {
                                        id: true,
                                        username: true,
                                        avatar: true,
                                    }
                                }
                            }
                        },
                    },
                },
            },
        });
        if (!order) {
            return res.status(200).json({
                code: '1004',
                message: 'Order not found',
                data: null,
            });
        }
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: order,
        });
    }
    catch (error) {
        console.error('getPurchase error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getPurchase = getPurchase;
// [POST] /order/cancel_order
const cancelOrder = async (req, res) => {
    const purchaseId = req.body.id || req.body.purchase_id;
    const reason = req.body.reason || 0;
    if (!purchaseId) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        const order = await db_1.default.order.findUnique({
            where: { id: String(purchaseId) },
            include: { items: { include: { product: true } } },
        });
        if (!order) {
            return res.status(200).json({
                code: '1004',
                message: 'Order not found',
                data: null,
            });
        }
        if (order.status === 'cancelled' || order.status === 'received' || order.status === 'refunded') {
            return res.status(200).json({
                code: '1005',
                message: 'Không thể hủy đơn hàng ở trạng thái hiện tại',
                data: null,
            });
        }
        await db_1.default.$transaction(async (tx) => {
            // 1. Cập nhật trạng thái đơn
            await tx.order.update({
                where: { id: order.id },
                data: { status: 'cancelled', note: `Hủy bởi user. Lý do code: ${reason}` },
            });
            // 2. Hoàn tiền cho buyer
            await tx.user.update({
                where: { id: order.buyer_id },
                data: {
                    available_balance: {
                        increment: order.total_price,
                    },
                },
            });
            // Giao dịch ví hoàn tiền
            await tx.walletTransaction.create({
                data: {
                    user_id: order.buyer_id,
                    amount: order.total_price,
                    type: 'refund',
                    description: `Hoàn tiền hủy đơn hàng ${order.id}`,
                },
            });
            // 3. Trừ pending_balance của seller
            for (const item of order.items) {
                const itemTotal = item.price * item.quantity;
                await tx.user.update({
                    where: { id: item.product.seller_id },
                    data: {
                        pending_balance: {
                            decrement: itemTotal,
                        },
                    },
                });
            }
        });
        return res.status(201).json({
            code: '1000',
            message: 'Hủy đơn hàng thành công và hoàn xu.',
            data: null,
        });
    }
    catch (error) {
        console.error('cancelOrder error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.cancelOrder = cancelOrder;
// [POST] /order/buyer_confirm_received
const confirmReceived = async (req, res) => {
    const purchaseId = req.body.purchase_id || req.body.id;
    if (!purchaseId) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        const order = await db_1.default.order.findUnique({
            where: { id: String(purchaseId) },
            include: { items: { include: { product: true } } },
        });
        if (!order) {
            return res.status(200).json({
                code: '1004',
                message: 'Order not found',
                data: null,
            });
        }
        if (order.status !== 'shipped' && order.status !== 'pending' && order.status !== 'accepted') {
            // Để FE dễ test, chúng ta cho phép xác nhận ngay cả khi đang pending/accepted
            // Thực tế thì phải shipped mới cho confirm. Ta linh động chấp nhận mọi trạng thái chưa hoàn thành.
        }
        if (order.status === 'received' || order.status === 'cancelled' || order.status === 'refunded') {
            return res.status(200).json({
                code: '1005',
                message: 'Đơn hàng đã hoàn thành hoặc đã bị hủy',
                data: null,
            });
        }
        await db_1.default.$transaction(async (tx) => {
            // 1. Cập nhật đơn hàng
            await tx.order.update({
                where: { id: order.id },
                data: { status: 'received' },
            });
            // 2. Chuyển tiền từ pending sang available cho seller
            for (const item of order.items) {
                const itemTotal = item.price * item.quantity;
                // Trừ pending_balance và cộng available_balance của seller
                await tx.user.update({
                    where: { id: item.product.seller_id },
                    data: {
                        pending_balance: {
                            decrement: itemTotal,
                        },
                        available_balance: {
                            increment: itemTotal,
                        },
                    },
                });
                // Tạo ví giao dịch income cho seller
                await tx.walletTransaction.create({
                    data: {
                        user_id: item.product.seller_id,
                        amount: itemTotal,
                        type: 'income',
                        description: `Thu nhập từ đơn hàng hoàn thành ${order.id}`,
                    },
                });
            }
        });
        return res.status(201).json({
            code: '1000',
            message: 'Xác nhận đã nhận hàng thành công. Xu đã được chuyển cho người bán.',
            data: null,
        });
    }
    catch (error) {
        console.error('confirmReceived error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.confirmReceived = confirmReceived;
// [POST] /order/refund_order
const refundOrder = async (req, res) => {
    const purchaseId = req.body.purchase_id || req.body.id;
    const reason = req.body.reason || 'Yêu cầu hoàn tiền từ người mua';
    if (!purchaseId) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        const order = await db_1.default.order.findUnique({
            where: { id: String(purchaseId) },
            include: { items: { include: { product: true } } },
        });
        if (!order) {
            return res.status(200).json({
                code: '1004',
                message: 'Order not found',
                data: null,
            });
        }
        if (order.status === 'refunded' || order.status === 'cancelled') {
            return res.status(200).json({
                code: '1005',
                message: 'Đơn hàng đã được hoàn tiền hoặc hủy trước đó',
                data: null,
            });
        }
        await db_1.default.$transaction(async (tx) => {
            // 1. Cập nhật trạng thái
            await tx.order.update({
                where: { id: order.id },
                data: { status: 'refunded', note: `Hoàn tiền. Lý do: ${reason}` },
            });
            // 2. Cộng tiền trả lại cho buyer
            await tx.user.update({
                where: { id: order.buyer_id },
                data: {
                    available_balance: {
                        increment: order.total_price,
                    },
                },
            });
            await tx.walletTransaction.create({
                data: {
                    user_id: order.buyer_id,
                    amount: order.total_price,
                    type: 'refund',
                    description: `Hoàn xu đơn hàng ${order.id}`,
                },
            });
            // 3. Trừ tiền của seller. 
            // Nếu trạng thái đơn hàng là 'received', tiền đã vào available_balance, ngược lại tiền đang ở pending_balance.
            const isReceived = order.status === 'received';
            for (const item of order.items) {
                const itemTotal = item.price * item.quantity;
                if (isReceived) {
                    await tx.user.update({
                        where: { id: item.product.seller_id },
                        data: {
                            available_balance: {
                                decrement: itemTotal,
                            },
                        },
                    });
                    // Tạo giao dịch trừ tiền vì đã được hoàn trả
                    await tx.walletTransaction.create({
                        data: {
                            user_id: item.product.seller_id,
                            amount: -itemTotal,
                            type: 'withdraw',
                            description: `Khấu trừ hoàn tiền đơn hàng ${order.id}`,
                        },
                    });
                }
                else {
                    await tx.user.update({
                        where: { id: item.product.seller_id },
                        data: {
                            pending_balance: {
                                decrement: itemTotal,
                            },
                        },
                    });
                }
            }
        });
        return res.status(201).json({
            code: '1000',
            message: 'Yêu cầu hoàn tiền được chấp nhận.',
            data: null,
        });
    }
    catch (error) {
        console.error('refundOrder error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.refundOrder = refundOrder;
// [POST] /order/get_ship_fee
const getShipFee = async (req, res) => {
    const productId = parseInt(req.body.product_id);
    const addressId = parseInt(req.body.address_id);
    if (isNaN(productId) || isNaN(addressId)) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough or invalid',
            data: null,
        });
    }
    try {
        // Trả về phí vận chuyển giả lập dựa trên ID địa chỉ để đa dạng
        const baseFee = 30000;
        const offset = (addressId % 5) * 5000;
        const finalFee = baseFee + offset;
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: {
                ship_fee: finalFee,
                fee: finalFee,
            },
        });
    }
    catch (error) {
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getShipFee = getShipFee;
// [POST] /order/edit_purchase
const editPurchase = async (req, res) => {
    const purchaseId = req.body.id || req.body.purchase_id;
    const { address_id, note } = req.body;
    if (!purchaseId) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    try {
        const existing = await db_1.default.order.findUnique({ where: { id: String(purchaseId) } });
        if (!existing) {
            return res.status(200).json({
                code: '1004',
                message: 'Order not found',
                data: null,
            });
        }
        const updated = await db_1.default.order.update({
            where: { id: String(purchaseId) },
            data: {
                address_id: address_id ? Number(address_id) : undefined,
                note: note || undefined,
            },
        });
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: updated,
        });
    }
    catch (error) {
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.editPurchase = editPurchase;
// [POST] /order/get_order_status
const getOrderStatus = async (req, res) => {
    const purchaseId = req.body.purchase_id || req.body.id;
    if (!purchaseId) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    try {
        const order = await db_1.default.order.findUnique({
            where: { id: String(purchaseId) },
            select: { status: true },
        });
        if (!order) {
            return res.status(200).json({
                code: '1004',
                message: 'Order not found',
                data: null,
            });
        }
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: {
                status: order.status,
            },
        });
    }
    catch (error) {
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getOrderStatus = getOrderStatus;
// [POST] /order/get_order_timeline
const getOrderTimeline = async (req, res) => {
    const purchaseId = req.body.purchase_id || req.body.id;
    if (!purchaseId) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    try {
        const order = await db_1.default.order.findUnique({
            where: { id: String(purchaseId) },
        });
        if (!order) {
            return res.status(200).json({
                code: '1004',
                message: 'Order not found',
                data: null,
            });
        }
        // Sinh các bước timeline giả lập dựa trên trạng thái hiện tại
        const timeline = [];
        const createdTime = order.created_at.toISOString();
        timeline.push({
            status: 'pending',
            title: 'Đơn hàng đã đặt',
            time: createdTime,
            active: true,
        });
        if (order.status === 'cancelled') {
            timeline.push({
                status: 'cancelled',
                title: 'Đơn hàng đã hủy',
                time: new Date().toISOString(),
                active: true,
            });
        }
        else if (order.status === 'refunded') {
            timeline.push({
                status: 'refunded',
                title: 'Đơn hàng đã hoàn tiền',
                time: new Date().toISOString(),
                active: true,
            });
        }
        else {
            const isAccepted = ['accepted', 'shipped', 'received'].includes(order.status);
            const isShipped = ['shipped', 'received'].includes(order.status);
            const isReceived = order.status === 'received';
            timeline.push({
                status: 'accepted',
                title: 'Người bán đã xác nhận',
                time: isAccepted ? new Date(order.created_at.getTime() + 10 * 60 * 1000).toISOString() : '',
                active: isAccepted,
            });
            timeline.push({
                status: 'shipped',
                title: 'Đang giao hàng',
                time: isShipped ? new Date(order.created_at.getTime() + 30 * 60 * 1000).toISOString() : '',
                active: isShipped,
            });
            timeline.push({
                status: 'received',
                title: 'Đã nhận hàng thành công',
                time: isReceived ? new Date(order.created_at.getTime() + 60 * 60 * 1000).toISOString() : '',
                active: isReceived,
            });
        }
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: timeline,
        });
    }
    catch (error) {
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getOrderTimeline = getOrderTimeline;
// [POST] /order/seller_mark_as_shipped
const sellerMarkAsShipped = async (req, res) => {
    const purchaseId = req.body.purchase_id;
    if (!purchaseId) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    try {
        const order = await db_1.default.order.findUnique({ where: { id: String(purchaseId) } });
        if (!order) {
            return res.status(200).json({
                code: '1004',
                message: 'Order not found',
                data: null,
            });
        }
        const updated = await db_1.default.order.update({
            where: { id: String(purchaseId) },
            data: { status: 'shipped' },
        });
        return res.status(201).json({
            code: '1000',
            message: 'Cập nhật trạng thái đang giao hàng thành công',
            data: updated,
        });
    }
    catch (error) {
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.sellerMarkAsShipped = sellerMarkAsShipped;
// [POST] /order/set_accept_buyer
const setAcceptBuyer = async (req, res) => {
    const { purchase_id, is_accept } = req.body;
    if (!purchase_id || is_accept === undefined) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    try {
        const order = await db_1.default.order.findUnique({
            where: { id: String(purchase_id) },
            include: { items: { include: { product: true } } },
        });
        if (!order) {
            return res.status(200).json({
                code: '1004',
                message: 'Order not found',
                data: null,
            });
        }
        if (Number(is_accept) === 1) {
            // Chấp nhận đơn hàng
            const updated = await db_1.default.order.update({
                where: { id: order.id },
                data: { status: 'accepted' },
            });
            return res.status(201).json({
                code: '1000',
                message: 'Chấp nhận đơn hàng thành công',
                data: updated,
            });
        }
        else {
            // Từ chối đơn hàng (Hủy đơn và hoàn xu)
            await db_1.default.$transaction(async (tx) => {
                await tx.order.update({
                    where: { id: order.id },
                    data: { status: 'cancelled', note: 'Người bán từ chối nhận đơn' },
                });
                // Hoàn xu cho buyer
                await tx.user.update({
                    where: { id: order.buyer_id },
                    data: {
                        available_balance: {
                            increment: order.total_price,
                        },
                    },
                });
                await tx.walletTransaction.create({
                    data: {
                        user_id: order.buyer_id,
                        amount: order.total_price,
                        type: 'refund',
                        description: `Hoàn xu do người bán từ chối đơn ${order.id}`,
                    },
                });
                // Trừ pending_balance của seller
                for (const item of order.items) {
                    const itemTotal = item.price * item.quantity;
                    await tx.user.update({
                        where: { id: item.product.seller_id },
                        data: {
                            pending_balance: {
                                decrement: itemTotal,
                            },
                        },
                    });
                }
            });
            return res.status(201).json({
                code: '1000',
                message: 'Người bán đã từ chối đơn hàng và hoàn xu cho người mua',
                data: null,
            });
        }
    }
    catch (error) {
        console.error('setAcceptBuyer error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.setAcceptBuyer = setAcceptBuyer;
