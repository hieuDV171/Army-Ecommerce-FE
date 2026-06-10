import 'package:army_ecommerce/core/api/dio_client.dart';
import 'package:army_ecommerce/core/constants/api_paths.dart';
import 'package:army_ecommerce/models/api_response.dart';
import 'package:dio/dio.dart';

class BlockRemoteDataSource {
  final DioClient _dioClient;

  BlockRemoteDataSource({required DioClient dioClient}) : _dioClient = dioClient;

  Future<ApiResponse<dynamic>> setBlocks({
    required String userId,
    required String action,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.setUserBlock,
        data: {
          'user_id': userId,
          'type': action == 'block' ? 0 : 1,
        },
      );
      return ApiResponse.fromDynamic(response.data, (json) => json);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }

  Future<ApiResponse<dynamic>> getListBlocks({
    required int index,
    required int count,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.getListBlocks,
        data: {
          'index': index,
          'count': count,
        },
      );
      return ApiResponse.fromDynamic(response.data, (json) => json);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }
}
