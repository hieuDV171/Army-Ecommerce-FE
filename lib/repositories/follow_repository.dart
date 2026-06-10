import 'package:army_ecommerce/models/user_follow_model.dart';

abstract class FollowRepository {
  Future<FollowActionResponse> setUserFollow({
    required String followeeId,
    required String action,
  });

  Future<UserFollowListResponse> getListFollowed({
    required String userId,
    required int index,
    required int count,
  });

  Future<UserFollowListResponse> getListFollowing({
    required String userId,
    required int index,
    required int count,
  });
}
