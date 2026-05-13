import 'package:army_ecommerce/core/api/dio_client.dart';
import 'package:army_ecommerce/core/services/session_manager.dart';
import 'package:army_ecommerce/models/message_model.dart';
import 'package:army_ecommerce/models/user_follow_model.dart';
import 'package:dio/dio.dart';

class BlockRepository {
  final DioClient _dioClient;

  BlockRepository({required DioClient dioClient}) : _dioClient = dioClient;

  // Block hoặc unblock một user
  // action: 'block' | 'unblock'
  Future<SimpleResponse> setBlocks({
    required String userId,
    required String action,
  }) async {
    try {
      final token = await SessionManager.getToken();

      final response = await _dioClient.dio.post(
        '/users/set_blocks',
        data: {
          'token': token,
          'user_id': userId,
          'action': action,
        },
      );

      return SimpleResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }

  // Lấy danh sách user mà người dùng hiện tại đã chặn
  Future<UserFollowListResponse> getListBlocks({
    required int index,
    required int count,
  }) async {
    try {
      final token = await SessionManager.getToken();

      final response = await _dioClient.dio.post(
        '/users/get_list_blocks',
        data: {
          'token': token,
          'index': index,
          'count': count,
        },
      );

      return UserFollowListResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }
}
