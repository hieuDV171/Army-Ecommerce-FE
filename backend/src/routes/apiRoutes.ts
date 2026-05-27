import { Router } from 'express';
import { authenticateToken } from '../middlewares/auth';
import { upload } from '../config/multer';

// Controllers
import * as authCtrl from '../controllers/authController';
import * as userCtrl from '../controllers/userController';
import * as productCtrl from '../controllers/productController';
import * as orderCtrl from '../controllers/orderController';
import * as uploadCtrl from '../controllers/uploadController';
import * as chatCtrl from '../controllers/chatController';
import * as walletCtrl from '../controllers/walletController';
import * as notifCtrl from '../controllers/notificationController';
import * as newsCtrl from '../controllers/newsController';
import * as socialCtrl from '../controllers/socialController';

const router = Router();

// ================= AUTH ROUTES =================
router.post('/auth/signup', authCtrl.signup);
router.post('/auth/login', authCtrl.login);
router.post('/auth/logout', authenticateToken, authCtrl.logout);
router.post('/auth/change_info_after_signup', authenticateToken, authCtrl.changeInfoAfterSignup);
router.post('/auth/change_password', authenticateToken, authCtrl.changePassword);
router.post('/auth/create_code_reset_password', authCtrl.createCodeResetPassword);
router.post('/auth/check_code_reset_password', authCtrl.checkCodeResetPassword);
router.post('/auth/reset_password', authCtrl.resetPassword);
router.post('/auth/set_dev_token', authenticateToken, authCtrl.setDevToken);
router.post('/auth/get_push_setting', authenticateToken, authCtrl.getPushSetting);
router.post('/push_settings/get_push_setting', authenticateToken, authCtrl.getPushSetting);
router.post('/auth/set_push_setting', authenticateToken, authCtrl.setPushSetting);
router.post('/push_settings/set_push_setting', authenticateToken, authCtrl.setPushSetting);
router.get('/auth/me', authenticateToken, authCtrl.getMe);

// ================= USER ROUTES =================
router.post('/users/get_user_info', authenticateToken, userCtrl.getUserInfo);
router.post('/users/set_user_info', authenticateToken, userCtrl.setUserInfo);

// ================= PRODUCT ROUTES =================
router.post('/api/add_product', authenticateToken, productCtrl.addProduct);
router.patch('/api/update/:id', authenticateToken, productCtrl.updateProduct);
router.delete('/api/delete/:id', authenticateToken, productCtrl.deleteProduct);
router.post('/api/get_categories', productCtrl.getCategories);
router.post('/api/get_list_brands', productCtrl.getListBrands);
router.post('/api/get_list_products', productCtrl.getListProducts);
router.post('/api/get_products', productCtrl.getProducts);
router.post('/api/get_user_listings', productCtrl.getUserListings);
router.post('/api/search_products', productCtrl.searchProducts);
router.post('/api/save_search', authenticateToken, productCtrl.saveSearch);
router.post('/api/get_saved_searches', authenticateToken, productCtrl.getSavedSearches);
router.post('/api/like_product', authenticateToken, productCtrl.likeProduct);
router.post('/api/get_comments', productCtrl.getComments);
router.post('/api/get_comments_product', productCtrl.getComments);
router.post('/api/send_comment', authenticateToken, productCtrl.sendComment);
router.post('/api/set_comments_product', authenticateToken, productCtrl.sendComment);
router.post('/api/report_product', authenticateToken, productCtrl.reportProduct);
router.post('/api/get_rates', productCtrl.getRates);
router.post('/api/set_rates', authenticateToken, productCtrl.setRates);

// ================= ORDER / ADDRESS ROUTES =================
router.post('/order/add_order_address', authenticateToken, orderCtrl.addOrderAddress);
router.get('/order/get_list_order_address', authenticateToken, orderCtrl.getListOrderAddress);
router.post('/order/get_list_order_address', authenticateToken, orderCtrl.getListOrderAddress);
router.get('/order/get_ship_from', authenticateToken, orderCtrl.getShipFrom);
router.patch('/order/update/:id', authenticateToken, orderCtrl.updateOrderAddress);
router.delete('/order/delete/:id', authenticateToken, orderCtrl.deleteOrderAddress);
router.post('/order/create_order', authenticateToken, orderCtrl.createOrder);
router.post('/order/get_list_purchases', authenticateToken, orderCtrl.getListPurchases);
router.post('/order/get_purchase', authenticateToken, orderCtrl.getPurchase);
router.post('/order/cancel_order', authenticateToken, orderCtrl.cancelOrder);
router.post('/order/buyer_confirm_received', authenticateToken, orderCtrl.confirmReceived);
router.post('/order/refund_order', authenticateToken, orderCtrl.refundOrder);
router.post('/order/get_ship_fee', authenticateToken, orderCtrl.getShipFee);
router.post('/order/edit_purchase', authenticateToken, orderCtrl.editPurchase);
router.post('/order/get_order_status', authenticateToken, orderCtrl.getOrderStatus);
router.post('/order/get_order_timeline', authenticateToken, orderCtrl.getOrderTimeline);
router.post('/order/seller_mark_as_shipped', authenticateToken, orderCtrl.sellerMarkAsShipped);
router.post('/order/set_accept_buyer', authenticateToken, orderCtrl.setAcceptBuyer);

// ================= CHAT ROUTES =================
router.post('/conversation/get_list_conversation', authenticateToken, chatCtrl.getConversations);
router.post('/conversation/get_conversation', authenticateToken, chatCtrl.getConversation);
router.post('/conversation/send_message', authenticateToken, chatCtrl.sendMessage);
router.post('/conversation/set_read_message', authenticateToken, chatCtrl.markConversationRead);

// ================= NOTIFICATION ROUTES =================
router.post('/notification/get_notification', authenticateToken, notifCtrl.getNotifications);
router.post('/notification/set_read_notification', authenticateToken, notifCtrl.markNotificationRead);

// ================= WALLET ROUTES =================
router.post('/wallets/get_current_balance', authenticateToken, walletCtrl.getCurrentBalance);
router.post('/wallets/get_balance_history', authenticateToken, walletCtrl.getBalanceHistory);

// ================= NEWS ROUTES =================
router.post('/News/list_news', newsCtrl.listNews);
router.get('/News/:id', newsCtrl.getNewsDetail);

// ================= SOCIAL ROUTES =================
router.post('/get_list_blocks', authenticateToken, socialCtrl.getListBlocks);
router.post('/set_user_block', authenticateToken, socialCtrl.setUserBlock);
router.post('/get_list_followed', authenticateToken, socialCtrl.getListFollowed);
router.post('/get_list_following', authenticateToken, socialCtrl.getListFollowing);
router.post('/set_user_follow', authenticateToken, socialCtrl.setUserFollow);

// ================= UPLOAD ROUTE =================
router.post('/upload/file', authenticateToken, upload.single('file'), uploadCtrl.uploadFile);

// Health check route
router.get('/', (_req, res) => {
  res.send('Army Ecommerce Backend is running successfully!');
});

export default router;
