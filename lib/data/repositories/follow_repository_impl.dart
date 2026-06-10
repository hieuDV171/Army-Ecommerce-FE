import 'package:army_ecommerce/data/sources/remote/follow_remote_data_source.dart';
import 'package:army_ecommerce/models/user_follow_model.dart';
import 'package:army_ecommerce/repositories/follow_repository.dart';

class FollowRepositoryImpl implements FollowRepository {
  final FollowRemoteDataSource remoteDataSource;

  FollowRepositoryImpl({required this.remoteDataSource});

  @override
  Future<FollowActionResponse> setUserFollow({
    required String followeeId,
    required String action,
  }) async {
    final response = await remoteDataSource.setUserFollow(
      followeeId: followeeId,
      action: action,
    );
    return FollowActionResponse.fromJson(response.rawJson);
  }

  @override
  Future<UserFollowListResponse> getListFollowed({
    required String userId,
    required int index,
    required int count,
  }) async {
    final response = await remoteDataSource.getListFollowed(
      userId: userId,
      index: index,
      count: count,
    );
    return UserFollowListResponse.fromJson(response.rawJson);
  }

  @override
  Future<UserFollowListResponse> getListFollowing({
    required String userId,
    required int index,
    required int count,
  }) async {
    final response = await remoteDataSource.getListFollowing(
      userId: userId,
      index: index,
      count: count,
    );
    return UserFollowListResponse.fromJson(response.rawJson);
  }
}
