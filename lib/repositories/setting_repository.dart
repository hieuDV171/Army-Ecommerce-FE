import 'package:army_ecommerce/models/api_response.dart';
import 'package:army_ecommerce/models/push_setting_model.dart';

abstract class SettingRepository {
  Future<ApiResponse<PushSettingModel>> getPushSetting();

  Future<ApiResponse<String?>> setPushSetting({
    String? like,
    String? comment,
    String? transaction,
    String? announcement,
    String? soundOn,
    String? soundDefault,
  });
}
