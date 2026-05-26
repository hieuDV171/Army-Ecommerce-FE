import 'package:army_ecommerce/models/api_response.dart';
import 'package:army_ecommerce/models/push_setting_model.dart';
import '../../../core/constants/api_paths.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/services/session_manager.dart';
import 'package:dio/dio.dart';

class SettingRemoteDataSource {
  final DioClient _dioClient;

  SettingRemoteDataSource({required DioClient dioClient}) : _dioClient = dioClient;

  Future<ApiResponse<PushSettingModel>> getPushSetting() async {
    try {
      final token = await SessionManager.getToken();

      final response = await _dioClient.dio.post(
        ApiPaths.getPushSetting,
        data: {
          'token': token
        },
      );

      return ApiResponse<PushSettingModel>.fromJson(
          response.data,
              (json) => PushSettingModel.fromJson(json as Map<String, dynamic>)
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Lỗi kết nối mạng");
    } catch (e) {
      throw Exception('Lỗi lấy cài đặt thông báo: $e');
    }
  }

  Future<ApiResponse<String?>> setPushSetting({
    String? like,
    String? comment,
    String? transaction,
    String? announcement,
    String? soundOn,
    String? soundDefault,
  }) async {
    try {
      final token = await SessionManager.getToken();
      final request = <String, dynamic>{
        'token': token ?? '',
      };
      if (like != null) request['like'] = like;
      if (comment != null) request['comment'] = comment;
      if (transaction != null) request['transaction'] = transaction;
      if (announcement != null) request['announcement'] = announcement;
      if (soundOn != null) request['sound_on'] = soundOn;
      if (soundDefault != null) request['sound_default'] = soundDefault;

      final response = await _dioClient.dio.post(
          ApiPaths.setPushSetting,
          data: request
      );

      return ApiResponse<String?>.fromJson(
        response.data,
            (json) => json?.toString(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Lỗi kết nối mạng");
    } catch (e) {
      throw Exception('Lỗi cập nhật cài đặt thông báo: $e');
    }
  }
}
