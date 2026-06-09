class ApiPaths {
  // Auth & Profile
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const logout = '/auth/logout';
  static const me = '/auth/me';
  static const changeInfoAfterSignup = '/auth/change_info_after_signup';
  static const changePassword = '/auth/change_password';
  static const createCodeResetPassword = '/auth/create_code_reset_password';
  static const checkCodeResetPassword = '/auth/check_code_reset_password';
  static const resetPassword = '/auth/reset_password';
  static const setDevToken = '/auth/set_dev_token';
  static const getUserInfo = '/users/get_user_info';
  static const setUserInfo = '/users/set_user_info';
  static const uploadFile = '/upload/file';

  // Push Settings
  static const getPushSetting = '/push_settings/get_push_setting';
  static const setPushSetting = '/push_settings/set_push_setting';

  // Marketplace & Products
  static const categories = '/api/get_categories';
  static const brands = '/api/get_list_brands';
  static const listProducts = '/api/get_list_products';
  static const productDetail = '/api/get_products';
  static const search = '/api/search';
  static const saveSearch = '/api/save_search';
  static const savedSearches = '/api/get_saved_searches';
  static const likeProduct = '/api/like_product';
  static const getCommentsProduct = '/api/get_comments_product';
  static const setCommentsProduct = '/api/set_comments_product';
  static const reportProduct = '/api/report_product';
  static const getRates = '/api/get_rates';
  static const setRates = '/api/set_rates';
  static const addProduct = '/api/add_product';
  static String updateProduct(String id) => '/api/update/$id';
  static String deleteProduct(String id) => '/api/delete/$id';

  // News
  static const listNews = '/News/list_news';
  static String newsDetail(String id) => '/News/$id';

  // Orders & Addresses
  static const getListOrderAddress = '/order/get_list_order_address';
  static const addOrderAddress = '/order/add_order_address';
  static String updateAddress(String id) => '/order/update/$id';
  static String deleteAddress(String id) => '/order/delete/$id';
  static const getListPurchases = '/order/get_list_purchases';
  static const getPurchase = '/order/get_purchase';
  static const getShipFee = '/order/get_ship_fee';
  static const createOrder = '/order/create_order';
  static const editPurchase = '/order/edit_purchase';
  static const cancelOrder = '/order/cancel_order';
  static const buyerConfirmReceived = '/order/buyer_confirm_received';
  static const sellerMarkAsShipped = '/order/seller_mark_as_shipped';
  static const refundOrder = '/order/refund_order';
  static const setAcceptBuyer = '/order/set_accept_buyer';
  static const getOrderTimeline = '/order/get_order_timeline';
  static const getProvinces = '/order/provinces';
  static const getWards = '/order/wards';

  // Wallet
  static const getBalanceHistory = '/wallets/get_balance_history';
  static const getCurrentBalance = '/wallets/get_current_balance';

  // Follow
  static const setUserFollow = '/set_user_follow';
  static const getListFollowed = '/get_list_followed';
  static const getListFollowing = '/get_list_following';

  // Chat / Conversations
  static const sendMessage = '/conversation/send_message';
  static const getListConversation = '/conversation/get_list_conversation';
  static const getConversation = '/conversation/get_conversation';
  static const setReadMessage = '/conversation/set_read_message';

  // Blocks
  static const setUserBlock = '/set_user_block';
  static const getListBlocks = '/get_list_blocks';

  // Notifications
  static const getNotification = '/notification/get_notification';
  static const setReadNotification = '/notification/set_read_notification';
}
