class ApiPaths {
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
  static const getPushSetting = '/push_settings/get_push_setting';
  static const setPushSetting = '/push_settings/set_push_setting';
  static const getUserInfo = '/users/get_user_info';
  static const setUserInfo = '/users/set_user_info';
  static const uploadFile = '/upload/file';

  static const categories = '/api/get_categories';
  static const brands = '/api/get_list_brands';
  static const listProducts = '/api/get_list_products';
  static const productDetail = '/api/get_products';
  static const search = '/api/search_products';
  static const saveSearch = '/api/save_search';
  static const savedSearches = '/api/get_saved_searches';
}
