import 'package:army_ecommerce/core/network/api_exception.dart';
import 'package:army_ecommerce/core/api/dio_client.dart';
import 'package:army_ecommerce/core/constants/api_paths.dart';
import 'package:army_ecommerce/models/api_response.dart';
import 'package:dio/dio.dart';

class FollowRemoteDataSource {
  final DioClient _dioClient;

  FollowRemoteDataSource({required DioClient dioClient})
    : _dioClient = dioClient;

  Future<ApiResponse<dynamic>> setUserFollow({
    required String followeeId,
    required String action,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.setUserFollow,
        data: {'followee_id': followeeId, 'action': action},
      );
      return ApiResponse.fromDynamic(response.data, (json) => json);
    } on DioException catch (e) {
      throw Exception(ApiException.getMessage(e));
    }
  }

  Future<ApiResponse<dynamic>> getListFollowed({
    required String userId,
    required int index,
    required int count,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.getListFollowed,
        data: {'user_id': userId, 'index': index, 'count': count},
      );
      return ApiResponse.fromDynamic(response.data, (json) => json);
    } on DioException catch (e) {
      throw Exception(ApiException.getMessage(e));
    }
  }

  Future<ApiResponse<dynamic>> getListFollowing({
    required String userId,
    required int index,
    required int count,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.getListFollowing,
        data: {'user_id': userId, 'index': index, 'count': count},
      );
      return ApiResponse.fromDynamic(response.data, (json) => json);
    } on DioException catch (e) {
      throw Exception(ApiException.getMessage(e));
    }
  }
}
