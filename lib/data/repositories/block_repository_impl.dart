import 'package:army_ecommerce/data/sources/remote/block_remote_data_source.dart';
import 'package:army_ecommerce/models/message_model.dart';
import 'package:army_ecommerce/models/user_follow_model.dart';
import 'package:army_ecommerce/repositories/block_repository.dart';

class BlockRepositoryImpl implements BlockRepository {
  final BlockRemoteDataSource remoteDataSource;

  BlockRepositoryImpl({required this.remoteDataSource});

  @override
  Future<SimpleResponse> setBlocks({
    required String userId,
    required String action,
  }) async {
    final response = await remoteDataSource.setBlocks(
      userId: userId,
      action: action,
    );
    return SimpleResponse.fromJson(response.rawJson);
  }

  @override
  Future<UserFollowListResponse> getListBlocks({
    required int index,
    required int count,
  }) async {
    final response = await remoteDataSource.getListBlocks(
      index: index,
      count: count,
    );
    return UserFollowListResponse.fromJson(response.rawJson);
  }
}
