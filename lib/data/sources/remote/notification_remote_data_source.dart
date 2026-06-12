import 'package:army_ecommerce/core/network/api_exception.dart';
import 'package:army_ecommerce/core/api/dio_client.dart';
import 'package:army_ecommerce/core/constants/api_paths.dart';
import 'package:army_ecommerce/models/api_response.dart';
import 'package:dio/dio.dart';

class NotificationRemoteDataSource {
  final DioClient _dioClient;

  NotificationRemoteDataSource({required DioClient dioClient}) : _dioClient = dioClient;

  Future<ApiResponse<dynamic>> getNotification({
    required int index,
    required int count,
    required int group,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.getNotification,
        data: {
          'index': index,
          'count': count,
          'group': group,
        },
      );
      return ApiResponse.fromDynamic(response.data, (json) => json);
    } on DioException catch (e) {
      throw Exception(ApiException.getMessage(e));
    }
  }

  Future<ApiResponse<dynamic>> setReadNotification({
    required String notificationId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.setReadNotification,
        data: {
          'notification_id': int.tryParse(notificationId) ?? 0,
        },
      );
      return ApiResponse.fromDynamic(response.data, (json) => json);
    } on DioException catch (e) {
      throw Exception(ApiException.getMessage(e));
    }
  }
}
