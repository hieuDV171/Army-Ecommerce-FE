"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("../middlewares/auth");
const multer_1 = require("../config/multer");
// Controllers
const authCtrl = __importStar(require("../controllers/authController"));
const userCtrl = __importStar(require("../controllers/userController"));
const productCtrl = __importStar(require("../controllers/productController"));
const orderCtrl = __importStar(require("../controllers/orderController"));
const uploadCtrl = __importStar(require("../controllers/uploadController"));
const chatCtrl = __importStar(require("../controllers/chatController"));
const walletCtrl = __importStar(require("../controllers/walletController"));
const notifCtrl = __importStar(require("../controllers/notificationController"));
const newsCtrl = __importStar(require("../controllers/newsController"));
const socialCtrl = __importStar(require("../controllers/socialController"));
const router = (0, express_1.Router)();
// ================= AUTH ROUTES =================
router.post('/auth/signup', authCtrl.signup);
router.post('/auth/login', authCtrl.login);
router.post('/auth/logout', auth_1.authenticateToken, authCtrl.logout);
router.post('/auth/change_info_after_signup', auth_1.authenticateToken, authCtrl.changeInfoAfterSignup);
router.post('/auth/change_password', auth_1.authenticateToken, authCtrl.changePassword);
router.post('/auth/create_code_reset_password', authCtrl.createCodeResetPassword);
router.post('/auth/check_code_reset_password', authCtrl.checkCodeResetPassword);
router.post('/auth/reset_password', authCtrl.resetPassword);
router.post('/auth/set_dev_token', auth_1.authenticateToken, authCtrl.setDevToken);
router.post('/auth/get_push_setting', auth_1.authenticateToken, authCtrl.getPushSetting);
router.post('/auth/set_push_setting', auth_1.authenticateToken, authCtrl.setPushSetting);
router.get('/auth/me', auth_1.authenticateToken, authCtrl.getMe);
// ================= USER ROUTES =================
router.post('/users/get_user_info', auth_1.authenticateToken, userCtrl.getUserInfo);
router.post('/users/set_user_info', auth_1.authenticateToken, userCtrl.setUserInfo);
// ================= PRODUCT ROUTES =================
router.post('/api/add_product', auth_1.authenticateToken, productCtrl.addProduct);
router.patch('/api/update/:id', auth_1.authenticateToken, productCtrl.updateProduct);
router.delete('/api/delete/:id', auth_1.authenticateToken, productCtrl.deleteProduct);
router.post('/api/get_categories', productCtrl.getCategories);
router.post('/api/get_list_brands', productCtrl.getListBrands);
router.post('/api/get_list_products', productCtrl.getListProducts);
router.post('/api/get_products', productCtrl.getProducts);
router.post('/api/get_user_listings', productCtrl.getUserListings);
router.post('/api/search_products', productCtrl.searchProducts);
router.post('/api/save_search', auth_1.authenticateToken, productCtrl.saveSearch);
router.post('/api/get_saved_searches', auth_1.authenticateToken, productCtrl.getSavedSearches);
router.post('/api/like_product', auth_1.authenticateToken, productCtrl.likeProduct);
router.post('/api/get_comments', productCtrl.getComments);
router.post('/api/get_comments_product', productCtrl.getComments);
router.post('/api/send_comment', auth_1.authenticateToken, productCtrl.sendComment);
router.post('/api/set_comments_product', auth_1.authenticateToken, productCtrl.sendComment);
router.post('/api/report_product', auth_1.authenticateToken, productCtrl.reportProduct);
router.post('/api/get_rates', productCtrl.getRates);
router.post('/api/set_rates', auth_1.authenticateToken, productCtrl.setRates);
// ================= ORDER / ADDRESS ROUTES =================
router.post('/order/add_order_address', auth_1.authenticateToken, orderCtrl.addOrderAddress);
router.get('/order/get_list_order_address', auth_1.authenticateToken, orderCtrl.getListOrderAddress);
router.get('/order/get_ship_from', auth_1.authenticateToken, orderCtrl.getShipFrom);
router.patch('/order/update/:id', auth_1.authenticateToken, orderCtrl.updateOrderAddress);
router.delete('/order/delete/:id', auth_1.authenticateToken, orderCtrl.deleteOrderAddress);
router.post('/order/create_order', auth_1.authenticateToken, orderCtrl.createOrder);
router.post('/order/get_list_purchases', auth_1.authenticateToken, orderCtrl.getListPurchases);
router.post('/order/get_purchase', auth_1.authenticateToken, orderCtrl.getPurchase);
router.post('/order/cancel_order', auth_1.authenticateToken, orderCtrl.cancelOrder);
router.post('/order/buyer_confirm_received', auth_1.authenticateToken, orderCtrl.confirmReceived);
router.post('/order/refund_order', auth_1.authenticateToken, orderCtrl.refundOrder);
router.post('/order/get_ship_fee', auth_1.authenticateToken, orderCtrl.getShipFee);
router.post('/order/edit_purchase', auth_1.authenticateToken, orderCtrl.editPurchase);
router.post('/order/get_order_status', auth_1.authenticateToken, orderCtrl.getOrderStatus);
router.post('/order/get_order_timeline', auth_1.authenticateToken, orderCtrl.getOrderTimeline);
router.post('/order/seller_mark_as_shipped', auth_1.authenticateToken, orderCtrl.sellerMarkAsShipped);
router.post('/order/set_accept_buyer', auth_1.authenticateToken, orderCtrl.setAcceptBuyer);
// ================= CHAT ROUTES =================
router.post('/conversation/get_list_conversation', auth_1.authenticateToken, chatCtrl.getConversations);
router.post('/conversation/get_conversation', auth_1.authenticateToken, chatCtrl.getConversation);
router.post('/conversation/send_message', auth_1.authenticateToken, chatCtrl.sendMessage);
router.post('/conversation/set_read_message', auth_1.authenticateToken, chatCtrl.markConversationRead);
// ================= NOTIFICATION ROUTES =================
router.post('/notification/get_notification', auth_1.authenticateToken, notifCtrl.getNotifications);
router.post('/notification/set_read_notification', auth_1.authenticateToken, notifCtrl.markNotificationRead);
// ================= WALLET ROUTES =================
router.post('/wallets/get_current_balance', auth_1.authenticateToken, walletCtrl.getCurrentBalance);
router.post('/wallets/get_balance_history', auth_1.authenticateToken, walletCtrl.getBalanceHistory);
// ================= NEWS ROUTES =================
router.post('/News/list_news', newsCtrl.listNews);
router.get('/News/:id', newsCtrl.getNewsDetail);
// ================= SOCIAL ROUTES =================
router.post('/get_list_blocks', auth_1.authenticateToken, socialCtrl.getListBlocks);
router.post('/set_user_block', auth_1.authenticateToken, socialCtrl.setUserBlock);
router.post('/get_list_followed', auth_1.authenticateToken, socialCtrl.getListFollowed);
router.post('/get_list_following', auth_1.authenticateToken, socialCtrl.getListFollowing);
router.post('/set_user_follow', auth_1.authenticateToken, socialCtrl.setUserFollow);
// ================= UPLOAD ROUTE =================
router.post('/upload/file', auth_1.authenticateToken, multer_1.upload.single('file'), uploadCtrl.uploadFile);
// Health check route
router.get('/', (_req, res) => {
    res.send('Army Ecommerce Backend is running successfully!');
});
exports.default = router;
