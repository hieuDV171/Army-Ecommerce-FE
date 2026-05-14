import 'package:army_ecommerce/core/api/dio_client.dart';
import 'package:army_ecommerce/models/user_follow_model.dart';
import 'package:dio/dio.dart';

class FollowRepository {
  final DioClient _dioClient;

  FollowRepository({required DioClient dioClient}) : _dioClient = dioClient;

  // Follow hoặc unfollow một user
  // action: 'follow' | 'unfollow'
  Future<FollowActionResponse> setUserFollow({
    required String followeeId,
    required String action,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/set_user_follow',
        data: {
          'followee_id': followeeId,
          'action': action,
        },
      );

      return FollowActionResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }

  // Lấy danh sách user đang theo dõi user_id (người theo dõi của user_id)
  Future<UserFollowListResponse> getListFollowed({
    required String userId,
    required int index,
    required int count,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/get_list_followed',
        data: {
          'user_id': userId,
          'index': index,
          'count': count,
        },
      );

      return UserFollowListResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }

  // Lấy danh sách user mà user_id đang theo dõi
  Future<UserFollowListResponse> getListFollowing({
    required String userId,
    required int index,
    required int count,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/get_list_following',
        data: {
          'user_id': userId,
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
