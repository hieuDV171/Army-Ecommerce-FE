import 'package:army_ecommerce/core/api/dio_client.dart';
import 'package:dio/dio.dart';

import '../core/services/session_manager.dart';
import '../models/api_response.dart';
import '../models/push_setting_model.dart';

class SettingRepository {
  final DioClient _dioClient;

  SettingRepository({required DioClient dioClient}) : _dioClient = dioClient;

  Future<ApiResponse<PushSettingModel>> getPushSetting() async {
    try {
      final token = await SessionManager.getToken();

      final response = await _dioClient.dio.post(
        '/push_settings/get_push_setting',
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
    String? soundDefault
  }) async {
    try {
      final token = await SessionManager.getToken();

      final request = SetPushSettingRequest(
          token: token ?? "",
          like: like,
          comment: comment,
          transaction: transaction,
          announcement: announcement,
          soundOn: soundOn,
          soundDefault: soundDefault
      );

      final response = await _dioClient.dio.post(
          'push_settings/set_push_setting',
          data: request.toJson()
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